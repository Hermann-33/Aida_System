-- TASK-OPS-002 / Phase 1 operational topology read grants.
-- Live migration: 20260910050152 grant_admin_operational_topology_reads.
-- The tables remain FORCE-RLS protected. Existing authenticated SELECT policies
-- expose rows only to Admin/Owner, while anonymous access and all direct DML stay denied.

grant select on table public.sales_points to authenticated;
grant select on table public.terminals to authenticated;

revoke select on table public.sales_points from anon;
revoke select on table public.terminals from anon;
