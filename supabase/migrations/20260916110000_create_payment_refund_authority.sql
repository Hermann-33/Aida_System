-- TASK-OPS-009 / Phase 9 — provider-neutral payment, refund and webhook authority.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/migrations/ only.
--
-- This migration creates payment/refund source facts without activating or
-- pretending that any external processor is configured. Provider secrets do
-- not live in these tables. External provider events can only be applied by a
-- server-side service-role boundary; normal anon/authenticated clients cannot
-- author captured/settled/refunded truth.

alter table public.orders
  add column if not exists refunded_sen bigint not null default 0;

alter table public.orders
  drop constraint if exists orders_tender_type_check,
  drop constraint if exists orders_payment_state_check,
  drop constraint if exists orders_payment_shape_check,
  drop constraint if exists orders_customer_shift_payment_check,
  drop constraint if exists orders_refunded_sen_check;

alter table public.orders
  add constraint orders_tender_type_check
    check (tender_type in ('unpaid','cash','external')),
  add constraint orders_payment_state_check
    check (payment_state in ('unpaid','pending','paid','partially_refunded','refunded')),
  add constraint orders_refunded_sen_check
    check (refunded_sen >= 0 and refunded_sen <= total_sen),
  add constraint orders_payment_shape_check
    check (
      (
        tender_type = 'unpaid'
        and payment_state = 'unpaid'
        and paid_at is null
        and refunded_sen = 0
      )
      or (
        tender_type = 'cash'
        and payment_state in ('paid','partially_refunded','refunded')
        and paid_at is not null
        and (
          (payment_state = 'paid' and refunded_sen = 0)
          or (payment_state = 'partially_refunded' and refunded_sen > 0 and refunded_sen < total_sen)
          or (payment_state = 'refunded' and refunded_sen = total_sen)
        )
      )
      or (
        tender_type = 'external'
        and (
          (payment_state = 'pending' and paid_at is null and refunded_sen = 0)
          or (
            payment_state in ('paid','partially_refunded','refunded')
            and paid_at is not null
            and (
              (payment_state = 'paid' and refunded_sen = 0)
              or (payment_state = 'partially_refunded' and refunded_sen > 0 and refunded_sen < total_sen)
              or (payment_state = 'refunded' and refunded_sen = total_sen)
            )
          )
        )
      )
    ),
  add constraint orders_customer_shift_payment_check
    check (
      source <> 'customer'
      or (
        shift_id is null
        and tender_type in ('unpaid','external')
        and not (tender_type = 'unpaid' and payment_state <> 'unpaid')
      )
    );

create table if not exists public.payment_provider_configs (
  provider_key text primary key,
  display_name text not null,
  environment text not null default 'test'
    check (environment in ('test','live')),
  is_active boolean not null default false,
  customer_enabled boolean not null default false,
  pos_enabled boolean not null default false,
  supports_refunds boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint payment_provider_key_shape_check
    check (provider_key ~ '^[a-z][a-z0-9_-]{1,39}$'),
  constraint payment_provider_display_name_check
    check (char_length(btrim(display_name)) between 1 and 80),
  constraint payment_provider_enabled_requires_active_check
    check (is_active or (not customer_enabled and not pos_enabled))
);

create unique index if not exists payment_provider_one_customer_active_idx
  on public.payment_provider_configs ((1))
  where is_active and customer_enabled;
create unique index if not exists payment_provider_one_pos_active_idx
  on public.payment_provider_configs ((1))
  where is_active and pos_enabled;

