-- TASK-OPS-001 branch/location authority regression.
-- Runs transactionally and leaves no synthetic users, branches, assignments or orders behind.

begin;

do $$
begin
  if not exists (
    select 1
    from information_schema.tables
    where table_schema = 'public' and table_name = 'branches'
  ) then
    raise exception 'branches table is missing';
  end if;

  if not exists (
    select 1
    from information_schema.tables
    where table_schema = 'public' and table_name = 'employee_branch_assignments'
  ) then
    raise exception 'employee_branch_assignments table is missing';
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'branch_id'
      and is_nullable = 'NO'
  ) then
    raise exception 'orders.branch_id is missing or nullable';
  end if;

  if (select count(*) from public.branches where is_default and is_active) <> 1 then
    raise exception 'exactly one active default branch is required';
  end if;

  if exists (select 1 from public.orders where branch_id is null) then
    raise exception 'existing order has no trusted branch';
  end if;

  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'branches'
      and c.relrowsecurity
      and c.relforcerowsecurity
  ) then
    raise exception 'branches does not have forced RLS';
  end if;

  if not exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'employee_branch_assignments'
      and c.relrowsecurity
      and c.relforcerowsecurity
  ) then
    raise exception 'employee branch assignments does not have forced RLS';
  end if;

  if not has_function_privilege('anon', 'public.list_branches()', 'execute') then
    raise exception 'anonymous clients cannot list active branches';
  end if;

  if has_function_privilege('anon', 'public.save_branch(jsonb)', 'execute')
     or has_function_privilege(
       'anon',
       'public.save_employee_branch_assignments(uuid,uuid[])',
       'execute'
     ) then
    raise exception 'anonymous role has privileged branch mutation capability';
  end if;

  if has_table_privilege('authenticated', 'public.branches', 'insert')
     or has_table_privilege('authenticated', 'public.branches', 'update')
     or has_table_privilege('authenticated', 'public.branches', 'delete')
     or has_table_privilege(
       'authenticated',
       'public.employee_branch_assignments',
       'insert'
     )
     or has_table_privilege(
       'authenticated',
       'public.employee_branch_assignments',
       'update'
     )
     or has_table_privilege(
       'authenticated',
       'public.employee_branch_assignments',
       'delete'
     ) then
    raise exception 'authenticated clients have direct branch mutation grants';
  end if;
end;
$$;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values
  (
    '40000000-0000-0000-0000-000000000001',
    'branch-staff@example.test',
    '{}'::jsonb,
    now(),
    now()
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    'branch-admin@example.test',
    '{}'::jsonb,
    now(),
    now()
  );

update public.user_profiles
set app_role = 'staff'
where user_id = '40000000-0000-0000-0000-000000000001';

update public.user_profiles
set app_role = 'admin'
where user_id = '40000000-0000-0000-0000-000000000002';

do $$
declare
  v_default uuid := (select private.default_branch_id());
begin
  if not exists (
    select 1
    from public.employee_branch_assignments
    where user_id = '40000000-0000-0000-0000-000000000001'
      and branch_id = v_default
  ) then
    raise exception 'staff role promotion did not assign the default branch';
  end if;
end;
$$;

set local role authenticated;

do $$
declare
  v_admin_id uuid := '40000000-0000-0000-0000-000000000002';
  v_branch jsonb;
  v_branch_id uuid;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_admin_id, 'role', 'authenticated')::text,
    true
  );

  select public.save_branch(jsonb_build_object(
    'code', 'BR-TEST',
    'name', 'Regression Branch',
    'timezone', 'Asia/Kuala_Lumpur',
    'isActive', true,
    'isDefault', false
  )) into v_branch;

  v_branch_id := (v_branch ->> 'id')::uuid;

  if v_branch_id is null
     or v_branch ->> 'code' <> 'BR-TEST'
     or (v_branch ->> 'isActive')::boolean is not true
     or (v_branch ->> 'isDefault')::boolean is not false then
    raise exception 'admin branch creation returned an invalid snapshot: %', v_branch;
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(public.list_admin_branches()) item
    where item ->> 'id' = v_branch_id::text
  ) then
    raise exception 'admin branch directory omitted the created branch';
  end if;
end;
$$;

reset role;

