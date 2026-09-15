-- TASK-OPS-008 / Phase 8 reporting, reconciliation and audit regression.
-- Transactional: identities/configuration/orders/report fixtures are rolled back.

begin;

do $$
begin
  if not has_function_privilege('authenticated','public.get_admin_reporting_summary(jsonb)','execute')
     or not has_function_privilege('authenticated','public.get_admin_transaction_report(jsonb)','execute')
     or not has_function_privilege('authenticated','public.get_admin_audit_events(jsonb)','execute') then
    raise exception 'Phase 8 authenticated reporting RPC grants are incomplete';
  end if;

  if has_function_privilege('anon','public.get_admin_reporting_summary(jsonb)','execute')
     or has_function_privilege('anon','public.get_admin_transaction_report(jsonb)','execute')
     or has_function_privilege('anon','public.get_admin_audit_events(jsonb)','execute') then
    raise exception 'anonymous role unexpectedly has privileged Phase 8 reporting access';
  end if;

  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname in (
        'get_admin_reporting_summary',
        'get_admin_transaction_report',
        'get_admin_audit_events'
      )
      and p.prosecdef
  ) then
    raise exception 'public Phase 8 reporting wrappers unexpectedly use SECURITY DEFINER';
  end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
  ('88000000-0000-0000-0000-000000000001','phase8-admin@example.test','{}'::jsonb,now(),now()),
  ('88000000-0000-0000-0000-000000000002','phase8-customer@example.test','{}'::jsonb,now(),now());

update public.user_profiles
set app_role='admin'
where user_id='88000000-0000-0000-0000-000000000001';

select set_config(
  'test.phase8.branch_id',
  (select id::text from public.branches where is_default limit 1),
  false
);
select set_config(
  'test.phase8.timezone',
  (select timezone from public.branches where id=current_setting('test.phase8.branch_id')::uuid),
  false
);
select set_config(
  'test.phase8.sales_point_id',
  (select id::text from public.sales_points where branch_id=current_setting('test.phase8.branch_id')::uuid order by code limit 1),
  false
);
select set_config(
  'test.phase8.terminal_id',
  (select id::text from public.terminals where sales_point_id=current_setting('test.phase8.sales_point_id')::uuid order by code limit 1),
  false
);
select set_config(
  'test.phase8.member_id',
  (select id::text from public.members where user_id='88000000-0000-0000-0000-000000000002'::uuid limit 1),
  false
);
select set_config(
  'test.phase8.item_id',
  (select id::text from public.catalogue_items where sku='FD-SAN' and kind='product' limit 1),
  false
);

-- Make the current default branch deterministic for an ASAP order regardless of
-- CI wall-clock time. All changes are inside this transaction.
delete from public.branch_service_exceptions
where branch_id=current_setting('test.phase8.branch_id')::uuid
  and service_date=(now() at time zone current_setting('test.phase8.timezone'))::date;

-- Ensure the existing recipe stock cannot make this reporting fixture flaky.
insert into public.branch_inventory(branch_id,inventory_item_id,on_hand_milli)
select current_setting('test.phase8.branch_id')::uuid, i.id, 1000000000
from public.inventory_items i
on conflict (branch_id,inventory_item_id) do update
set on_hand_milli=greatest(public.branch_inventory.on_hand_milli,excluded.on_hand_milli),
    updated_at=now();

set local role authenticated;
do $$
declare
  v_admin uuid := '88000000-0000-0000-0000-000000000001';
  v_branch uuid := current_setting('test.phase8.branch_id')::uuid;
  v_timezone text := current_setting('test.phase8.timezone');
  v_today date := (now() at time zone v_timezone)::date;
  v_weekday integer := extract(dow from (now() at time zone v_timezone))::integer;
  v_config jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);

  select public.save_branch_pickup_configuration(jsonb_build_object(
    'branchId',v_branch,
    'asapEnabled',true,
    'scheduleEnabled',true,
    'minimumLeadMinutes',0,
    'preparationLeadMinutes',0,
    'slotIntervalMinutes',15,
    'maximumAdvanceDays',7,
    'slotCapacityOrders',100,
    'windows',jsonb_build_array(jsonb_build_object(
      'weekday',v_weekday,
      'isAllDay',true,
      'isActive',true
    ))
  )) into v_config;

  if v_config#>>'{policy,asapEnabled}' <> 'true' then
    raise exception 'Phase 8 fixture branch configuration failed: %',v_config;
  end if;

  perform public.save_promotion(jsonb_build_object(
    'code','P8_REPORT_200',
    'name','Phase 8 Reporting Promotion',
    'discountType','fixed',
    'fixedAmountSen',200,
    'priority',10,
    'stackingMode','exclusive',
    'allowWithVoucher',true,
    'requiresMember',false,
    'isActive',true,
    'branchIds',jsonb_build_array(v_branch::text)
  ));
end;
$$;
reset role;

-- Issue a trusted test voucher directly as database owner. The customer still
-- has to pass the normal Phase 6/7 quote/place ownership and atomic-use checks.
insert into public.member_vouchers(
  member_id,reward_id,code,source,status,
  reward_code_snapshot,reward_name_snapshot,reward_type_snapshot,
  fixed_amount_sen_snapshot,eligible_category_slugs_snapshot,
  eligible_item_skus_snapshot,points_spent,expires_at
) values (
  current_setting('test.phase8.member_id')::uuid,
  null,
  'AIDA-V-P8REPORT0001',
  'admin',
  'active',
  'P8-RM1',
  'Phase 8 RM1 Voucher',
  'fixed_amount',
  100,
  '{}'::text[],
  '{}'::text[],
  0,
  now()+interval '1 day'
);
select set_config(
  'test.phase8.voucher_id',
  (select id::text from public.member_vouchers where code='AIDA-V-P8REPORT0001'),
  false
);

set local role authenticated;
do $$
declare
  v_customer uuid := '88000000-0000-0000-0000-000000000002';
  v_order jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);

  select public.place_customer_order(jsonb_build_object(
    'branchId',current_setting('test.phase8.branch_id'),
    'clientRequestId','88100000-0000-0000-0000-000000000001',
    'fulfillmentType','asap',
    'voucherId',current_setting('test.phase8.voucher_id'),
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',current_setting('test.phase8.item_id'),
      'addOnIds','[]'::jsonb,
      'quantity',1
    ))
  )) into v_order;

  if (v_order->>'voucherDiscountSen')::bigint <> 100
     or (v_order->>'promotionDiscountSen')::bigint <> 200
     or (v_order->>'discountSen')::bigint <> 300
     or (v_order->>'totalSen')::bigint <> (v_order->>'subtotalSen')::bigint - 300 then
    raise exception 'Phase 8 fixture did not preserve Phase 7 discount separation: %',v_order;
  end if;

  perform set_config('test.phase8.order_id',v_order->>'id',false);
end;
$$;
reset role;

-- Add a trusted shift/cash ledger fact on the same reporting branch.
insert into public.shifts(
  branch_id,sales_point_id,terminal_id,opened_by_user_id,operator_user_id,
  status,opening_float_sen
) values (
  current_setting('test.phase8.branch_id')::uuid,
  current_setting('test.phase8.sales_point_id')::uuid,
  current_setting('test.phase8.terminal_id')::uuid,
  '88000000-0000-0000-0000-000000000001'::uuid,
  '88000000-0000-0000-0000-000000000001'::uuid,
  'open',
  5000
) returning id::text into strict _phase8_shift_id;
