-- TASK-OPS-004 / Phase 4 branch scheduling and pickup authority regression.
-- Transactional: no synthetic users/branches/orders/policy changes survive.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='branch_ordering_policies'
  ) then raise exception 'branch_ordering_policies table is missing'; end if;
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='branch_service_windows'
  ) then raise exception 'branch_service_windows table is missing'; end if;
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='branch_service_exceptions'
  ) then raise exception 'branch_service_exceptions table is missing'; end if;

  if not has_function_privilege('anon','public.quote_order(jsonb)','execute')
     or not has_function_privilege('anon','public.list_pickup_branches()','execute')
     or not has_function_privilege('anon','public.get_branch_pickup_state(uuid,timestamp with time zone)','execute')
     or not has_function_privilege('anon','public.list_branch_pickup_slots(uuid,date)','execute') then
    raise exception 'public pickup read/quote RPC grants are incomplete';
  end if;

  if has_function_privilege('anon','public.save_branch_pickup_configuration(jsonb)','execute')
     or has_function_privilege('anon','public.save_branch_service_exception(jsonb)','execute') then
    raise exception 'anonymous role has branch scheduling mutation authority';
  end if;

  if has_table_privilege('authenticated','public.branch_ordering_policies','insert')
     or has_table_privilege('authenticated','public.branch_service_windows','update')
     or has_table_privilege('authenticated','public.branch_service_exceptions','delete') then
    raise exception 'authenticated role has direct branch scheduling DML';
  end if;

  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='branch_ordering_policies'
      and c.relrowsecurity and c.relforcerowsecurity
  ) or not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='branch_service_windows'
      and c.relrowsecurity and c.relforcerowsecurity
  ) or not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='branch_service_exceptions'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then
    raise exception 'Phase 4 scheduling tables do not all have forced RLS';
  end if;
end;
$$;

insert into auth.users (id,email,raw_user_meta_data,created_at,updated_at)
values
  ('44000000-0000-0000-0000-000000000001','phase4-admin@example.test','{}'::jsonb,now(),now()),
  ('44000000-0000-0000-0000-000000000002','phase4-customer-one@example.test','{}'::jsonb,now(),now()),
  ('44000000-0000-0000-0000-000000000003','phase4-customer-two@example.test','{}'::jsonb,now(),now());

update public.user_profiles set app_role='admin'
where user_id='44000000-0000-0000-0000-000000000001';

set local role authenticated;

