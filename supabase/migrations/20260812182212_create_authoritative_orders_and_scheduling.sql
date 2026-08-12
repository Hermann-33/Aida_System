-- TASK-DEMO-ORDER-001 — authoritative ordering, scheduled pickup, and live fulfilment.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/.
--
-- Payment capture, discounts, loyalty, inventory depletion, branch capacity,
-- delivery, tax and branch-hours policy are deliberately outside this bounded
-- task. Clients send IDs/quantities/intent; the database resolves catalogue
-- compatibility/prices and owns order IDs, totals, schedules and status.

create table public.order_schedule_settings (
  id smallint primary key,
  timezone text not null default 'Asia/Kuala_Lumpur',
  schedule_enabled boolean not null default true,
  minimum_lead_minutes integer not null default 15,
  slot_interval_minutes integer not null default 15,
  maximum_advance_days integer not null default 7,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint order_schedule_settings_singleton check (id = 1),
  constraint order_schedule_settings_lead_check check (minimum_lead_minutes between 0 and 1440),
  constraint order_schedule_settings_slot_check check (slot_interval_minutes between 5 and 240),
  constraint order_schedule_settings_horizon_check check (maximum_advance_days between 1 and 31)
);

insert into public.order_schedule_settings (
  id, timezone, schedule_enabled, minimum_lead_minutes,
  slot_interval_minutes, maximum_advance_days
) values (1, 'Asia/Kuala_Lumpur', true, 15, 15, 7);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number bigint generated always as identity (start with 100001) unique,
  source text not null,
  customer_user_id uuid references auth.users(id) on delete set null,
  member_id uuid references public.members(id) on delete set null,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,
  client_request_id uuid not null,
  request_hash text not null,
  fulfillment_type text not null,
  requested_pickup_at timestamptz,
  status text not null,
  status_version bigint not null default 1,
  currency text not null default 'MYR',
  pricing_version integer not null default 1,
  subtotal_sen bigint not null,
  total_sen bigint not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  status_updated_at timestamptz not null default now(),
  preparing_at timestamptz,
  ready_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  constraint orders_source_check check (source in ('customer', 'pos')),
  constraint orders_customer_owner_check check (
    source = 'pos'
    or (customer_user_id is not null and member_id is not null)
  ),
  constraint orders_fulfillment_check check (fulfillment_type in ('asap', 'scheduled')),
  constraint orders_schedule_shape_check check (
    (fulfillment_type = 'asap' and requested_pickup_at is null)
    or (fulfillment_type = 'scheduled' and requested_pickup_at is not null)
  ),
  constraint orders_status_check check (
    status in ('confirmed', 'scheduled', 'preparing', 'ready', 'completed', 'cancelled')
  ),
  constraint orders_asap_status_check check (not (fulfillment_type = 'asap' and status = 'scheduled')),
  constraint orders_currency_check check (currency = 'MYR'),
  constraint orders_pricing_version_check check (pricing_version >= 1),
  constraint orders_subtotal_check check (subtotal_sen >= 0),
  constraint orders_total_check check (total_sen >= 0),
  constraint orders_total_consistency_check check (total_sen = subtotal_sen),
  constraint orders_status_version_check check (status_version >= 1),
  constraint orders_idempotency_unique unique (created_by_user_id, client_request_id)
);

create index orders_customer_created_idx
  on public.orders (customer_user_id, created_at desc)
  where customer_user_id is not null;
create index orders_active_queue_idx
  on public.orders (status, requested_pickup_at, created_at)
  where status not in ('completed', 'cancelled');
create index orders_created_idx on public.orders (created_at desc);

