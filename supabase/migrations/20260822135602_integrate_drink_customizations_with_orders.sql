-- TASK-MENU-CUSTOMIZATION-001
-- Carry drink option IDs through authoritative quote/place and persist immutable
-- option snapshots so later catalogue edits cannot rewrite historical orders.

alter table public.order_lines
  add column if not exists option_total_sen integer not null default 0;
alter table public.order_lines
  add constraint order_lines_option_total_check
  check (option_total_sen between -10000000 and 10000000);

create table public.order_line_options (
  id uuid primary key default gen_random_uuid(),
  order_line_id uuid not null references public.order_lines(id) on delete cascade,
  catalogue_option_group_id uuid not null references public.catalogue_option_groups(id) on delete restrict,
  catalogue_option_value_id uuid not null,
  group_code_snapshot text not null,
  group_name_snapshot text not null,
  option_code_snapshot text not null,
  option_label_snapshot text not null,
  price_delta_sen integer not null default 0,
  created_at timestamptz not null default now(),
  constraint order_line_options_line_option_unique
    unique (order_line_id, catalogue_option_value_id),
  constraint order_line_options_option_group_fk
    foreign key (catalogue_option_value_id, catalogue_option_group_id)
    references public.catalogue_option_values(id, group_id) on delete restrict,
  constraint order_line_options_group_code_length
    check (char_length(group_code_snapshot) between 1 and 80),
  constraint order_line_options_group_name_length
    check (char_length(group_name_snapshot) between 1 and 80),
  constraint order_line_options_option_code_length
    check (char_length(option_code_snapshot) between 1 and 80),
  constraint order_line_options_option_label_length
    check (char_length(option_label_snapshot) between 1 and 80),
  constraint order_line_options_price_check
    check (price_delta_sen between -10000000 and 10000000)
);

create index order_line_options_line_idx
  on public.order_line_options (order_line_id);
create index order_line_options_group_idx
  on public.order_line_options (catalogue_option_group_id);
create index order_line_options_value_idx
  on public.order_line_options (catalogue_option_value_id);

alter table public.order_line_options enable row level security;
alter table public.order_line_options force row level security;
revoke all on public.order_line_options from anon, authenticated;

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
set search_path to 'public', 'pg_temp'
as $function$
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
  v_option_ids jsonb;
  v_option_text text;
  v_selected_option_ids uuid[];
  v_group record;
  v_option record;
  v_group_selected_count integer;
  v_option_total integer;
  v_options jsonb;
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

    v_option_ids := coalesce(v_line -> 'optionValueIds', '[]'::jsonb);
    if jsonb_typeof(v_option_ids) <> 'array' then
      raise exception 'optionValueIds must be a JSON array' using errcode = '22023';
    end if;
    if jsonb_array_length(v_option_ids) > 20 then
      raise exception 'a line cannot contain more than 20 customization options' using errcode = '22023';
    end if;

    v_selected_option_ids := array[]::uuid[];
    for v_option_text in select value #>> '{}' from jsonb_array_elements(v_option_ids)
    loop
      begin
        v_selected_option_ids := array_append(v_selected_option_ids, v_option_text::uuid);
      exception when invalid_text_representation then
        raise exception 'customization option IDs must be valid UUIDs' using errcode = '22023';
      end;
    end loop;
    if cardinality(v_selected_option_ids) <> (
      select count(distinct selected_id) from unnest(v_selected_option_ids) as selected_id
    ) then
      raise exception 'duplicate customization options are not allowed' using errcode = '22023';
    end if;

    v_option_total := 0;
    v_options := '[]'::jsonb;
    if not v_catalogue_item.is_drink then
      if cardinality(v_selected_option_ids) > 0 then
        raise exception 'this item does not accept drink customization options' using errcode = '22023';
      end if;
    else
      if exists (
        select 1
        from unnest(v_selected_option_ids) selected_id
        where not exists (
          select 1
          from public.catalogue_item_option_values iv
          join public.catalogue_option_values ov on ov.id = iv.option_value_id
          join public.catalogue_option_groups g on g.id = iv.group_id
          where iv.item_id = v_item_id
            and iv.option_value_id = selected_id
            and iv.is_available
            and ov.is_active
            and g.is_active
        )
      ) then
        raise exception 'customization option is unavailable or does not belong to the item' using errcode = '22023';
      end if;

      for v_group in
        select g.id, g.code, g.name, g.sort_order
        from public.catalogue_option_groups g
        where g.is_active
          and exists (
            select 1
            from public.catalogue_item_option_values iv
            join public.catalogue_option_values ov on ov.id = iv.option_value_id
            where iv.item_id = v_item_id
              and iv.group_id = g.id
              and iv.is_available
              and ov.is_active
          )
        order by g.sort_order, g.name
      loop
        select count(*) into v_group_selected_count
        from public.catalogue_item_option_values iv
        join public.catalogue_option_values ov on ov.id = iv.option_value_id
        where iv.item_id = v_item_id
          and iv.group_id = v_group.id
          and iv.option_value_id = any(v_selected_option_ids)
          and ov.is_active;
        if v_group_selected_count > 1 then
          raise exception 'only one customization option may be selected from each group' using errcode = '22023';
        end if;

        if v_group_selected_count = 1 then
          select iv.option_value_id, ov.code,
                 coalesce(iv.label_override, ov.label) as label,
                 iv.price_delta_sen
          into v_option
          from public.catalogue_item_option_values iv
          join public.catalogue_option_values ov on ov.id = iv.option_value_id
          where iv.item_id = v_item_id
            and iv.group_id = v_group.id
            and iv.option_value_id = any(v_selected_option_ids)
            and iv.is_available
            and ov.is_active
          limit 1;
          if not found then
            raise exception 'selected customization option is unavailable' using errcode = '22023';
          end if;
        else
          select iv.option_value_id, ov.code,
                 coalesce(iv.label_override, ov.label) as label,
                 iv.price_delta_sen
          into v_option
          from public.catalogue_item_option_values iv
          join public.catalogue_option_values ov on ov.id = iv.option_value_id
          where iv.item_id = v_item_id
            and iv.group_id = v_group.id
            and iv.is_available
            and iv.is_default
            and ov.is_active
          limit 1;
          if not found then
            raise exception 'drink customization group has no available default option' using errcode = '55000';
          end if;
        end if;

        v_option_total := v_option_total + v_option.price_delta_sen;
        v_options := v_options || jsonb_build_array(jsonb_build_object(
          'groupId', v_group.id,
          'groupCode', v_group.code,
          'groupName', v_group.name,
          'optionValueId', v_option.option_value_id,
          'optionCode', v_option.code,
          'optionLabel', v_option.label,
          'priceDeltaSen', v_option.price_delta_sen
        ));
      end loop;
    end if;

    v_unit_price := v_catalogue_item.base_price_sen + v_variant_delta + v_addon_total + v_option_total;
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
      'options', v_options,
      'optionTotalSen', v_option_total,
      'unitPriceSen', v_unit_price,
      'quantity', v_quantity,
      'lineTotalSen', v_line_total,
      'note', v_note
    ));
  end loop;

  return jsonb_build_object(
    'pricingVersion', 2,
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
      'preparationLeadMinutes', v_settings.preparation_lead_minutes,
      'slotIntervalMinutes', v_settings.slot_interval_minutes,
      'maximumAdvanceDays', v_settings.maximum_advance_days
    ),
    'lines', v_lines
  );
