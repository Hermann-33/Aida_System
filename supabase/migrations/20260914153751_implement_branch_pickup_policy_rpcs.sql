create or replace function private.initialize_branch_scheduling_impl()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_settings public.order_schedule_settings%rowtype;
begin
  select * into v_settings from public.order_schedule_settings where id = 1;

  insert into public.branch_ordering_policies (
    branch_id, asap_enabled, schedule_enabled, minimum_lead_minutes,
    preparation_lead_minutes, slot_interval_minutes, maximum_advance_days,
    slot_capacity_orders
  ) values (
    new.id, true, coalesce(v_settings.schedule_enabled, true),
    coalesce(v_settings.minimum_lead_minutes, 15),
    coalesce(v_settings.preparation_lead_minutes, 15),
    coalesce(v_settings.slot_interval_minutes, 15),
    coalesce(v_settings.maximum_advance_days, 7), null
  ) on conflict (branch_id) do nothing;

  insert into public.branch_service_windows (branch_id, weekday, is_all_day, is_active)
  select new.id, d.weekday, true, true
  from generate_series(0, 6) as d(weekday)
  on conflict do nothing;

  return new;
end;
$$;

revoke all on function private.initialize_branch_scheduling_impl() from public, anon, authenticated;

create trigger branches_initialize_scheduling
after insert on public.branches
for each row execute function private.initialize_branch_scheduling_impl();

