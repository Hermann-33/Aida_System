-- TASK-DB-001 hardening: keep role helper functions outside the exposed public API schema.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create or replace function private.current_app_role()
returns public.app_user_role
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(
    (select app_role from public.user_profiles where user_id = auth.uid() and disabled_at is null),
    'customer'::public.app_user_role
  );
$$;

create or replace function private.is_staff_or_above()
returns boolean
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  select private.current_app_role() in ('staff', 'admin', 'owner');
$$;

revoke all on function private.current_app_role() from public, anon, authenticated;
revoke all on function private.is_staff_or_above() from public, anon, authenticated;
grant execute on function private.current_app_role() to authenticated;
grant execute on function private.is_staff_or_above() to authenticated;

drop policy if exists "user_profiles_select_own_or_staff" on public.user_profiles;
drop policy if exists "members_select_own_or_staff" on public.members;
drop policy if exists "student_verifications_select_own_or_staff" on public.student_verifications;
drop policy if exists "student_verifications_staff_review" on public.student_verifications;

create policy "user_profiles_select_own_or_staff"
on public.user_profiles
for select
to authenticated
using (user_id = auth.uid() or private.is_staff_or_above());

create policy "members_select_own_or_staff"
on public.members
for select
to authenticated
using (user_id = auth.uid() or private.is_staff_or_above());

create policy "student_verifications_select_own_or_staff"
on public.student_verifications
for select
to authenticated
using (
  exists (
    select 1
    from public.members m
    where m.id = student_verifications.member_id
      and m.user_id = auth.uid()
  )
  or private.is_staff_or_above()
);

create policy "student_verifications_staff_review"
on public.student_verifications
for update
to authenticated
using (private.is_staff_or_above())
with check (private.is_staff_or_above());

drop function if exists public.current_app_role() cascade;
drop function if exists public.is_staff_or_above() cascade;

comment on schema private is 'Non-exposed helper schema for RLS support functions. Do not add to Supabase exposed schemas.';
comment on function private.current_app_role() is 'Returns trusted application role for the authenticated user from public.user_profiles. Used by RLS policies.';
comment on function private.is_staff_or_above() is 'True when authenticated user has staff, admin, or owner role. Used by RLS policies.';
