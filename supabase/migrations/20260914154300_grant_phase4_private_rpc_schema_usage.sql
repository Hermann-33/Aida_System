-- Phase 4 hardened public RPC wrappers execute as the caller and delegate only
-- to explicitly granted private helper functions. PostgreSQL requires USAGE on
-- the containing schema before a caller can execute one of those functions.
-- This does not grant table access or EXECUTE on any other private function.

grant usage on schema private to anon, authenticated;

revoke all on function private.default_branch_id() from public, anon, authenticated;
grant execute on function private.default_branch_id() to anon, authenticated;

-- Reassert the deliberately exposed helper boundary used by public Phase 4
-- invoker wrappers. Other private functions retain their existing privileges.
revoke all on function private.quote_order_catalogue_legacy(jsonb) from public, anon, authenticated;
revoke all on function private.get_branch_pickup_state_impl(uuid, timestamptz) from public, anon, authenticated;
revoke all on function private.list_pickup_branches_impl() from public, anon, authenticated;
revoke all on function private.list_branch_pickup_slots_impl(uuid, date) from public, anon, authenticated;

grant execute on function private.quote_order_catalogue_legacy(jsonb) to anon, authenticated;
grant execute on function private.get_branch_pickup_state_impl(uuid, timestamptz) to anon, authenticated;
grant execute on function private.list_pickup_branches_impl() to anon, authenticated;
grant execute on function private.list_branch_pickup_slots_impl(uuid, date) to anon, authenticated;
