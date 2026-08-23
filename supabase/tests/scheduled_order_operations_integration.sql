-- TASK-SCHEDULED-OPS-001 scheduled-order preparation/queue regression.
-- Runs transactionally and leaves no synthetic rows or policy changes behind.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'order_schedule_settings'
      and column_name = 'preparation_lead_minutes'
  ) then
    raise exception 'preparation_lead_minutes is missing';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'orders'
      and column_name = 'prepare_at'
  ) then
    raise exception 'orders.prepare_at is missing';
  end if;

  if (select preparation_lead_minutes from public.order_schedule_settings where id = 1)
     > (select minimum_lead_minutes from public.order_schedule_settings where id = 1) then
    raise exception 'preparation lead exceeds customer minimum lead';
  end if;
end;
$$;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values
  ('32000000-0000-0000-0000-000000000001', 'scheduled-ops-customer@example.test', '{}'::jsonb, now(), now()),
  ('32000000-0000-0000-0000-000000000002', 'scheduled-ops-admin@example.test', '{}'::jsonb, now(), now());

update public.user_profiles
set app_role = 'admin'
where user_id = '32000000-0000-0000-0000-000000000002';

set local role authenticated;

do $$
declare
  v_customer_id uuid := '32000000-0000-0000-0000-000000000001';
  v_admin_id uuid := '32000000-0000-0000-0000-000000000002';
  v_item_id uuid;
  v_variant_id uuid;
  v_schedule timestamptz;
  v_prepare_at timestamptz;
  v_expected_prepare_at timestamptz;
  v_request_id uuid := '32100000-0000-0000-0000-000000000001';
  v_payload jsonb;
  v_order jsonb;
  v_retry jsonb;
  v_policy jsonb;
  v_pos_order jsonb;
  v_prep_lead integer;
begin
  select id into strict v_item_id
  from public.catalogue_items
  where sku = 'CF-SCL';

  select v.id into strict v_variant_id
  from public.catalogue_item_variants v
  join public.catalogue_items i on i.id = v.item_id
  where i.sku = 'CF-SCL' and v.code = 'medium';

  select preparation_lead_minutes into strict v_prep_lead
  from public.order_schedule_settings
  where id = 1;

  v_schedule := (
    date_trunc('hour', now() at time zone 'Asia/Kuala_Lumpur') + interval '2 hours'
  ) at time zone 'Asia/Kuala_Lumpur';
  v_expected_prepare_at := v_schedule - make_interval(mins => v_prep_lead);

  v_payload := jsonb_build_object(
    'clientRequestId', v_request_id,
    'fulfillmentType', 'scheduled',
    'requestedPickupAt', v_schedule,
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_customer_id, 'role', 'authenticated')::text,
    true
  );

  select public.place_customer_order(v_payload) into v_order;
  v_prepare_at := (v_order ->> 'prepareAt')::timestamptz;

  if v_order ->> 'status' <> 'scheduled'
     or v_order ->> 'scheduleState' <> 'future'
     or v_prepare_at is distinct from v_expected_prepare_at
     or (v_order ->> 'serverNow')::timestamptz is null then
    raise exception 'scheduled order operational snapshot is invalid: %', v_order;
  end if;

  select public.place_customer_order(v_payload) into v_retry;
  if v_retry ->> 'id' <> v_order ->> 'id'
     or (v_retry ->> 'prepareAt')::timestamptz is distinct from v_prepare_at then
    raise exception 'idempotent retry changed scheduled preparation authority';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_admin_id, 'role', 'authenticated')::text,
    true
  );

  select public.save_ordering_policy(jsonb_build_object(
    'minimumLeadMinutes', 20,
    'preparationLeadMinutes', 10
  )) into v_policy;

  if (v_policy ->> 'minimumLeadMinutes')::integer <> 20
     or (v_policy ->> 'preparationLeadMinutes')::integer <> 10 then
    raise exception 'admin preparation policy update failed';
  end if;

  begin
    perform public.save_ordering_policy(jsonb_build_object(
      'minimumLeadMinutes', 10,
      'preparationLeadMinutes', 15
    ));
    raise exception 'invalid preparation lead unexpectedly accepted';
  exception when invalid_parameter_value then
    null;
  end;

  v_schedule := (
    date_trunc('hour', now() at time zone 'Asia/Kuala_Lumpur') + interval '3 hours'
  ) at time zone 'Asia/Kuala_Lumpur';

  select public.place_pos_order(jsonb_build_object(
    'clientRequestId', '32100000-0000-0000-0000-000000000002',
    'fulfillmentType', 'scheduled',
    'requestedPickupAt', v_schedule,
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  )) into v_pos_order;

  if (v_pos_order ->> 'prepareAt')::timestamptz
       is distinct from v_schedule - interval '10 minutes'
     or v_pos_order ->> 'scheduleState' <> 'future' then
    raise exception 'new scheduled POS order did not snapshot current preparation lead';
  end if;

  -- Policy changes never rewrite a previously accepted scheduled order.
  select public.get_order((v_order ->> 'id')::uuid) into v_retry;
  if (v_retry ->> 'prepareAt')::timestamptz is distinct from v_prepare_at then
    raise exception 'policy change rewrote persisted prepareAt';
  end if;
end;
$$;

reset role;
rollback;