end;
$function$;

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
set search_path to ''
as $function$
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
  v_option jsonb;
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
    from public.order_schedule_settings s where s.id = 1;
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
      option_total_sen, unit_price_sen, quantity, line_total_sen, note
    ) values (
      v_order_id, (v_line ->> 'lineNumber')::integer, (v_line ->> 'itemId')::uuid,
      v_line ->> 'sku', v_line ->> 'name', v_line ->> 'prepRoute',
      (v_line ->> 'basePriceSen')::integer,
      nullif(v_line #>> '{variant,id}', '')::uuid,
      nullif(v_line #>> '{variant,code}', ''),
      nullif(v_line #>> '{variant,label}', ''),
      coalesce((v_line #>> '{variant,priceDeltaSen}')::integer, 0),
      (v_line ->> 'addOnTotalSen')::integer,
      coalesce((v_line ->> 'optionTotalSen')::integer, 0),
      (v_line ->> 'unitPriceSen')::integer,
      (v_line ->> 'quantity')::integer,
      (v_line ->> 'lineTotalSen')::bigint,
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

    for v_option in select value from jsonb_array_elements(coalesce(v_line -> 'options', '[]'::jsonb))
    loop
      insert into public.order_line_options (
        order_line_id, catalogue_option_group_id, catalogue_option_value_id,
        group_code_snapshot, group_name_snapshot,
        option_code_snapshot, option_label_snapshot, price_delta_sen
      ) values (
        v_line_id,
        (v_option ->> 'groupId')::uuid,
        (v_option ->> 'optionValueId')::uuid,
        v_option ->> 'groupCode',
        v_option ->> 'groupName',
        v_option ->> 'optionCode',
        v_option ->> 'optionLabel',
        (v_option ->> 'priceDeltaSen')::integer
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
$function$;

create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path to ''
as $function$
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
        'options', coalesce((
          select jsonb_agg(jsonb_build_object(
            'groupId', x.catalogue_option_group_id,
            'groupCode', x.group_code_snapshot,
            'groupName', x.group_name_snapshot,
            'optionValueId', x.catalogue_option_value_id,
            'optionCode', x.option_code_snapshot,
            'optionLabel', x.option_label_snapshot,
            'priceDeltaSen', x.price_delta_sen
          ) order by x.created_at, x.id)
          from public.order_line_options x
          where x.order_line_id = l.id
        ), '[]'::jsonb),
        'optionTotalSen', l.option_total_sen,
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
$function$;
