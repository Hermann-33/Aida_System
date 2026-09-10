-- TASK-OPS-002 / Phase 1 advisor cleanup.
-- Live migration: 20260910023552 harden_operational_topology_rls_and_indexes.

create policy sales_points_admin_read
on public.sales_points
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy terminals_admin_read
on public.terminals
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy terminal_enrolment_codes_explicit_deny
on private.terminal_enrolment_codes
for all
to anon, authenticated
using (false)
with check (false);

create policy terminal_credentials_explicit_deny
on private.terminal_credentials
for all
to anon, authenticated
using (false)
with check (false);

create index terminal_enrolment_codes_issued_by_idx
  on private.terminal_enrolment_codes (issued_by);

create index orders_sales_point_branch_fk_idx
  on public.orders (sales_point_id, branch_id)
  where sales_point_id is not null;

create index orders_terminal_sales_point_fk_idx
  on public.orders (terminal_id, sales_point_id)
  where terminal_id is not null;
