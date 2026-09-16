-- TASK-OPS-008 / Phase 8 — read-only operational reporting and audit authority.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/migrations/ only.
--
-- Reporting is derived from trusted Phase 1–7 facts. These RPCs do not create
-- mutation authority and deliberately avoid statutory-accounting or processor-
-- settlement claims that AIDA does not yet persist.

create or replace function private.require_reporting_admin(p_actor_user_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch'
      using errcode = '42501', detail = 'REPORTING_ACTOR_MISMATCH';
  end if;

  if not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required'
      using errcode = '42501', detail = 'REPORTING_ADMIN_REQUIRED';
  end if;
end;
$$;

revoke all on function private.require_reporting_admin(uuid)
from public, anon, authenticated;

create or replace function private.reporting_filter_impl(
  p_filter jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_filter jsonb := coalesce(p_filter, '{}'::jsonb);
  v_from_date date;
  v_to_date date;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_sales_point_branch_id uuid;
  v_page_size integer := 50;
  v_offset integer := 0;
begin
  perform private.require_reporting_admin(p_actor_user_id);

  if jsonb_typeof(v_filter) <> 'object' then
    raise exception 'report filter must be a JSON object'
      using errcode = '22023', detail = 'REPORT_FILTER_INVALID';
  end if;

  if nullif(v_filter ->> 'fromDate', '') is null
     or nullif(v_filter ->> 'toDate', '') is null then
    raise exception 'fromDate and toDate are required'
      using errcode = '22023', detail = 'REPORT_DATE_RANGE_REQUIRED';
  end if;

  begin
    v_from_date := (v_filter ->> 'fromDate')::date;
    v_to_date := (v_filter ->> 'toDate')::date;
  exception when others then
    raise exception 'fromDate and toDate must be valid ISO dates'
      using errcode = '22023', detail = 'REPORT_DATE_RANGE_INVALID';
  end;

  if v_to_date < v_from_date then
    raise exception 'toDate must be on or after fromDate'
      using errcode = '22023', detail = 'REPORT_DATE_RANGE_INVALID';
  end if;

  if (v_to_date - v_from_date) > 366 then
    raise exception 'report date range cannot exceed 367 calendar days'
      using errcode = '22023', detail = 'REPORT_DATE_RANGE_TOO_LARGE';
  end if;

  begin
    v_branch_id := nullif(v_filter ->> 'branchId', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'branchId must be a valid UUID'
      using errcode = '22023', detail = 'REPORT_BRANCH_INVALID';
  end;

  begin
    v_sales_point_id := nullif(v_filter ->> 'salesPointId', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'salesPointId must be a valid UUID'
      using errcode = '22023', detail = 'REPORT_SALES_POINT_INVALID';
  end;

  if v_branch_id is not null
     and not exists (select 1 from public.branches b where b.id = v_branch_id) then
    raise exception 'branch not found'
      using errcode = 'P0002', detail = 'REPORT_BRANCH_NOT_FOUND';
  end if;

  if v_sales_point_id is not null then
    select sp.branch_id
    into v_sales_point_branch_id
    from public.sales_points sp
    where sp.id = v_sales_point_id;

    if v_sales_point_branch_id is null then
      raise exception 'sales point not found'
        using errcode = 'P0002', detail = 'REPORT_SALES_POINT_NOT_FOUND';
    end if;

    if v_branch_id is not null
       and v_branch_id is distinct from v_sales_point_branch_id then
      raise exception 'sales point does not belong to selected branch'
        using errcode = '22023', detail = 'REPORT_TOPOLOGY_MISMATCH';
    end if;

    v_branch_id := coalesce(v_branch_id, v_sales_point_branch_id);
  end if;

  if v_filter ? 'pageSize' then
    begin
      v_page_size := (v_filter ->> 'pageSize')::integer;
    exception when others then
      raise exception 'pageSize must be an integer'
        using errcode = '22023', detail = 'REPORT_PAGE_INVALID';
    end;
  end if;

  if v_page_size < 1 or v_page_size > 100 then
    raise exception 'pageSize must be between 1 and 100'
      using errcode = '22023', detail = 'REPORT_PAGE_INVALID';
  end if;

  if v_filter ? 'offset' then
    begin
      v_offset := (v_filter ->> 'offset')::integer;
    exception when others then
      raise exception 'offset must be an integer'
        using errcode = '22023', detail = 'REPORT_PAGE_INVALID';
    end;
  end if;

  if v_offset < 0 or v_offset > 100000 then
    raise exception 'offset must be between 0 and 100000'
      using errcode = '22023', detail = 'REPORT_PAGE_INVALID';
  end if;

  return jsonb_build_object(
    'fromDate', v_from_date,
    'toDate', v_to_date,
    'branchId', v_branch_id,
    'salesPointId', v_sales_point_id,
    'pageSize', v_page_size,
    'offset', v_offset
  );
end;
$$;

revoke all on function private.reporting_filter_impl(jsonb, uuid)
from public, anon, authenticated;

grant execute on function private.reporting_filter_impl(jsonb, uuid)
to authenticated;

create or replace function private.get_admin_reporting_summary_impl(
  p_filter jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_filter jsonb;
  v_from_date date;
  v_to_date date;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_orders jsonb;
  v_statuses jsonb;
  v_by_branch jsonb;
  v_by_sales_point jsonb;
  v_by_product jsonb;
  v_shifts jsonb;
  v_cash jsonb;
  v_loyalty jsonb;
  v_inventory jsonb;
begin
  v_filter := private.reporting_filter_impl(p_filter, p_actor_user_id);
  v_from_date := (v_filter ->> 'fromDate')::date;
  v_to_date := (v_filter ->> 'toDate')::date;
  v_branch_id := nullif(v_filter ->> 'branchId', '')::uuid;
  v_sales_point_id := nullif(v_filter ->> 'salesPointId', '')::uuid;

  with selected_orders as (
    select
      o.*,
      b.code as branch_code,
      b.name as branch_name,
      b.timezone,
      coalesce((
        select sum(v.discount_sen)
        from public.voucher_order_applications v
        where v.order_id = o.id
      ), 0)::bigint as voucher_discount_sen,
      coalesce((
        select sum(p.discount_sen)
        from public.promotion_order_applications p
        where p.order_id = o.id
      ), 0)::bigint as promotion_discount_sen
    from public.orders o
    join public.branches b on b.id = o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id = v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id = v_sales_point_id)
  )
  select jsonb_build_object(
    'orderCount', count(*),
    'acceptedOrderCount', count(*) filter (where status <> 'cancelled'),
    'cancelledOrderCount', count(*) filter (where status = 'cancelled'),
    'subtotalSen', coalesce(sum(subtotal_sen) filter (where status <> 'cancelled'), 0),
    'voucherDiscountSen', coalesce(sum(voucher_discount_sen) filter (where status <> 'cancelled'), 0),
    'promotionDiscountSen', coalesce(sum(promotion_discount_sen) filter (where status <> 'cancelled'), 0),
    'discountSen', coalesce(sum(discount_sen) filter (where status <> 'cancelled'), 0),
    'acceptedOrderValueSen', coalesce(sum(total_sen) filter (where status <> 'cancelled'), 0),
    'averageAcceptedOrderValueSen', case
      when count(*) filter (where status <> 'cancelled') = 0 then 0
      else floor(
        coalesce(sum(total_sen) filter (where status <> 'cancelled'), 0)::numeric
        / (count(*) filter (where status <> 'cancelled'))::numeric
      )::bigint
    end,
    'paidPosCashSen', coalesce(sum(total_sen) filter (
      where status <> 'cancelled'
        and source = 'pos'
        and tender_type = 'cash'
        and payment_state = 'paid'
    ), 0),
    'unpaidAcceptedOrderValueSen', coalesce(sum(total_sen) filter (
      where status <> 'cancelled' and payment_state = 'unpaid'
    ), 0),
    'discountReconciled', coalesce(bool_and(
      discount_sen = voucher_discount_sen + promotion_discount_sen
    ), true)
  )
  into v_orders
  from selected_orders;

  with selected_orders as (
    select o.status
    from public.orders o
    join public.branches b on b.id = o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id = v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id = v_sales_point_id)
  )
  select coalesce(jsonb_object_agg(status, row_count order by status), '{}'::jsonb)
  into v_statuses
  from (
    select status, count(*)::bigint as row_count
    from selected_orders
    group by status
  ) x;

  with selected_orders as (
    select
      o.*,
      b.code as branch_code,
      b.name as branch_name,
      b.timezone,
      coalesce((select sum(v.discount_sen) from public.voucher_order_applications v where v.order_id=o.id),0)::bigint as voucher_discount_sen,
      coalesce((select sum(p.discount_sen) from public.promotion_order_applications p where p.order_id=o.id),0)::bigint as promotion_discount_sen
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
      and o.status <> 'cancelled'
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'branchId', branch_id,
    'branchCode', branch_code,
    'branchName', branch_name,
    'timezone', timezone,
    'orderCount', order_count,
    'subtotalSen', subtotal_sen,
    'voucherDiscountSen', voucher_discount_sen,
    'promotionDiscountSen', promotion_discount_sen,
    'discountSen', discount_sen,
    'acceptedOrderValueSen', accepted_order_value_sen
  ) order by branch_code), '[]'::jsonb)
  into v_by_branch
  from (
    select branch_id, branch_code, branch_name, timezone,
      count(*)::bigint as order_count,
      sum(subtotal_sen)::bigint as subtotal_sen,
      sum(voucher_discount_sen)::bigint as voucher_discount_sen,
      sum(promotion_discount_sen)::bigint as promotion_discount_sen,
      sum(discount_sen)::bigint as discount_sen,
      sum(total_sen)::bigint as accepted_order_value_sen
    from selected_orders
    group by branch_id, branch_code, branch_name, timezone
  ) x;

  with selected_orders as (
    select o.*
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
      and o.status <> 'cancelled'
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'salesPointId', sales_point_id,
    'salesPointCode', sales_point_code,
    'salesPointName', sales_point_name,
    'orderCount', order_count,
    'acceptedOrderValueSen', accepted_order_value_sen
  ) order by sales_point_code nulls first), '[]'::jsonb)
  into v_by_sales_point
  from (
    select sales_point_id,
      max(sales_point_code_snapshot) as sales_point_code,
      max(sales_point_name_snapshot) as sales_point_name,
      count(*)::bigint as order_count,
      sum(total_sen)::bigint as accepted_order_value_sen
    from selected_orders
    group by sales_point_id
  ) x;

  with selected_orders as (
    select o.id
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
      and o.status <> 'cancelled'
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'itemId', catalogue_item_id,
    'sku', sku_snapshot,
    'name', name_snapshot,
    'quantity', quantity,
    'lineValueSen', line_value_sen
  ) order by line_value_sen desc, sku_snapshot), '[]'::jsonb)
  into v_by_product
  from (
    select l.catalogue_item_id,
      max(l.sku_snapshot) as sku_snapshot,
      max(l.name_snapshot) as name_snapshot,
      sum(l.quantity)::bigint as quantity,
      sum(l.line_total_sen)::bigint as line_value_sen
    from selected_orders so
    join public.order_lines l on l.order_id=so.id
    group by l.catalogue_item_id
  ) x;

  with selected_shifts as (
    select s.*
    from public.shifts s
    join public.branches b on b.id=s.branch_id
    where (s.opened_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or s.branch_id=v_branch_id)
      and (v_sales_point_id is null or s.sales_point_id=v_sales_point_id)
  )
  select jsonb_build_object(
    'shiftOpenedCount', count(*),
    'openOrLockedShiftCount', count(*) filter (where status in ('open','locked')),
    'closedShiftCount', count(*) filter (where status='closed'),
    'openingFloatSen', coalesce(sum(opening_float_sen),0),
    'closingExpectedCashSen', coalesce(sum(closing_expected_cash_sen) filter (where status='closed'),0),
    'closingActualCashSen', coalesce(sum(closing_actual_cash_sen) filter (where status='closed'),0),
    'cashVarianceSen', coalesce(sum(cash_variance_sen) filter (where status='closed'),0),
    'unapprovedClosedShiftCount', count(*) filter (where status='closed' and approved_at is null)
  )
  into v_shifts
  from selected_shifts;

  with selected_cash as (
    select cm.*
    from public.cash_movements cm
    join public.shifts s on s.id=cm.shift_id
    join public.branches b on b.id=s.branch_id
    where (cm.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or s.branch_id=v_branch_id)
      and (v_sales_point_id is null or s.sales_point_id=v_sales_point_id)
  )
  select jsonb_build_object(
    'movementCount', count(*),
    'cashInSen', coalesce(sum(amount_sen) filter (where movement_type='cash_in'),0),
    'cashOutSen', coalesce(sum(amount_sen) filter (where movement_type='cash_out'),0),
    'netMovementSen', coalesce(sum(case when movement_type='cash_in' then amount_sen else -amount_sen end),0)
  )
  into v_cash
  from selected_cash;

  with selected_orders as (
    select o.id
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
      and o.status <> 'cancelled'
  )
  select jsonb_build_object(
    'awardedOrderCount', (select count(*) from public.loyalty_order_awards a join selected_orders so on so.id=a.order_id),
    'pointsAwarded', coalesce((select sum(a.points_awarded) from public.loyalty_order_awards a join selected_orders so on so.id=a.order_id),0),
    'stampsAwarded', coalesce((select sum(a.stamps_awarded) from public.loyalty_order_awards a join selected_orders so on so.id=a.order_id),0),
    'voucherApplicationCount', (select count(*) from public.voucher_order_applications v join selected_orders so on so.id=v.order_id),
    'voucherDiscountSen', coalesce((select sum(v.discount_sen) from public.voucher_order_applications v join selected_orders so on so.id=v.order_id),0),
    'promotionApplicationCount', (select count(*) from public.promotion_order_applications p join selected_orders so on so.id=p.order_id),
    'promotionDiscountSen', coalesce((select sum(p.discount_sen) from public.promotion_order_applications p join selected_orders so on so.id=p.order_id),0)
  )
  into v_loyalty;

  with selected_movements as (
    select m.*, i.sku, i.name, i.base_unit
    from public.inventory_movements m
    join public.inventory_items i on i.id=m.inventory_item_id
    join public.branches b on b.id=m.branch_id
    where (m.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or m.branch_id=v_branch_id)
      and (
        v_sales_point_id is null
        or exists (
          select 1 from public.orders o
          where o.id=m.order_id and o.sales_point_id=v_sales_point_id
        )
      )
  ), per_item as (
    select inventory_item_id, sku, name, base_unit,
      count(*)::bigint as movement_count,
      sum(delta_milli)::bigint as net_delta_milli,
      coalesce(sum(delta_milli) filter (where movement_kind='receiving'),0)::bigint as received_milli,
      coalesce(sum(delta_milli) filter (where movement_kind='waste'),0)::bigint as waste_milli,
      coalesce(sum(delta_milli) filter (where movement_kind='adjustment'),0)::bigint as adjustment_milli,
      coalesce(sum(delta_milli) filter (where movement_kind='order_consumption'),0)::bigint as consumed_milli,
      coalesce(sum(delta_milli) filter (where movement_kind='order_reversal'),0)::bigint as reversed_milli
    from selected_movements
    group by inventory_item_id, sku, name, base_unit
  )
  select jsonb_build_object(
    'movementCount', (select count(*) from selected_movements),
    'byItem', coalesce((select jsonb_agg(jsonb_build_object(
      'inventoryItemId', inventory_item_id,
      'sku', sku,
      'name', name,
      'baseUnit', base_unit,
      'movementCount', movement_count,
      'netDeltaMilli', net_delta_milli,
      'receivedMilli', received_milli,
      'wasteMilli', waste_milli,
      'adjustmentMilli', adjustment_milli,
      'consumedMilli', consumed_milli,
      'reversedMilli', reversed_milli
    ) order by name, inventory_item_id) from per_item), '[]'::jsonb)
  )
  into v_inventory;

  return jsonb_build_object(
    'semantics', jsonb_build_object(
      'commercialValue', 'accepted_order_value_not_processor_settlement',
      'cancelledOrdersExcludedFromCommercialTotals', true,
      'inventoryQuantitiesGroupedByBaseUnitItem', true,
      'statutoryAccountingIncluded', false,
      'processorSettlementIncluded', false
    ),
    'filter', v_filter - 'pageSize' - 'offset',
    'orders', v_orders || jsonb_build_object('statusCounts', v_statuses),
    'byBranch', v_by_branch,
    'bySalesPoint', v_by_sales_point,
    'byProduct', v_by_product,
    'shifts', v_shifts,
    'cashMovements', v_cash,
    'loyaltyAndDiscountApplications', v_loyalty,
    'inventoryMovements', v_inventory
  );