create table public.order_lines (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  line_number integer not null,
  catalogue_item_id uuid not null references public.catalogue_items(id) on delete restrict,
  sku_snapshot text not null,
  name_snapshot text not null,
  prep_route_snapshot text not null,
  base_price_sen integer not null,
  variant_id uuid references public.catalogue_item_variants(id) on delete restrict,
  variant_code_snapshot text,
  variant_label_snapshot text,
  variant_price_delta_sen integer not null default 0,
  addon_total_sen integer not null default 0,
  unit_price_sen integer not null,
  quantity integer not null,
  line_total_sen bigint not null,
  note text,
  created_at timestamptz not null default now(),
  constraint order_lines_line_number_check check (line_number >= 1),
  constraint order_lines_sku_length check (char_length(sku_snapshot) between 2 and 32),
  constraint order_lines_name_length check (char_length(name_snapshot) between 1 and 120),
  constraint order_lines_prep_route_check check (prep_route_snapshot in ('bar', 'kitchen')),
  constraint order_lines_base_price_check check (base_price_sen >= 0),
  constraint order_lines_addon_total_check check (addon_total_sen >= 0),
  constraint order_lines_unit_price_check check (unit_price_sen >= 0),
  constraint order_lines_quantity_check check (quantity between 1 and 20),
  constraint order_lines_line_total_check check (
    line_total_sen = unit_price_sen::bigint * quantity::bigint
  ),
  constraint order_lines_note_length check (note is null or char_length(note) <= 300),
  constraint order_lines_variant_snapshot_check check (
    (variant_id is null and variant_code_snapshot is null and variant_label_snapshot is null)
    or (variant_id is not null and variant_code_snapshot is not null and variant_label_snapshot is not null)
  ),
  constraint order_lines_order_line_unique unique (order_id, line_number)
);

create index order_lines_order_idx on public.order_lines (order_id, line_number);

create table public.order_line_addons (
  id uuid primary key default gen_random_uuid(),
  order_line_id uuid not null references public.order_lines(id) on delete cascade,
  catalogue_addon_item_id uuid not null references public.catalogue_items(id) on delete restrict,
  sku_snapshot text not null,
  name_snapshot text not null,
  price_sen integer not null,
  created_at timestamptz not null default now(),
  constraint order_line_addons_price_check check (price_sen >= 0),
  constraint order_line_addons_unique unique (order_line_id, catalogue_addon_item_id)
);

create index order_line_addons_line_idx on public.order_line_addons (order_line_id);

create table public.order_events (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.orders(id) on delete cascade,
  event_type text not null,
  actor_user_id uuid references auth.users(id) on delete set null,
  from_status text,
  to_status text,
  reason text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint order_events_type_check check (event_type in ('created', 'status_changed')),
  constraint order_events_status_check check (
    (event_type = 'created' and from_status is null and to_status is not null)
    or (event_type = 'status_changed' and from_status is not null and to_status is not null)
  ),
  constraint order_events_reason_length check (reason is null or char_length(reason) <= 300)
);

create index order_events_order_idx on public.order_events (order_id, created_at, id);
create index order_events_actor_idx on public.order_events (actor_user_id, created_at desc);

create trigger order_schedule_settings_set_updated_at
before update on public.order_schedule_settings
for each row execute function public.set_updated_at();

create trigger orders_set_updated_at
before update on public.orders
for each row execute function public.set_updated_at();

-- Defense in depth against a future accidental table-write grant. Only status
-- and status timestamps/version may change after commercial snapshots persist.
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

revoke all on function private.protect_order_commercial_fields() from public, anon, authenticated;

create trigger orders_protect_commercial_fields
before update on public.orders
for each row execute function private.protect_order_commercial_fields();

