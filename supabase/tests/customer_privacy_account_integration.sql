-- TASK-PRIVACY-001 / Phase 3 customer privacy and account-deletion regression.
-- Transactional: no synthetic users/orders/preferences survive.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'customer_deleted_at'
  ) then
    raise exception 'orders.customer_deleted_at is missing';
  end if;

  if not exists (
    select 1 from information_schema.tables
    where table_schema = 'public'
      and table_name = 'customer_privacy_preferences'
  ) then
    raise exception 'customer_privacy_preferences is missing';
  end if;

  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'customer_privacy_preferences'
      and c.relrowsecurity
      and c.relforcerowsecurity
  ) then
    raise exception 'customer_privacy_preferences does not have forced RLS';
  end if;

  if has_function_privilege('anon', 'public.delete_own_account()', 'execute')
     or has_function_privilege(
       'anon',
       'public.save_my_privacy_preferences(boolean,boolean)',
       'execute'
     ) then
    raise exception 'anonymous role has customer privacy mutation authority';
  end if;

  if not has_function_privilege(
       'authenticated',
       'public.delete_own_account()',
       'execute'
     )
     or not has_function_privilege(
       'authenticated',
       'public.save_my_privacy_preferences(boolean,boolean)',
       'execute'
     ) then
    raise exception 'authenticated customer privacy RPC grants are missing';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'delete_own_account'
      and pg_get_function_arguments(p.oid) <> ''
  ) then
    raise exception 'delete_own_account unexpectedly accepts a target argument';
  end if;

  if has_table_privilege(
       'authenticated',
       'public.customer_privacy_preferences',
       'select'
     )
     or has_table_privilege(
       'authenticated',
       'public.customer_privacy_preferences',
       'insert'
     )
     or has_table_privilege(
       'authenticated',
       'public.customer_privacy_preferences',
       'update'
     ) then
    raise exception 'privacy preference table is directly exposed to authenticated';
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'created_by_user_id'
      and is_nullable <> 'YES'
  ) then
    raise exception 'orders.created_by_user_id is still non-nullable';
  end if;
end;
$$;

set local role anon;

do $$
begin
  begin
    perform public.delete_own_account();
    raise exception 'anonymous account deletion unexpectedly succeeded';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.save_my_privacy_preferences(false, true);
    raise exception 'anonymous privacy preference update unexpectedly succeeded';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

reset role;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values
  ('51000000-0000-0000-0000-000000000001', 'privacy-order@example.test', '{}'::jsonb, now(), now()),
  ('51000000-0000-0000-0000-000000000002', 'privacy-other@example.test', '{}'::jsonb, now(), now()),
  ('51000000-0000-0000-0000-000000000003', 'privacy-empty@example.test', '{}'::jsonb, now(), now()),
  ('51000000-0000-0000-0000-000000000004', 'privacy-staff@example.test', '{}'::jsonb, now(), now());

update public.user_profiles
set app_role = 'staff'
where user_id = '51000000-0000-0000-0000-000000000004';

-- Synthetic legacy POS record proves customer deletion does not weaken the
-- staff actor audit trail. This uses server-level test setup, not a client path.
insert into public.orders (
  source,
  customer_user_id,
  member_id,
  created_by_user_id,
  branch_id,
  client_request_id,
  request_hash,
  fulfillment_type,
  status,
  currency,
  pricing_version,
  subtotal_sen,
  total_sen
) values (
  'pos',
  null,
  null,
  '51000000-0000-0000-0000-000000000004',
  (select id from public.branches where is_default and is_active limit 1),
  '51100000-0000-0000-0000-000000000004',
  'phase3-pos-audit',
  'asap',
  'confirmed',
  'MYR',
  2,
  100,
  100
);

set local role authenticated;

do $$
declare
  v_customer_with_order uuid := '51000000-0000-0000-0000-000000000001';
  v_other_customer uuid := '51000000-0000-0000-0000-000000000002';
  v_empty_customer uuid := '51000000-0000-0000-0000-000000000003';
  v_staff uuid := '51000000-0000-0000-0000-000000000004';
  v_item_id uuid;
  v_preferences jsonb;
  v_order jsonb;
  v_delete jsonb;
