-- The hardened quote endpoint is SECURITY INVOKER and therefore the caller
-- needs EXECUTE on the exact private scheduling helper it delegates to. Schema
-- USAGE is granted separately; no table access or unrelated function execution
-- is granted here.

revoke all on function private.branch_pickup_state_impl(uuid, timestamptz, boolean)
  from public, anon, authenticated;
grant execute on function private.branch_pickup_state_impl(uuid, timestamptz, boolean)
  to anon, authenticated;