create table if not exists public.payment_intents (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  provider_key text not null references public.payment_provider_configs(provider_key) on delete restrict,
  channel text not null check (channel in ('customer','pos')),
  state text not null default 'created'
    check (state in ('created','requires_action','authorized','captured','failed','cancelled')),
  settlement_state text not null default 'not_reported'
    check (settlement_state in ('not_reported','pending','settled','failed')),
  amount_sen bigint not null check (amount_sen > 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  idempotency_key uuid not null,
  provider_payment_id text,
  created_by_user_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  authorized_at timestamptz,
  captured_at timestamptz,
  failed_at timestamptz,
  cancelled_at timestamptz,
  settled_at timestamptz,
  constraint payment_intents_order_idempotency_key unique(order_id,idempotency_key),
  constraint payment_intents_provider_payment_id_check
    check (provider_payment_id is null or char_length(provider_payment_id) between 1 and 200),
  constraint payment_intents_state_timestamp_check
    check (
      (state <> 'captured' or captured_at is not null)
      and (state <> 'failed' or failed_at is not null)
      and (state <> 'cancelled' or cancelled_at is not null)
      and (settlement_state <> 'settled' or settled_at is not null)
    )
);

create unique index if not exists payment_intents_provider_reference_idx
  on public.payment_intents(provider_key,provider_payment_id)
  where provider_payment_id is not null;
create unique index if not exists payment_intents_one_capture_per_order_idx
  on public.payment_intents(order_id)
  where state = 'captured';
create index if not exists payment_intents_order_created_idx
  on public.payment_intents(order_id,created_at desc,id desc);
create index if not exists payment_intents_state_created_idx
  on public.payment_intents(state,created_at desc,id desc);

create table if not exists public.payment_events (
  id uuid primary key default gen_random_uuid(),
  payment_intent_id uuid not null references public.payment_intents(id) on delete restrict,
  provider_key text not null,
  event_type text not null
    check (event_type in (
      'created','requires_action','authorized','captured','failed','cancelled',
      'settlement_pending','settled','settlement_failed'
    )),
  provider_event_id text,
  payload_sha256 text,
  actor_user_id uuid,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  details jsonb not null default '{}'::jsonb,
  constraint payment_events_provider_event_id_check
    check (provider_event_id is null or char_length(provider_event_id) between 1 and 200),
  constraint payment_events_payload_sha256_check
    check (payload_sha256 is null or payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint payment_events_details_object_check
    check (jsonb_typeof(details) = 'object')
);

create unique index if not exists payment_events_provider_event_idx
  on public.payment_events(provider_key,provider_event_id)
  where provider_event_id is not null;
create index if not exists payment_events_intent_created_idx
  on public.payment_events(payment_intent_id,created_at,id);

create table if not exists public.payment_refunds (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  payment_intent_id uuid references public.payment_intents(id) on delete restrict,
  tender_type text not null check (tender_type in ('cash','external')),
  state text not null default 'requested'
    check (state in ('requested','processing','succeeded','failed','cancelled')),
  amount_sen bigint not null check (amount_sen > 0),
  idempotency_key uuid not null,
  reason text,
  requested_by_user_id uuid,
  provider_refund_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  processing_at timestamptz,
  succeeded_at timestamptz,
  failed_at timestamptz,
  cancelled_at timestamptz,
  constraint payment_refunds_order_idempotency_key unique(order_id,idempotency_key),
  constraint payment_refunds_reason_check
    check (reason is null or char_length(btrim(reason)) between 1 and 300),
  constraint payment_refunds_provider_reference_check
    check (provider_refund_id is null or char_length(provider_refund_id) between 1 and 200),
  constraint payment_refunds_tender_intent_check
    check ((tender_type = 'cash' and payment_intent_id is null) or (tender_type = 'external' and payment_intent_id is not null)),
  constraint payment_refunds_state_timestamp_check
    check (
      (state <> 'processing' or processing_at is not null)
      and (state <> 'succeeded' or succeeded_at is not null)
      and (state <> 'failed' or failed_at is not null)
      and (state <> 'cancelled' or cancelled_at is not null)
    )
);

create unique index if not exists payment_refunds_provider_reference_idx
  on public.payment_refunds(provider_refund_id)
  where provider_refund_id is not null;
create index if not exists payment_refunds_order_created_idx
  on public.payment_refunds(order_id,created_at desc,id desc);
create index if not exists payment_refunds_intent_created_idx
  on public.payment_refunds(payment_intent_id,created_at desc,id desc)
  where payment_intent_id is not null;

create table if not exists public.payment_refund_events (
  id uuid primary key default gen_random_uuid(),
  refund_id uuid not null references public.payment_refunds(id) on delete restrict,
  provider_key text,
  event_type text not null
    check (event_type in ('requested','processing','succeeded','failed','cancelled')),
  provider_event_id text,
  payload_sha256 text,
  actor_user_id uuid,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  details jsonb not null default '{}'::jsonb,
  constraint payment_refund_events_provider_event_id_check
    check (provider_event_id is null or char_length(provider_event_id) between 1 and 200),
  constraint payment_refund_events_payload_sha256_check
    check (payload_sha256 is null or payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint payment_refund_events_details_object_check
    check (jsonb_typeof(details) = 'object')
);

create unique index if not exists payment_refund_events_provider_event_idx
  on public.payment_refund_events(provider_key,provider_event_id)
  where provider_key is not null and provider_event_id is not null;
create index if not exists payment_refund_events_refund_created_idx
  on public.payment_refund_events(refund_id,created_at,id);

create table if not exists public.payment_webhook_receipts (
  id uuid primary key default gen_random_uuid(),
  provider_key text not null,
  provider_event_id text not null,
  event_type text not null,
  payload_sha256 text not null,
  processing_state text not null default 'received'
    check (processing_state in ('received','processed','ignored','failed')),
  payment_intent_id uuid references public.payment_intents(id) on delete restrict,
  refund_id uuid references public.payment_refunds(id) on delete restrict,
  received_at timestamptz not null default now(),
  processed_at timestamptz,
  error_code text,
  constraint payment_webhook_provider_event_unique unique(provider_key,provider_event_id),
  constraint payment_webhook_provider_key_check
    check (provider_key ~ '^[a-z][a-z0-9_-]{1,39}$'),
  constraint payment_webhook_event_id_check
    check (char_length(provider_event_id) between 1 and 200),
  constraint payment_webhook_payload_sha256_check
    check (payload_sha256 ~ '^[0-9a-f]{64}$')
);

create index if not exists payment_webhook_received_idx
  on public.payment_webhook_receipts(received_at desc,id desc);

alter table public.payment_provider_configs enable row level security;
alter table public.payment_provider_configs force row level security;
alter table public.payment_intents enable row level security;
alter table public.payment_intents force row level security;
alter table public.payment_events enable row level security;
alter table public.payment_events force row level security;
alter table public.payment_refunds enable row level security;
alter table public.payment_refunds force row level security;
alter table public.payment_refund_events enable row level security;
alter table public.payment_refund_events force row level security;
alter table public.payment_webhook_receipts enable row level security;
alter table public.payment_webhook_receipts force row level security;

revoke all on table public.payment_provider_configs from public,anon,authenticated;
revoke all on table public.payment_intents from public,anon,authenticated;
revoke all on table public.payment_events from public,anon,authenticated;
revoke all on table public.payment_refunds from public,anon,authenticated;
revoke all on table public.payment_refund_events from public,anon,authenticated;
revoke all on table public.payment_webhook_receipts from public,anon,authenticated;

create or replace function private.reject_payment_history_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'payment/refund event history is append-only'
    using errcode='42501',detail='PAYMENT_HISTORY_IMMUTABLE';
end;
$$;

revoke all on function private.reject_payment_history_mutation()
from public,anon,authenticated;

drop trigger if exists payment_events_immutable on public.payment_events;
create trigger payment_events_immutable
before update or delete on public.payment_events
for each row execute function private.reject_payment_history_mutation();

drop trigger if exists payment_refund_events_immutable on public.payment_refund_events;
create trigger payment_refund_events_immutable
before update or delete on public.payment_refund_events
for each row execute function private.reject_payment_history_mutation();

create or replace function private.payment_refunded_sen(p_order_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(sum(r.amount_sen),0)::bigint
  from public.payment_refunds r
  where r.order_id=p_order_id and r.state='succeeded';
$$;

revoke all on function private.payment_refunded_sen(uuid)
from public,anon,authenticated;

create or replace function private.project_order_payment_state_impl(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_captured public.payment_intents%rowtype;
  v_active public.payment_intents%rowtype;
  v_refunded bigint;
  v_tender text;
  v_state text;
  v_paid_at timestamptz;
begin
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then
    raise exception 'order not found' using errcode='P0002',detail='ORDER_NOT_FOUND';
  end if;

  v_refunded := private.payment_refunded_sen(p_order_id);
  if v_refunded > v_order.total_sen then
    raise exception 'refund total exceeds accepted order total'
      using errcode='23514',detail='REFUND_TOTAL_EXCEEDED';
  end if;

  if v_order.tender_type='cash' then
    v_tender := 'cash';
    v_paid_at := v_order.paid_at;
    v_state := case
      when v_refunded=0 then 'paid'
      when v_refunded<v_order.total_sen then 'partially_refunded'
      else 'refunded'
    end;
  else
    select * into v_captured
    from public.payment_intents
    where order_id=p_order_id and state='captured'
    order by captured_at desc nulls last,created_at desc,id desc
    limit 1;

    if found then
      if v_captured.amount_sen<>v_order.total_sen or v_captured.currency<>v_order.currency then
        raise exception 'captured payment does not match accepted order total'
          using errcode='23514',detail='PAYMENT_AMOUNT_MISMATCH';
      end if;
      v_tender := 'external';
      v_paid_at := v_captured.captured_at;
      v_state := case
        when v_refunded=0 then 'paid'
        when v_refunded<v_order.total_sen then 'partially_refunded'
        else 'refunded'
      end;
    else
      select * into v_active
      from public.payment_intents
      where order_id=p_order_id and state in ('created','requires_action','authorized')
      order by created_at desc,id desc
      limit 1;
      if found then
        v_tender := 'external';
        v_state := 'pending';
        v_paid_at := null;
        if v_refunded<>0 then
          raise exception 'uncaptured order cannot have succeeded refunds'
            using errcode='23514',detail='REFUND_WITHOUT_CAPTURE';
        end if;
      else
        v_tender := 'unpaid';
        v_state := 'unpaid';
        v_paid_at := null;
        if v_refunded<>0 then
          raise exception 'unpaid order cannot have succeeded refunds'
            using errcode='23514',detail='REFUND_WITHOUT_CAPTURE';
        end if;
      end if;
    end if;
  end if;

  perform set_config('aida.internal_payment_projection','on',true);
  update public.orders
  set tender_type=v_tender,
      payment_state=v_state,
      paid_at=v_paid_at,
      refunded_sen=v_refunded,
      updated_at=now()
  where id=p_order_id;
  perform set_config('aida.internal_payment_projection','off',true);
end;
$$;

revoke all on function private.project_order_payment_state_impl(uuid)
from public,anon,authenticated;

-- Extend the existing commercial immutability trigger with a narrowly scoped
-- internal payment projection path while preserving shift-finalization and
-- customer-anonymisation behavior.
create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = 'public','pg_temp'
as $$
declare
  v_internal_finalize boolean := coalesce(current_setting('aida.internal_order_shift_finalize',true),'')='on';
  v_internal_payment boolean := coalesce(current_setting('aida.internal_payment_projection',true),'')='on';
  v_internal_anonymize boolean := coalesce(current_setting('aida.internal_customer_anonymize',true),'')='on';
  v_identity_changed boolean := new.customer_user_id is distinct from old.customer_user_id
    or new.member_id is distinct from old.member_id
    or new.created_by_user_id is distinct from old.created_by_user_id
    or new.customer_deleted_at is distinct from old.customer_deleted_at;
  v_request_hash_changed boolean := new.request_hash is distinct from old.request_hash;
  v_valid_anonymize boolean := v_internal_anonymize
    and old.source='customer'
    and old.customer_user_id is not null
    and old.member_id is not null
    and old.created_by_user_id=old.customer_user_id
    and old.customer_deleted_at is null
    and new.customer_user_id is null
    and new.member_id is null
    and new.created_by_user_id is null
    and new.customer_deleted_at is not null
    and new.request_hash=md5('deleted:'||old.id::text);
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.branch_id is distinct from old.branch_id
     or new.sales_point_id is distinct from old.sales_point_id
     or new.terminal_id is distinct from old.terminal_id
     or new.sales_point_code_snapshot is distinct from old.sales_point_code_snapshot
     or new.sales_point_name_snapshot is distinct from old.sales_point_name_snapshot
     or new.terminal_code_snapshot is distinct from old.terminal_code_snapshot
     or new.client_request_id is distinct from old.client_request_id
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.discount_sen is distinct from old.discount_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable' using errcode='42501';
  end if;

  if (v_identity_changed or v_request_hash_changed) and not v_valid_anonymize then
    raise exception 'persisted order customer identity fields are immutable' using errcode='42501';
  end if;

  if new.shift_id is distinct from old.shift_id then
    if not v_internal_finalize
       or old.source<>'pos'
       or old.shift_id is not null
       or new.shift_id is null then
      raise exception 'persisted order shift/payment fields are immutable' using errcode='42501';
    end if;
  end if;

  if new.tender_type is distinct from old.tender_type
     or new.payment_state is distinct from old.payment_state
     or new.paid_at is distinct from old.paid_at
     or new.refunded_sen is distinct from old.refunded_sen then
    if v_internal_finalize then
      if old.source<>'pos'
         or old.shift_id is not null
         or new.shift_id is null
         or old.tender_type<>'unpaid'
         or old.payment_state<>'unpaid'
         or old.paid_at is not null
         or old.refunded_sen<>0
         or new.refunded_sen<>0 then
        raise exception 'persisted order shift/payment fields are immutable' using errcode='42501';
      end if;
    elsif v_internal_payment then
      if new.shift_id is distinct from old.shift_id then
        raise exception 'payment projection cannot change shift' using errcode='42501';
      end if;
    else
      raise exception 'persisted order shift/payment fields are immutable' using errcode='42501';
    end if;
  end if;

  return new;
end;
$$;

create or replace function private.payment_public_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'tenderType',o.tender_type,
    'paymentState',o.payment_state,
    'paidAt',o.paid_at,
    'refundedSen',o.refunded_sen,
    'refundableSen',greatest(o.total_sen-o.refunded_sen,0),
    'providerAvailable',exists(
      select 1 from public.payment_provider_configs c
      where c.is_active and (
        (o.source='customer' and c.customer_enabled)
        or (o.source='pos' and c.pos_enabled)
      )
    ),
    'latestIntent',(
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
      from public.payment_refunds r where r.order_id=o.id
    ),'[]'::jsonb)
  )
  from public.orders o where o.id=p_order_id;
$$;

revoke all on function private.payment_public_snapshot(uuid)
from public,anon,authenticated;

-- Add Phase 9 payment/refund projection without weakening the existing order
-- access check performed by the Phase 5 base snapshot.
create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when base.snapshot is null then null else
    base.snapshot || jsonb_build_object(
      'voucherDiscountSen',coalesce((base.snapshot#>>'{voucher,discountSen}')::bigint,0),
      'promotionDiscountSen',coalesce((
        select sum(a.discount_sen) from public.promotion_order_applications a where a.order_id=o.id
      ),0),
      'promotions',coalesce((
        select jsonb_agg(jsonb_build_object(
          'code',a.promotion_code_snapshot,
          'name',a.promotion_name_snapshot,
          'discountType',a.discount_type_snapshot,
          'discountValue',a.discount_value_snapshot,
          'discountSen',a.discount_sen,
          'priority',a.priority_snapshot,
          'stackingMode',a.stacking_mode_snapshot,
          'allowWithVoucher',a.allow_with_voucher_snapshot,
          'appliedAt',a.applied_at
        ) order by a.priority_snapshot,a.promotion_code_snapshot)
        from public.promotion_order_applications a where a.order_id=o.id
      ),'[]'::jsonb),
      'refundedSen',o.refunded_sen,
      'payment',private.payment_public_snapshot(o.id)
    ) end
  from public.orders o
  cross join lateral (select private.order_snapshot_phase6(o.id) as snapshot) base
  where o.id=p_order_id;
$$;

create or replace function private.get_order_payment_state_impl(
  p_order_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501',detail='PAYMENT_ACTOR_MISMATCH';
  end if;
  select * into v_order from public.orders where id=p_order_id;
  if not found then raise exception 'order not found' using errcode='P0002',detail='ORDER_NOT_FOUND'; end if;
  if v_order.customer_user_id is distinct from p_actor_user_id
     and not (select private.can_operate_branch(v_order.branch_id)) then
    raise exception 'order access required' using errcode='42501',detail='ORDER_ACCESS_REQUIRED';
  end if;
  return private.payment_public_snapshot(p_order_id);
end;
$$;

revoke all on function private.get_order_payment_state_impl(uuid,uuid)
from public,anon,authenticated;
grant execute on function private.get_order_payment_state_impl(uuid,uuid) to authenticated;

create or replace function public.get_order_payment_state(p_order_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public,pg_temp
as $$
  select private.get_order_payment_state_impl(p_order_id,(select auth.uid()));
$$;

revoke all on function public.get_order_payment_state(uuid) from public,anon,authenticated;
grant execute on function public.get_order_payment_state(uuid) to authenticated;

create or replace function private.request_external_payment_impl(
  p_order_id uuid,
  p_idempotency_key uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_provider public.payment_provider_configs%rowtype;
  v_existing public.payment_intents%rowtype;
  v_intent public.payment_intents%rowtype;
  v_channel text;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501',detail='PAYMENT_ACTOR_MISMATCH';
  end if;
  if p_idempotency_key is null then
    raise exception 'idempotency key is required' using errcode='22023',detail='PAYMENT_IDEMPOTENCY_REQUIRED';
  end if;

  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'order not found' using errcode='P0002',detail='ORDER_NOT_FOUND'; end if;
  if v_order.customer_user_id=p_actor_user_id then
    v_channel := 'customer';
  elsif (select private.can_operate_branch(v_order.branch_id)) then
    v_channel := 'pos';
  else
    raise exception 'order access required' using errcode='42501',detail='ORDER_ACCESS_REQUIRED';
  end if;

  if v_order.status='cancelled' then
    raise exception 'cancelled order cannot be paid' using errcode='22023',detail='PAYMENT_ORDER_CANCELLED';
  end if;
  if v_order.payment_state in ('paid','partially_refunded','refunded') then
    raise exception 'order already has captured payment' using errcode='22023',detail='PAYMENT_ALREADY_CAPTURED';
  end if;
  if v_order.tender_type='cash' then
    raise exception 'cash order cannot start external payment' using errcode='22023',detail='PAYMENT_TENDER_CONFLICT';
  end if;

  select * into v_existing
  from public.payment_intents
  where order_id=p_order_id and idempotency_key=p_idempotency_key;
  if found then
    if v_existing.amount_sen<>v_order.total_sen or v_existing.currency<>v_order.currency or v_existing.channel<>v_channel then
      raise exception 'payment idempotency key conflicts with existing intent'
        using errcode='23505',detail='PAYMENT_IDEMPOTENCY_CONFLICT';
    end if;
    return private.payment_public_snapshot(p_order_id);
  end if;

  select * into v_provider
  from public.payment_provider_configs c
  where c.is_active
    and ((v_channel='customer' and c.customer_enabled) or (v_channel='pos' and c.pos_enabled))
  order by c.provider_key
  limit 1;
  if not found then
    raise exception 'external payment provider is not configured'
      using errcode='55000',detail='PAYMENT_PROVIDER_UNAVAILABLE';
  end if;

  insert into public.payment_intents(
    order_id,provider_key,channel,state,amount_sen,currency,idempotency_key,created_by_user_id
  ) values (
    p_order_id,v_provider.provider_key,v_channel,'created',v_order.total_sen,v_order.currency,p_idempotency_key,
    case when v_channel='customer' then null else p_actor_user_id end
  ) returning * into v_intent;

  insert into public.payment_events(
    payment_intent_id,provider_key,event_type,actor_user_id,details
  ) values (
    v_intent.id,v_intent.provider_key,'created',case when v_channel='customer' then null else p_actor_user_id end,
    jsonb_build_object('channel',v_channel)
  );

  perform private.project_order_payment_state_impl(p_order_id);
  return private.payment_public_snapshot(p_order_id);
end;
$$;

revoke all on function private.request_external_payment_impl(uuid,uuid,uuid)
from public,anon,authenticated;
grant execute on function private.request_external_payment_impl(uuid,uuid,uuid) to authenticated;

create or replace function public.request_external_payment(
  p_order_id uuid,
  p_idempotency_key uuid
)
returns jsonb
language sql
security invoker
set search_path = public,pg_temp
as $$
  select private.request_external_payment_impl(p_order_id,p_idempotency_key,(select auth.uid()));
$$;

revoke all on function public.request_external_payment(uuid,uuid) from public,anon,authenticated;
grant execute on function public.request_external_payment(uuid,uuid) to authenticated;

create or replace function private.apply_payment_provider_event_impl(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_intent public.payment_intents%rowtype;
  v_receipt public.payment_webhook_receipts%rowtype;
  v_receipt_id uuid;
  v_intent_id uuid;
  v_provider_key text := lower(btrim(coalesce(p_payload->>'providerKey','')));
  v_event_id text := nullif(btrim(coalesce(p_payload->>'providerEventId','')),'');
  v_event_type text := lower(btrim(coalesce(p_payload->>'eventType','')));
  v_digest text := lower(btrim(coalesce(p_payload->>'payloadSha256','')));
  v_provider_payment_id text := nullif(btrim(coalesce(p_payload->>'providerPaymentId','')),'');
  v_occurred_at timestamptz := coalesce(nullif(p_payload->>'occurredAt','')::timestamptz,now());
begin
  begin v_intent_id := nullif(p_payload->>'paymentIntentId','')::uuid;
  exception when invalid_text_representation then
    raise exception 'paymentIntentId must be a UUID' using errcode='22023',detail='PAYMENT_INTENT_INVALID';
  end;
  if v_intent_id is null or v_provider_key='' or v_event_id is null or v_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'provider event identity and digest are required'
      using errcode='22023',detail='PAYMENT_PROVIDER_EVENT_INVALID';
  end if;
  if v_event_type not in ('requires_action','authorized','captured','failed','cancelled','settlement_pending','settled','settlement_failed') then
    raise exception 'unsupported provider payment event'
      using errcode='22023',detail='PAYMENT_PROVIDER_EVENT_INVALID';
  end if;

  insert into public.payment_webhook_receipts(
    provider_key,provider_event_id,event_type,payload_sha256,payment_intent_id
  ) values (v_provider_key,v_event_id,v_event_type,v_digest,v_intent_id)
  on conflict (provider_key,provider_event_id) do nothing
  returning id into v_receipt_id;

  if v_receipt_id is null then
    select * into v_receipt from public.payment_webhook_receipts
    where provider_key=v_provider_key and provider_event_id=v_event_id;
    if v_receipt.payload_sha256<>v_digest or v_receipt.payment_intent_id is distinct from v_intent_id then
      raise exception 'provider event id was reused with different content'
        using errcode='23505',detail='PAYMENT_PROVIDER_EVENT_CONFLICT';
    end if;
    if v_receipt.processing_state='processed' then
      return private.payment_public_snapshot((select order_id from public.payment_intents where id=v_intent_id));
    end if;
  end if;

  select * into v_intent from public.payment_intents where id=v_intent_id for update;
  if not found or v_intent.provider_key<>v_provider_key then
    raise exception 'payment intent/provider mismatch'
      using errcode='P0002',detail='PAYMENT_INTENT_NOT_FOUND';
  end if;
  if v_provider_payment_id is not null
     and v_intent.provider_payment_id is not null
     and v_intent.provider_payment_id<>v_provider_payment_id then
    raise exception 'provider payment reference conflict'
      using errcode='23505',detail='PAYMENT_PROVIDER_REFERENCE_CONFLICT';
  end if;

  if v_event_type in ('requires_action','authorized','captured','failed','cancelled') then
    if not (
      (v_intent.state='created' and v_event_type in ('requires_action','authorized','captured','failed','cancelled'))
      or (v_intent.state='requires_action' and v_event_type in ('authorized','captured','failed','cancelled'))
      or (v_intent.state='authorized' and v_event_type in ('captured','failed','cancelled'))
      or (v_intent.state=v_event_type)
    ) then
      raise exception 'illegal payment state transition from % to %',v_intent.state,v_event_type
        using errcode='22023',detail='PAYMENT_STATE_TRANSITION_INVALID';
    end if;

    update public.payment_intents
    set state=v_event_type,
        provider_payment_id=coalesce(provider_payment_id,v_provider_payment_id),
        authorized_at=case when v_event_type='authorized' then coalesce(authorized_at,v_occurred_at) else authorized_at end,
        captured_at=case when v_event_type='captured' then coalesce(captured_at,v_occurred_at) else captured_at end,
        failed_at=case when v_event_type='failed' then coalesce(failed_at,v_occurred_at) else failed_at end,
        cancelled_at=case when v_event_type='cancelled' then coalesce(cancelled_at,v_occurred_at) else cancelled_at end,
        updated_at=now()
    where id=v_intent_id;
  else
    if v_intent.state<>'captured' then
      raise exception 'settlement events require captured payment'
        using errcode='22023',detail='PAYMENT_SETTLEMENT_BEFORE_CAPTURE';
    end if;
    update public.payment_intents
    set settlement_state=case
          when v_event_type='settlement_pending' then 'pending'
          when v_event_type='settled' then 'settled'
          else 'failed'
        end,
        settled_at=case when v_event_type='settled' then coalesce(settled_at,v_occurred_at) else settled_at end,
        updated_at=now()
    where id=v_intent_id;
  end if;

  insert into public.payment_events(
    payment_intent_id,provider_key,event_type,provider_event_id,payload_sha256,occurred_at,details
  ) values (
    v_intent_id,v_provider_key,v_event_type,v_event_id,v_digest,v_occurred_at,
    jsonb_build_object('providerPaymentId',v_provider_payment_id)
  ) on conflict (provider_key,provider_event_id) where provider_event_id is not null do nothing;

  update public.payment_webhook_receipts
  set processing_state='processed',processed_at=now(),error_code=null
  where provider_key=v_provider_key and provider_event_id=v_event_id;

  perform private.project_order_payment_state_impl(v_intent.order_id);
  return private.payment_public_snapshot(v_intent.order_id);
end;
$$;

revoke all on function private.apply_payment_provider_event_impl(jsonb)
from public,anon,authenticated;
grant execute on function private.apply_payment_provider_event_impl(jsonb) to service_role;

create or replace function public.apply_payment_provider_event(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public,pg_temp
as $$ select private.apply_payment_provider_event_impl(p_payload); $$;

revoke all on function public.apply_payment_provider_event(jsonb)
from public,anon,authenticated;
grant execute on function public.apply_payment_provider_event(jsonb) to service_role;

create or replace function private.request_external_refund_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_intent public.payment_intents%rowtype;
  v_refund public.payment_refunds%rowtype;
  v_existing public.payment_refunds%rowtype;
  v_order_id uuid;
  v_idempotency uuid;
  v_amount bigint;
  v_reserved bigint;
  v_reason text := nullif(btrim(coalesce(p_payload->>'reason','')),'');
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required' using errcode='42501',detail='PAYMENT_ADMIN_REQUIRED';
  end if;
  begin v_order_id:=nullif(p_payload->>'orderId','')::uuid;
  exception when invalid_text_representation then raise exception 'orderId must be UUID' using errcode='22023'; end;
  begin v_idempotency:=nullif(p_payload->>'idempotencyKey','')::uuid;
  exception when invalid_text_representation then raise exception 'idempotencyKey must be UUID' using errcode='22023'; end;
  begin v_amount:=(p_payload->>'amountSen')::bigint;
  exception when others then raise exception 'amountSen must be integer sen' using errcode='22023'; end;
  if v_order_id is null or v_idempotency is null or v_amount is null or v_amount<=0 then
    raise exception 'orderId, idempotencyKey and positive amountSen are required' using errcode='22023';
  end if;
  if v_reason is not null and char_length(v_reason)>300 then raise exception 'reason too long' using errcode='22023'; end if;

  select * into v_order from public.orders where id=v_order_id for update;
  if not found then raise exception 'order not found' using errcode='P0002'; end if;
  if not (select private.can_operate_branch(v_order.branch_id)) then raise exception 'branch access required' using errcode='42501'; end if;
  if v_order.tender_type<>'external' or v_order.payment_state not in ('paid','partially_refunded') then
    raise exception 'external captured payment required' using errcode='22023',detail='REFUND_EXTERNAL_CAPTURE_REQUIRED';
  end if;

  select * into v_existing from public.payment_refunds
  where order_id=v_order_id and idempotency_key=v_idempotency;
  if found then
    if v_existing.amount_sen<>v_amount or coalesce(v_existing.reason,'')<>coalesce(v_reason,'') then
      raise exception 'refund idempotency key conflicts' using errcode='23505',detail='REFUND_IDEMPOTENCY_CONFLICT';
    end if;
    return private.payment_public_snapshot(v_order_id);
  end if;

  select * into v_intent from public.payment_intents
  where order_id=v_order_id and state='captured'
  order by captured_at desc,id desc limit 1;
  if not found then raise exception 'captured payment intent not found' using errcode='P0002',detail='PAYMENT_CAPTURE_NOT_FOUND'; end if;

  select coalesce(sum(amount_sen),0)::bigint into v_reserved
  from public.payment_refunds
  where order_id=v_order_id and state in ('requested','processing','succeeded');
  if v_reserved+v_amount>v_order.total_sen then
    raise exception 'refund amount exceeds refundable balance' using errcode='22023',detail='REFUND_AMOUNT_EXCEEDED';
  end if;

  insert into public.payment_refunds(
    order_id,payment_intent_id,tender_type,state,amount_sen,idempotency_key,reason,requested_by_user_id
  ) values (
    v_order_id,v_intent.id,'external','requested',v_amount,v_idempotency,v_reason,p_actor_user_id
  ) returning * into v_refund;
  insert into public.payment_refund_events(refund_id,provider_key,event_type,actor_user_id,details)
  values (v_refund.id,v_intent.provider_key,'requested',p_actor_user_id,jsonb_build_object('amountSen',v_amount));

  return private.payment_public_snapshot(v_order_id);
end;
$$;

revoke all on function private.request_external_refund_impl(jsonb,uuid)
from public,anon,authenticated;
grant execute on function private.request_external_refund_impl(jsonb,uuid) to authenticated;

create or replace function public.request_external_refund(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public,pg_temp
as $$ select private.request_external_refund_impl(p_payload,(select auth.uid())); $$;

revoke all on function public.request_external_refund(jsonb) from public,anon,authenticated;
grant execute on function public.request_external_refund(jsonb) to authenticated;

create or replace function private.refund_cash_order_impl(
  p_payload jsonb,
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_shift jsonb;
  v_existing public.payment_refunds%rowtype;
  v_refund public.payment_refunds%rowtype;
  v_order_id uuid;
  v_idempotency uuid;
  v_amount bigint;
  v_refunded bigint;
  v_reason text := nullif(btrim(coalesce(p_payload->>'reason','')),'');
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required' using errcode='42501',detail='PAYMENT_ADMIN_REQUIRED';
  end if;
  begin v_order_id:=nullif(p_payload->>'orderId','')::uuid;
  exception when invalid_text_representation then raise exception 'orderId must be UUID' using errcode='22023'; end;
  begin v_idempotency:=nullif(p_payload->>'idempotencyKey','')::uuid;
  exception when invalid_text_representation then raise exception 'idempotencyKey must be UUID' using errcode='22023'; end;
  begin v_amount:=(p_payload->>'amountSen')::bigint;
  exception when others then raise exception 'amountSen must be integer sen' using errcode='22023'; end;
  if v_order_id is null or v_idempotency is null or v_amount is null or v_amount<=0 then
    raise exception 'orderId, idempotencyKey and positive amountSen are required' using errcode='22023';
  end if;
  if v_reason is not null and char_length(v_reason)>300 then raise exception 'reason too long' using errcode='22023'; end if;

  v_shift:=private.require_open_shift_impl(p_terminal_credential,p_actor_user_id);
  select * into v_order from public.orders where id=v_order_id for update;
  if not found then raise exception 'order not found' using errcode='P0002'; end if;
  if v_order.branch_id is distinct from (v_shift->>'branchId')::uuid then
    raise exception 'refund shift branch does not match order' using errcode='42501',detail='REFUND_SHIFT_BRANCH_MISMATCH';
  end if;
  if v_order.tender_type<>'cash' or v_order.payment_state not in ('paid','partially_refunded') then
    raise exception 'paid cash order required' using errcode='22023',detail='REFUND_CASH_PAYMENT_REQUIRED';
  end if;

  select * into v_existing from public.payment_refunds
  where order_id=v_order_id and idempotency_key=v_idempotency;
  if found then
    if v_existing.tender_type<>'cash' or v_existing.amount_sen<>v_amount or coalesce(v_existing.reason,'')<>coalesce(v_reason,'') then
      raise exception 'refund idempotency key conflicts' using errcode='23505',detail='REFUND_IDEMPOTENCY_CONFLICT';
    end if;
    return private.payment_public_snapshot(v_order_id);
  end if;

  v_refunded:=private.payment_refunded_sen(v_order_id);
  if v_refunded+v_amount>v_order.total_sen then
    raise exception 'refund amount exceeds refundable balance' using errcode='22023',detail='REFUND_AMOUNT_EXCEEDED';
  end if;

  insert into public.payment_refunds(
    order_id,payment_intent_id,tender_type,state,amount_sen,idempotency_key,reason,requested_by_user_id,succeeded_at
  ) values (
    v_order_id,null,'cash','succeeded',v_amount,v_idempotency,v_reason,p_actor_user_id,now()
  ) returning * into v_refund;

  insert into public.payment_refund_events(refund_id,event_type,actor_user_id,details)
  values (v_refund.id,'succeeded',p_actor_user_id,jsonb_build_object('amountSen',v_amount,'shiftId',v_shift->>'id'));

  insert into public.cash_movements(shift_id,movement_type,amount_sen,reason,actor_user_id)
  values ((v_shift->>'id')::uuid,'cash_out',v_amount,coalesce(v_reason,'Cash order refund'),p_actor_user_id);

  perform private.project_order_payment_state_impl(v_order_id);
  return private.payment_public_snapshot(v_order_id);
end;
$$;

revoke all on function private.refund_cash_order_impl(jsonb,text,uuid)
from public,anon,authenticated;
grant execute on function private.refund_cash_order_impl(jsonb,text,uuid) to authenticated;

create or replace function public.refund_cash_order(
  p_payload jsonb,
  p_terminal_credential text
)
returns jsonb
language sql
security invoker
set search_path = public,pg_temp
as $$ select private.refund_cash_order_impl(p_payload,p_terminal_credential,(select auth.uid())); $$;

revoke all on function public.refund_cash_order(jsonb,text) from public,anon,authenticated;
grant execute on function public.refund_cash_order(jsonb,text) to authenticated;

create or replace function private.apply_refund_provider_event_impl(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_refund public.payment_refunds%rowtype;
  v_intent public.payment_intents%rowtype;
  v_receipt public.payment_webhook_receipts%rowtype;
  v_receipt_id uuid;
  v_refund_id uuid;
  v_provider_key text := lower(btrim(coalesce(p_payload->>'providerKey','')));
  v_event_id text := nullif(btrim(coalesce(p_payload->>'providerEventId','')),'');
  v_event_type text := lower(btrim(coalesce(p_payload->>'eventType','')));
  v_digest text := lower(btrim(coalesce(p_payload->>'payloadSha256','')));
  v_provider_refund_id text := nullif(btrim(coalesce(p_payload->>'providerRefundId','')),'');
  v_occurred_at timestamptz := coalesce(nullif(p_payload->>'occurredAt','')::timestamptz,now());
begin
  begin v_refund_id:=nullif(p_payload->>'refundId','')::uuid;
  exception when invalid_text_representation then raise exception 'refundId must be UUID' using errcode='22023'; end;
  if v_refund_id is null or v_provider_key='' or v_event_id is null or v_digest !~ '^[0-9a-f]{64}$' then
    raise exception 'provider refund event identity and digest are required' using errcode='22023',detail='REFUND_PROVIDER_EVENT_INVALID';
  end if;
  if v_event_type not in ('processing','succeeded','failed','cancelled') then
    raise exception 'unsupported provider refund event' using errcode='22023',detail='REFUND_PROVIDER_EVENT_INVALID';
  end if;

  insert into public.payment_webhook_receipts(
    provider_key,provider_event_id,event_type,payload_sha256,refund_id
  ) values (v_provider_key,v_event_id,'refund_'||v_event_type,v_digest,v_refund_id)
  on conflict (provider_key,provider_event_id) do nothing
  returning id into v_receipt_id;

  if v_receipt_id is null then
    select * into v_receipt from public.payment_webhook_receipts
    where provider_key=v_provider_key and provider_event_id=v_event_id;
    if v_receipt.payload_sha256<>v_digest or v_receipt.refund_id is distinct from v_refund_id then
      raise exception 'provider event id was reused with different content'
        using errcode='23505',detail='REFUND_PROVIDER_EVENT_CONFLICT';
    end if;
    if v_receipt.processing_state='processed' then
      return private.payment_public_snapshot((select order_id from public.payment_refunds where id=v_refund_id));
    end if;
  end if;

  select * into v_refund from public.payment_refunds where id=v_refund_id for update;
  if not found or v_refund.tender_type<>'external' then
    raise exception 'external refund not found' using errcode='P0002',detail='REFUND_NOT_FOUND';
  end if;
  select * into v_intent from public.payment_intents where id=v_refund.payment_intent_id;
  if not found or v_intent.provider_key<>v_provider_key then
    raise exception 'refund provider mismatch' using errcode='42501',detail='REFUND_PROVIDER_MISMATCH';
  end if;
  if v_provider_refund_id is not null and v_refund.provider_refund_id is not null and v_refund.provider_refund_id<>v_provider_refund_id then
    raise exception 'provider refund reference conflict' using errcode='23505',detail='REFUND_PROVIDER_REFERENCE_CONFLICT';
  end if;
  if not (
    (v_refund.state='requested' and v_event_type in ('processing','succeeded','failed','cancelled'))
    or (v_refund.state='processing' and v_event_type in ('succeeded','failed','cancelled'))
    or (v_refund.state=v_event_type)
  ) then
    raise exception 'illegal refund state transition from % to %',v_refund.state,v_event_type
      using errcode='22023',detail='REFUND_STATE_TRANSITION_INVALID';
  end if;

  update public.payment_refunds
  set state=v_event_type,
      provider_refund_id=coalesce(provider_refund_id,v_provider_refund_id),
      processing_at=case when v_event_type='processing' then coalesce(processing_at,v_occurred_at) else processing_at end,
      succeeded_at=case when v_event_type='succeeded' then coalesce(succeeded_at,v_occurred_at) else succeeded_at end,
      failed_at=case when v_event_type='failed' then coalesce(failed_at,v_occurred_at) else failed_at end,
      cancelled_at=case when v_event_type='cancelled' then coalesce(cancelled_at,v_occurred_at) else cancelled_at end,
      updated_at=now()
  where id=v_refund_id;

  insert into public.payment_refund_events(
    refund_id,provider_key,event_type,provider_event_id,payload_sha256,occurred_at,details
  ) values (
    v_refund_id,v_provider_key,v_event_type,v_event_id,v_digest,v_occurred_at,
    jsonb_build_object('providerRefundId',v_provider_refund_id)
  ) on conflict (provider_key,provider_event_id) where provider_key is not null and provider_event_id is not null do nothing;

  update public.payment_webhook_receipts
  set processing_state='processed',processed_at=now(),error_code=null
  where provider_key=v_provider_key and provider_event_id=v_event_id;

  perform private.project_order_payment_state_impl(v_refund.order_id);
  return private.payment_public_snapshot(v_refund.order_id);
end;
$$;

revoke all on function private.apply_refund_provider_event_impl(jsonb)
from public,anon,authenticated;
grant execute on function private.apply_refund_provider_event_impl(jsonb) to service_role;

create or replace function public.apply_refund_provider_event(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public,pg_temp
as $$ select private.apply_refund_provider_event_impl(p_payload); $$;

revoke all on function public.apply_refund_provider_event(jsonb)
from public,anon,authenticated;
grant execute on function public.apply_refund_provider_event(jsonb) to service_role;

-- Paid or pending orders cannot be cancelled until their payment/refund state is
-- resolved. A fully refunded order may proceed through the normal cancellation
-- state machine.
create or replace function private.transition_order_status_impl(
  p_order_id uuid,
  p_to_status text,
  p_expected_version bigint,
  p_reason text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_now timestamptz:=now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode='42501';
  end if;
  if p_expected_version is null or p_expected_version<1 then
    raise exception 'expected status version is required' using errcode='22023';
  end if;
  if p_reason is not null and char_length(btrim(p_reason))>300 then
    raise exception 'status reason must be 300 characters or fewer' using errcode='22023';
  end if;

  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'order not found' using errcode='P0002'; end if;
  if not (select private.can_operate_branch(v_order.branch_id)) then raise exception 'branch access required' using errcode='42501'; end if;
  if v_order.status_version<>p_expected_version then
    raise exception 'order status changed; refresh before retrying' using errcode='40001';
  end if;
  if p_to_status='cancelled' and v_order.payment_state in ('pending','paid','partially_refunded') then
    raise exception 'order payment must be cancelled or fully refunded before order cancellation'
      using errcode='42501',detail='PAID_ORDER_REFUND_REQUIRED';
  end if;
  if not (
    (v_order.status='scheduled' and p_to_status in ('preparing','cancelled'))
    or (v_order.status='confirmed' and p_to_status in ('preparing','cancelled'))
    or (v_order.status='preparing' and p_to_status in ('ready','cancelled'))
    or (v_order.status='ready' and p_to_status='completed')
  ) then
    raise exception 'illegal order status transition from % to %',v_order.status,p_to_status using errcode='22023';
  end if;

  update public.orders
  set status=p_to_status,
      status_version=status_version+1,
      status_updated_at=v_now,
      preparing_at=case when p_to_status='preparing' then coalesce(preparing_at,v_now) else preparing_at end,
      ready_at=case when p_to_status='ready' then coalesce(ready_at,v_now) else ready_at end,
      completed_at=case when p_to_status='completed' then coalesce(completed_at,v_now) else completed_at end,
      cancelled_at=case when p_to_status='cancelled' then coalesce(cancelled_at,v_now) else cancelled_at end
  where id=p_order_id;

  insert into public.order_events(order_id,event_type,actor_user_id,from_status,to_status,reason,details)
  values (
    p_order_id,'status_changed',p_actor_user_id,v_order.status,p_to_status,
    nullif(btrim(coalesce(p_reason,'')),''),
    jsonb_build_object('branchId',v_order.branch_id,'shiftId',v_order.shift_id,'previousVersion',v_order.status_version,'newVersion',v_order.status_version+1)
  );
  return private.order_snapshot(p_order_id);
end;
$$;

comment on table public.payment_provider_configs is
  'Non-secret provider activation metadata only. Provider API/webhook secrets must remain server-side outside this table.';
comment on table public.payment_intents is
  'Canonical Phase 9 provider-neutral payment attempts. Client code cannot directly mutate this table.';
comment on table public.payment_events is
  'Append-only payment lifecycle evidence.';
comment on table public.payment_refunds is
  'Canonical Phase 9 refund records. Succeeded refunds compensate accepted order value without rewriting order commercial totals.';
comment on table public.payment_refund_events is
  'Append-only refund lifecycle evidence.';
comment on table public.payment_webhook_receipts is
  'Provider webhook idempotency/digest receipts; raw provider payloads and secrets are intentionally not stored.';