begin
  select id into strict v_item_id
  from public.catalogue_items
  where sku = 'FD-SAN'
    and kind = 'product'
    and is_published
    and is_available;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_customer_with_order, 'role', 'authenticated')::text,
    true
  );

  select public.get_my_privacy_preferences() into v_preferences;
  if (v_preferences ->> 'marketingNotificationsEnabled')::boolean
     or not (v_preferences ->> 'transactionalNotificationsEnabled')::boolean then
    raise exception 'privacy preference defaults are incorrect: %', v_preferences;
  end if;

  select public.save_my_privacy_preferences(true, false) into v_preferences;
  if not (v_preferences ->> 'marketingNotificationsEnabled')::boolean
     or (v_preferences ->> 'transactionalNotificationsEnabled')::boolean then
    raise exception 'privacy preference save failed: %', v_preferences;
  end if;

  begin
    perform * from public.customer_privacy_preferences;
    raise exception 'customer unexpectedly has direct preference table access';
  exception when insufficient_privilege then
    null;
  end;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId', '51100000-0000-0000-0000-000000000001',
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  )) into v_order;

  if v_order ->> 'source' <> 'customer'
     or v_order ->> 'customerUserId' <> v_customer_with_order::text then
    raise exception 'customer regression order was not created correctly';
  end if;

  begin
    update public.orders
    set customer_deleted_at = now()
    where client_request_id = '51100000-0000-0000-0000-000000000001';
    raise exception 'customer unexpectedly mutated deletion state directly';
  exception when insufficient_privilege then
    null;
  end;

  select public.delete_own_account() into v_delete;
  if (v_delete ->> 'retainedOrderCount')::integer <> 1
     or nullif(v_delete ->> 'deletedAt', '') is null then
    raise exception 'account deletion returned invalid retention result: %', v_delete;
  end if;

  -- Simulate an already-issued access JWT that has not yet expired. The Auth
  -- row is gone, but request claims still contain the old subject.
  begin
    perform public.get_my_privacy_preferences();
    raise exception 'deleted customer stale JWT still read privacy preferences';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.get_my_orders(20);
    raise exception 'deleted customer stale JWT still read personalized order history';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.place_customer_order(jsonb_build_object(
      'clientRequestId', '51100000-0000-0000-0000-000000000005',
      'fulfillmentType', 'asap',
      'items', jsonb_build_array(jsonb_build_object(
        'itemId', v_item_id,
        'addOnIds', '[]'::jsonb,
        'quantity', 1
      ))
    ));
    raise exception 'deleted customer stale JWT still placed a customer order';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.delete_own_account();
    raise exception 'deleted customer stale JWT deleted twice';
  exception when insufficient_privilege then
    null;
  end;

  -- Another customer remains isolated and keeps the default-off marketing
  -- preference; there is no target-user-id parameter to attack customer A.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_other_customer, 'role', 'authenticated')::text,
    true
  );
  select public.get_my_privacy_preferences() into v_preferences;
  if (v_preferences ->> 'marketingNotificationsEnabled')::boolean
     or not (v_preferences ->> 'transactionalNotificationsEnabled')::boolean then
    raise exception 'other customer preference defaults changed unexpectedly';
  end if;

  -- Employee identities are explicitly outside customer self-deletion.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_staff, 'role', 'authenticated')::text,
    true
  );
  begin
    perform public.delete_own_account();
    raise exception 'staff account unexpectedly used customer self-deletion';
  exception when insufficient_privilege then
    null;
  end;

  -- Deletion with no historical orders is valid and retains nothing.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_empty_customer, 'role', 'authenticated')::text,
    true
  );
  select public.delete_own_account() into v_delete;
  if (v_delete ->> 'retainedOrderCount')::integer <> 0 then
    raise exception 'empty account unexpectedly retained orders: %', v_delete;
  end if;
end;
$$;

reset role;

do $$
declare
  v_order public.orders%rowtype;
  v_expected_total bigint;
begin
  if exists (
    select 1 from auth.users
    where id in (
      '51000000-0000-0000-0000-000000000001'::uuid,
      '51000000-0000-0000-0000-000000000003'::uuid
    )
  ) then
    raise exception 'deleted customer Auth rows still exist';
  end if;

  if exists (
    select 1 from public.user_profiles
    where user_id in (
      '51000000-0000-0000-0000-000000000001'::uuid,
      '51000000-0000-0000-0000-000000000003'::uuid
    )
  ) then
    raise exception 'deleted customer profiles still exist';
  end if;

  if exists (
    select 1 from public.members
    where user_id in (
      '51000000-0000-0000-0000-000000000001'::uuid,
      '51000000-0000-0000-0000-000000000003'::uuid
    )
  ) then
    raise exception 'deleted customer memberships still exist';
  end if;

  if exists (
    select 1 from public.customer_privacy_preferences
    where user_id = '51000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'deleted customer preference row still exists';
  end if;

  if not exists (
    select 1 from auth.users
    where id = '51000000-0000-0000-0000-000000000002'
  ) then
    raise exception 'unrelated customer was deleted';
  end if;

  select * into strict v_order
  from public.orders
  where client_request_id = '51100000-0000-0000-0000-000000000001';

  select base_price_sen::bigint into strict v_expected_total
  from public.catalogue_items
  where sku = 'FD-SAN';

  if v_order.source <> 'customer'
     or v_order.customer_user_id is not null
     or v_order.member_id is not null
     or v_order.created_by_user_id is not null
     or v_order.customer_deleted_at is null
     or v_order.total_sen <> v_expected_total
     or v_order.subtotal_sen <> v_expected_total
     or v_order.shift_id is not null
     or v_order.tender_type <> 'unpaid'
     or v_order.payment_state <> 'unpaid'
     or v_order.paid_at is not null then
    raise exception 'retained customer order was not correctly anonymized: %', row_to_json(v_order);
  end if;

  if exists (
    select 1
    from public.order_events e
    where e.order_id = v_order.id
      and e.actor_user_id is not null
  ) then
    raise exception 'retained customer order event still contains Auth identity';
  end if;

  if not exists (
    select 1
    from public.orders o
    where o.client_request_id = '51100000-0000-0000-0000-000000000004'
      and o.source = 'pos'
      and o.created_by_user_id = '51000000-0000-0000-0000-000000000004'
      and o.customer_deleted_at is null
  ) then
    raise exception 'customer deletion weakened POS/staff actor retention';
  end if;

  if exists (
    select 1 from auth.users
    where id = '00000000-0000-0000-0000-000000000001'
      or email = 'deleted-customer@internal.aida.invalid'
  ) then
    raise exception 'synthetic deleted-customer Auth placeholder was created';
  end if;
end;
$$;

rollback;
