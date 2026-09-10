-- TASK-OPS-002 / Phase 1 operational topology regression.
-- Transactional: no synthetic users/branches/terminals/orders survive.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='sales_points'
  ) then
    raise exception 'sales_points table is missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='terminals'
  ) then
    raise exception 'terminals table is missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema='private' and table_name='terminal_credentials'
  ) then
    raise exception 'private terminal credential table is missing';
  end if;

  if has_function_privilege(
      'authenticated',
      'public.place_pos_order(jsonb)',
      'execute'
    ) then
    raise exception 'credentialless POS placement is still executable';
  end if;

  if not has_function_privilege(
      'authenticated',
      'public.place_pos_order(jsonb,text)',
      'execute'
    ) then
    raise exception 'credential-bound POS placement is not executable';
  end if;

  if has_function_privilege('anon','public.enrol_terminal(text)','execute')
     or has_function_privilege(
       'anon',
       'public.resolve_terminal_credential(text)',
       'execute'
     ) then
    raise exception 'anonymous role has terminal enrolment/status capability';
  end if;

  if has_table_privilege('authenticated','public.sales_points','insert')
     or has_table_privilege('authenticated','public.terminals','insert')
     or has_table_privilege(
       'authenticated',
       'private.terminal_credentials',
       'select'
     ) then
    raise exception 'client roles have direct operational-topology table access';
  end if;

  if not exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname='sales_points'
      and c.relrowsecurity
      and c.relforcerowsecurity
  ) then
    raise exception 'sales_points does not have forced RLS';
  end if;

  if not exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public'
      and c.relname='terminals'
      and c.relrowsecurity
      and c.relforcerowsecurity
  ) then
    raise exception 'terminals does not have forced RLS';
  end if;
end;
$$;

insert into auth.users (id,email,raw_user_meta_data,created_at,updated_at)
values
  ('42000000-0000-0000-0000-000000000001','topology-staff@example.test','{}'::jsonb,now(),now()),
  ('42000000-0000-0000-0000-000000000002','topology-admin@example.test','{}'::jsonb,now(),now()),
  ('42000000-0000-0000-0000-000000000003','topology-customer@example.test','{}'::jsonb,now(),now());

update public.user_profiles
set app_role='staff'
where user_id='42000000-0000-0000-0000-000000000001';

update public.user_profiles
set app_role='admin'
where user_id='42000000-0000-0000-0000-000000000002';

set local role authenticated;

