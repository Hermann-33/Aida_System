-- TASK-DEMO-ORDER-001 authoritative order/scheduling regression.
-- Runs entirely inside a transaction and leaves no synthetic rows behind.

begin;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'orders'
  ) then
    raise exception 'orders is not published to Supabase Realtime';
  end if;

  if not has_function_privilege('anon', 'public.quote_order(jsonb)', 'execute') then
    raise exception 'anonymous clients cannot request authoritative quotes';
  end if;
  if has_function_privilege('anon', 'public.place_customer_order(jsonb)', 'execute')
     or has_function_privilege('anon', 'public.place_pos_order(jsonb)', 'execute')
     or has_function_privilege('anon', 'public.transition_order_status(uuid,text,bigint,text)', 'execute') then
    raise exception 'anonymous role has privileged order capability';
  end if;

  if has_table_privilege('authenticated', 'public.orders', 'insert')
     or has_table_privilege('authenticated', 'public.orders', 'update')
     or has_table_privilege('authenticated', 'public.order_lines', 'insert')
     or has_table_privilege('authenticated', 'public.order_line_addons', 'insert')
     or has_table_privilege('authenticated', 'public.order_events', 'insert') then
    raise exception 'authenticated clients have direct order DML grants';
  end if;

  if not exists (
    select 1 from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relname = 'orders'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then
    raise exception 'orders does not have forced RLS';
  end if;
end;
$$;

-- Public quote proves client price/total fields are ignored and the database
-- resolves the current catalogue price, variant delta and compatible add-on.
set local role anon;

do $$
declare
  v_quote jsonb;
  v_item_id uuid;
  v_variant_id uuid;
  v_addon_id uuid;
  v_expected_unit integer;
begin
  select id into strict v_item_id
  from public.catalogue_items
  where sku = 'CF-SCL';
  select v.id into strict v_variant_id
  from public.catalogue_item_variants v
  join public.catalogue_items i on i.id = v.item_id
  where i.sku = 'CF-SCL' and v.code = 'medium';
  select id into strict v_addon_id
  from public.catalogue_items
  where sku = 'AD-OAT';

  select item.base_price_sen + variant.price_delta_sen + addon.base_price_sen
  into strict v_expected_unit
  from public.catalogue_items item
  join public.catalogue_item_variants variant
    on variant.id = v_variant_id and variant.item_id = item.id
  join public.catalogue_items addon on addon.id = v_addon_id
  where item.id = v_item_id;

  select public.quote_order(jsonb_build_object(
    'fulfillmentType', 'asap',
    'subtotalSen', 1,
    'totalSen', 1,
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'addOnIds', jsonb_build_array(v_addon_id),
      'quantity', 2,
      'clientPriceSen', 1
    ))
  )) into v_quote;

  if (v_quote ->> 'totalSen')::bigint <> v_expected_unit::bigint * 2
     or (v_quote #>> '{lines,0,unitPriceSen}')::integer <> v_expected_unit
     or (v_quote #>> '{lines,0,lineTotalSen}')::bigint <> v_expected_unit::bigint * 2 then
    raise exception 'authoritative quote did not resolve expected catalogue price';
  end if;

  begin
    perform public.quote_order(jsonb_build_object(
      'fulfillmentType', 'asap',
      'items', jsonb_build_array(jsonb_build_object(
        'itemId', (select id from public.catalogue_items where sku = 'FD-SAN'),
        'addOnIds', jsonb_build_array(v_addon_id),
        'quantity', 1
      ))
    ));
    raise exception 'incompatible add-on unexpectedly quoted';
  exception when invalid_parameter_value then
    null;
  end;

  begin
    perform public.quote_order(jsonb_build_object(
      'fulfillmentType', 'scheduled',
      'requestedPickupAt', now() - interval '1 hour',
      'items', jsonb_build_array(jsonb_build_object(
        'itemId', v_item_id,
        'variantId', v_variant_id,
        'addOnIds', '[]'::jsonb,
        'quantity', 1
      ))
    ));
    raise exception 'past scheduled pickup unexpectedly quoted';
  exception when invalid_parameter_value then
    null;
  end;
end;
$$;

reset role;

-- Synthetic users are transaction-local. Existing Auth provisioning triggers
-- create trusted profiles/member rows; role promotion happens only from DB state.
insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values
  ('30000000-0000-0000-0000-000000000001', 'order-customer@example.test', '{}'::jsonb, now(), now()),
  ('30000000-0000-0000-0000-000000000002', 'order-staff@example.test', '{}'::jsonb, now(), now()),
  ('30000000-0000-0000-0000-000000000003', 'order-admin@example.test', '{}'::jsonb, now(), now());

update public.user_profiles
set app_role = 'staff'
where user_id = '30000000-0000-0000-0000-000000000002';
update public.user_profiles
set app_role = 'admin'
where user_id = '30000000-0000-0000-0000-000000000003';

set local role authenticated;

do $$
declare
  v_customer_id uuid := '30000000-0000-0000-0000-000000000001';
  v_staff_id uuid := '30000000-0000-0000-0000-000000000002';
  v_admin_id uuid := '30000000-0000-0000-0000-000000000003';
  v_item_id uuid;
  v_variant_id uuid;
  v_addon_id uuid;
  v_schedule timestamptz;
  v_request_id uuid := '31000000-0000-0000-0000-000000000001';
  v_payload jsonb;
  v_order jsonb;
  v_retry jsonb;
  v_order_id uuid;
  v_orders jsonb;
  v_pos_order jsonb;
  v_policy jsonb;
  v_expected_unit integer;
  v_expected_pos_total integer;
begin
  select id into strict v_item_id
  from public.catalogue_items
  where sku = 'CF-SCL';
  select v.id into strict v_variant_id
  from public.catalogue_item_variants v
  join public.catalogue_items i on i.id = v.item_id
  where i.sku = 'CF-SCL' and v.code = 'medium';
  select id into strict v_addon_id
  from public.catalogue_items
  where sku = 'AD-OAT';
  select item.base_price_sen + variant.price_delta_sen + addon.base_price_sen
  into strict v_expected_unit
  from public.catalogue_items item
  join public.catalogue_item_variants variant
    on variant.id = v_variant_id and variant.item_id = item.id
  join public.catalogue_items addon on addon.id = v_addon_id
  where item.id = v_item_id;
  select base_price_sen into strict v_expected_pos_total
  from public.catalogue_items
  where sku = 'FD-SAN';

  -- Two hours ahead, aligned to a whole local hour and therefore a 15-minute slot.
  v_schedule := (
    date_trunc('hour', now() at time zone 'Asia/Kuala_Lumpur') + interval '2 hours'
  ) at time zone 'Asia/Kuala_Lumpur';

  v_payload := jsonb_build_object(
    'clientRequestId', v_request_id,
    'fulfillmentType', 'scheduled',
    'requestedPickupAt', v_schedule,
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'addOnIds', jsonb_build_array(v_addon_id),
      'quantity', 2,
      'note', 'Regression order'
    ))
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_customer_id, 'role', 'authenticated')::text,
    true
  );

  select public.place_customer_order(v_payload) into v_order;
  v_order_id := (v_order ->> 'id')::uuid;

  if v_order_id is null
     or v_order ->> 'status' <> 'scheduled'
     or v_order ->> 'fulfillmentType' <> 'scheduled'
     or (v_order ->> 'totalSen')::bigint <> v_expected_unit::bigint * 2
     or (v_order ->> 'statusVersion')::bigint <> 1
     or jsonb_array_length(v_order -> 'lines') <> 1 then
    raise exception 'customer scheduled order snapshot is invalid';
  end if;

  select public.place_customer_order(v_payload) into v_retry;
  if v_retry ->> 'id' <> v_order ->> 'id'
     or (select count(*) from public.orders where created_by_user_id = v_customer_id and client_request_id = v_request_id) <> 1 then
    raise exception 'idempotent retry created a duplicate order';
  end if;

  begin
    perform public.place_customer_order(
      jsonb_set(v_payload, '{items,0,quantity}', '3'::jsonb)
    );
    raise exception 'reused idempotency key accepted a different payload';
  exception when unique_violation then
    null;
  end;

  select public.get_my_orders(20) into v_orders;
  if not exists (
    select 1 from jsonb_array_elements(v_orders) item
    where item ->> 'id' = v_order_id::text
  ) then
    raise exception 'customer order history did not return own order';
  end if;

  begin
    insert into public.orders (
      source, customer_user_id, member_id, created_by_user_id, client_request_id,
      request_hash, fulfillment_type, status, subtotal_sen, total_sen
    ) values (
      'customer', v_customer_id,
      (select id from public.members where user_id = v_customer_id), v_customer_id,
      gen_random_uuid(), 'forbidden', 'asap', 'confirmed', 1, 1
    );
    raise exception 'customer unexpectedly inserted directly into orders';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.transition_order_status(v_order_id, 'preparing', 1, null);
    raise exception 'customer unexpectedly transitioned an order';
  exception when insufficient_privilege then
    null;
  end;

  -- Staff queue, POS placement and legal transitions use the caller JWT.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_staff_id, 'role', 'authenticated')::text,
    true
  );

  select public.list_orders(array['scheduled'], 100) into v_orders;
  if not exists (
    select 1 from jsonb_array_elements(v_orders) item
    where item ->> 'id' = v_order_id::text
  ) then
    raise exception 'staff order queue did not return scheduled order';
  end if;

  select public.place_pos_order(jsonb_build_object(
    'clientRequestId', '31000000-0000-0000-0000-000000000002',
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', (select id from public.catalogue_items where sku = 'FD-SAN'),
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  )) into v_pos_order;
  if v_pos_order ->> 'source' <> 'pos'
     or v_pos_order ->> 'status' <> 'confirmed'
     or (v_pos_order ->> 'totalSen')::bigint <> v_expected_pos_total then
    raise exception 'staff POS order did not persist authoritative quote';
  end if;

  select public.transition_order_status(v_order_id, 'preparing', 1, null) into v_order;
  if v_order ->> 'status' <> 'preparing' or (v_order ->> 'statusVersion')::bigint <> 2 then
    raise exception 'scheduled -> preparing transition failed';
  end if;

  begin
    perform public.transition_order_status(v_order_id, 'ready', 1, null);
    raise exception 'stale status version unexpectedly succeeded';
  exception when serialization_failure then
    null;
  end;

  select public.transition_order_status(v_order_id, 'ready', 2, null) into v_order;
  select public.transition_order_status(v_order_id, 'completed', 3, null) into v_order;
  if v_order ->> 'status' <> 'completed' or (v_order ->> 'statusVersion')::bigint <> 4 then
    raise exception 'order did not complete through legal transition chain';
  end if;

  begin
    perform public.transition_order_status(v_order_id, 'preparing', 4, null);
    raise exception 'terminal completed order unexpectedly transitioned';
  exception when invalid_parameter_value then
    null;
  end;

  -- Staff cannot edit scheduling policy; admin can, and rollback restores it.
  begin
    perform public.save_ordering_policy('{"minimumLeadMinutes":30}'::jsonb);
    raise exception 'staff unexpectedly changed ordering policy';
  exception when insufficient_privilege then
    null;
  end;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_admin_id, 'role', 'authenticated')::text,
    true
  );
  select public.save_ordering_policy(jsonb_build_object(
    'timezone', 'Asia/Kuala_Lumpur',
    'scheduleEnabled', true,
    'minimumLeadMinutes', 20,
    'slotIntervalMinutes', 15,
    'maximumAdvanceDays', 7
  )) into v_policy;
  if (v_policy ->> 'minimumLeadMinutes')::integer <> 20 then
    raise exception 'admin ordering policy update failed';
  end if;
end;
$$;

reset role;

do $$
declare
  v_expected_unit integer;
begin
  select item.base_price_sen + variant.price_delta_sen + addon.base_price_sen
  into strict v_expected_unit
  from public.catalogue_items item
  join public.catalogue_item_variants variant
    on variant.item_id = item.id and variant.code = 'medium'
  join public.catalogue_items addon on addon.sku = 'AD-OAT'
  where item.sku = 'CF-SCL';

  if (select count(*) from public.order_events where order_id in (
    select id from public.orders where created_by_user_id = '30000000-0000-0000-0000-000000000001'
  )) <> 4 then
    raise exception 'expected created + three fulfilment events for customer regression order';
  end if;

  if exists (
    select 1 from public.order_lines l
    join public.orders o on o.id = l.order_id
    where o.created_by_user_id = '30000000-0000-0000-0000-000000000001'
      and (
        l.sku_snapshot <> 'CF-SCL'
        or l.unit_price_sen <> v_expected_unit
        or l.line_total_sen <> v_expected_unit::bigint * 2
      )
  ) then
    raise exception 'persisted commercial order snapshot is incorrect';
  end if;
end;
$$;

rollback;