create or replace function private.branch_pickup_state_impl(
  p_branch_id uuid,
  p_requested_pickup_at timestamptz,
  p_check_capacity boolean default true
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch public.branches%rowtype;
  v_policy public.branch_ordering_policies%rowtype;
  v_exception public.branch_service_exceptions%rowtype;
  v_has_exception boolean := false;
  v_target timestamptz := coalesce(p_requested_pickup_at, now());
  v_local timestamp without time zone;
  v_service_date date;
  v_local_time time without time zone;
  v_weekday smallint;
  v_open boolean := false;
  v_capacity integer;
  v_used integer := 0;
  v_valid boolean := true;
  v_code text := 'AVAILABLE';
  v_message text := 'Pickup is available';
  v_prepare_at timestamptz;
begin
  select * into v_branch
  from public.branches
  where id = p_branch_id and is_active;

  if not found then
    return jsonb_build_object('valid', false, 'code', 'BRANCH_UNAVAILABLE', 'message', 'Branch is unavailable for ordering', 'branchId', p_branch_id, 'serverNow', now());
  end if;

  select * into v_policy from public.branch_ordering_policies where branch_id = p_branch_id;
  if not found then
    return jsonb_build_object('valid', false, 'code', 'BRANCH_POLICY_UNAVAILABLE', 'message', 'Branch ordering policy is unavailable', 'branchId', p_branch_id, 'serverNow', now());
  end if;

  if not exists (select 1 from pg_catalog.pg_timezone_names where name = v_branch.timezone) then
    return jsonb_build_object('valid', false, 'code', 'BRANCH_TIMEZONE_INVALID', 'message', 'Branch timezone configuration is invalid', 'branchId', p_branch_id, 'serverNow', now());
  end if;

  v_local := v_target at time zone v_branch.timezone;
  v_service_date := v_local::date;
  v_local_time := v_local::time;
  v_weekday := extract(dow from v_local)::smallint;

  select * into v_exception
  from public.branch_service_exceptions
  where branch_id = p_branch_id and service_date = v_service_date;
  v_has_exception := found;

  if v_has_exception and v_exception.is_closed then
    v_open := false;
  elsif v_has_exception and v_exception.is_all_day then
    v_open := true;
  elsif v_has_exception and v_exception.opens_at is not null and v_exception.closes_at is not null then
    v_open := v_local_time >= v_exception.opens_at and v_local_time < v_exception.closes_at;
  else
    select exists (
      select 1 from public.branch_service_windows w
      where w.branch_id = p_branch_id and w.weekday = v_weekday and w.is_active
        and (w.is_all_day or (v_local_time >= w.opens_at and v_local_time < w.closes_at))
    ) into v_open;
  end if;

  v_capacity := coalesce(case when v_has_exception then v_exception.slot_capacity_orders end, v_policy.slot_capacity_orders);

  if p_requested_pickup_at is null then
    if not v_policy.asap_enabled then
      v_valid := false; v_code := 'ASAP_DISABLED'; v_message := 'ASAP ordering is disabled for this branch';
    elsif not v_open then
      v_valid := false; v_code := 'BRANCH_CLOSED'; v_message := 'Branch is currently closed for pickup';
    end if;
  else
    v_prepare_at := p_requested_pickup_at - make_interval(mins => v_policy.preparation_lead_minutes);
    if not v_policy.schedule_enabled then
      v_valid := false; v_code := 'SCHEDULE_DISABLED'; v_message := 'Scheduled pickup is disabled for this branch';
    elsif p_requested_pickup_at < now() + make_interval(mins => v_policy.minimum_lead_minutes) then
      v_valid := false; v_code := 'PICKUP_LEAD_TIME'; v_message := 'Scheduled pickup does not meet the branch minimum lead time';
    elsif p_requested_pickup_at > now() + make_interval(days => v_policy.maximum_advance_days) then
      v_valid := false; v_code := 'PICKUP_HORIZON'; v_message := 'Scheduled pickup exceeds the branch scheduling horizon';
    elsif extract(second from v_local) <> 0 then
      v_valid := false; v_code := 'PICKUP_SLOT_ALIGNMENT'; v_message := 'Scheduled pickup must align to a whole-minute slot';
    elsif mod(extract(hour from v_local)::integer * 60 + extract(minute from v_local)::integer, v_policy.slot_interval_minutes) <> 0 then
      v_valid := false; v_code := 'PICKUP_SLOT_ALIGNMENT'; v_message := 'Scheduled pickup is not aligned to the branch slot interval';
    elsif not v_open then
      v_valid := false; v_code := 'BRANCH_CLOSED'; v_message := 'Branch is closed at the requested pickup time';
    end if;

    if v_valid and v_capacity is not null then
      select count(*)::integer into v_used
      from public.orders o
      where o.branch_id = p_branch_id and o.fulfillment_type = 'scheduled'
        and o.requested_pickup_at = p_requested_pickup_at and o.status <> 'cancelled';
      if p_check_capacity and v_used >= v_capacity then
        v_valid := false; v_code := 'PICKUP_SLOT_FULL'; v_message := 'Scheduled pickup slot is full';
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'valid', v_valid, 'code', v_code, 'message', v_message, 'serverNow', now(),
    'branchId', v_branch.id,
    'branch', jsonb_build_object('id', v_branch.id, 'code', v_branch.code, 'name', v_branch.name, 'timezone', v_branch.timezone, 'addressText', v_branch.address_text, 'phone', v_branch.phone),
    'localServiceDate', v_service_date, 'openAtTarget', v_open,
    'requestedPickupAt', p_requested_pickup_at, 'prepareAt', v_prepare_at,
    'policy', jsonb_build_object('asapEnabled', v_policy.asap_enabled, 'scheduleEnabled', v_policy.schedule_enabled, 'minimumLeadMinutes', v_policy.minimum_lead_minutes, 'preparationLeadMinutes', v_policy.preparation_lead_minutes, 'slotIntervalMinutes', v_policy.slot_interval_minutes, 'maximumAdvanceDays', v_policy.maximum_advance_days, 'slotCapacityOrders', v_policy.slot_capacity_orders),
    'effectiveSlotCapacityOrders', v_capacity, 'slotUsedOrders', v_used,
    'slotRemainingOrders', case when v_capacity is null then null else greatest(v_capacity - v_used, 0) end
  );
end;
$$;

revoke all on function private.branch_pickup_state_impl(uuid, timestamptz, boolean) from public, anon, authenticated;

create or replace function public.get_branch_pickup_state(p_branch_id uuid default null, p_requested_pickup_at timestamptz default null)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_branch_id uuid := p_branch_id;
begin
  if v_branch_id is null then select private.default_branch_id() into v_branch_id; end if;
  return private.branch_pickup_state_impl(v_branch_id, p_requested_pickup_at, true);
end;
$$;

