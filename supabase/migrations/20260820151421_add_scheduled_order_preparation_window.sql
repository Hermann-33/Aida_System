-- TASK-SCHEDULED-OPS-001 — scheduled-order operational preparation authority.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/.
--
-- Scheduled orders remain persisted fulfilment state. This migration adds a
-- server-owned immutable preparation due time and a derived operational state
-- for staff queues; it deliberately does NOT auto-transition orders to
-- preparing/ready/completed. Staff actions remain the only trusted fulfilment
-- transitions.

alter table public.order_schedule_settings
  add column if not exists preparation_lead_minutes integer not null default 15;

alter table public.order_schedule_settings
  drop constraint if exists order_schedule_settings_preparation_lead_check;
alter table public.order_schedule_settings
  add constraint order_schedule_settings_preparation_lead_check
  check (preparation_lead_minutes between 0 and 1440);

alter table public.order_schedule_settings
  drop constraint if exists order_schedule_settings_preparation_vs_customer_lead_check;
alter table public.order_schedule_settings
  add constraint order_schedule_settings_preparation_vs_customer_lead_check
  check (preparation_lead_minutes <= minimum_lead_minutes);

alter table public.orders
  add column if not exists prepare_at timestamptz;

-- Existing scheduled orders receive the current operational preparation lead
-- so they immediately become classifiable as future/due/overdue without
-- changing their persisted fulfilment status.
update public.orders o
set prepare_at = o.requested_pickup_at - make_interval(mins => s.preparation_lead_minutes)
from public.order_schedule_settings s
where s.id = 1
  and o.fulfillment_type = 'scheduled'
  and o.prepare_at is null;

alter table public.orders
  drop constraint if exists orders_prepare_shape_check;
alter table public.orders
  add constraint orders_prepare_shape_check check (
    (fulfillment_type = 'asap' and prepare_at is null)
    or (
      fulfillment_type = 'scheduled'
      and prepare_at is not null
      and requested_pickup_at is not null
      and prepare_at <= requested_pickup_at
    )
  );

create index if not exists orders_scheduled_prepare_idx
  on public.orders (prepare_at, requested_pickup_at, created_at)
  where status = 'scheduled';

comment on column public.order_schedule_settings.preparation_lead_minutes is
  'Server-owned operational lead used to derive immutable prepare_at for scheduled orders. Distinct from customer minimum lead time.';

comment on column public.orders.prepare_at is
  'Server-owned scheduled-order preparation due time, snapshotted at placement. Does not mutate fulfilment status automatically.';

-- prepare_at is part of the accepted schedule snapshot and cannot be rewritten
-- by a later policy change or browser action.
create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.customer_user_id is distinct from old.customer_user_id
     or new.member_id is distinct from old.member_id
     or new.created_by_user_id is distinct from old.created_by_user_id
     or new.client_request_id is distinct from old.client_request_id
     or new.request_hash is distinct from old.request_hash
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Order snapshots expose serverNow and a server-derived operational schedule
-- state so the Dashboard never needs to use the workstation clock as business
-- authority. scheduleState is deliberately separate from persisted status.
create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'orderNumber', o.order_number,
    'source', o.source,
    'customerUserId', o.customer_user_id,
    'memberId', o.member_id,
    'fulfillmentType', o.fulfillment_type,
    'requestedPickupAt', o.requested_pickup_at,
    'prepareAt', o.prepare_at,
    'serverNow', now(),
    'scheduleState', case
      when o.fulfillment_type = 'scheduled' and o.status = 'scheduled' then
        case
          when o.requested_pickup_at < now() then 'overdue'
          when o.prepare_at <= now() then 'due'
          else 'future'
        end
      else null
    end,
    'status', o.status,
    'statusVersion', o.status_version,
    'currency', o.currency,
    'pricingVersion', o.pricing_version,
    'subtotalSen', o.subtotal_sen,
    'totalSen', o.total_sen,
    'createdAt', o.created_at,
    'updatedAt', o.updated_at,
    'statusUpdatedAt', o.status_updated_at,
    'preparingAt', o.preparing_at,
    'readyAt', o.ready_at,
    'completedAt', o.completed_at,
    'cancelledAt', o.cancelled_at,
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', l.id,
        'lineNumber', l.line_number,
        'itemId', l.catalogue_item_id,
        'sku', l.sku_snapshot,
        'name', l.name_snapshot,
        'prepRoute', l.prep_route_snapshot,
        'basePriceSen', l.base_price_sen,
        'variant', case when l.variant_id is null then null else jsonb_build_object(
          'id', l.variant_id,
          'code', l.variant_code_snapshot,
          'label', l.variant_label_snapshot,
          'priceDeltaSen', l.variant_price_delta_sen
        ) end,
        'addOns', coalesce((
          select jsonb_agg(jsonb_build_object(
            'itemId', a.catalogue_addon_item_id,
            'sku', a.sku_snapshot,
            'name', a.name_snapshot,
            'priceSen', a.price_sen
          ) order by a.created_at, a.id)
          from public.order_line_addons a
          where a.order_line_id = l.id
        ), '[]'::jsonb),
        'addOnTotalSen', l.addon_total_sen,
        'unitPriceSen', l.unit_price_sen,
        'quantity', l.quantity,
        'lineTotalSen', l.line_total_sen,
        'note', l.note
      ) order by l.line_number)
      from public.order_lines l
      where l.order_id = o.id
    ), '[]'::jsonb)
  )
  from public.orders o
  where o.id = p_order_id
    and (
      o.customer_user_id = (select auth.uid())
      or (select private.is_staff_or_above())
    );
