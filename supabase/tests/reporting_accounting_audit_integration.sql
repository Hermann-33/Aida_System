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
select set_config(
  'test.phase8.inventory_item_id',
  (select id::text from public.inventory_items where is_active order by sku,id limit 1),
  false
);

-- Make the current default branch deterministic for an ASAP order regardless of
-- CI wall-clock time. All changes are inside this transaction.
delete from public.branch_service_exceptions
where branch_id=current_setting('test.phase8.branch_id')::uuid
  and service_date=(now() at time zone current_setting('test.phase8.timezone'))::date;

set local role authenticated;
do $$
declare
  v_admin uuid := '88000000-0000-0000-0000-000000000001';
  v_branch uuid := current_setting('test.phase8.branch_id')::uuid;
  v_timezone text := current_setting('test.phase8.timezone');
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

  -- Resolve the inventory item before entering the authenticated role. Direct
  -- inventory-item table reads are intentionally not the Admin write path.
  -- The actual source fact is still authored through the Phase 5 movement RPC.
  perform public.record_inventory_movement(
    v_branch,
    current_setting('test.phase8.inventory_item_id')::uuid,
    1000000000,
    'receiving',
    'Phase 8 reporting regression stock'
  );
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
  perform set_config('test.phase8.order_total_sen',v_order->>'totalSen',false);
end;
$$;
reset role;

-- Add a durable closed shift + cash ledger fact without creating a live-shift
-- uniqueness conflict with any seed topology.
with inserted_shift as (
  insert into public.shifts(
    branch_id,sales_point_id,terminal_id,opened_by_user_id,operator_user_id,
    status,opening_float_sen,opened_at,closed_at,
    closing_expected_cash_sen,closing_actual_cash_sen,cash_variance_sen,
    close_notes,closed_by_user_id
  ) values (
    current_setting('test.phase8.branch_id')::uuid,
    current_setting('test.phase8.sales_point_id')::uuid,
    current_setting('test.phase8.terminal_id')::uuid,
    '88000000-0000-0000-0000-000000000001'::uuid,
    '88000000-0000-0000-0000-000000000001'::uuid,
    'closed',
    5000,
    now()-interval '10 minutes',
    now(),
    5500,
    5400,
    -100,
    'Phase 8 reporting regression close',
    '88000000-0000-0000-0000-000000000001'::uuid
  )
  returning id
)
select set_config('test.phase8.shift_id',(select id::text from inserted_shift),false);

insert into public.cash_movements(
  shift_id,movement_type,amount_sen,reason,actor_user_id
) values (
  current_setting('test.phase8.shift_id')::uuid,
  'cash_in',
  500,
  'Phase 8 reporting regression',
  '88000000-0000-0000-0000-000000000001'::uuid
);