-- Public quote: the single trusted commercial calculation used by both quote
-- preview and persistence. It explicitly filters to active/published/available
-- catalogue data and ignores any client-supplied price/name/total fields.
create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_items jsonb := p_payload -> 'items';
  v_fulfillment_type text := coalesce(nullif(p_payload ->> 'fulfillmentType', ''), 'asap');
  v_requested_pickup_at timestamptz := nullif(p_payload ->> 'requestedPickupAt', '')::timestamptz;
  v_settings public.order_schedule_settings%rowtype;
  v_local timestamp;
  v_minute_of_day integer;
  v_line jsonb;
  v_line_number integer := 0;
  v_item_id uuid;
  v_variant_id uuid;
  v_quantity integer;
  v_note text;
  v_catalogue_item public.catalogue_items%rowtype;
  v_variant public.catalogue_item_variants%rowtype;
  v_variant_count integer;
  v_variant_delta integer;
  v_addon_ids jsonb;
  v_addon_text text;
  v_addon_id uuid;
  v_addon public.catalogue_items%rowtype;
  v_addon_total integer;
  v_addons jsonb;
  v_unit_price integer;
  v_line_total bigint;
  v_subtotal bigint := 0;
  v_lines jsonb := '[]'::jsonb;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'order payload must be a JSON object' using errcode = '22023';
  end if;

  if v_items is null or jsonb_typeof(v_items) <> 'array' then
    raise exception 'items must be a JSON array' using errcode = '22023';
  end if;
  if jsonb_array_length(v_items) < 1 or jsonb_array_length(v_items) > 50 then
    raise exception 'orders require between 1 and 50 line items' using errcode = '22023';
  end if;

  select * into v_settings from public.order_schedule_settings where id = 1;
  if not found then
    raise exception 'ordering schedule configuration is unavailable' using errcode = '55000';
  end if;

  if v_fulfillment_type = 'asap' then
    if v_requested_pickup_at is not null then
      raise exception 'ASAP orders cannot include a scheduled pickup time' using errcode = '22023';
    end if;
  elsif v_fulfillment_type = 'scheduled' then
    if not v_settings.schedule_enabled then
      raise exception 'scheduled ordering is currently unavailable' using errcode = '22023';
    end if;
    if v_requested_pickup_at is null then
      raise exception 'scheduled orders require requestedPickupAt' using errcode = '22023';
    end if;
    if v_requested_pickup_at < now() + make_interval(mins => v_settings.minimum_lead_minutes) then
      raise exception 'scheduled pickup does not meet the minimum lead time' using errcode = '22023';
    end if;
    if v_requested_pickup_at > now() + make_interval(days => v_settings.maximum_advance_days) then
      raise exception 'scheduled pickup exceeds the maximum scheduling horizon' using errcode = '22023';
    end if;
    if not exists (select 1 from pg_catalog.pg_timezone_names where name = v_settings.timezone) then
      raise exception 'configured ordering timezone is invalid' using errcode = '55000';
    end if;
    v_local := v_requested_pickup_at at time zone v_settings.timezone;
    if extract(second from v_local) <> 0 then
      raise exception 'scheduled pickup must align to a whole-minute slot' using errcode = '22023';
    end if;
    v_minute_of_day := extract(hour from v_local)::integer * 60 + extract(minute from v_local)::integer;
    if mod(v_minute_of_day, v_settings.slot_interval_minutes) <> 0 then
      raise exception 'scheduled pickup is not aligned to the configured slot interval' using errcode = '22023';
    end if;
  else
    raise exception 'fulfillmentType must be asap or scheduled' using errcode = '22023';
  end if;

  for v_line in select value from jsonb_array_elements(v_items)
  loop
    v_line_number := v_line_number + 1;
    if jsonb_typeof(v_line) <> 'object' then
      raise exception 'each order line must be a JSON object' using errcode = '22023';
    end if;

    begin
      v_item_id := nullif(v_line ->> 'itemId', '')::uuid;
    exception when invalid_text_representation then
      raise exception 'itemId must be a valid UUID' using errcode = '22023';
    end;
    if v_item_id is null then
      raise exception 'itemId is required' using errcode = '22023';
    end if;

    begin
      v_quantity := coalesce((v_line ->> 'quantity')::integer, 1);
    exception when invalid_text_representation then
      raise exception 'quantity must be an integer' using errcode = '22023';
    end;
    if v_quantity < 1 or v_quantity > 20 then
      raise exception 'quantity must be between 1 and 20' using errcode = '22023';
    end if;

    v_note := nullif(btrim(coalesce(v_line ->> 'note', '')), '');
    if v_note is not null and char_length(v_note) > 300 then
      raise exception 'line note must be 300 characters or fewer' using errcode = '22023';
    end if;

    select i.* into v_catalogue_item
    from public.catalogue_items i
    join public.catalogue_categories c on c.id = i.category_id
    where i.id = v_item_id
      and i.kind = 'product'
      and i.is_published
      and i.is_available
      and c.is_active;
    if not found then
      raise exception 'catalogue item is unavailable for ordering' using errcode = '22023';
    end if;

    select count(*) into v_variant_count
    from public.catalogue_item_variants v
    where v.item_id = v_item_id and v.is_available;

    begin
      v_variant_id := nullif(v_line ->> 'variantId', '')::uuid;
    exception when invalid_text_representation then
      raise exception 'variantId must be a valid UUID' using errcode = '22023';
    end;
    v_variant_delta := 0;

    if v_variant_count > 0 then
      if v_variant_id is null then
        raise exception 'an available variant is required for this item' using errcode = '22023';
      end if;
      select * into v_variant
      from public.catalogue_item_variants
      where id = v_variant_id and item_id = v_item_id and is_available;
      if not found then
        raise exception 'variant is unavailable or does not belong to the item' using errcode = '22023';
      end if;
      v_variant_delta := v_variant.price_delta_sen;
    elsif v_variant_id is not null then
      raise exception 'this item does not accept a variant' using errcode = '22023';
    end if;

    v_addon_ids := coalesce(v_line -> 'addOnIds', '[]'::jsonb);
    if jsonb_typeof(v_addon_ids) <> 'array' then
      raise exception 'addOnIds must be a JSON array' using errcode = '22023';
    end if;
    if jsonb_array_length(v_addon_ids) > 20 then
      raise exception 'a line cannot contain more than 20 add-ons' using errcode = '22023';
    end if;
    if (select count(*) <> count(distinct value #>> '{}') from jsonb_array_elements(v_addon_ids)) then
      raise exception 'duplicate add-ons are not allowed' using errcode = '22023';
    end if;

    v_addon_total := 0;
    v_addons := '[]'::jsonb;
    for v_addon_text in select value #>> '{}' from jsonb_array_elements(v_addon_ids)
    loop
      begin
        v_addon_id := v_addon_text::uuid;
      exception when invalid_text_representation then
        raise exception 'add-on IDs must be valid UUIDs' using errcode = '22023';
      end;

      select addon.* into v_addon
      from public.catalogue_item_addons link
      join public.catalogue_items addon on addon.id = link.addon_item_id
      join public.catalogue_categories category on category.id = addon.category_id
      where link.parent_item_id = v_item_id
        and link.addon_item_id = v_addon_id
        and addon.kind = 'addon'
        and addon.is_published
        and addon.is_available
        and category.is_active;
      if not found then
        raise exception 'add-on is unavailable or incompatible with the item' using errcode = '22023';
      end if;

      v_addon_total := v_addon_total + v_addon.base_price_sen;
      v_addons := v_addons || jsonb_build_array(jsonb_build_object(
        'itemId', v_addon.id,
        'sku', v_addon.sku,
        'name', v_addon.name,
        'priceSen', v_addon.base_price_sen
      ));
    end loop;

    v_unit_price := v_catalogue_item.base_price_sen + v_variant_delta + v_addon_total;
    if v_unit_price < 0 then
      raise exception 'resolved unit price cannot be negative' using errcode = '22023';
    end if;
    v_line_total := v_unit_price::bigint * v_quantity::bigint;
    v_subtotal := v_subtotal + v_line_total;

    v_lines := v_lines || jsonb_build_array(jsonb_build_object(
      'lineNumber', v_line_number,
      'itemId', v_catalogue_item.id,
      'sku', v_catalogue_item.sku,
      'name', v_catalogue_item.name,
      'prepRoute', v_catalogue_item.prep_route,
      'basePriceSen', v_catalogue_item.base_price_sen,
      'variant', case when v_variant_id is null then null else jsonb_build_object(
        'id', v_variant.id,
        'code', v_variant.code,
        'label', v_variant.label,
        'priceDeltaSen', v_variant.price_delta_sen
      ) end,
      'addOns', v_addons,
      'addOnTotalSen', v_addon_total,
      'unitPriceSen', v_unit_price,
      'quantity', v_quantity,
      'lineTotalSen', v_line_total,
      'note', v_note
    ));
  end loop;

  return jsonb_build_object(
    'pricingVersion', 1,
    'currency', 'MYR',
    'subtotalSen', v_subtotal,
    'totalSen', v_subtotal,
    'fulfillmentType', v_fulfillment_type,
    'requestedPickupAt', v_requested_pickup_at,
    'serverNow', now(),
    'schedulePolicy', jsonb_build_object(
      'timezone', v_settings.timezone,
      'scheduleEnabled', v_settings.schedule_enabled,
      'minimumLeadMinutes', v_settings.minimum_lead_minutes,
      'slotIntervalMinutes', v_settings.slot_interval_minutes,
      'maximumAdvanceDays', v_settings.maximum_advance_days
    ),
    'lines', v_lines
  );
end;
$$;

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

revoke all on function private.order_snapshot(uuid) from public, anon, authenticated;
grant execute on function private.order_snapshot(uuid) to authenticated;

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

  insert into public.orders (
    source, customer_user_id, member_id, created_by_user_id,
    client_request_id, request_hash, fulfillment_type, requested_pickup_at,
    status, currency, pricing_version, subtotal_sen, total_sen
  ) values (
    p_source, p_customer_user_id, p_member_id, p_actor_user_id,
    v_client_request_id, v_request_hash, v_quote ->> 'fulfillmentType',
    nullif(v_quote ->> 'requestedPickupAt', '')::timestamptz,
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
      'totalSen', (v_quote ->> 'totalSen')::bigint
    )
  );

  return private.order_snapshot(v_order_id);
end;
$$;

revoke all on function private.create_order_impl(jsonb, text, uuid, uuid, uuid)
  from public, anon, authenticated;
grant execute on function private.create_order_impl(jsonb, text, uuid, uuid, uuid)
  to authenticated;

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
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version < 1 then
    raise exception 'expected status version is required' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(btrim(p_reason)) > 300 then
    raise exception 'status reason must be 300 characters or fewer' using errcode = '22023';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'order not found' using errcode = 'P0002';
  end if;
  if v_order.status_version <> p_expected_version then
    raise exception 'order status changed; refresh before retrying' using errcode = '40001';
  end if;
  if not (
    (v_order.status = 'scheduled' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'confirmed' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'preparing' and p_to_status in ('ready', 'cancelled'))
    or (v_order.status = 'ready' and p_to_status = 'completed')
  ) then
    raise exception 'illegal order status transition from % to %', v_order.status, p_to_status
      using errcode = '22023';
  end if;

  update public.orders
  set status = p_to_status,
      status_version = status_version + 1,
      status_updated_at = v_now,
      preparing_at = case when p_to_status = 'preparing' then coalesce(preparing_at, v_now) else preparing_at end,
      ready_at = case when p_to_status = 'ready' then coalesce(ready_at, v_now) else ready_at end,
      completed_at = case when p_to_status = 'completed' then coalesce(completed_at, v_now) else completed_at end,
      cancelled_at = case when p_to_status = 'cancelled' then coalesce(cancelled_at, v_now) else cancelled_at end
  where id = p_order_id;

  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, reason, details
  ) values (
    p_order_id, 'status_changed', p_actor_user_id, v_order.status, p_to_status,
    nullif(btrim(coalesce(p_reason, '')), ''),
    jsonb_build_object('previousVersion', v_order.status_version, 'newVersion', v_order.status_version + 1)
  );

  return private.order_snapshot(p_order_id);