$$;

-- New scheduled placements snapshot prepare_at from the operational policy.
-- Existing idempotent retries keep the original persisted prepare_at.
create or replace function private.create_order_impl(
  p_payload jsonb,
  p_source text,
  p_customer_user_id uuid,
  p_member_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_client_request_id uuid;
  v_request_hash text := md5(p_payload::text);
  v_existing public.orders%rowtype;
  v_quote jsonb;
  v_order_id uuid;
  v_status text;
  v_prepare_at timestamptz;
  v_preparation_lead integer;
  v_line jsonb;
  v_line_id uuid;
  v_addon jsonb;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode = '42501';
  end if;

  begin
    v_client_request_id := nullif(p_payload ->> 'clientRequestId', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'clientRequestId must be a valid UUID' using errcode = '22023';
  end;
  if v_client_request_id is null then
    raise exception 'clientRequestId is required for idempotent placement' using errcode = '22023';
  end if;

  select * into v_existing
  from public.orders
  where created_by_user_id = p_actor_user_id and client_request_id = v_client_request_id;
  if found then
    if v_existing.request_hash <> v_request_hash then
      raise exception 'clientRequestId was already used with a different order payload' using errcode = '23505';
    end if;
    return private.order_snapshot(v_existing.id);
  end if;

  if p_source = 'customer' then
    if p_customer_user_id is null
       or p_customer_user_id is distinct from p_actor_user_id
       or p_member_id is null then
      raise exception 'customer order ownership is invalid' using errcode = '42501';
    end if;
    if not exists (
      select 1 from public.members m
      where m.id = p_member_id and m.user_id = p_customer_user_id and m.active
    ) then
      raise exception 'active member record is required for customer ordering' using errcode = '42501';
    end if;
  elsif p_source = 'pos' then
    if not (select private.is_staff_or_above()) then
      raise exception 'staff access required for POS order creation' using errcode = '42501';
    end if;
  else
    raise exception 'invalid order source' using errcode = '22023';
  end if;

  v_quote := public.quote_order(p_payload);
  v_status := case v_quote ->> 'fulfillmentType' when 'scheduled' then 'scheduled' else 'confirmed' end;

  if v_status = 'scheduled' then
    select s.preparation_lead_minutes into strict v_preparation_lead
    from public.order_schedule_settings s
    where s.id = 1;
    v_prepare_at := nullif(v_quote ->> 'requestedPickupAt', '')::timestamptz
      - make_interval(mins => v_preparation_lead);
  end if;

  insert into public.orders (
    source, customer_user_id, member_id, created_by_user_id,
    client_request_id, request_hash, fulfillment_type, requested_pickup_at,
    prepare_at, status, currency, pricing_version, subtotal_sen, total_sen
  ) values (
    p_source, p_customer_user_id, p_member_id, p_actor_user_id,
    v_client_request_id, v_request_hash, v_quote ->> 'fulfillmentType',
    nullif(v_quote ->> 'requestedPickupAt', '')::timestamptz,
    v_prepare_at,
    v_status, v_quote ->> 'currency', (v_quote ->> 'pricingVersion')::integer,
    (v_quote ->> 'subtotalSen')::bigint, (v_quote ->> 'totalSen')::bigint
  ) returning id into v_order_id;

  for v_line in select value from jsonb_array_elements(v_quote -> 'lines')
  loop
    insert into public.order_lines (
      order_id, line_number, catalogue_item_id, sku_snapshot, name_snapshot,
      prep_route_snapshot, base_price_sen, variant_id, variant_code_snapshot,
      variant_label_snapshot, variant_price_delta_sen, addon_total_sen,
      unit_price_sen, quantity, line_total_sen, note
    ) values (
      v_order_id, (v_line ->> 'lineNumber')::integer, (v_line ->> 'itemId')::uuid,
      v_line ->> 'sku', v_line ->> 'name', v_line ->> 'prepRoute',
      (v_line ->> 'basePriceSen')::integer,
      nullif(v_line #>> '{variant,id}', '')::uuid,
      nullif(v_line #>> '{variant,code}', ''),
      nullif(v_line #>> '{variant,label}', ''),
      coalesce((v_line #>> '{variant,priceDeltaSen}')::integer, 0),
      (v_line ->> 'addOnTotalSen')::integer, (v_line ->> 'unitPriceSen')::integer,
      (v_line ->> 'quantity')::integer, (v_line ->> 'lineTotalSen')::bigint,
      nullif(v_line ->> 'note', '')
    ) returning id into v_line_id;

    for v_addon in select value from jsonb_array_elements(v_line -> 'addOns')
    loop
      insert into public.order_line_addons (
        order_line_id, catalogue_addon_item_id, sku_snapshot, name_snapshot, price_sen
      ) values (
        v_line_id, (v_addon ->> 'itemId')::uuid, v_addon ->> 'sku',
        v_addon ->> 'name', (v_addon ->> 'priceSen')::integer
      );
    end loop;
  end loop;

  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, details
  ) values (
    v_order_id, 'created', p_actor_user_id, null, v_status,
    jsonb_build_object(
      'source', p_source,
      'fulfillmentType', v_quote ->> 'fulfillmentType',
      'requestedPickupAt', v_quote -> 'requestedPickupAt',
      'prepareAt', v_prepare_at,
      'totalSen', (v_quote ->> 'totalSen')::bigint
    )
  );

  return private.order_snapshot(v_order_id);
end;
$$;

-- Preparation lead is operational authority. It may never exceed the customer
-- minimum lead because that would permit a newly accepted order whose
-- preparation due time is already in the past.
create or replace function private.save_ordering_policy_impl(p_payload jsonb, p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_current public.order_schedule_settings%rowtype;
  v_timezone text;
  v_schedule_enabled boolean;
  v_minimum_lead integer;
  v_preparation_lead integer;
  v_slot_interval integer;
  v_maximum_advance integer;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select * into v_current from public.order_schedule_settings where id = 1 for update;
  v_timezone := coalesce(nullif(p_payload ->> 'timezone', ''), v_current.timezone);
  v_schedule_enabled := coalesce((p_payload ->> 'scheduleEnabled')::boolean, v_current.schedule_enabled);
  v_minimum_lead := coalesce((p_payload ->> 'minimumLeadMinutes')::integer, v_current.minimum_lead_minutes);
  v_preparation_lead := coalesce((p_payload ->> 'preparationLeadMinutes')::integer, v_current.preparation_lead_minutes);
  v_slot_interval := coalesce((p_payload ->> 'slotIntervalMinutes')::integer, v_current.slot_interval_minutes);
  v_maximum_advance := coalesce((p_payload ->> 'maximumAdvanceDays')::integer, v_current.maximum_advance_days);

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = v_timezone) then
    raise exception 'invalid ordering timezone' using errcode = '22023';
  end if;
  if v_minimum_lead not between 0 and 1440
     or v_preparation_lead not between 0 and 1440
     or v_preparation_lead > v_minimum_lead
     or v_slot_interval not between 5 and 240
     or v_maximum_advance not between 1 and 31 then
    raise exception 'ordering schedule policy is outside allowed bounds' using errcode = '22023';
  end if;

  update public.order_schedule_settings
  set timezone = v_timezone,
      schedule_enabled = v_schedule_enabled,
      minimum_lead_minutes = v_minimum_lead,
      preparation_lead_minutes = v_preparation_lead,
      slot_interval_minutes = v_slot_interval,
      maximum_advance_days = v_maximum_advance
  where id = 1;

  return jsonb_build_object(
    'serverNow', now(),
    'timezone', v_timezone,
    'scheduleEnabled', v_schedule_enabled,
    'minimumLeadMinutes', v_minimum_lead,
    'preparationLeadMinutes', v_preparation_lead,
    'slotIntervalMinutes', v_slot_interval,
    'maximumAdvanceDays', v_maximum_advance
  );
end;
$$;

create or replace function public.get_ordering_policy()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'serverNow', now(),
    'timezone', s.timezone,
    'scheduleEnabled', s.schedule_enabled,
    'minimumLeadMinutes', s.minimum_lead_minutes,
    'preparationLeadMinutes', s.preparation_lead_minutes,
    'slotIntervalMinutes', s.slot_interval_minutes,
    'maximumAdvanceDays', s.maximum_advance_days
  )
  from public.order_schedule_settings s
  where s.id = 1;
$$;
