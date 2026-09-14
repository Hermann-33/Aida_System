-- TASK-OPS-003 / Phase 2 — covering indexes for new foreign keys.
-- Live migration: 20260912000002 index_shift_cash_foreign_keys.

create index shifts_opened_by_user_idx
  on public.shifts (opened_by_user_id);
create index shifts_sales_point_branch_fk_idx
  on public.shifts (sales_point_id, branch_id);
create index shifts_terminal_sales_point_fk_idx
  on public.shifts (terminal_id, sales_point_id);
create index orders_shift_topology_fk_idx
  on public.orders (shift_id, terminal_id, sales_point_id, branch_id)
  where shift_id is not null;