insert into public.orders (
  source,
  branch_id,
  customer_user_id,
  member_id,
  created_by_user_id,
  client_request_id,
  request_hash,
  fulfillment_type,
  requested_pickup_at,
  prepare_at,
  status,
  pricing_version,
  subtotal_sen,
  total_sen
)
values (
  'pos',
  (select id from public.branches where code = 'BR-TEST'),
  null,
  null,
  '40000000-0000-0000-0000-000000000002',
  '41000000-0000-0000-0000-000000000001',
  'branch-scope-regression',
  'asap',
  null,
  null,
  'confirmed',
  2,
  0,
  0
);

do $$
declare
  v_order_id uuid := (
    select id
    from public.orders
    where client_request_id = '41000000-0000-0000-0000-000000000001'
  );
begin
  begin
    update public.orders
    set branch_id = private.default_branch_id()
    where id = v_order_id;
    raise exception 'persisted order branch unexpectedly changed';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

set local role authenticated;

do $$
declare
  v_staff_id uuid := '40000000-0000-0000-0000-000000000001';
  v_order_id uuid := (
    select id
    from public.orders
    where client_request_id = '41000000-0000-0000-0000-000000000001'
  );
  v_orders jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_staff_id, 'role', 'authenticated')::text,
    true
  );

  select public.list_orders(array['confirmed'], 250) into v_orders;

  if exists (
    select 1
    from jsonb_array_elements(v_orders) item
    where item ->> 'id' = v_order_id::text
  ) then
    raise exception 'unassigned staff saw an order from another branch';
  end if;

  if public.get_order(v_order_id) is not null then
    raise exception 'unassigned staff read another branch order by ID';
  end if;

  begin
    perform public.transition_order_status(v_order_id, 'preparing', 1, null);
    raise exception 'unassigned staff transitioned another branch order';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.save_branch('{"code":"BR-NOPE","name":"Nope"}'::jsonb);
    raise exception 'ordinary staff unexpectedly mutated branch configuration';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.branches (code, name)
    values ('BR-DIRECT', 'Direct Write');
    raise exception 'ordinary staff unexpectedly inserted a branch directly';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

do $$
declare
  v_admin_id uuid := '40000000-0000-0000-0000-000000000002';
  v_staff_id uuid := '40000000-0000-0000-0000-000000000001';
  v_default uuid := (select private.default_branch_id());
  v_test uuid := (select id from public.branches where code = 'BR-TEST');
  v_saved jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_admin_id, 'role', 'authenticated')::text,
    true
  );

  select public.save_employee_branch_assignments(
    v_staff_id,
    array[v_default, v_test]
  ) into v_saved;

  if jsonb_array_length(v_saved) <> 2 then
    raise exception 'admin employee branch assignment update failed: %', v_saved;
  end if;
end;
$$;

do $$
declare
  v_staff_id uuid := '40000000-0000-0000-0000-000000000001';
  v_order_id uuid := (
    select id
    from public.orders
    where client_request_id = '41000000-0000-0000-0000-000000000001'
  );
  v_orders jsonb;
  v_order jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_staff_id, 'role', 'authenticated')::text,
    true
  );

  select public.list_orders(array['confirmed'], 250) into v_orders;

  if not exists (
    select 1
    from jsonb_array_elements(v_orders) item
    where item ->> 'id' = v_order_id::text
      and item #>> '{branch,code}' = 'BR-TEST'
  ) then
    raise exception 'assigned staff did not receive branch-scoped order';
  end if;

  select public.transition_order_status(
    v_order_id,
    'preparing',
    1,
    'Branch authority regression'
  ) into v_order;

  if v_order ->> 'status' <> 'preparing'
     or v_order #>> '{branch,code}' <> 'BR-TEST' then
    raise exception 'assigned branch transition returned an invalid order snapshot';
  end if;
end;
$$;

reset role;

set local role anon;

do $$
declare
  v_branches jsonb;
begin
  select public.list_branches() into v_branches;

  if not exists (
    select 1
    from jsonb_array_elements(v_branches) item
    where item ->> 'code' = 'BR-MAIN'
  ) then
    raise exception 'public branch list omitted the active default branch';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(v_branches) item
    where item ->> 'code' = 'BR-TEST'
  ) then
    raise exception 'public branch list omitted the active regression branch';
  end if;
end;
$$;

reset role;

rollback;
