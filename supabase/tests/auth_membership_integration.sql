-- TASK-AUTH-001 integration checks.
-- Run against a disposable database after migrations.

begin;

insert into auth.users (
  id,
  email,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'standard@example.test',
    '{"display_name":"Standard Member","is_student":false,"app_role":"owner","member_code":"FORGED"}'::jsonb,
    now(),
    now()
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'student@example.test',
    '{"display_name":"Student Member","is_student":true,"app_role":"owner","student_status":"verified","member_code":"FORGED"}'::jsonb,
    now(),
    now()
  );

do $$
declare
  v_standard public.members%rowtype;
  v_student public.members%rowtype;
  v_role public.app_user_role;
begin
  select * into strict v_standard
  from public.members
  where user_id = '10000000-0000-0000-0000-000000000001';

  if v_standard.member_type <> 'standard'
     or v_standard.student_status <> 'not_submitted'
     or v_standard.member_code = 'FORGED' then
    raise exception 'standard signup provisioning failed';
  end if;

  select * into strict v_student
  from public.members
  where user_id = '10000000-0000-0000-0000-000000000002';

  if v_student.member_type <> 'student'
     or v_student.student_status <> 'pending'
     or v_student.member_code = 'FORGED' then
    raise exception 'student signup provisioning/tamper protection failed';
  end if;

  select app_role into strict v_role
  from public.user_profiles
  where user_id = '10000000-0000-0000-0000-000000000002';

  if v_role <> 'customer' then
    raise exception 'signup metadata escalated app_role';
  end if;
end;
$$;

select 'admin member directory exists and is not executable by anon' as check_name
where to_regprocedure('public.list_admin_members()') is not null
  and not has_function_privilege('anon', 'public.list_admin_members()', 'execute')
  and has_function_privilege('authenticated', 'public.list_admin_members()', 'execute');

select 'admin helper is private' as check_name
where to_regprocedure('private.is_admin_or_owner()') is not null
  and to_regprocedure('public.is_admin_or_owner()') is null;

rollback;