end;
$$;

revoke all on function private.transition_order_status_impl(uuid, text, bigint, text, uuid)
  from public, anon, authenticated;
grant execute on function private.transition_order_status_impl(uuid, text, bigint, text, uuid)
  to authenticated;

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
  v_slot_interval := coalesce((p_payload ->> 'slotIntervalMinutes')::integer, v_current.slot_interval_minutes);
  v_maximum_advance := coalesce((p_payload ->> 'maximumAdvanceDays')::integer, v_current.maximum_advance_days);

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = v_timezone) then
    raise exception 'invalid ordering timezone' using errcode = '22023';
  end if;
  if v_minimum_lead not between 0 and 1440
     or v_slot_interval not between 5 and 240
     or v_maximum_advance not between 1 and 31 then
    raise exception 'ordering schedule policy is outside allowed bounds' using errcode = '22023';
  end if;

  update public.order_schedule_settings
  set timezone = v_timezone,
      schedule_enabled = v_schedule_enabled,
      minimum_lead_minutes = v_minimum_lead,
      slot_interval_minutes = v_slot_interval,
      maximum_advance_days = v_maximum_advance
  where id = 1;

  return jsonb_build_object(
    'serverNow', now(),
    'timezone', v_timezone,
    'scheduleEnabled', v_schedule_enabled,
    'minimumLeadMinutes', v_minimum_lead,
    'slotIntervalMinutes', v_slot_interval,
    'maximumAdvanceDays', v_maximum_advance
  );
