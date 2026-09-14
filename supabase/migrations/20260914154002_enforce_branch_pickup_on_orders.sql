alter function public.quote_order(jsonb) rename to quote_order_catalogue_legacy;
revoke all on function public.quote_order_catalogue_legacy(jsonb) from public, anon, authenticated;

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_fulfillment_type text;
  v_requested_pickup_at timestamptz;
  v_branch_id uuid;
  v_context_branch text;
  v_catalogue_payload jsonb;
  v_quote jsonb;
  v_state jsonb;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'order payload must be a JSON object' using errcode = '22023';
  end if;
  v_fulfillment_type := coalesce(nullif(p_payload ->> 'fulfillmentType', ''), 'asap');
  if v_fulfillment_type not in ('asap', 'scheduled') then raise exception 'fulfillmentType must be asap or scheduled' using errcode = '22023'; end if;
  begin v_requested_pickup_at := nullif(p_payload ->> 'requestedPickupAt', '')::timestamptz;
  exception when invalid_text_representation then raise exception 'requestedPickupAt must be a valid timestamp' using errcode = '22023'; end;
  if v_fulfillment_type = 'asap' and v_requested_pickup_at is not null then raise exception 'ASAP orders cannot include a scheduled pickup time' using errcode = '22023'; end if;
  if v_fulfillment_type = 'scheduled' and v_requested_pickup_at is null then raise exception 'scheduled orders require requestedPickupAt' using errcode = '22023'; end if;

  v_context_branch := nullif(current_setting('aida.trusted_order_branch_id', true), '');
  if v_context_branch is null then v_context_branch := nullif(current_setting('aida.customer_order_branch_id', true), ''); end if;
  begin
    if v_context_branch is not null then v_branch_id := v_context_branch::uuid; else v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid; end if;
  exception when invalid_text_representation then raise exception 'branchId must be a valid UUID' using errcode = '22023'; end;
  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  if v_branch_id is null then raise exception 'default branch is unavailable' using errcode = '55000'; end if;

  v_catalogue_payload := (p_payload - 'requestedPickupAt' - 'branchId') || jsonb_build_object('fulfillmentType', 'asap');
  v_quote := public.quote_order_catalogue_legacy(v_catalogue_payload);
  v_state := private.branch_pickup_state_impl(v_branch_id, case when v_fulfillment_type = 'scheduled' then v_requested_pickup_at else null end, true);
  if not coalesce((v_state ->> 'valid')::boolean, false) then
    raise exception '%', coalesce(v_state ->> 'message', 'Pickup is unavailable') using errcode = '22023', detail = coalesce(v_state ->> 'code', 'PICKUP_UNAVAILABLE');
  end if;

  return v_quote || jsonb_build_object(
    'serverNow', v_state -> 'serverNow', 'branchId', v_branch_id, 'branch', v_state -> 'branch',
    'fulfillmentType', v_fulfillment_type, 'requestedPickupAt', v_requested_pickup_at,
    'schedulePolicy', v_state -> 'policy',
    'pickupAvailability', jsonb_build_object('code', v_state ->> 'code', 'localServiceDate', v_state -> 'localServiceDate', 'openAtTarget', v_state -> 'openAtTarget', 'effectiveSlotCapacityOrders', v_state -> 'effectiveSlotCapacityOrders', 'slotUsedOrders', v_state -> 'slotUsedOrders', 'slotRemainingOrders', v_state -> 'slotRemainingOrders')
  );
end;
$$;

revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

create or replace function private.enforce_branch_pickup_order_insert()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_customer_branch text; v_state jsonb;
begin
  if new.source = 'customer' then
    v_customer_branch := nullif(current_setting('aida.customer_order_branch_id', true), '');
    if v_customer_branch is not null then new.branch_id := v_customer_branch::uuid; end if;
  end if;
  if new.fulfillment_type = 'scheduled' then
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(new.branch_id::text), pg_catalog.hashtext(new.requested_pickup_at::text));
    v_state := private.branch_pickup_state_impl(new.branch_id, new.requested_pickup_at, true);
  else
    v_state := private.branch_pickup_state_impl(new.branch_id, null, false);
  end if;
  if not coalesce((v_state ->> 'valid')::boolean, false) then raise exception '%', coalesce(v_state ->> 'message', 'Pickup is unavailable') using errcode = '22023', detail = coalesce(v_state ->> 'code', 'PICKUP_UNAVAILABLE'); end if;
  if new.fulfillment_type = 'scheduled' then new.prepare_at := nullif(v_state ->> 'prepareAt', '')::timestamptz; else new.prepare_at := null; end if;
  return new;
end;
$$;
revoke all on function private.enforce_branch_pickup_order_insert() from public, anon, authenticated;
create trigger orders_enforce_branch_pickup before insert on public.orders for each row execute function private.enforce_branch_pickup_order_insert();

create or replace function private.normalize_created_order_event()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_order public.orders%rowtype;
begin
  if new.event_type <> 'created' then return new; end if;
  select * into v_order from public.orders where id = new.order_id;
  if not found then return new; end if;
  new.details := coalesce(new.details, '{}'::jsonb) || jsonb_build_object('branchId', v_order.branch_id, 'fulfillmentType', v_order.fulfillment_type, 'requestedPickupAt', v_order.requested_pickup_at, 'prepareAt', v_order.prepare_at, 'totalSen', v_order.total_sen);
  return new;
