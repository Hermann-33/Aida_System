-- TASK-PRIVACY-001 / Phase 3 deletion edge-case regression.
-- Transactional: verifies whole-account deletion removes student PII through
-- the trusted member cascade and remains available when membership provisioning
-- is missing/degraded. No synthetic state survives.

begin;

-- Student-verification cascade.
insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values (
  '52000000-0000-0000-0000-000000000001',
  'privacy-student@example.test',
  '{}'::jsonb,
  now(),
  now()
);

insert into public.student_verifications (member_id, campus_id)
select id, 'PHASE3-CAMPUS-DELETE-001'
from public.members
where user_id = '52000000-0000-0000-0000-000000000001';

do $$
begin
  if not exists (
    select 1
    from public.student_verifications
    where campus_id = 'PHASE3-CAMPUS-DELETE-001'
  ) then
    raise exception 'student verification fixture was not created';
  end if;
end;
$$;

set local role authenticated;

select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', '52000000-0000-0000-0000-000000000001'::uuid,
    'role', 'authenticated'
  )::text,
  true
);

select public.delete_own_account();

reset role;

do $$
begin
  if exists (
    select 1
    from public.student_verifications
    where campus_id = 'PHASE3-CAMPUS-DELETE-001'
  ) then
    raise exception 'student verification survived whole-account deletion';
  end if;

  if exists (
    select 1
    from public.members
    where user_id = '52000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'student member survived whole-account deletion';
  end if;

  if exists (
    select 1
    from public.user_profiles
    where user_id = '52000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'student profile survived whole-account deletion';
  end if;

  if exists (
    select 1
    from auth.users
    where id = '52000000-0000-0000-0000-000000000001'
  ) then
    raise exception 'student Auth identity survived whole-account deletion';
  end if;
end;
$$;

-- Degraded account: the trusted customer profile exists but its membership row
-- has already disappeared. Whole-account deletion must still be available.
insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values (
  '52000000-0000-0000-0000-000000000002',
  'privacy-degraded@example.test',
  '{}'::jsonb,
  now(),
  now()
);

delete from public.members
where user_id = '52000000-0000-0000-0000-000000000002';

do $$
begin
  if not exists (
    select 1 from public.user_profiles
    where user_id = '52000000-0000-0000-0000-000000000002'
      and app_role = 'customer'
  ) then
    raise exception 'degraded customer profile fixture is missing';
  end if;

  if exists (
    select 1 from public.members
    where user_id = '52000000-0000-0000-0000-000000000002'
  ) then
    raise exception 'degraded customer member fixture still exists';
  end if;
end;
$$;

set local role authenticated;

select set_config(
  'request.jwt.claims',
  jsonb_build_object(
    'sub', '52000000-0000-0000-0000-000000000002'::uuid,
    'role', 'authenticated'
  )::text,
  true
);

select public.delete_own_account();

reset role;

do $$
begin
  if exists (
    select 1 from public.user_profiles
    where user_id = '52000000-0000-0000-0000-000000000002'
  ) then
    raise exception 'degraded customer profile survived whole-account deletion';
  end if;

  if exists (
    select 1 from auth.users
    where id = '52000000-0000-0000-0000-000000000002'
  ) then
    raise exception 'degraded customer Auth identity survived whole-account deletion';
  end if;
end;
$$;

rollback;
