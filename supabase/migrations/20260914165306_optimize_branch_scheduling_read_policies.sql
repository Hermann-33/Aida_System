drop policy if exists branch_ordering_policies_active_read on public.branch_ordering_policies;
drop policy if exists branch_ordering_policies_admin_read on public.branch_ordering_policies;
drop policy if exists branch_service_windows_active_read on public.branch_service_windows;
drop policy if exists branch_service_windows_admin_read on public.branch_service_windows;
drop policy if exists branch_service_exceptions_active_read on public.branch_service_exceptions;
drop policy if exists branch_service_exceptions_admin_read on public.branch_service_exceptions;

create policy branch_ordering_policies_anon_active_read
on public.branch_ordering_policies
for select
to anon
using (exists (
  select 1 from public.branches b
  where b.id = branch_ordering_policies.branch_id and b.is_active
));

create policy branch_ordering_policies_authenticated_read
on public.branch_ordering_policies
for select
to authenticated
using (
  exists (
    select 1 from public.branches b
    where b.id = branch_ordering_policies.branch_id and b.is_active
  )
  or (select private.is_admin_or_owner())
);

create policy branch_service_windows_anon_active_read
on public.branch_service_windows
for select
to anon
using (exists (
  select 1 from public.branches b
  where b.id = branch_service_windows.branch_id and b.is_active
));

create policy branch_service_windows_authenticated_read
on public.branch_service_windows
for select
to authenticated
using (
  exists (
    select 1 from public.branches b
    where b.id = branch_service_windows.branch_id and b.is_active
  )
  or (select private.is_admin_or_owner())
);

create policy branch_service_exceptions_anon_active_read
on public.branch_service_exceptions
for select
to anon
using (exists (
  select 1 from public.branches b
  where b.id = branch_service_exceptions.branch_id and b.is_active
));

create policy branch_service_exceptions_authenticated_read
on public.branch_service_exceptions
for select
to authenticated
using (
  exists (
    select 1 from public.branches b
    where b.id = branch_service_exceptions.branch_id and b.is_active
  )
  or (select private.is_admin_or_owner())
);
