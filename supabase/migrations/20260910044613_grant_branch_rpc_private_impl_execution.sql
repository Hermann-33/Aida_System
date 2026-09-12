-- TASK-OPS-002 / Phase 1 branch RPC execution hardening.
-- Live migration: 20260910044613 grant_branch_rpc_private_impl_execution.
-- Public branch mutation RPCs are SECURITY INVOKER wrappers. Their private
-- SECURITY DEFINER implementations remain authenticated-only and verify that
-- the supplied actor matches auth.uid() and is Admin/Owner.

grant execute on function private.save_branch_impl(jsonb, uuid) to authenticated;
grant execute on function private.save_employee_branch_assignments_impl(uuid, uuid[], uuid) to authenticated;

revoke execute on function private.save_branch_impl(jsonb, uuid) from anon;
revoke execute on function private.save_employee_branch_assignments_impl(uuid, uuid[], uuid) from anon;
