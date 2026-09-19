-- Reconcile the live Phase 4 RPC hardening history with clean migration replay.
-- Earlier live changes were applied in fewer migration entries than the canonical
-- repository split. This migration is intentionally idempotent across both shapes
-- and makes the final RPC/security contract identical.

do $$
begin
  if to_regprocedure('private.get_branch_pickup_state_impl(uuid,timestamptz)') is null
     and to_regprocedure('public.get_branch_pickup_state(uuid,timestamptz)') is not null then
    alter function public.get_branch_pickup_state(uuid, timestamptz) set schema private;
    alter function private.get_branch_pickup_state(uuid, timestamptz) rename to get_branch_pickup_state_impl;
  end if;

  if to_regprocedure('private.list_pickup_branches_impl()') is null
     and to_regprocedure('public.list_pickup_branches()') is not null then
    alter function public.list_pickup_branches() set schema private;
    alter function private.list_pickup_branches() rename to list_pickup_branches_impl;
  end if;

  if to_regprocedure('private.list_branch_pickup_slots_impl(uuid,date)') is null
     and to_regprocedure('public.list_branch_pickup_slots(uuid,date)') is not null then
    alter function public.list_branch_pickup_slots(uuid, date) set schema private;
    alter function private.list_branch_pickup_slots(uuid, date) rename to list_branch_pickup_slots_impl;
  end if;

  if to_regprocedure('private.quote_order_phase4_impl(jsonb)') is null
     and to_regprocedure('public.quote_order(jsonb)') is not null then
    alter function public.quote_order(jsonb) set schema private;
    alter function private.quote_order(jsonb) rename to quote_order_phase4_impl;
  end if;
end;
$$;

grant usage on schema private to anon, authenticated;

revoke all on function private.default_branch_id() from public, anon, authenticated;
grant execute on function private.default_branch_id() to anon, authenticated;
revoke all on function private.quote_order_catalogue_legacy(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_catalogue_legacy(jsonb) to anon, authenticated;
revoke all on function private.get_branch_pickup_state_impl(uuid, timestamptz) from public, anon, authenticated;
grant execute on function private.get_branch_pickup_state_impl(uuid, timestamptz) to anon, authenticated;
revoke all on function private.list_pickup_branches_impl() from public, anon, authenticated;
grant execute on function private.list_pickup_branches_impl() to anon, authenticated;
revoke all on function private.list_branch_pickup_slots_impl(uuid, date) from public, anon, authenticated;
grant execute on function private.list_branch_pickup_slots_impl(uuid, date) to anon, authenticated;
revoke all on function private.branch_pickup_state_impl(uuid, timestamptz, boolean) from public, anon, authenticated;
grant execute on function private.branch_pickup_state_impl(uuid, timestamptz, boolean) to anon, authenticated;
revoke all on function private.quote_order_phase4_impl(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_phase4_impl(jsonb) to anon, authenticated;

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

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_quote jsonb;
  v_timezone text;
begin
  v_quote := private.quote_order_phase4_impl(p_payload);
  v_timezone := v_quote #>> '{branch,timezone}';

  return jsonb_set(
    v_quote,
    '{schedulePolicy}',
    coalesce(v_quote -> 'schedulePolicy', '{}'::jsonb)
      || jsonb_build_object('timezone', v_timezone),
    true
  );
end;
$$;

revoke all on function public.get_branch_pickup_state(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.list_pickup_branches() from public, anon, authenticated;
revoke all on function public.list_branch_pickup_slots(uuid, date) from public, anon, authenticated;
revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.get_branch_pickup_state(uuid, timestamptz) to anon, authenticated;
grant execute on function public.list_pickup_branches() to anon, authenticated;
grant execute on function public.list_branch_pickup_slots(uuid, date) to anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;
