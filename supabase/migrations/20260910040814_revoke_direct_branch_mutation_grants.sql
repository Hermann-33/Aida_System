-- TASK-OPS-002 / Phase 1 branch mutation hardening.
-- Live migration: 20260910040814 revoke_direct_branch_mutation_grants.
-- Privileged branch writes remain RPC/BFF-only; SELECT grants/policies are unchanged.

revoke insert, update, delete on table public.branches from authenticated;
revoke insert, update, delete on table public.employee_branch_assignments from authenticated;

revoke insert, update, delete on table public.branches from anon;
revoke insert, update, delete on table public.employee_branch_assignments from anon;
