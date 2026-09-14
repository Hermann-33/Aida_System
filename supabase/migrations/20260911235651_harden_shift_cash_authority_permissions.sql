-- TASK-OPS-003 / Phase 2 — grants and API hardening.
-- Live migration: 20260911235651 harden_shift_cash_authority_permissions.

revoke all on function private.prevent_cash_movement_mutation() from public, anon, authenticated;
revoke all on function private.expected_shift_cash_sen(uuid) from public, anon, authenticated;
revoke all on function private.shift_cash_breakdown_impl(uuid) from public, anon, authenticated;
revoke all on function private.shift_snapshot_impl(uuid, uuid) from public, anon, authenticated;
revoke all on function private.current_terminal_shift_impl(text, uuid) from public, anon, authenticated;
revoke all on function private.require_open_shift_impl(text, uuid) from public, anon, authenticated;
revoke all on function private.open_shift_impl(text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.transition_shift_impl(uuid, text, text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.record_cash_movement_impl(uuid, text, text, bigint, text, uuid) from public, anon, authenticated;
revoke all on function private.shift_reconciliation_impl(uuid, text, uuid) from public, anon, authenticated;
revoke all on function private.close_shift_impl(uuid, text, bigint, text, text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.list_admin_shifts_impl(integer, uuid) from public, anon, authenticated;
revoke all on function private.finalize_pos_order_shift_impl(uuid, uuid, text, text, uuid) from public, anon, authenticated;

grant usage on schema private to authenticated;
grant execute on function private.current_terminal_shift_impl(text, uuid) to authenticated;
grant execute on function private.require_open_shift_impl(text, uuid) to authenticated;
grant execute on function private.open_shift_impl(text, bigint, uuid) to authenticated;
grant execute on function private.transition_shift_impl(uuid, text, text, bigint, uuid) to authenticated;
grant execute on function private.record_cash_movement_impl(uuid, text, text, bigint, text, uuid) to authenticated;
grant execute on function private.shift_reconciliation_impl(uuid, text, uuid) to authenticated;
grant execute on function private.close_shift_impl(uuid, text, bigint, text, text, bigint, uuid) to authenticated;
grant execute on function private.list_admin_shifts_impl(integer, uuid) to authenticated;
grant execute on function private.finalize_pos_order_shift_impl(uuid, uuid, text, text, uuid) to authenticated;

revoke all on function public.get_current_shift(text) from public, anon, authenticated;
revoke all on function public.open_shift(text, bigint) from public, anon, authenticated;
revoke all on function public.lock_shift(uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.resume_shift(uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.record_cash_movement(uuid, text, text, bigint, text) from public, anon, authenticated;
revoke all on function public.get_shift_reconciliation(uuid, text) from public, anon, authenticated;
revoke all on function public.close_shift(uuid, text, bigint, text, text, bigint) from public, anon, authenticated;
revoke all on function public.list_admin_shifts(integer) from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb) from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb, text) from public, anon, authenticated;
revoke all on function public.place_customer_order(jsonb) from public, anon, authenticated;

grant execute on function public.get_current_shift(text) to authenticated;
grant execute on function public.open_shift(text, bigint) to authenticated;
grant execute on function public.lock_shift(uuid, text, bigint) to authenticated;
grant execute on function public.resume_shift(uuid, text, bigint) to authenticated;
grant execute on function public.record_cash_movement(uuid, text, text, bigint, text) to authenticated;
grant execute on function public.get_shift_reconciliation(uuid, text) to authenticated;
grant execute on function public.close_shift(uuid, text, bigint, text, text, bigint) to authenticated;
grant execute on function public.list_admin_shifts(integer) to authenticated;
grant execute on function public.place_pos_order(jsonb, text) to authenticated;
grant execute on function public.place_customer_order(jsonb) to authenticated;

do $$
begin
  if has_table_privilege('authenticated', 'public.shifts', 'insert')
     or has_table_privilege('authenticated', 'public.shifts', 'update')
     or has_table_privilege('authenticated', 'public.shifts', 'delete')
     or has_table_privilege('authenticated', 'public.cash_movements', 'insert')
     or has_table_privilege('authenticated', 'public.cash_movements', 'update')
     or has_table_privilege('authenticated', 'public.cash_movements', 'delete') then
    raise exception 'authenticated role unexpectedly has direct Phase 2 mutation grants';
  end if;

  if has_function_privilege('anon', 'public.open_shift(text,bigint)'::regprocedure, 'execute')
     or has_function_privilege('anon', 'public.place_pos_order(jsonb,text)'::regprocedure, 'execute') then
    raise exception 'anonymous role unexpectedly has Phase 2 operational capability';
  end if;
end;
$$;
