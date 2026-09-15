-- Combined Phase 1–3 Codex audit remediation regression.
-- Proves the three accepted backend blockers remain closed:
--   1) generic private order writer is not client-executable;
--   2) matching POS retries resolve after shift lock without creating a new order;
--   3) account deletion removes the digest of the original customer payload.
-- Transactional: all synthetic state rolls back.

begin;

do $$
begin
  if has_function_privilege(
    'authenticated',
    'private.create_order_impl_v2(jsonb,text,uuid,uuid,uuid,text)',
    'execute'
  ) then
    raise exception 'authenticated can execute generic private order writer';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.place_pos_order(jsonb,text)',
    'execute'
  ) then
    raise exception 'authenticated is missing trusted POS placement RPC';
  end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
  ('67000000-0000-0000-0000-000000000001','audit-pos-staff@example.test','{}'::jsonb,now(),now()),
  ('67000000-0000-0000-0000-000000000002','audit-admin@example.test','{}'::jsonb,now(),now()),
  ('67000000-0000-0000-0000-000000000003','audit-customer@example.test','{}'::jsonb,now(),now());

update public.user_profiles set app_role='staff'
where user_id='67000000-0000-0000-0000-000000000001';
update public.user_profiles set app_role='admin'
where user_id='67000000-0000-0000-0000-000000000002';

set local role authenticated;

do $$
declare
  v_staff uuid := '67000000-0000-0000-0000-000000000001';
  v_admin uuid := '67000000-0000-0000-0000-000000000002';
  v_terminal_id uuid;
  v_issue jsonb;
  v_enrol jsonb;
  v_credential text;
  v_shift jsonb;
  v_shift_id uuid;
  v_shift_version bigint;
  v_item uuid;
  v_payload jsonb;
  v_order jsonb;
  v_retry jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );

  select (terminal->>'id')::uuid
  into strict v_terminal_id
  from jsonb_array_elements(public.list_admin_operational_locations()) branch,
       jsonb_array_elements(branch->'salesPoints') sales_point,
       jsonb_array_elements(sales_point->'terminals') terminal
  where terminal->>'code'='POS-MAIN-01';

  select public.issue_terminal_enrolment_code(v_terminal_id) into v_issue;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff,'role','authenticated')::text,
    true
  );
  select public.enrol_terminal(v_issue->>'code') into v_enrol;
  v_credential := v_enrol->>'credential';

  select public.open_shift(v_credential,5000) into v_shift;
  v_shift_id := (v_shift->>'id')::uuid;
  v_shift_version := (v_shift->>'statusVersion')::bigint;

  select id into strict v_item
  from public.catalogue_items
  where kind='product'
    and is_published
    and is_available
    and not is_drink
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=catalogue_items.id and v.is_available
    )
  order by created_at,id
  limit 1;

  v_payload := jsonb_build_object(
    'clientRequestId','67100000-0000-0000-0000-000000000001',
    'fulfillmentType','asap',
    'tenderType','unpaid',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item,
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  );

  select public.place_pos_order(v_payload,v_credential) into v_order;
  if v_order->>'shiftId' <> v_shift_id::text then
    raise exception 'new POS order did not receive open-shift attribution';
  end if;

  select public.lock_shift(v_shift_id,v_credential,v_shift_version) into v_shift;
  if v_shift->>'status' <> 'locked' then
    raise exception 'audit shift did not lock';
  end if;

  -- A transport retry of the exact already-persisted request must resolve the
  -- immutable existing order even though no new order may be created now.
  select public.place_pos_order(v_payload,v_credential) into v_retry;
  if v_retry->>'id' is distinct from v_order->>'id'
     or v_retry->>'shiftId' is distinct from v_order->>'shiftId' then
    raise exception 'locked-shift idempotent retry did not resolve existing POS order';
  end if;

  if (
    select count(*) from public.orders
    where created_by_user_id=v_staff
      and client_request_id='67100000-0000-0000-0000-000000000001'
  ) <> 1 then
    raise exception 'locked-shift retry duplicated POS order';
  end if;
end;
$$;

reset role;

set local role authenticated;
do $$
declare
  v_customer uuid := '67000000-0000-0000-0000-000000000003';
  v_item uuid;
  v_order jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_customer,'role','authenticated')::text,
    true
  );

  select id into strict v_item
  from public.catalogue_items
  where kind='product'
    and is_published
    and is_available
    and not is_drink
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=catalogue_items.id and v.is_available
    )
  order by created_at,id
  limit 1;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId','67100000-0000-0000-0000-000000000002',
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item,
      'addOnIds','[]'::jsonb,
      'quantity',1,
      'note','private low entropy audit note'
    ))
  )) into v_order;

  if nullif(v_order->>'id','') is null then
    raise exception 'audit customer order was not created';
  end if;
end;
$$;
reset role;

do $$
declare
  v_order_id uuid;
  v_before_hash text;
begin
  select id,request_hash into strict v_order_id,v_before_hash
  from public.orders
  where client_request_id='67100000-0000-0000-0000-000000000002';

  if v_before_hash = md5('deleted:'||v_order_id::text) then
    raise exception 'customer request digest was already deletion marker before deletion';
  end if;

  perform set_config('aida.audit_original_request_hash',v_before_hash,true);
end;
$$;

set local role authenticated;
do $$
declare v_customer uuid := '67000000-0000-0000-0000-000000000003';
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_customer,'role','authenticated')::text,
    true
  );
  perform public.delete_own_account();
end;
$$;
reset role;

do $$
declare
  v_order_id uuid;
  v_hash text;
begin
  select id,request_hash into strict v_order_id,v_hash
  from public.orders
  where client_request_id='67100000-0000-0000-0000-000000000002';

  if v_hash <> md5('deleted:'||v_order_id::text) then
    raise exception 'deleted customer retained original payload-derived request digest';
  end if;

  if exists (
    select 1 from public.order_lines
    where order_id=v_order_id and note is not null
  ) then
    raise exception 'deleted customer retained order-line free text';
  end if;
end;
$$;

rollback;
