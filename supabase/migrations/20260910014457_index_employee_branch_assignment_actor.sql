-- TASK-OPS-001 advisor cleanup.

create index employee_branch_assignments_assigned_by_idx
  on public.employee_branch_assignments (assigned_by)
  where assigned_by is not null;