end;
$$;
revoke all on function private.normalize_created_order_event() from public, anon, authenticated;
create trigger order_events_normalize_created_schedule before insert on public.order_events for each row execute function private.normalize_created_order_event();

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_user_id uuid := (select auth.uid()); v_member_id uuid; v_branch_id uuid; v_result jsonb;
begin
  if v_user_id is null then raise exception 'authentication required' using errcode = '42501'; end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then raise exception 'customer identity required' using errcode = '42501'; end if;
  select m.id into v_member_id from public.members m where m.user_id = v_user_id and m.active limit 1;
  if v_member_id is null then raise exception 'active member record is required for customer ordering' using errcode = '42501'; end if;
  begin v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid; exception when invalid_text_representation then raise exception 'branchId must be a valid UUID' using errcode = '22023'; end;
  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  if not exists (select 1 from public.branches where id = v_branch_id and is_active) then raise exception 'branch is unavailable for ordering' using errcode = '22023', detail = 'BRANCH_UNAVAILABLE'; end if;
  perform set_config('aida.customer_order_branch_id', v_branch_id::text, true);
  v_result := private.create_order_impl(p_payload, 'customer', v_user_id, v_member_id, v_user_id);
  perform set_config('aida.customer_order_branch_id', '', true);
  return v_result;
end;
$$;

create or replace function public.place_pos_order(p_payload jsonb, p_terminal_credential text)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare
  v_user_id uuid := (select auth.uid()); v_shift jsonb; v_order jsonb; v_order_id uuid;
  v_tender text := lower(btrim(coalesce(p_payload ->> 'tenderType', 'unpaid')));
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then raise exception 'staff access required' using errcode = '42501'; end if;
  if v_tender not in ('unpaid', 'cash') then raise exception 'tenderType must be unpaid or cash' using errcode = '22023', detail = 'ORDER_TENDER_INVALID'; end if;
  v_shift := private.require_open_shift_impl(p_terminal_credential, v_user_id);
  perform set_config('aida.trusted_order_branch_id', v_shift ->> 'branchId', true);
  v_order := private.create_order_impl_v2(p_payload, 'pos', null, null, v_user_id, p_terminal_credential);
  perform set_config('aida.trusted_order_branch_id', '', true);
  v_order_id := (v_order ->> 'id')::uuid;
  perform private.finalize_pos_order_shift_impl(v_order_id, (v_shift ->> 'id')::uuid, v_tender, p_terminal_credential, v_user_id);
  return private.order_snapshot(v_order_id);
end;
$$;

create or replace function public.get_ordering_policy()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_branch_id uuid; v_branch public.branches%rowtype; v_policy public.branch_ordering_policies%rowtype;
begin
  select private.default_branch_id() into v_branch_id;
  select * into v_branch from public.branches where id = v_branch_id and is_active;
  select * into v_policy from public.branch_ordering_policies where branch_id = v_branch_id;
  if v_branch.id is null or v_policy.branch_id is null then raise exception 'default branch ordering policy is unavailable' using errcode = '55000'; end if;
  return jsonb_build_object('serverNow', now(), 'branchId', v_branch.id, 'timezone', v_branch.timezone, 'asapEnabled', v_policy.asap_enabled, 'scheduleEnabled', v_policy.schedule_enabled, 'minimumLeadMinutes', v_policy.minimum_lead_minutes, 'preparationLeadMinutes', v_policy.preparation_lead_minutes, 'slotIntervalMinutes', v_policy.slot_interval_minutes, 'maximumAdvanceDays', v_policy.maximum_advance_days, 'slotCapacityOrders', v_policy.slot_capacity_orders);
end;
$$;

create or replace function public.save_ordering_policy(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_branch_id uuid; v_timezone text; v_payload jsonb;
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode = '42501'; end if;
  select private.default_branch_id() into v_branch_id;
  select timezone into v_timezone from public.branches where id = v_branch_id;
  if p_payload ? 'timezone' and nullif(p_payload ->> 'timezone', '') is distinct from v_timezone then raise exception 'change timezone through branch settings' using errcode = '22023', detail = 'BRANCH_TIMEZONE_AUTHORITY'; end if;
  v_payload := (p_payload - 'timezone') || jsonb_build_object('branchId', v_branch_id);
  return private.save_branch_pickup_configuration_impl(v_payload, (select auth.uid()));
end;
$$;

revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb, text) from public, anon, authenticated;
revoke all on function public.get_ordering_policy() from public, anon, authenticated;
revoke all on function public.save_ordering_policy(jsonb) from public, anon, authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;
grant execute on function public.place_pos_order(jsonb, text) to authenticated;
grant execute on function public.get_ordering_policy() to anon, authenticated;
grant execute on function public.save_ordering_policy(jsonb) to authenticated;

comment on function public.quote_order(jsonb) is 'Authoritative catalogue quote plus branch-local pickup-hours, lead-time, slot and capacity validation.';
comment on function public.list_branch_pickup_slots(uuid, date) is 'Lists currently available server-authoritative scheduled pickup slots for one active branch-local service date.';