end;
$$;

revoke all on function private.get_admin_reporting_summary_impl(jsonb, uuid)
from public, anon, authenticated;
grant execute on function private.get_admin_reporting_summary_impl(jsonb, uuid)
to authenticated;

create or replace function public.get_admin_reporting_summary(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.get_admin_reporting_summary_impl(p_filter, (select auth.uid()));
$$;

revoke all on function public.get_admin_reporting_summary(jsonb)
from public, anon, authenticated;
grant execute on function public.get_admin_reporting_summary(jsonb)
to authenticated;

create or replace function private.get_admin_transaction_report_impl(
  p_filter jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_filter jsonb;
  v_from_date date;
  v_to_date date;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_page_size integer;
  v_offset integer;
  v_total_count bigint;
  v_rows jsonb;
begin
  v_filter := private.reporting_filter_impl(p_filter, p_actor_user_id);
  v_from_date := (v_filter ->> 'fromDate')::date;
  v_to_date := (v_filter ->> 'toDate')::date;
  v_branch_id := nullif(v_filter ->> 'branchId', '')::uuid;
  v_sales_point_id := nullif(v_filter ->> 'salesPointId', '')::uuid;
  v_page_size := (v_filter ->> 'pageSize')::integer;
  v_offset := (v_filter ->> 'offset')::integer;

  select count(*)
  into v_total_count
  from public.orders o
  join public.branches b on b.id=o.branch_id
  where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
    and (v_branch_id is null or o.branch_id=v_branch_id)
    and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id);

  with selected_orders as (
    select o.*, b.code as branch_code, b.name as branch_name, b.timezone
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
    order by o.created_at desc, o.id desc
    offset v_offset
    limit v_page_size
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'orderId', o.id,
    'orderNumber', o.order_number,
    'createdAt', o.created_at,
    'localDate', (o.created_at at time zone o.timezone)::date,
    'localTime', to_char(o.created_at at time zone o.timezone, 'HH24:MI:SS'),
    'branch', jsonb_build_object(
      'id', o.branch_id,
      'code', o.branch_code,
      'name', o.branch_name,
      'timezone', o.timezone
    ),
    'salesPoint', case when o.sales_point_id is null then null else jsonb_build_object(
      'id', o.sales_point_id,
      'code', o.sales_point_code_snapshot,
      'name', o.sales_point_name_snapshot
    ) end,
    'terminalCode', o.terminal_code_snapshot,
    'source', o.source,
    'status', o.status,
    'fulfillmentType', o.fulfillment_type,
    'requestedPickupAt', o.requested_pickup_at,
    'subtotalSen', o.subtotal_sen,
    'voucherDiscountSen', coalesce((select sum(v.discount_sen) from public.voucher_order_applications v where v.order_id=o.id),0),
    'promotionDiscountSen', coalesce((select sum(p.discount_sen) from public.promotion_order_applications p where p.order_id=o.id),0),
    'discountSen', o.discount_sen,
    'totalSen', o.total_sen,
    'discountReconciled', o.discount_sen =
      coalesce((select sum(v.discount_sen) from public.voucher_order_applications v where v.order_id=o.id),0)
      + coalesce((select sum(p.discount_sen) from public.promotion_order_applications p where p.order_id=o.id),0),
    'tenderType', o.tender_type,
    'paymentState', o.payment_state,
    'paidAt', o.paid_at,
    'shiftId', o.shift_id,
    'createdByUserId', o.created_by_user_id,
    'memberAttached', o.member_id is not null,
    'voucher', (
      select jsonb_build_object(
        'code', v.voucher_code_snapshot,
        'rewardCode', v.reward_code_snapshot,
        'rewardName', v.reward_name_snapshot,
        'rewardType', v.reward_type_snapshot,
        'discountSen', v.discount_sen,
        'appliedAt', v.applied_at
      )
      from public.voucher_order_applications v
      where v.order_id=o.id
      limit 1
    ),
    'promotions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', p.promotion_code_snapshot,
        'name', p.promotion_name_snapshot,
        'discountType', p.discount_type_snapshot,
        'discountValue', p.discount_value_snapshot,
        'discountSen', p.discount_sen,
        'appliedAt', p.applied_at
      ) order by p.priority_snapshot, p.promotion_code_snapshot)
      from public.promotion_order_applications p
      where p.order_id=o.id
    ), '[]'::jsonb),
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
        'lineNumber', l.line_number,
        'itemId', l.catalogue_item_id,
        'sku', l.sku_snapshot,
        'name', l.name_snapshot,
        'variantLabel', l.variant_label_snapshot,
        'unitPriceSen', l.unit_price_sen,
        'quantity', l.quantity,
        'lineTotalSen', l.line_total_sen
      ) order by l.line_number)
      from public.order_lines l
      where l.order_id=o.id
    ), '[]'::jsonb)
  ) order by o.created_at desc, o.id desc), '[]'::jsonb)
  into v_rows
  from selected_orders o;

  return jsonb_build_object(
    'semantics', jsonb_build_object(
      'totalSen', 'accepted_order_value_not_processor_settlement',
      'refundDataAvailable', false,
      'processorSettlementIncluded', false
    ),
    'filter', v_filter,
    'totalCount', v_total_count,
    'items', v_rows
  );
