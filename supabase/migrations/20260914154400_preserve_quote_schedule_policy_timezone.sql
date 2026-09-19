-- Phase 4 quote compatibility: preserve the pre-Phase-4 schedulePolicy timezone
-- field while keeping the hardened public endpoint SECURITY INVOKER.

alter function public.quote_order(jsonb) set schema private;
alter function private.quote_order(jsonb) rename to quote_order_phase4_impl;

revoke all on function private.quote_order_phase4_impl(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_phase4_impl(jsonb) to anon, authenticated;

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

revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

comment on function public.quote_order(jsonb) is
  'Authoritative catalogue quote plus branch-local pickup validation. Preserves legacy schedulePolicy.timezone contract; public wrapper is SECURITY INVOKER.';