end;
$$;

revoke all on function private.save_ordering_policy_impl(jsonb, uuid)
  from public, anon, authenticated;
grant execute on function private.save_ordering_policy_impl(jsonb, uuid) to authenticated;

-- Public RPCs stay SECURITY INVOKER. Privileged writes happen only inside the
-- private, non-exposed SECURITY DEFINER helpers above, with explicit auth/role checks.
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
    'slotIntervalMinutes', s.slot_interval_minutes,
    'maximumAdvanceDays', s.maximum_advance_days
  )
  from public.order_schedule_settings s
  where s.id = 1;
$$;

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_member_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then
    raise exception 'customer identity required' using errcode = '42501';
  end if;
  select m.id into v_member_id
  from public.members m
  where m.user_id = v_user_id and m.active
  limit 1;
  if v_member_id is null then
    raise exception 'active member record is required for customer ordering' using errcode = '42501';
  end if;
  return private.create_order_impl(p_payload, 'customer', v_user_id, v_member_id, v_user_id);
end;
$$;

create or replace function public.place_pos_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  return private.create_order_impl(p_payload, 'pos', null, null, v_user_id);
end;
$$;

create or replace function public.get_order(p_order_id uuid)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.order_snapshot(p_order_id);
$$;

create or replace function public.get_my_orders(p_limit integer default 20)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_limit integer := greatest(1, least(coalesce(p_limit, 20), 100));
  v_result jsonb;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  select coalesce(jsonb_agg(private.order_snapshot(x.id) order by x.created_at desc), '[]'::jsonb)
  into v_result
  from (
    select o.id, o.created_at
    from public.orders o
    where o.customer_user_id = v_user_id
    order by o.created_at desc
    limit v_limit
  ) x;
  return v_result;