do $$
declare
  v_admin_id uuid := '44000000-0000-0000-0000-000000000001';
  v_customer_one uuid := '44000000-0000-0000-0000-000000000002';
  v_customer_two uuid := '44000000-0000-0000-0000-000000000003';
  v_branch jsonb;
  v_branch_id uuid;
  v_config jsonb;
  v_service_date date;
  v_today date;
  v_weekday integer;
  v_pickup_at timestamptz;
  v_item_id uuid;
  v_quote jsonb;
  v_slots jsonb;
  v_order_one jsonb;
  v_order_two jsonb;
  v_cancelled jsonb;
  v_request_one uuid := '44100000-0000-0000-0000-000000000001';
  v_request_two uuid := '44100000-0000-0000-0000-000000000002';
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub',v_admin_id,'role','authenticated')::text, true);

  select public.save_branch(jsonb_build_object(
    'code','BR-PH4-TEST',
    'name','Phase 4 Test Branch',
    'timezone','Asia/Kuala_Lumpur',
    'isActive',true,
    'isDefault',false
  )) into v_branch;
  v_branch_id := (v_branch->>'id')::uuid;

  if not exists (select 1 from public.branch_ordering_policies where branch_id=v_branch_id)
     or (select count(*) from public.branch_service_windows where branch_id=v_branch_id) <> 7 then
    raise exception 'new branch did not receive scheduling foundation';
  end if;

  v_today := (now() at time zone 'Asia/Kuala_Lumpur')::date;
  v_service_date := v_today + 1;
  v_weekday := extract(dow from v_service_date)::integer;
  v_pickup_at := (v_service_date + time '12:00') at time zone 'Asia/Kuala_Lumpur';

  select public.save_branch_pickup_configuration(jsonb_build_object(
    'branchId',v_branch_id,
    'asapEnabled',true,
    'scheduleEnabled',true,
    'minimumLeadMinutes',10,
    'preparationLeadMinutes',10,
    'slotIntervalMinutes',15,
    'maximumAdvanceDays',7,
    'slotCapacityOrders',1,
    'windows',jsonb_build_array(jsonb_build_object(
      'weekday',v_weekday,
      'isAllDay',false,
      'opensAt','11:00',
      'closesAt','13:00',
      'isActive',true
    ))
  )) into v_config;

  if v_config#>>'{policy,slotCapacityOrders}' <> '1'
     or v_config#>>'{policy,preparationLeadMinutes}' <> '10'
     or jsonb_array_length(v_config->'windows') <> 1 then
    raise exception 'Admin branch pickup configuration did not persist: %',v_config;
  end if;

  perform public.save_branch_service_exception(jsonb_build_object(
    'branchId',v_branch_id,
    'serviceDate',v_today,
    'isClosed',true
  ));

  perform set_config('request.jwt.claims', jsonb_build_object('sub',v_customer_one,'role','authenticated')::text, true);

  begin
    perform public.quote_order(jsonb_build_object(
      'branchId',v_branch_id,
      'fulfillmentType','asap',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',(select id from public.catalogue_items where kind='product' and is_published and is_available and not is_drink order by created_at,id limit 1),
        'addOnIds','[]'::jsonb,
        'quantity',1
      ))
    ));
    raise exception 'dated closure unexpectedly allowed ASAP quote';
  exception when invalid_parameter_value then
    null;
  end;

  select id into strict v_item_id
  from public.catalogue_items
  where kind='product' and is_published and is_available
    and not is_drink
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=catalogue_items.id and v.is_available
    )
  order by created_at,id
  limit 1;

  select public.quote_order(jsonb_build_object(
    'branchId',v_branch_id,
    'fulfillmentType','scheduled',
    'requestedPickupAt',v_pickup_at,
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item_id,
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  )) into v_quote;

  if v_quote->>'branchId' <> v_branch_id::text
     or v_quote#>>'{pickupAvailability,slotRemainingOrders}' <> '1'
     or v_quote#>>'{schedulePolicy,preparationLeadMinutes}' <> '10' then
    raise exception 'branch-aware quote is invalid: %',v_quote;
  end if;

  select public.list_branch_pickup_slots(v_branch_id,v_service_date) into v_slots;
  if not exists (
    select 1 from jsonb_array_elements(v_slots->'slots') slot
    where (slot->>'pickupAt')::timestamptz = v_pickup_at
  ) then
    raise exception 'available pickup slot listing omitted configured noon slot: %',v_slots;
  end if;

  select public.place_customer_order(jsonb_build_object(
    'branchId',v_branch_id,
    'clientRequestId',v_request_one,
    'fulfillmentType','scheduled',
    'requestedPickupAt',v_pickup_at,
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item_id,
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  )) into v_order_one;

  if v_order_one->>'branchId' <> v_branch_id::text
     or (v_order_one->>'prepareAt')::timestamptz is distinct from v_pickup_at - interval '10 minutes'
     or v_order_one->>'status' <> 'scheduled' then
    raise exception 'customer order did not persist branch pickup authority: %',v_order_one;
  end if;

  perform set_config('request.jwt.claims', jsonb_build_object('sub',v_customer_two,'role','authenticated')::text, true);
  begin
    perform public.place_customer_order(jsonb_build_object(
      'branchId',v_branch_id,
      'clientRequestId',v_request_two,
      'fulfillmentType','scheduled',
      'requestedPickupAt',v_pickup_at,
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,
        'addOnIds','[]'::jsonb,
        'quantity',1
      ))
    ));
    raise exception 'full scheduled pickup slot accepted a second order';
  exception when invalid_parameter_value then
    null;
  end;

  perform set_config('request.jwt.claims', jsonb_build_object('sub',v_admin_id,'role','authenticated')::text, true);
  select public.transition_order_status((v_order_one->>'id')::uuid,'cancelled',1,'Phase 4 capacity regression') into v_cancelled;
  if v_cancelled->>'status' <> 'cancelled' then raise exception 'capacity regression order did not cancel'; end if;

  perform set_config('request.jwt.claims', jsonb_build_object('sub',v_customer_two,'role','authenticated')::text, true);
  select public.place_customer_order(jsonb_build_object(
    'branchId',v_branch_id,
    'clientRequestId',v_request_two,
    'fulfillmentType','scheduled',
    'requestedPickupAt',v_pickup_at,
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item_id,
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  )) into v_order_two;

  if v_order_two->>'branchId' <> v_branch_id::text
     or v_order_two->>'status' <> 'scheduled' then
    raise exception 'cancellation did not free scheduled slot capacity';
  end if;

  begin
    insert into public.branch_service_exceptions(branch_id,service_date,is_closed)
    values(v_branch_id,v_service_date+2,true);
    raise exception 'customer unexpectedly inserted branch service exception directly';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

reset role;
rollback;