do $$
declare
  v_staff_id uuid := '42000000-0000-0000-0000-000000000001';
  v_admin_id uuid := '42000000-0000-0000-0000-000000000002';
  v_customer_id uuid := '42000000-0000-0000-0000-000000000003';
  v_branch jsonb;
  v_branch_id uuid;
  v_sales_point jsonb;
  v_sales_point_id uuid;
  v_terminal jsonb;
  v_terminal_id uuid;
  v_issue jsonb;
  v_code text;
  v_enrol jsonb;
  v_credential text;
  v_context jsonb;
  v_order jsonb;
  v_order_id uuid;
  v_retry jsonb;
  v_customer_order jsonb;
  v_item_id uuid;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin_id,'role','authenticated')::text,
    true
  );

  select public.save_branch(jsonb_build_object(
    'code','BR-OPS-TEST',
    'name','Operational Test Branch',
    'timezone','Asia/Kuala_Lumpur',
    'isActive',true,
    'isDefault',false
  )) into v_branch;
  v_branch_id := (v_branch->>'id')::uuid;

  select public.save_sales_point(jsonb_build_object(
    'branchId',v_branch_id,
    'code','SP-OPS-TEST',
    'name','Operational Test Counter',
    'isActive',true
  )) into v_sales_point;
  v_sales_point_id := (v_sales_point->>'id')::uuid;

  select public.save_terminal(jsonb_build_object(
    'salesPointId',v_sales_point_id,
    'code','POS-OPS-TEST-01',
    'name','Operational Test POS'
  )) into v_terminal;
  v_terminal_id := (v_terminal->>'id')::uuid;

  if v_terminal->>'status' <> 'pending' then
    raise exception 'new terminal is not pending';
  end if;

  select public.issue_terminal_enrolment_code(v_terminal_id) into v_issue;
  v_code := v_issue->>'code';

  if v_code is null
     or char_length(v_code) < 8
     or (v_issue->>'expiresAt')::timestamptz <= now() then
    raise exception 'terminal enrolment code issuance is invalid';
  end if;

  -- Staff starts assigned only to the default branch. Possessing the OTC is
  -- insufficient to activate a terminal in another branch.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_id,'role','authenticated')::text,
    true
  );

  begin
    perform public.enrol_terminal(v_code);
    raise exception 'unassigned staff unexpectedly enrolled another branch terminal';
  exception when insufficient_privilege then
    null;
  end;

  -- The failed authorization must not consume the one-time code.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin_id,'role','authenticated')::text,
    true
  );
  perform public.save_employee_branch_assignments(
    v_staff_id,
    array[(select private.default_branch_id()),v_branch_id]
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_id,'role','authenticated')::text,
    true
  );

  select public.enrol_terminal(v_code) into v_enrol;
  v_credential := v_enrol->>'credential';

  if v_credential is null
     or char_length(v_credential) < 40
     or v_enrol#>>'{location,branchCode}' <> 'BR-OPS-TEST'
     or v_enrol#>>'{location,salesPointCode}' <> 'SP-OPS-TEST'
     or v_enrol#>>'{location,terminalCode}' <> 'POS-OPS-TEST-01' then
    raise exception 'terminal enrolment returned invalid authority: %',v_enrol;
  end if;

  begin
    perform public.enrol_terminal(v_code);
    raise exception 'one-time terminal code was accepted twice';
  exception when invalid_parameter_value then
    null;
  end;

  select public.resolve_terminal_credential(v_credential) into v_context;
  if v_context->>'terminalId' <> v_terminal_id::text
     or v_context->>'branchId' <> v_branch_id::text
     or v_context->>'salesPointId' <> v_sales_point_id::text then
    raise exception 'terminal credential resolved the wrong topology';
  end if;

  select id into strict v_item_id
  from public.catalogue_items
  where kind='product'
    and is_published
    and is_available
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=catalogue_items.id and v.is_available
    )
    and not is_drink
  order by created_at,id
  limit 1;

  select public.place_pos_order(
    jsonb_build_object(
      'clientRequestId','42100000-0000-0000-0000-000000000001',
      'fulfillmentType','asap',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,
        'addOnIds','[]'::jsonb,
        'quantity',1
      ))
    ),
    v_credential
  ) into v_order;

  v_order_id := (v_order->>'id')::uuid;

  if v_order->>'source' <> 'pos'
     or v_order->>'branchId' <> v_branch_id::text
     or v_order->>'salesPointId' <> v_sales_point_id::text
     or v_order->>'terminalId' <> v_terminal_id::text
     or v_order#>>'{salesPoint,code}' <> 'SP-OPS-TEST'
     or v_order#>>'{terminal,code}' <> 'POS-OPS-TEST-01' then
    raise exception 'POS order lacks trusted operational attribution: %',v_order;
  end if;

  select public.place_pos_order(
    jsonb_build_object(
      'clientRequestId','42100000-0000-0000-0000-000000000001',
      'fulfillmentType','asap',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,
        'addOnIds','[]'::jsonb,
        'quantity',1
      ))
    ),
    v_credential
  ) into v_retry;

  if v_retry->>'id' <> v_order_id::text then
    raise exception 'same-terminal idempotent retry created a new order';
  end if;

  begin
    update public.orders
    set terminal_id=(select id from public.terminals where code='POS-MAIN-01')
    where id=v_order_id;
    raise exception 'persisted terminal attribution unexpectedly changed';
  exception when insufficient_privilege then
    null;
  end;

  -- Customer flow remains terminal-free.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_customer_id,'role','authenticated')::text,
    true
  );

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId','42100000-0000-0000-0000-000000000002',
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item_id,
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  )) into v_customer_order;

  if v_customer_order->>'source' <> 'customer'
     or v_customer_order->'salesPoint' is not null
     or v_customer_order->'terminal' is not null
     or v_customer_order->>'salesPointId' is not null
     or v_customer_order->>'terminalId' is not null then
    raise exception 'customer order unexpectedly received terminal authority';
  end if;

  -- Revocation invalidates the credential immediately.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin_id,'role','authenticated')::text,
    true
  );
  select public.revoke_terminal(v_terminal_id) into v_terminal;

  if v_terminal->>'status' <> 'revoked' then
    raise exception 'terminal revocation failed';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_id,'role','authenticated')::text,
    true
  );

  begin
    perform public.resolve_terminal_credential(v_credential);
    raise exception 'revoked terminal credential still resolves';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.place_pos_order(
      jsonb_build_object(
        'clientRequestId','42100000-0000-0000-0000-000000000003',
        'fulfillmentType','asap',
        'items',jsonb_build_array(jsonb_build_object(
          'itemId',v_item_id,
          'addOnIds','[]'::jsonb,
          'quantity',1
        ))
      ),
      v_credential
    );
    raise exception 'revoked terminal credential still places POS orders';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

reset role;
rollback;