set local role authenticated;
do $$
declare
  v_admin uuid := '88000000-0000-0000-0000-000000000001';
  v_local_date text := ((now() at time zone current_setting('test.phase8.timezone'))::date)::text;
  v_filter jsonb;
  v_summary jsonb;
  v_transactions jsonb;
  v_audit jsonb;
  v_page_one jsonb;
  v_page_two jsonb;
  v_detail text;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);

  v_filter := jsonb_build_object(
    'fromDate',v_local_date,
    'toDate',v_local_date,
    'branchId',current_setting('test.phase8.branch_id'),
    'pageSize',100,
    'offset',0
  );

  select public.get_admin_reporting_summary(v_filter) into v_summary;

  if (v_summary#>>'{semantics,commercialValue}') <> 'accepted_order_value_not_processor_settlement'
     or (v_summary#>>'{semantics,statutoryAccountingIncluded}')::boolean
     or (v_summary#>>'{semantics,processorSettlementIncluded}')::boolean then
    raise exception 'Phase 8 summary semantics are misleading: %',v_summary->'semantics';
  end if;

  if (v_summary#>>'{orders,acceptedOrderCount}')::bigint < 1
     or (v_summary#>>'{orders,voucherDiscountSen}')::bigint <> 100
     or (v_summary#>>'{orders,promotionDiscountSen}')::bigint <> 200
     or (v_summary#>>'{orders,discountSen}')::bigint <> 300
     or not (v_summary#>>'{orders,discountReconciled}')::boolean
     or (v_summary#>>'{orders,unpaidAcceptedOrderValueSen}')::bigint <> current_setting('test.phase8.order_total_sen')::bigint
     or (v_summary#>>'{orders,paidPosCashSen}')::bigint <> 0 then
    raise exception 'Phase 8 order summary did not reconcile authoritative order facts: %',v_summary->'orders';
  end if;

  if (v_summary#>>'{loyaltyAndDiscountApplications,voucherApplicationCount}')::bigint <> 1
     or (v_summary#>>'{loyaltyAndDiscountApplications,voucherDiscountSen}')::bigint <> 100
     or (v_summary#>>'{loyaltyAndDiscountApplications,promotionApplicationCount}')::bigint <> 1
     or (v_summary#>>'{loyaltyAndDiscountApplications,promotionDiscountSen}')::bigint <> 200 then
    raise exception 'Phase 8 loyalty/discount summary did not reconcile application snapshots: %',v_summary->'loyaltyAndDiscountApplications';
  end if;

  if (v_summary#>>'{shifts,shiftOpenedCount}')::bigint < 1
     or (v_summary#>>'{shifts,closedShiftCount}')::bigint < 1
     or (v_summary#>>'{shifts,cashVarianceSen}')::bigint <> -100
     or (v_summary#>>'{cashMovements,movementCount}')::bigint < 1
     or (v_summary#>>'{cashMovements,cashInSen}')::bigint <> 500 then
    raise exception 'Phase 8 shift/cash summary did not reconcile source ledgers: shifts %, cash %',v_summary->'shifts',v_summary->'cashMovements';
  end if;

  if (v_summary#>>'{inventoryMovements,movementCount}')::bigint < 1
     or jsonb_array_length(v_summary#>'{inventoryMovements,byItem}') < 1 then
    raise exception 'Phase 8 inventory movement summary is missing source-ledger facts: %',v_summary->'inventoryMovements';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(v_summary->'byProduct') x
    where x->>'sku'='FD-SAN'
      and (x->>'quantity')::bigint >= 1
  ) then
    raise exception 'Phase 8 product reporting did not use immutable order-line snapshots: %',v_summary->'byProduct';
  end if;

  select public.get_admin_transaction_report(v_filter) into v_transactions;

  if not (v_transactions#>>'{semantics,refundDataAvailable}')::boolean
     or not (v_transactions#>>'{semantics,providerLifecycleAvailable}')::boolean
     or not (v_transactions#>>'{semantics,acceptedOrderValueUnchangedByRefunds}')::boolean
     or (v_transactions#>>'{semantics,processorSettlementIncluded}')::boolean then
    raise exception 'Cumulative Phase 8/9 transaction semantics are misleading: %',v_transactions->'semantics';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements(v_transactions->'items') x
    where x->>'orderId'=current_setting('test.phase8.order_id')
      and (x->>'voucherDiscountSen')::bigint=100
      and (x->>'promotionDiscountSen')::bigint=200
      and (x->>'discountSen')::bigint=300
      and (x->>'discountReconciled')::boolean
      and (x->>'refundedSen')::bigint=0
      and (x->>'refundableSen')::bigint=(x->>'totalSen')::bigint
      and (x->>'refundReservedSen')::bigint=0
      and (x->>'refundReconciled')::boolean
      and x->>'latestPaymentIntent' is null
      and jsonb_array_length(x->'refunds')=0
      and jsonb_array_length(x->'lines')=1
  ) then
    raise exception 'Phase 8 transaction report did not preserve authoritative commercial detail: %',v_transactions;
  end if;

  select public.get_admin_audit_events(v_filter) into v_audit;

  if not (v_audit#>>'{coverage,sourceBackedOnly}')::boolean
     or (v_audit#>>'{coverage,completeGeneralAuditLog}')::boolean
     or (v_audit->>'totalCount')::bigint < 5 then
    raise exception 'Phase 8 audit coverage declaration or source facts are invalid: %',v_audit;
  end if;

  if not exists (select 1 from jsonb_array_elements(v_audit->'items') x where x->>'category'='order')
     or not exists (select 1 from jsonb_array_elements(v_audit->'items') x where x->>'category'='discount')
     or not exists (select 1 from jsonb_array_elements(v_audit->'items') x where x->>'category'='inventory')
     or not exists (select 1 from jsonb_array_elements(v_audit->'items') x where x->>'category'='cash')
     or not exists (select 1 from jsonb_array_elements(v_audit->'items') x where x->>'category'='shift') then
    raise exception 'Phase 8 audit projection omitted a durable source category: %',v_audit->'items';
  end if;

  select public.get_admin_audit_events(v_filter || '{"pageSize":1,"offset":0}'::jsonb) into v_page_one;
  select public.get_admin_audit_events(v_filter || '{"pageSize":1,"offset":1}'::jsonb) into v_page_two;

  if jsonb_array_length(v_page_one->'items') <> 1
     or jsonb_array_length(v_page_two->'items') <> 1
     or v_page_one#>>'{items,0,eventKey}' = v_page_two#>>'{items,0,eventKey}' then
    raise exception 'Phase 8 audit pagination is not deterministic: page1 %, page2 %',v_page_one,v_page_two;
  end if;

  begin
    perform public.get_admin_reporting_summary(jsonb_build_object(
      'fromDate',v_local_date,
      'toDate',v_local_date,
      'pageSize',101
    ));
    raise exception 'expected invalid Phase 8 page size to fail';
  exception when sqlstate '22023' then
    get stacked diagnostics v_detail = PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REPORT_PAGE_INVALID' then
      raise exception 'unexpected invalid page-size detail: %',v_detail;
    end if;
  end;

  begin
    perform public.get_admin_transaction_report(jsonb_build_object(
      'fromDate',(current_date+1)::text,
      'toDate',current_date::text
    ));
    raise exception 'expected reversed Phase 8 date range to fail';
  exception when sqlstate '22023' then
    get stacked diagnostics v_detail = PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REPORT_DATE_RANGE_INVALID' then
      raise exception 'unexpected invalid date-range detail: %',v_detail;
    end if;
  end;
end;
$$;
reset role;

-- A normal customer can execute the wrapper symbol but cannot cross the
-- caller-bound Admin/Owner authorization boundary.
set local role authenticated;
do $$
declare
  v_customer uuid := '88000000-0000-0000-0000-000000000002';
  v_local_date text := ((now() at time zone current_setting('test.phase8.timezone'))::date)::text;
  v_filter jsonb := jsonb_build_object('fromDate',v_local_date,'toDate',v_local_date);
  v_detail text;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);

  begin
    perform public.get_admin_reporting_summary(v_filter);
    raise exception 'expected customer Phase 8 summary access to fail';
  exception when insufficient_privilege then
    get stacked diagnostics v_detail = PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REPORTING_ADMIN_REQUIRED' then
      raise exception 'unexpected customer summary denial detail: %',v_detail;
    end if;
  end;

  begin
    perform public.get_admin_transaction_report(v_filter);
    raise exception 'expected customer Phase 8 transaction access to fail';
  exception when insufficient_privilege then
    get stacked diagnostics v_detail = PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REPORTING_ADMIN_REQUIRED' then
      raise exception 'unexpected customer transaction denial detail: %',v_detail;
    end if;
  end;

  begin
    perform public.get_admin_audit_events(v_filter);
    raise exception 'expected customer Phase 8 audit access to fail';
  exception when insufficient_privilege then
    get stacked diagnostics v_detail = PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REPORTING_ADMIN_REQUIRED' then
      raise exception 'unexpected customer audit denial detail: %',v_detail;
    end if;
  end;
end;
$$;
reset role;

rollback;