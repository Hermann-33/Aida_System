-- TASK-DB-001 performance hardening for initial RLS policies.

create index if not exists student_verifications_reviewed_by_idx
on public.student_verifications(reviewed_by);

drop policy if exists "user_profiles_select_own_or_staff" on public.user_profiles;
drop policy if exists "user_profiles_update_own_basic_fields" on public.user_profiles;
drop policy if exists "members_select_own_or_staff" on public.members;
drop policy if exists "student_verifications_select_own_or_staff" on public.student_verifications;
drop policy if exists "student_verifications_insert_own_pending" on public.student_verifications;
drop policy if exists "student_verifications_staff_review" on public.student_verifications;

create policy "user_profiles_select_own_or_staff"
on public.user_profiles
for select
to authenticated
using (user_id = (select auth.uid()) or (select private.is_staff_or_above()));

create policy "user_profiles_update_own_basic_fields"
on public.user_profiles
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

create policy "members_select_own_or_staff"
on public.members
for select
to authenticated
using (user_id = (select auth.uid()) or (select private.is_staff_or_above()));

create policy "student_verifications_select_own_or_staff"
on public.student_verifications
for select
to authenticated
using (
  exists (
    select 1
    from public.members m
    where m.id = student_verifications.member_id
      and m.user_id = (select auth.uid())
  )
  or (select private.is_staff_or_above())
);

create policy "student_verifications_insert_own_pending"
on public.student_verifications
for insert
to authenticated
with check (
  status = 'pending'
  and reviewed_by is null
  and reviewed_at is null
  and exists (
    select 1
    from public.members m
    where m.id = student_verifications.member_id
      and m.user_id = (select auth.uid())
  )
);

create policy "student_verifications_staff_review"
on public.student_verifications
for update
to authenticated
using ((select private.is_staff_or_above()))
with check ((select private.is_staff_or_above()));
