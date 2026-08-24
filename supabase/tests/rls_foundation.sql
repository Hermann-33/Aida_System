-- TASK-DB-001 RLS foundation checks.
-- Run against a disposable local database after `supabase db reset`.
-- These checks are intentionally lightweight and do not replace integration tests.

begin;

-- Schema shape checks.
select 'user_profiles exists' as check_name
where to_regclass('public.user_profiles') is not null;

select 'members exists' as check_name
where to_regclass('public.members') is not null;

select 'student_verifications exists' as check_name
where to_regclass('public.student_verifications') is not null;

select 'all exposed foundation tables have rls enabled and forced' as check_name
where not exists (
  select 1
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('user_profiles', 'members', 'student_verifications')
    and (not c.relrowsecurity or not c.relforcerowsecurity)
);

select 'anon has no direct table privileges' as check_name
where not exists (
  select 1
  from information_schema.table_privileges
  where table_schema = 'public'
    and table_name in ('user_profiles', 'members', 'student_verifications')
    and grantee = 'anon'
);

select 'private role helpers are outside exposed public schema' as check_name
where to_regprocedure('private.current_app_role()') is not null
  and to_regprocedure('private.is_staff_or_above()') is not null
  and to_regprocedure('public.current_app_role()') is null
  and to_regprocedure('public.is_staff_or_above()') is null;

select 'expected policy count' as check_name
where (
  select count(*)
  from pg_policies
  where schemaname = 'public'
    and tablename in ('user_profiles', 'members', 'student_verifications')
) = 6;

rollback;