end;
$$;

create or replace function public.list_orders(p_statuses text[] default null, p_limit integer default 100)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 250));
  v_result jsonb;
begin
  if (select auth.uid()) is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if p_statuses is not null and exists (
    select 1 from unnest(p_statuses) status_value
    where status_value not in ('confirmed', 'scheduled', 'preparing', 'ready', 'completed', 'cancelled')
  ) then
    raise exception 'invalid order status filter' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(
    private.order_snapshot(x.id)
    order by case when x.status = 'scheduled' then x.requested_pickup_at end asc nulls last,
             x.created_at asc
  ), '[]'::jsonb)
  into v_result
  from (
    select o.id, o.status, o.requested_pickup_at, o.created_at
    from public.orders o
    where (p_statuses is null and o.status not in ('completed', 'cancelled'))
       or (p_statuses is not null and o.status = any(p_statuses))
    order by case when o.status = 'scheduled' then o.requested_pickup_at end asc nulls last,
             o.created_at asc
    limit v_limit
  ) x;
  return v_result;
end;
$$;

create or replace function public.transition_order_status(
  p_order_id uuid,
  p_to_status text,
  p_expected_version bigint,
  p_reason text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if (select auth.uid()) is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  return private.transition_order_status_impl(
    p_order_id, p_to_status, p_expected_version, p_reason, (select auth.uid())
  );
end;
$$;

create or replace function public.save_ordering_policy(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_ordering_policy_impl(p_payload, (select auth.uid()));
$$;

-- RLS and explicit Data API grants.
alter table public.order_schedule_settings enable row level security;
alter table public.order_schedule_settings force row level security;
alter table public.orders enable row level security;
alter table public.orders force row level security;
alter table public.order_lines enable row level security;
alter table public.order_lines force row level security;
alter table public.order_line_addons enable row level security;
alter table public.order_line_addons force row level security;
alter table public.order_events enable row level security;
alter table public.order_events force row level security;

create policy order_schedule_settings_public_read
on public.order_schedule_settings
for select
to anon, authenticated
using (id = 1);

create policy orders_authenticated_read
on public.orders
for select
to authenticated
using (
  customer_user_id = (select auth.uid())
  or (select private.is_staff_or_above())
);

create policy order_lines_authenticated_read
on public.order_lines
for select
to authenticated
using (
  exists (
    select 1 from public.orders o
    where o.id = order_lines.order_id
      and (o.customer_user_id = (select auth.uid()) or (select private.is_staff_or_above()))
  )
);

create policy order_line_addons_authenticated_read
on public.order_line_addons
for select
to authenticated
using (
  exists (
    select 1
    from public.order_lines l
    join public.orders o on o.id = l.order_id
    where l.id = order_line_addons.order_line_id
      and (o.customer_user_id = (select auth.uid()) or (select private.is_staff_or_above()))
  )
);

create policy order_events_staff_read
on public.order_events
for select
to authenticated
using ((select private.is_staff_or_above()));

revoke all on public.order_schedule_settings from anon, authenticated;
revoke all on public.orders from anon, authenticated;
revoke all on public.order_lines from anon, authenticated;
revoke all on public.order_line_addons from anon, authenticated;
revoke all on public.order_events from anon, authenticated;

grant select on public.order_schedule_settings to anon, authenticated;
grant select on public.orders to authenticated;
-- Lines/add-ons/events are returned through authorized RPC snapshots only; no
-- ordinary browser table grant is needed.

revoke all on function public.get_ordering_policy() from public, anon, authenticated;
revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb) from public, anon, authenticated;
revoke all on function public.get_order(uuid) from public, anon, authenticated;
revoke all on function public.get_my_orders(integer) from public, anon, authenticated;
revoke all on function public.list_orders(text[], integer) from public, anon, authenticated;
revoke all on function public.transition_order_status(uuid, text, bigint, text) from public, anon, authenticated;
revoke all on function public.save_ordering_policy(jsonb) from public, anon, authenticated;

grant execute on function public.get_ordering_policy() to anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;
grant execute on function public.place_pos_order(jsonb) to authenticated;
grant execute on function public.get_order(uuid) to authenticated;
grant execute on function public.get_my_orders(integer) to authenticated;
grant execute on function public.list_orders(text[], integer) to authenticated;
grant execute on function public.transition_order_status(uuid, text, bigint, text) to authenticated;
grant execute on function public.save_ordering_policy(jsonb) to authenticated;

-- Publish only the mutable order header. Commercial line snapshots are immutable;
-- clients re-fetch the full authorized order after an order-row Realtime event.
alter publication supabase_realtime add table public.orders;

comment on table public.order_schedule_settings is
  'Singleton scheduling policy for ASAP/scheduled pickup. Branch hours/capacity are intentionally not modelled yet.';
comment on table public.orders is
  'Authoritative order header. Commercial fields are server-owned and immutable after placement.';
comment on table public.order_lines is 'Immutable server-priced order line snapshots.';
comment on table public.order_line_addons is 'Immutable add-on price/name snapshots attached to an order line.';
comment on table public.order_events is 'Append-only order creation/status transition evidence.';
comment on function public.quote_order(jsonb) is
  'Server-authoritative quote validating publication/availability, variants, add-on compatibility, quantities and schedule.';
comment on function public.place_customer_order(jsonb) is
  'Idempotently persists a customer order from server-resolved catalogue pricing; requires an authenticated customer with an active member.';
comment on function public.place_pos_order(jsonb) is
  'Idempotently persists a POS order from server-resolved catalogue pricing; requires staff or above.';
comment on function public.transition_order_status(uuid, text, bigint, text) is
  'Applies a legal staff fulfilment transition with optimistic status-version concurrency.';