create or replace function public.list_pickup_branches()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', b.id, 'code', b.code, 'name', b.name, 'timezone', b.timezone,
    'addressText', b.address_text, 'phone', b.phone, 'isDefault', b.is_default,
    'policy', jsonb_build_object('asapEnabled', p.asap_enabled, 'scheduleEnabled', p.schedule_enabled, 'minimumLeadMinutes', p.minimum_lead_minutes, 'preparationLeadMinutes', p.preparation_lead_minutes, 'slotIntervalMinutes', p.slot_interval_minutes, 'maximumAdvanceDays', p.maximum_advance_days, 'slotCapacityOrders', p.slot_capacity_orders)
  ) order by b.is_default desc, b.code), '[]'::jsonb)
  from public.branches b join public.branch_ordering_policies p on p.branch_id = b.id where b.is_active;
$$;

create or replace function public.list_branch_pickup_slots(p_branch_id uuid, p_service_date date)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_branch public.branches%rowtype; v_policy public.branch_ordering_policies%rowtype;
  v_minute integer; v_local timestamp without time zone; v_pickup_at timestamptz;
  v_state jsonb; v_slots jsonb := '[]'::jsonb;
begin
  select * into v_branch from public.branches where id = p_branch_id and is_active;
  if not found then raise exception 'branch is unavailable for ordering' using errcode = '22023', detail = 'BRANCH_UNAVAILABLE'; end if;
  select * into v_policy from public.branch_ordering_policies where branch_id = p_branch_id;
  if not found then raise exception 'branch ordering policy is unavailable' using errcode = '55000', detail = 'BRANCH_POLICY_UNAVAILABLE'; end if;
  for v_minute in 0..1439 by v_policy.slot_interval_minutes loop
    v_local := p_service_date::timestamp + make_interval(mins => v_minute);
    v_pickup_at := v_local at time zone v_branch.timezone;
    v_state := private.branch_pickup_state_impl(p_branch_id, v_pickup_at, true);
    if coalesce((v_state ->> 'valid')::boolean, false) then
      v_slots := v_slots || jsonb_build_array(jsonb_build_object('pickupAt', v_pickup_at, 'prepareAt', v_state -> 'prepareAt', 'remainingOrders', v_state -> 'slotRemainingOrders'));
    end if;
  end loop;
  return jsonb_build_object('serverNow', now(), 'branchId', p_branch_id, 'serviceDate', p_service_date, 'timezone', v_branch.timezone, 'slotIntervalMinutes', v_policy.slot_interval_minutes, 'slots', v_slots);
end;
$$;

