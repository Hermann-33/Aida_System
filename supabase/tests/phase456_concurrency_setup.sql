\set ON_ERROR_STOP on

-- Phase 4-6 true-concurrency regression fixture.
-- This data is intentionally committed only inside the disposable local Supabase
-- instance created by backend-database-audit.yml. The contention script runs last
-- and the workflow tears the stack down immediately afterwards.

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
  ('77000000-0000-0000-0000-000000000001','p16-conc-admin@example.test','{}'::jsonb,now(),now()),
  ('77000000-0000-0000-0000-000000000002','p16-conc-schedule-one@example.test','{}'::jsonb,now(),now()),
  ('77000000-0000-0000-0000-000000000003','p16-conc-schedule-two@example.test','{}'::jsonb,now(),now()),
  ('77000000-0000-0000-0000-000000000004','p16-conc-inventory-one@example.test','{}'::jsonb,now(),now()),
  ('77000000-0000-0000-0000-000000000005','p16-conc-inventory-two@example.test','{}'::jsonb,now(),now()),
  ('77000000-0000-0000-0000-000000000006','p16-conc-loyalty@example.test','{}'::jsonb,now(),now());

update public.user_profiles
set app_role='admin'
where user_id='77000000-0000-0000-0000-000000000001';

set role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"77000000-0000-0000-0000-000000000001","role":"authenticated"}',
  false
);

do $$
declare
  v_branch jsonb;
  v_branch_id uuid;
  v_service_date date := (now() at time zone 'Asia/Kuala_Lumpur')::date + 1;
  v_weekday integer;
  v_inventory jsonb;
  v_inventory_id uuid;
  v_item uuid;
begin
  select public.save_branch(jsonb_build_object(
    'code','BR-P16-CONC',
    'name','Phase 1-6 Concurrency Branch',
    'timezone','Asia/Kuala_Lumpur',
    'isActive',true,
    'isDefault',false
  )) into v_branch;
  v_branch_id := (v_branch->>'id')::uuid;
  v_weekday := extract(dow from v_service_date)::integer;

  perform public.save_branch_pickup_configuration(jsonb_build_object(
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
  ));

  select ci.id into strict v_item
  from public.catalogue_items ci
  where ci.kind='product'
    and ci.is_published
    and ci.is_available
    and not ci.is_drink
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=ci.id and v.is_available
    )
    and not exists (
      select 1 from public.recipes r
      where r.item_id=ci.id and r.variant_id is null and r.is_active
    )
  order by ci.created_at,ci.id
  limit 1;

  select public.save_inventory_item(jsonb_build_object(
    'sku','P16-CONC-STOCK',
    'name','Phase 1-6 Concurrency Stock',
    'baseUnit','unit',
    'isActive',true
  )) into v_inventory;
  v_inventory_id := (v_inventory->>'id')::uuid;

  perform public.record_inventory_movement(
    (select id from public.branches where is_default and is_active limit 1),
    v_inventory_id,
    100000,
    'receiving',
    'Phase 1-6 concurrency fixture'
  );

  perform public.save_recipe(jsonb_build_object(
    'itemId',v_item,
    'variantId',null,
    'name','Phase 1-6 concurrency recipe',
    'isActive',true,
    'components',jsonb_build_array(jsonb_build_object(
      'inventoryItemId',v_inventory_id,
      'quantityMilli',100000
    ))
  ));
end;
$$;

reset role;

-- Create exactly ten earned points for the loyalty contention customer through
-- the real completed-order award path.
set role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"77000000-0000-0000-0000-000000000006","role":"authenticated"}',
  false
);

select public.place_customer_order(jsonb_build_object(
  'clientRequestId','77300000-0000-0000-0000-000000000001',
  'branchId',(select id from public.branches where is_default and is_active limit 1),
  'fulfillmentType','asap',
  'items',jsonb_build_array(jsonb_build_object(
    'itemId',(select id from public.catalogue_items where sku='CF-LAT'),
    'variantId',(select v.id from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id where i.sku='CF-LAT' and v.code='medium'),
    'addOnIds','[]'::jsonb,
    'quantity',1
  ))
));

reset role;

update public.orders
set status='completed',
    completed_at=now(),
    status_updated_at=now(),
    status_version=status_version+1
where client_request_id='77300000-0000-0000-0000-000000000001';

insert into public.reward_catalogue(
  code,name,reward_type,points_cost,fixed_amount_sen,expiry_days,is_points_redeemable,is_active
)
values('P16_CONC_RM1','Phase 1-6 Concurrency RM1','fixed_amount',10,100,7,true,true);

do $$
declare
  v_member uuid;
  v_points bigint;
begin
  select id into strict v_member
  from public.members
  where user_id='77000000-0000-0000-0000-000000000006';

  select coalesce(sum(points_delta),0) into v_points
  from public.loyalty_point_ledger
  where member_id=v_member;

  if v_points <> 10 then
    raise exception 'concurrency fixture expected exactly 10 loyalty points, got %',v_points;
  end if;
end;
$$;
