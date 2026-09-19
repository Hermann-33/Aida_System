-- Phase 4 compatibility: keep the legacy ordering-policy response contract
-- while delegating writes to the branch-owned scheduling authority.

create or replace function public.save_ordering_policy(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_branch_id uuid;
  v_timezone text;
  v_payload jsonb;
  v_result jsonb;
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select private.default_branch_id() into v_branch_id;
  select timezone into v_timezone from public.branches where id = v_branch_id;

  if p_payload ? 'timezone'
     and nullif(p_payload ->> 'timezone', '') is distinct from v_timezone then
    raise exception 'change timezone through branch settings'
      using errcode = '22023', detail = 'BRANCH_TIMEZONE_AUTHORITY';
  end if;

  v_payload := (p_payload - 'timezone') || jsonb_build_object('branchId', v_branch_id);
  v_result := private.save_branch_pickup_configuration_impl(v_payload, (select auth.uid()));

  -- Preserve the pre-Phase-4 flat response shape. New branch-only fields such
  -- as ASAP/capacity/windows remain available through the Phase-4 admin RPCs.
  return jsonb_build_object(
    'serverNow', now(),
    'timezone', v_result #>> '{branch,timezone}',
    'scheduleEnabled', (v_result #>> '{policy,scheduleEnabled}')::boolean,
    'minimumLeadMinutes', (v_result #>> '{policy,minimumLeadMinutes}')::integer,
    'preparationLeadMinutes', (v_result #>> '{policy,preparationLeadMinutes}')::integer,
    'slotIntervalMinutes', (v_result #>> '{policy,slotIntervalMinutes}')::integer,
    'maximumAdvanceDays', (v_result #>> '{policy,maximumAdvanceDays}')::integer
  );
end;
$$;

revoke all on function public.save_ordering_policy(jsonb) from public, anon, authenticated;
grant execute on function public.save_ordering_policy(jsonb) to authenticated;