revoke all on function public.get_branch_pickup_state(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.list_pickup_branches() from public, anon, authenticated;
revoke all on function public.list_branch_pickup_slots(uuid, date) from public, anon, authenticated;
grant execute on function public.get_branch_pickup_state(uuid, timestamptz) to anon, authenticated;
grant execute on function public.list_pickup_branches() to anon, authenticated;
grant execute on function public.list_branch_pickup_slots(uuid, date) to anon, authenticated;

create or replace function private.admin_branch_pickup_configuration_impl(p_branch_id uuid, p_actor_user_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_branch public.branches%rowtype; v_policy public.branch_ordering_policies%rowtype;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501', detail = 'ADMIN_REQUIRED';
  end if;
  select * into v_branch from public.branches where id = p_branch_id;
  if not found then raise exception 'branch not found' using errcode = 'P0002'; end if;
  select * into v_policy from public.branch_ordering_policies where branch_id = p_branch_id;
  if not found then raise exception 'branch ordering policy not found' using errcode = 'P0002'; end if;
  return jsonb_build_object(
    'branch', jsonb_build_object('id', v_branch.id, 'code', v_branch.code, 'name', v_branch.name, 'timezone', v_branch.timezone, 'isActive', v_branch.is_active, 'isDefault', v_branch.is_default),
    'policy', jsonb_build_object('asapEnabled', v_policy.asap_enabled, 'scheduleEnabled', v_policy.schedule_enabled, 'minimumLeadMinutes', v_policy.minimum_lead_minutes, 'preparationLeadMinutes', v_policy.preparation_lead_minutes, 'slotIntervalMinutes', v_policy.slot_interval_minutes, 'maximumAdvanceDays', v_policy.maximum_advance_days, 'slotCapacityOrders', v_policy.slot_capacity_orders),
    'windows', coalesce((select jsonb_agg(jsonb_build_object('id', w.id, 'weekday', w.weekday, 'isAllDay', w.is_all_day, 'opensAt', w.opens_at, 'closesAt', w.closes_at, 'isActive', w.is_active) order by w.weekday, w.opens_at nulls first, w.id) from public.branch_service_windows w where w.branch_id = p_branch_id), '[]'::jsonb),
    'exceptions', coalesce((select jsonb_agg(jsonb_build_object('serviceDate', e.service_date, 'isClosed', e.is_closed, 'isAllDay', e.is_all_day, 'opensAt', e.opens_at, 'closesAt', e.closes_at, 'slotCapacityOrders', e.slot_capacity_orders) order by e.service_date) from public.branch_service_exceptions e where e.branch_id = p_branch_id and e.service_date >= (now() at time zone v_branch.timezone)::date - 31), '[]'::jsonb)
  );
end;
$$;

create or replace function private.save_branch_pickup_configuration_impl(p_payload jsonb, p_actor_user_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_branch_id uuid; v_current public.branch_ordering_policies%rowtype; v_windows jsonb; v_window jsonb;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode = '42501', detail = 'ADMIN_REQUIRED'; end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then raise exception 'pickup configuration must be a JSON object' using errcode = '22023'; end if;
  begin v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid; exception when invalid_text_representation then raise exception 'branchId must be a valid UUID' using errcode = '22023'; end;
  if v_branch_id is null then raise exception 'branchId is required' using errcode = '22023'; end if;
  select * into v_current from public.branch_ordering_policies where branch_id = v_branch_id for update;
  if not found then raise exception 'branch ordering policy not found' using errcode = 'P0002'; end if;
  update public.branch_ordering_policies
  set asap_enabled = coalesce((p_payload ->> 'asapEnabled')::boolean, v_current.asap_enabled),
      schedule_enabled = coalesce((p_payload ->> 'scheduleEnabled')::boolean, v_current.schedule_enabled),
      minimum_lead_minutes = coalesce((p_payload ->> 'minimumLeadMinutes')::integer, v_current.minimum_lead_minutes),
      preparation_lead_minutes = coalesce((p_payload ->> 'preparationLeadMinutes')::integer, v_current.preparation_lead_minutes),
      slot_interval_minutes = coalesce((p_payload ->> 'slotIntervalMinutes')::integer, v_current.slot_interval_minutes),
      maximum_advance_days = coalesce((p_payload ->> 'maximumAdvanceDays')::integer, v_current.maximum_advance_days),
      slot_capacity_orders = case when p_payload ? 'slotCapacityOrders' then nullif(p_payload ->> 'slotCapacityOrders', '')::integer else v_current.slot_capacity_orders end
  where branch_id = v_branch_id;
  if p_payload ? 'windows' then
    v_windows := p_payload -> 'windows';
    if jsonb_typeof(v_windows) <> 'array' then raise exception 'windows must be a JSON array' using errcode = '22023'; end if;
    delete from public.branch_service_windows where branch_id = v_branch_id;
    for v_window in select value from jsonb_array_elements(v_windows) loop
      insert into public.branch_service_windows (branch_id, weekday, is_all_day, opens_at, closes_at, is_active)
      values (v_branch_id, (v_window ->> 'weekday')::smallint, coalesce((v_window ->> 'isAllDay')::boolean, false), nullif(v_window ->> 'opensAt', '')::time, nullif(v_window ->> 'closesAt', '')::time, coalesce((v_window ->> 'isActive')::boolean, true));
    end loop;
  end if;
  return private.admin_branch_pickup_configuration_impl(v_branch_id, p_actor_user_id);
end;
$$;

create or replace function private.save_branch_service_exception_impl(p_payload jsonb, p_actor_user_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_branch_id uuid; v_service_date date;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode = '42501', detail = 'ADMIN_REQUIRED'; end if;
  begin v_branch_id := nullif(p_payload ->> 'branchId', '')::uuid; v_service_date := nullif(p_payload ->> 'serviceDate', '')::date; exception when others then raise exception 'valid branchId and serviceDate are required' using errcode = '22023'; end;
  if v_branch_id is null or v_service_date is null then raise exception 'branchId and serviceDate are required' using errcode = '22023'; end if;
  if not exists (select 1 from public.branches where id = v_branch_id) then raise exception 'branch not found' using errcode = 'P0002'; end if;
  insert into public.branch_service_exceptions (branch_id, service_date, is_closed, is_all_day, opens_at, closes_at, slot_capacity_orders)
  values (v_branch_id, v_service_date, coalesce((p_payload ->> 'isClosed')::boolean, false), coalesce((p_payload ->> 'isAllDay')::boolean, false), nullif(p_payload ->> 'opensAt', '')::time, nullif(p_payload ->> 'closesAt', '')::time, nullif(p_payload ->> 'slotCapacityOrders', '')::integer)
  on conflict (branch_id, service_date) do update set is_closed = excluded.is_closed, is_all_day = excluded.is_all_day, opens_at = excluded.opens_at, closes_at = excluded.closes_at, slot_capacity_orders = excluded.slot_capacity_orders;
  return private.admin_branch_pickup_configuration_impl(v_branch_id, p_actor_user_id);
end;
$$;

create or replace function private.delete_branch_service_exception_impl(p_branch_id uuid, p_service_date date, p_actor_user_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode = '42501', detail = 'ADMIN_REQUIRED'; end if;
  delete from public.branch_service_exceptions where branch_id = p_branch_id and service_date = p_service_date;
  return private.admin_branch_pickup_configuration_impl(p_branch_id, p_actor_user_id);
end;
$$;

revoke all on function private.admin_branch_pickup_configuration_impl(uuid, uuid) from public, anon, authenticated;
revoke all on function private.save_branch_pickup_configuration_impl(jsonb, uuid) from public, anon, authenticated;
revoke all on function private.save_branch_service_exception_impl(jsonb, uuid) from public, anon, authenticated;
revoke all on function private.delete_branch_service_exception_impl(uuid, date, uuid) from public, anon, authenticated;
grant execute on function private.admin_branch_pickup_configuration_impl(uuid, uuid) to authenticated;
grant execute on function private.save_branch_pickup_configuration_impl(jsonb, uuid) to authenticated;
grant execute on function private.save_branch_service_exception_impl(jsonb, uuid) to authenticated;
grant execute on function private.delete_branch_service_exception_impl(uuid, date, uuid) to authenticated;

create or replace function public.get_admin_branch_pickup_configuration(p_branch_id uuid)
returns jsonb language sql stable security invoker set search_path = public, pg_temp as $$ select private.admin_branch_pickup_configuration_impl(p_branch_id, (select auth.uid())); $$;
create or replace function public.save_branch_pickup_configuration(p_payload jsonb)
returns jsonb language sql security invoker set search_path = public, pg_temp as $$ select private.save_branch_pickup_configuration_impl(p_payload, (select auth.uid())); $$;
create or replace function public.save_branch_service_exception(p_payload jsonb)
returns jsonb language sql security invoker set search_path = public, pg_temp as $$ select private.save_branch_service_exception_impl(p_payload, (select auth.uid())); $$;
create or replace function public.delete_branch_service_exception(p_branch_id uuid, p_service_date date)
returns jsonb language sql security invoker set search_path = public, pg_temp as $$ select private.delete_branch_service_exception_impl(p_branch_id, p_service_date, (select auth.uid())); $$;

revoke all on function public.get_admin_branch_pickup_configuration(uuid) from public, anon, authenticated;
revoke all on function public.save_branch_pickup_configuration(jsonb) from public, anon, authenticated;
revoke all on function public.save_branch_service_exception(jsonb) from public, anon, authenticated;
revoke all on function public.delete_branch_service_exception(uuid, date) from public, anon, authenticated;
grant execute on function public.get_admin_branch_pickup_configuration(uuid) to authenticated;
grant execute on function public.save_branch_pickup_configuration(jsonb) to authenticated;
grant execute on function public.save_branch_service_exception(jsonb) to authenticated;
grant execute on function public.delete_branch_service_exception(uuid, date) to authenticated;
