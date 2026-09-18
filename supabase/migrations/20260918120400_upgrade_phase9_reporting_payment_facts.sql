-- TASK-OPS-009 / Phase 9 — reporting/payment capability completion.
-- Adds source-backed payment/refund reporting without rewriting accepted order
-- commercial facts, and enforces declared provider refund capability.

create or replace function private.enforce_external_refund_provider_capability()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_supports_refunds boolean;
begin
  if new.tender_type <> 'external' then
    return new;
  end if;

  select c.supports_refunds
  into v_supports_refunds
  from public.payment_intents p
  join public.payment_provider_configs c on c.provider_key=p.provider_key
  where p.id=new.payment_intent_id;

  if not coalesce(v_supports_refunds,false) then
    raise exception 'payment provider does not support refunds'
      using errcode='55000',detail='REFUND_PROVIDER_UNSUPPORTED';
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_external_refund_provider_capability()
from public,anon,authenticated;

drop trigger if exists payment_refunds_provider_capability on public.payment_refunds;
create trigger payment_refunds_provider_capability
before insert on public.payment_refunds
for each row execute function private.enforce_external_refund_provider_capability();

create or replace function private.get_payment_provider_admin_state_impl(
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform private.require_reporting_admin(p_actor_user_id);

  select coalesce(jsonb_agg(jsonb_build_object(
    'providerKey',c.provider_key,
    'displayName',c.display_name,
    'environment',c.environment,
    'isActive',c.is_active,
    'customerEnabled',c.customer_enabled,
    'posEnabled',c.pos_enabled,
    'supportsRefunds',c.supports_refunds,
    'createdAt',c.created_at,
    'updatedAt',c.updated_at
  ) order by c.provider_key),'[]'::jsonb)
  into v_result
  from public.payment_provider_configs c;

  return v_result;
end;
$$;

revoke all on function private.get_payment_provider_admin_state_impl(uuid)
from public,anon,authenticated;
grant execute on function private.get_payment_provider_admin_state_impl(uuid)
to authenticated;

create or replace function public.get_payment_provider_admin_state()
returns jsonb
language sql
stable
security invoker
set search_path = public,pg_temp
as $$
  select private.get_payment_provider_admin_state_impl((select auth.uid()));
$$;

revoke all on function public.get_payment_provider_admin_state()
from public,anon,authenticated;
grant execute on function public.get_payment_provider_admin_state()
to authenticated;

create or replace function private.get_admin_reporting_summary_phase9_impl(
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
  v_base jsonb;
  v_filter jsonb;
  v_from_date date;
  v_to_date date;
  v_branch_id uuid;
  v_sales_point_id uuid;
  v_payments jsonb;
  v_paid_pos_cash_sen bigint;
begin
  v_base := private.get_admin_reporting_summary_impl(p_filter,p_actor_user_id);
  v_filter := private.reporting_filter_impl(p_filter,p_actor_user_id);
  v_from_date := (v_filter->>'fromDate')::date;
  v_to_date := (v_filter->>'toDate')::date;
  v_branch_id := nullif(v_filter->>'branchId','')::uuid;
  v_sales_point_id := nullif(v_filter->>'salesPointId','')::uuid;

  with selected_orders as (
    select
      o.*,
      coalesce((
        select sum(r.amount_sen)
        from public.payment_refunds r
        where r.order_id=o.id and r.state='succeeded'
      ),0)::bigint as ledger_refunded_sen
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
  ),
  state_counts as (
    select payment_state,count(*)::bigint as row_count
    from selected_orders
    group by payment_state
  )
  select jsonb_build_object(
    'capturedOrderCount',count(*) filter (
      where payment_state in ('paid','partially_refunded','refunded')
    ),
    'grossCapturedSen',coalesce(sum(total_sen) filter (
      where payment_state in ('paid','partially_refunded','refunded')
    ),0),
    'cashCapturedSen',coalesce(sum(total_sen) filter (
      where tender_type='cash' and payment_state in ('paid','partially_refunded','refunded')
    ),0),
    'externalCapturedSen',coalesce(sum(total_sen) filter (
      where tender_type='external' and payment_state in ('paid','partially_refunded','refunded')
    ),0),
    'pendingExternalSen',coalesce(sum(total_sen) filter (
      where tender_type='external' and payment_state='pending'
    ),0),
    'succeededRefundSen',coalesce(sum(refunded_sen),0),
    'cashRefundedSen',coalesce((
      select sum(r.amount_sen)
      from public.payment_refunds r
      join selected_orders so on so.id=r.order_id
      where r.state='succeeded' and r.tender_type='cash'
    ),0),
    'externalRefundedSen',coalesce((
      select sum(r.amount_sen)
      from public.payment_refunds r
      join selected_orders so on so.id=r.order_id
      where r.state='succeeded' and r.tender_type='external'
    ),0),
    'netCapturedAfterRefundSen',coalesce(sum(total_sen-refunded_sen) filter (
      where payment_state in ('paid','partially_refunded','refunded')
    ),0),
    'refundReconciled',coalesce(bool_and(refunded_sen=ledger_refunded_sen),true),
    'paymentStateCounts',coalesce((
      select jsonb_object_agg(payment_state,row_count order by payment_state)
      from state_counts
    ),'{}'::jsonb),
    'externalSettlement',jsonb_build_object(
      'settledSen',coalesce((
        select sum(p.amount_sen)
        from public.payment_intents p
        join selected_orders so on so.id=p.order_id
        where p.state='captured' and p.settlement_state='settled'
      ),0),
      'pendingSen',coalesce((
        select sum(p.amount_sen)
        from public.payment_intents p
        join selected_orders so on so.id=p.order_id
        where p.state='captured' and p.settlement_state='pending'
      ),0),
      'failedSen',coalesce((
        select sum(p.amount_sen)
        from public.payment_intents p
        join selected_orders so on so.id=p.order_id
        where p.state='captured' and p.settlement_state='failed'
      ),0),
      'notReportedSen',coalesce((
        select sum(p.amount_sen)
        from public.payment_intents p
        join selected_orders so on so.id=p.order_id
        where p.state='captured' and p.settlement_state='not_reported'
      ),0)
    )
  )
  into v_payments
  from selected_orders;

  with selected_orders as (
    select o.*
    from public.orders o
    join public.branches b on b.id=o.branch_id
    where (o.created_at at time zone b.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or o.branch_id=v_branch_id)
      and (v_sales_point_id is null or o.sales_point_id=v_sales_point_id)
      and o.status<>'cancelled'
  )
  select coalesce(sum(total_sen) filter (
    where source='pos'
      and tender_type='cash'
      and payment_state in ('paid','partially_refunded','refunded')
  ),0)::bigint
  into v_paid_pos_cash_sen
  from selected_orders;

  v_base := jsonb_set(
    v_base,
    '{orders}',
    (v_base->'orders') || jsonb_build_object('paidPosCashSen',v_paid_pos_cash_sen),
    true
  );
  v_base := jsonb_set(
    v_base,
    '{semantics}',
    (v_base->'semantics') || jsonb_build_object(
      'refundDataAvailable',true,
      'paymentFactsIncludeCancelledOrders',true,
      'acceptedOrderValueIsSettlement',false,
      'providerSettlementStateAvailable',true
    ),
    true
  );

  return v_base || jsonb_build_object('payments',v_payments);
end;
$$;

revoke all on function private.get_admin_reporting_summary_phase9_impl(jsonb,uuid)
from public,anon,authenticated;
grant execute on function private.get_admin_reporting_summary_phase9_impl(jsonb,uuid)
to authenticated;

create or replace function public.get_admin_reporting_summary(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public,pg_temp
as $$
  select private.get_admin_reporting_summary_phase9_impl(p_filter,(select auth.uid()));
$$;

revoke all on function public.get_admin_reporting_summary(jsonb)
from public,anon,authenticated;
grant execute on function public.get_admin_reporting_summary(jsonb)
to authenticated;

create or replace function private.get_admin_transaction_report_phase9_impl(
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
  v_base jsonb;
  v_rows jsonb;
begin
  v_base := private.get_admin_transaction_report_impl(p_filter,p_actor_user_id);

  select coalesce(jsonb_agg(
    item || jsonb_build_object(
      'currency',o.currency,
      'refundedSen',o.refunded_sen,
      'refundableSen',greatest(o.total_sen-o.refunded_sen,0),
      'refundReservedSen',coalesce((
        select sum(r.amount_sen)
        from public.payment_refunds r
        where r.order_id=o.id and r.state in ('requested','processing','succeeded')
      ),0),
      'refundReconciled',o.refunded_sen=coalesce((
        select sum(r.amount_sen)
        from public.payment_refunds r
        where r.order_id=o.id and r.state='succeeded'
      ),0),
      'latestPaymentIntent',(
        select jsonb_build_object(
          'id',p.id,
          'providerKey',p.provider_key,
          'state',p.state,
          'settlementState',p.settlement_state,
          'amountSen',p.amount_sen,
          'currency',p.currency,
          'createdAt',p.created_at,
          'authorizedAt',p.authorized_at,
          'capturedAt',p.captured_at,
          'settledAt',p.settled_at
        )
        from public.payment_intents p
        where p.order_id=o.id
        order by p.created_at desc,p.id desc
        limit 1
      ),
      'refunds',coalesce((
        select jsonb_agg(jsonb_build_object(
          'id',r.id,
          'tenderType',r.tender_type,
          'state',r.state,
          'amountSen',r.amount_sen,
          'reason',r.reason,
          'createdAt',r.created_at,
          'succeededAt',r.succeeded_at
        ) order by r.created_at,r.id)
        from public.payment_refunds r
        where r.order_id=o.id
      ),'[]'::jsonb)
    )
    order by ordinality
  ),'[]'::jsonb)
  into v_rows
  from jsonb_array_elements(v_base->'items') with ordinality rows(item,ordinality)
  join public.orders o on o.id=(item->>'orderId')::uuid;

  v_base := jsonb_set(v_base,'{items}',v_rows,true);
  v_base := jsonb_set(
    v_base,
    '{semantics}',
    (v_base->'semantics') || jsonb_build_object(
      'refundDataAvailable',true,
      'providerLifecycleAvailable',true,
      'acceptedOrderValueUnchangedByRefunds',true,
      'providerSettlementStateAvailable',true
    ),
    true
  );

  return v_base;
end;
$$;

revoke all on function private.get_admin_transaction_report_phase9_impl(jsonb,uuid)
from public,anon,authenticated;
grant execute on function private.get_admin_transaction_report_phase9_impl(jsonb,uuid)
to authenticated;

create or replace function public.get_admin_transaction_report(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public,pg_temp
as $$
  select private.get_admin_transaction_report_phase9_impl(p_filter,(select auth.uid()));
$$;

revoke all on function public.get_admin_transaction_report(jsonb)
from public,anon,authenticated;
grant execute on function public.get_admin_transaction_report(jsonb)
to authenticated;

create or replace function private.get_admin_payment_audit_events_impl(
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
  v_filter := private.reporting_filter_impl(p_filter,p_actor_user_id);
  v_from_date := (v_filter->>'fromDate')::date;
  v_to_date := (v_filter->>'toDate')::date;
  v_branch_id := nullif(v_filter->>'branchId','')::uuid;
  v_sales_point_id := nullif(v_filter->>'salesPointId','')::uuid;
  v_page_size := (v_filter->>'pageSize')::integer;
  v_offset := (v_filter->>'offset')::integer;

  with all_events as (
    select
      e.created_at as event_at,
      'payment:'||e.id::text as event_key,
      'payment'::text as category,
      e.event_type::text as action,
      e.actor_user_id,
      o.branch_id,
      o.sales_point_id,
      b.timezone,
      'payment_intent'::text as entity_type,
      p.id::text as entity_id,
      'Order '||o.order_number::text||' payment' as entity_label,
      jsonb_build_object(
        'orderId',o.id,
        'providerKey',e.provider_key,
        'providerEventId',e.provider_event_id,
        'payloadSha256',e.payload_sha256,
        'amountSen',p.amount_sen,
        'currency',p.currency,
        'paymentState',p.state,
        'settlementState',p.settlement_state
      ) as details
    from public.payment_events e
    join public.payment_intents p on p.id=e.payment_intent_id
    join public.orders o on o.id=p.order_id
    join public.branches b on b.id=o.branch_id

    union all

    select
      e.created_at,
      'refund:'||e.id::text,
      'refund',
      e.event_type,
      e.actor_user_id,
      o.branch_id,
      o.sales_point_id,
      b.timezone,
      'payment_refund',
      r.id::text,
      'Order '||o.order_number::text||' refund',
      jsonb_build_object(
        'orderId',o.id,
        'providerKey',e.provider_key,
        'providerEventId',e.provider_event_id,
        'payloadSha256',e.payload_sha256,
        'tenderType',r.tender_type,
        'refundState',r.state,
        'amountSen',r.amount_sen,
        'reason',r.reason
      )
    from public.payment_refund_events e
    join public.payment_refunds r on r.id=e.refund_id
    join public.orders o on o.id=r.order_id
    join public.branches b on b.id=o.branch_id
  ), filtered as (
    select *
    from all_events e
    where (e.event_at at time zone e.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or e.branch_id=v_branch_id)
      and (v_sales_point_id is null or e.sales_point_id=v_sales_point_id)
  )
  select count(*) into v_total_count from filtered;

  with all_events as (
    select e.created_at as event_at,'payment:'||e.id::text as event_key,'payment'::text as category,e.event_type::text as action,e.actor_user_id,o.branch_id,o.sales_point_id,b.timezone,'payment_intent'::text as entity_type,p.id::text as entity_id,'Order '||o.order_number::text||' payment' as entity_label,jsonb_build_object('orderId',o.id,'providerKey',e.provider_key,'providerEventId',e.provider_event_id,'payloadSha256',e.payload_sha256,'amountSen',p.amount_sen,'currency',p.currency,'paymentState',p.state,'settlementState',p.settlement_state) as details
    from public.payment_events e join public.payment_intents p on p.id=e.payment_intent_id join public.orders o on o.id=p.order_id join public.branches b on b.id=o.branch_id
    union all
    select e.created_at,'refund:'||e.id::text,'refund',e.event_type,e.actor_user_id,o.branch_id,o.sales_point_id,b.timezone,'payment_refund',r.id::text,'Order '||o.order_number::text||' refund',jsonb_build_object('orderId',o.id,'providerKey',e.provider_key,'providerEventId',e.provider_event_id,'payloadSha256',e.payload_sha256,'tenderType',r.tender_type,'refundState',r.state,'amountSen',r.amount_sen,'reason',r.reason)
    from public.payment_refund_events e join public.payment_refunds r on r.id=e.refund_id join public.orders o on o.id=r.order_id join public.branches b on b.id=o.branch_id
  ), filtered as (
    select *
    from all_events e
    where (e.event_at at time zone e.timezone)::date between v_from_date and v_to_date
      and (v_branch_id is null or e.branch_id=v_branch_id)
      and (v_sales_point_id is null or e.sales_point_id=v_sales_point_id)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'eventKey',event_key,
    'occurredAt',event_at,
    'localDate',(event_at at time zone timezone)::date,
    'localTime',to_char(event_at at time zone timezone,'HH24:MI:SS'),
    'timezone',timezone,
    'category',category,
    'action',action,
    'actorUserId',actor_user_id,
    'branchId',branch_id,
    'salesPointId',sales_point_id,
    'entityType',entity_type,
    'entityId',entity_id,
    'entityLabel',entity_label,
    'details',details
  ) order by event_at desc,event_key desc),'[]'::jsonb)
  into v_rows
  from (
    select *
    from filtered
    order by event_at desc,event_key desc
    offset v_offset
    limit v_page_size
  ) page_rows;

  return jsonb_build_object(
    'coverage',jsonb_build_object(
      'sourceBackedOnly',true,
      'rawProviderPayloadIncluded',false,
      'notes',jsonb_build_array(
        'Payment/refund lifecycle events are projected from append-only Phase 9 source facts.',
        'Provider payload digests may be shown for reconciliation; raw provider payloads and secrets are not stored.'
      )
    ),
    'filter',v_filter,
    'totalCount',v_total_count,
    'items',v_rows
  );
end;
$$;

revoke all on function private.get_admin_payment_audit_events_impl(jsonb,uuid)
from public,anon,authenticated;
grant execute on function private.get_admin_payment_audit_events_impl(jsonb,uuid)
to authenticated;

create or replace function public.get_admin_payment_audit_events(
  p_filter jsonb default '{}'::jsonb
)
returns jsonb
language sql
stable
security invoker
set search_path = public,pg_temp
as $$
  select private.get_admin_payment_audit_events_impl(p_filter,(select auth.uid()));
$$;

revoke all on function public.get_admin_payment_audit_events(jsonb)
from public,anon,authenticated;
grant execute on function public.get_admin_payment_audit_events(jsonb)
to authenticated;

comment on function public.get_payment_provider_admin_state() is
  'Admin/Owner read-only projection of non-secret Phase 9 provider capability/activation metadata.';
comment on function public.get_admin_payment_audit_events(jsonb) is
  'Admin/Owner source-backed Phase 9 payment/refund audit events; no raw provider payloads or secrets.';
