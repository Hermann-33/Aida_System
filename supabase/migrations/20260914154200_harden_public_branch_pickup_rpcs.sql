-- Phase 4 security hardening: public PostgREST entrypoints are SECURITY INVOKER.
-- Privileged table access remains isolated behind private SECURITY DEFINER
-- helpers with explicit EXECUTE grants.

-- Keep the pre-Phase-4 catalogue-only quote implementation out of the exposed
-- public schema. The public quote wrapper below remains the only supported quote
-- surface and adds branch scheduling/capacity validation.
alter function public.quote_order_catalogue_legacy(jsonb) set schema private;
revoke all on function private.quote_order_catalogue_legacy(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_catalogue_legacy(jsonb) to anon, authenticated;

-- Convert the three public branch read RPC implementations into private helpers
-- without changing their proven logic.
alter function public.get_branch_pickup_state(uuid, timestamptz) set schema private;
alter function private.get_branch_pickup_state(uuid, timestamptz) rename to get_branch_pickup_state_impl;

alter function public.list_pickup_branches() set schema private;
alter function private.list_pickup_branches() rename to list_pickup_branches_impl;

alter function public.list_branch_pickup_slots(uuid, date) set schema private;
alter function private.list_branch_pickup_slots(uuid, date) rename to list_branch_pickup_slots_impl;

revoke all on function private.get_branch_pickup_state_impl(uuid, timestamptz) from public, anon, authenticated;
revoke all on function private.list_pickup_branches_impl() from public, anon, authenticated;
revoke all on function private.list_branch_pickup_slots_impl(uuid, date) from public, anon, authenticated;
grant execute on function private.get_branch_pickup_state_impl(uuid, timestamptz) to anon, authenticated;
grant execute on function private.list_pickup_branches_impl() to anon, authenticated;
grant execute on function private.list_branch_pickup_slots_impl(uuid, date) to anon, authenticated;

create or replace function public.get_branch_pickup_state(
  p_branch_id uuid default null,
  p_requested_pickup_at timestamptz default null
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.get_branch_pickup_state_impl(p_branch_id, p_requested_pickup_at);
$$;

create or replace function public.list_pickup_branches()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.list_pickup_branches_impl();
$$;

create or replace function public.list_branch_pickup_slots(
  p_branch_id uuid,
  p_service_date date
)
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.list_branch_pickup_slots_impl(p_branch_id, p_service_date);
$$;

revoke all on function public.get_branch_pickup_state(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.list_pickup_branches() from public, anon, authenticated;
revoke all on function public.list_branch_pickup_slots(uuid, date) from public, anon, authenticated;
grant execute on function public.get_branch_pickup_state(uuid, timestamptz) to anon, authenticated;
grant execute on function public.list_pickup_branches() to anon, authenticated;
grant execute on function public.list_branch_pickup_slots(uuid, date) to anon, authenticated;

-- Rebuild quote_order as an invoker wrapper. The legacy catalogue calculation
-- remains invoker code in private; branch policy/capacity authority remains in
-- private.branch_pickup_state_impl().
create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
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
  if v_fulfillment_type not in ('asap', 'scheduled') then
    raise exception 'fulfillmentType must be asap or scheduled' using errcode = '22023';
  end if;

  begin
    v_requested_pickup_at := nullif(p_payload ->> 'requestedPickupAt', '')::timestamptz;
  exception when invalid_text_representation then
    raise exception 'requestedPickupAt must be a valid timestamp' using errcode = '22023';
  end;

  if v_fulfillment_type = 'asap' and v_requested_pickup_at is not null then
    raise exception 'ASAP orders cannot include a scheduled pickup time' using errcode = '22023';
  end if;
  if v_fulfillment_type = 'scheduled' and v_requested_pickup_at is null then
    raise exception 'scheduled orders require requestedPickupAt' using errcode = '22023';
  end if;

  v_context_branch := nullif(current_setting('aida.trusted_order_branch_id', true), '');
  if v_context_branch is null then
    v_context_branch := nullif(current_setting('aida.customer_order_branch_id', true), '');
  end if;

  begin
    if v_context_branch is not null then
      v_branch_id := v_context_branch::uuid;
    else
      v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid;
    end if;
  exception when invalid_text_representation then
    raise exception 'branchId must be a valid UUID' using errcode = '22023';
  end;

  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  if v_branch_id is null then raise exception 'default branch is unavailable' using errcode = '55000'; end if;

  v_catalogue_payload := (p_payload - 'requestedPickupAt' - 'branchId')
    || jsonb_build_object('fulfillmentType', 'asap');
  v_quote := private.quote_order_catalogue_legacy(v_catalogue_payload);
  v_state := private.branch_pickup_state_impl(
    v_branch_id,
    case when v_fulfillment_type = 'scheduled' then v_requested_pickup_at else null end,
    true
  );

  if not coalesce((v_state ->> 'valid')::boolean, false) then
    raise exception '%', coalesce(v_state ->> 'message', 'Pickup is unavailable')
      using errcode = '22023', detail = coalesce(v_state ->> 'code', 'PICKUP_UNAVAILABLE');
  end if;

  return v_quote || jsonb_build_object(
    'serverNow', v_state -> 'serverNow',
    'branchId', v_branch_id,
    'branch', v_state -> 'branch',
    'fulfillmentType', v_fulfillment_type,
    'requestedPickupAt', v_requested_pickup_at,
    'schedulePolicy', v_state -> 'policy',
    'pickupAvailability', jsonb_build_object(
      'code', v_state ->> 'code',
      'localServiceDate', v_state -> 'localServiceDate',
      'openAtTarget', v_state -> 'openAtTarget',
      'effectiveSlotCapacityOrders', v_state -> 'effectiveSlotCapacityOrders',
      'slotUsedOrders', v_state -> 'slotUsedOrders',
      'slotRemainingOrders', v_state -> 'slotRemainingOrders'
    )
  );
end;
$$;

revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

comment on function public.quote_order(jsonb) is
  'Authoritative catalogue quote plus branch-local pickup-hours, lead-time, slot and capacity validation. Public wrapper is SECURITY INVOKER.';