end;
$$;

revoke all on function private.get_admin_transaction_report_impl(jsonb, uuid)
from public, anon, authenticated;
grant execute on function private.get_admin_transaction_report_impl(jsonb, uuid)
to authenticated;

create or replace function public.get_admin_transaction_report(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.get_admin_transaction_report_impl(p_filter, (select auth.uid()));
$$;

revoke all on function public.get_admin_transaction_report(jsonb)
from public, anon, authenticated;
grant execute on function public.get_admin_transaction_report(jsonb)
to authenticated;

create or replace function private.get_admin_audit_events_impl(
  p_filter jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_filter jsonb;
  v_from_date date;
  v_to_date date;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_page_size integer;
  v_offset integer;
  v_default_timezone text := 'Asia/Kuala_Lumpur';
  v_total_count bigint;
  v_rows jsonb;
begin
  v_filter := private.reporting_filter_impl(p_filter, p_actor_user_id);
  v_from_date := (v_filter ->> 'fromDate')::date;
  v_to_date := (v_filter ->> 'toDate')::date;
  v_branch_id := nullif(v_filter ->> 'branchId', '')::uuid;
  v_sales_point_id := nullif(v_filter ->> 'salesPointId', '')::uuid;
  v_page_size := (v_filter ->> 'pageSize')::integer;
  v_offset := (v_filter ->> 'offset')::integer;

  select coalesce(b.timezone, 'Asia/Kuala_Lumpur')
  into v_default_timezone
  from public.branches b
  where b.is_default
  order by b.created_at, b.id
  limit 1;

  v_default_timezone := coalesce(v_default_timezone, 'Asia/Kuala_Lumpur');

  with all_events as (
    select
      e.created_at as event_at,
      'order:' || e.id::text as event_key,
      'order'::text as category,
      e.event_type::text as action,
      e.actor_user_id,
      o.branch_id,
      o.sales_point_id,
      b.timezone,
      'order'::text as entity_type,
      o.id::text as entity_id,
      'Order ' || o.order_number::text as entity_label,
      jsonb_build_object(
        'fromStatus', e.from_status,
        'toStatus', e.to_status,
        'reason', e.reason,
        'details', e.details
      ) as details
    from public.order_events e
    join public.orders o on o.id=e.order_id
    join public.branches b on b.id=o.branch_id

    union all

    select
      cm.created_at,
      'cash:' || cm.id::text,
      'cash',
      cm.movement_type,
      cm.actor_user_id,
      s.branch_id,
      s.sales_point_id,
      b.timezone,
      'shift',
      s.id::text,
      'Shift ' || s.id::text,
      jsonb_build_object('amountSen',cm.amount_sen,'reason',cm.reason)
    from public.cash_movements cm
    join public.shifts s on s.id=cm.shift_id
    join public.branches b on b.id=s.branch_id

    union all

    select
      m.created_at,
      'inventory:' || m.id::text,
      'inventory',
      m.movement_kind,
      m.actor_user_id,
      m.branch_id,
      o.sales_point_id,
      b.timezone,
      'inventory_item',
      m.inventory_item_id::text,
      i.name,
      jsonb_build_object(
        'sku',i.sku,
        'baseUnit',i.base_unit,
        'deltaMilli',m.delta_milli,
        'orderId',m.order_id,
        'note',m.note
      )
    from public.inventory_movements m
    join public.inventory_items i on i.id=m.inventory_item_id
    join public.branches b on b.id=m.branch_id
    left join public.orders o on o.id=m.order_id

    union all

    select
      l.created_at,
      'loyalty-points:' || l.id::text,
      'loyalty',
      'points_' || l.event_kind,
      l.actor_user_id,
      o.branch_id,
      o.sales_point_id,
      coalesce(b.timezone,v_default_timezone),
      'member',
      l.member_id::text,
      'Member loyalty',
      jsonb_build_object(
        'deltaPoints',l.delta_points,
        'orderId',l.order_id,
        'rewardId',l.reward_id,
        'reason',l.reason
      )
    from public.loyalty_point_ledger l
    left join public.orders o on o.id=l.order_id
    left join public.branches b on b.id=o.branch_id

    union all

    select
      l.created_at,
      'loyalty-stamps:' || l.id::text,
      'loyalty',
      'stamps_' || l.event_kind,
      l.actor_user_id,
      o.branch_id,
      o.sales_point_id,
      coalesce(b.timezone,v_default_timezone),
      'member',
      l.member_id::text,
      'Member loyalty',
      jsonb_build_object(
        'deltaStamps',l.delta_stamps,
        'orderId',l.order_id,
        'rewardId',l.reward_id,
        'reason',l.reason
      )
    from public.loyalty_stamp_ledger l
    left join public.orders o on o.id=l.order_id
    left join public.branches b on b.id=o.branch_id

    union all

    select
      v.applied_at,
      'voucher:' || v.id::text,
      'discount',
      'voucher_applied',
      null::uuid,
      o.branch_id,
      o.sales_point_id,
      b.timezone,
      'order',
      o.id::text,
      'Order ' || o.order_number::text,
      jsonb_build_object(
        'voucherCode',v.voucher_code_snapshot,
        'rewardCode',v.reward_code_snapshot,
        'discountSen',v.discount_sen
      )
    from public.voucher_order_applications v
    join public.orders o on o.id=v.order_id
    join public.branches b on b.id=o.branch_id

    union all

    select
      p.applied_at,
      'promotion:' || p.id::text,
      'discount',
      'promotion_applied',
      null::uuid,
      o.branch_id,
      o.sales_point_id,
      b.timezone,
      'order',
      o.id::text,
      'Order ' || o.order_number::text,
      jsonb_build_object(
        'promotionCode',p.promotion_code_snapshot,
        'promotionName',p.promotion_name_snapshot,
        'discountSen',p.discount_sen
      )
    from public.promotion_order_applications p
    join public.orders o on o.id=p.order_id
    join public.branches b on b.id=o.branch_id

    union all

    select
      s.opened_at,
      'shift-opened:' || s.id::text,
      'shift',
      'opened',
      s.opened_by_user_id,
      s.branch_id,
      s.sales_point_id,
      b.timezone,
      'shift',
      s.id::text,
      'Shift ' || s.id::text,
      jsonb_build_object('openingFloatSen',s.opening_float_sen)
    from public.shifts s
    join public.branches b on b.id=s.branch_id

    union all

    select
      s.closed_at,
      'shift-closed:' || s.id::text,
      'shift',
      'closed',
      s.closed_by_user_id,
      s.branch_id,
      s.sales_point_id,
      b.timezone,
      'shift',
      s.id::text,
      'Shift ' || s.id::text,
      jsonb_build_object(
        'expectedCashSen',s.closing_expected_cash_sen,
        'actualCashSen',s.closing_actual_cash_sen,
        'varianceSen',s.cash_variance_sen
      )
    from public.shifts s
    join public.branches b on b.id=s.branch_id
    where s.closed_at is not null

    union all

    select
      s.approved_at,
      'shift-approved:' || s.id::text,
      'shift',
      'variance_approved',
      s.approved_by_user_id,
      s.branch_id,
      s.sales_point_id,
      b.timezone,
      'shift',
      s.id::text,
      'Shift ' || s.id::text,
      jsonb_build_object('varianceSen',s.cash_variance_sen)
    from public.shifts s
    join public.branches b on b.id=s.branch_id
    where s.approved_at is not null
  ), filtered as (
    select *
    from all_events e
    where (e.event_at at time zone coalesce(e.timezone,v_default_timezone))::date between v_from_date and v_to_date
      and (v_branch_id is null or e.branch_id=v_branch_id)
      and (v_sales_point_id is null or e.sales_point_id=v_sales_point_id)
  )
  select count(*) into v_total_count from filtered;

  with all_events as (
    select e.created_at as event_at,'order:'||e.id::text as event_key,'order'::text as category,e.event_type::text as action,e.actor_user_id,o.branch_id,o.sales_point_id,b.timezone,'order'::text as entity_type,o.id::text as entity_id,'Order '||o.order_number::text as entity_label,jsonb_build_object('fromStatus',e.from_status,'toStatus',e.to_status,'reason',e.reason,'details',e.details) as details from public.order_events e join public.orders o on o.id=e.order_id join public.branches b on b.id=o.branch_id
    union all
    select cm.created_at,'cash:'||cm.id::text,'cash',cm.movement_type,cm.actor_user_id,s.branch_id,s.sales_point_id,b.timezone,'shift',s.id::text,'Shift '||s.id::text,jsonb_build_object('amountSen',cm.amount_sen,'reason',cm.reason) from public.cash_movements cm join public.shifts s on s.id=cm.shift_id join public.branches b on b.id=s.branch_id
    union all
    select m.created_at,'inventory:'||m.id::text,'inventory',m.movement_kind,m.actor_user_id,m.branch_id,o.sales_point_id,b.timezone,'inventory_item',m.inventory_item_id::text,i.name,jsonb_build_object('sku',i.sku,'baseUnit',i.base_unit,'deltaMilli',m.delta_milli,'orderId',m.order_id,'note',m.note) from public.inventory_movements m join public.inventory_items i on i.id=m.inventory_item_id join public.branches b on b.id=m.branch_id left join public.orders o on o.id=m.order_id
    union all
    select l.created_at,'loyalty-points:'||l.id::text,'loyalty','points_'||l.event_kind,l.actor_user_id,o.branch_id,o.sales_point_id,coalesce(b.timezone,v_default_timezone),'member',l.member_id::text,'Member loyalty',jsonb_build_object('deltaPoints',l.delta_points,'orderId',l.order_id,'rewardId',l.reward_id,'reason',l.reason) from public.loyalty_point_ledger l left join public.orders o on o.id=l.order_id left join public.branches b on b.id=o.branch_id
    union all
    select l.created_at,'loyalty-stamps:'||l.id::text,'loyalty','stamps_'||l.event_kind,l.actor_user_id,o.branch_id,o.sales_point_id,coalesce(b.timezone,v_default_timezone),'member',l.member_id::text,'Member loyalty',jsonb_build_object('deltaStamps',l.delta_stamps,'orderId',l.order_id,'rewardId',l.reward_id,'reason',l.reason) from public.loyalty_stamp_ledger l left join public.orders o on o.id=l.order_id left join public.branches b on b.id=o.branch_id
    union all
    select v.applied_at,'voucher:'||v.id::text,'discount','voucher_applied',null::uuid,o.branch_id,o.sales_point_id,b.timezone,'order',o.id::text,'Order '||o.order_number::text,jsonb_build_object('voucherCode',v.voucher_code_snapshot,'rewardCode',v.reward_code_snapshot,'discountSen',v.discount_sen) from public.voucher_order_applications v join public.orders o on o.id=v.order_id join public.branches b on b.id=o.branch_id
    union all
    select p.applied_at,'promotion:'||p.id::text,'discount','promotion_applied',null::uuid,o.branch_id,o.sales_point_id,b.timezone,'order',o.id::text,'Order '||o.order_number::text,jsonb_build_object('promotionCode',p.promotion_code_snapshot,'promotionName',p.promotion_name_snapshot,'discountSen',p.discount_sen) from public.promotion_order_applications p join public.orders o on o.id=p.order_id join public.branches b on b.id=o.branch_id
    union all
    select s.opened_at,'shift-opened:'||s.id::text,'shift','opened',s.opened_by_user_id,s.branch_id,s.sales_point_id,b.timezone,'shift',s.id::text,'Shift '||s.id::text,jsonb_build_object('openingFloatSen',s.opening_float_sen) from public.shifts s join public.branches b on b.id=s.branch_id
    union all
    select s.closed_at,'shift-closed:'||s.id::text,'shift','closed',s.closed_by_user_id,s.branch_id,s.sales_point_id,b.timezone,'shift',s.id::text,'Shift '||s.id::text,jsonb_build_object('expectedCashSen',s.closing_expected_cash_sen,'actualCashSen',s.closing_actual_cash_sen,'varianceSen',s.cash_variance_sen) from public.shifts s join public.branches b on b.id=s.branch_id where s.closed_at is not null
    union all
    select s.approved_at,'shift-approved:'||s.id::text,'shift','variance_approved',s.approved_by_user_id,s.branch_id,s.sales_point_id,b.timezone,'shift',s.id::text,'Shift '||s.id::text,jsonb_build_object('varianceSen',s.cash_variance_sen) from public.shifts s join public.branches b on b.id=s.branch_id where s.approved_at is not null
  ), filtered as (
    select *
    from all_events e
    where (e.event_at at time zone coalesce(e.timezone,v_default_timezone))::date between v_from_date and v_to_date
      and (v_branch_id is null or e.branch_id=v_branch_id)
      and (v_sales_point_id is null or e.sales_point_id=v_sales_point_id)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'eventKey', event_key,
    'occurredAt', event_at,
    'localDate', (event_at at time zone coalesce(timezone,v_default_timezone))::date,
    'localTime', to_char(event_at at time zone coalesce(timezone,v_default_timezone),'HH24:MI:SS'),
    'timezone', coalesce(timezone,v_default_timezone),
    'category', category,
    'action', action,
    'actorUserId', actor_user_id,
    'branchId', branch_id,
    'salesPointId', sales_point_id,
    'entityType', entity_type,
    'entityId', entity_id,
    'entityLabel', entity_label,
    'details', details
  ) order by event_at desc,event_key desc), '[]'::jsonb)
  into v_rows
  from (
    select *
    from filtered
    order by event_at desc,event_key desc
    offset v_offset
    limit v_page_size
  ) page_rows;

  return jsonb_build_object(
    'coverage', jsonb_build_object(
      'sourceBackedOnly', true,
      'completeGeneralAuditLog', false,
      'notes', jsonb_build_array(
        'Order status, cash, inventory, loyalty ledger, voucher/promotion application and durable shift lifecycle facts are projected.',
        'Historical configuration edits and repeated shift lock/resume transitions were not durably event-sourced before Phase 8 and are not fabricated.'
      )
    ),
    'filter', v_filter,
    'totalCount', v_total_count,
    'items', v_rows
  );
end;
$$;

revoke all on function private.get_admin_audit_events_impl(jsonb, uuid)
from public, anon, authenticated;
grant execute on function private.get_admin_audit_events_impl(jsonb, uuid)
to authenticated;

create or replace function public.get_admin_audit_events(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.get_admin_audit_events_impl(p_filter, (select auth.uid()));
$$;

revoke all on function public.get_admin_audit_events(jsonb)
from public, anon, authenticated;
grant execute on function public.get_admin_audit_events(jsonb)
to authenticated;

comment on function public.get_admin_reporting_summary(jsonb) is
  'Phase 8 read-only operational summary. Commercial totals are accepted order values, not processor settlement.';
comment on function public.get_admin_transaction_report(jsonb) is
  'Phase 8 paginated source-backed order transaction report; refund/processor settlement is intentionally unavailable until Phase 9.';
comment on function public.get_admin_audit_events(jsonb) is
  'Phase 8 source-backed audit projection over durable Phase 1–7 ledgers/events; incomplete historical event coverage is declared in the response.';
