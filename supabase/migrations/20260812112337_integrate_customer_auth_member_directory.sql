-- TASK-AUTH-001: customer signup hardening + admin member directory.
-- Frontends remain untrusted. Signup metadata may express a student claim,
-- but cannot assign roles, verification, member codes, or active state.

create or replace function private.is_admin_or_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.user_profiles profile
    where profile.user_id = (select auth.uid())
      and profile.app_role in ('admin', 'owner')
      and profile.disabled_at is null
  );
$$;

revoke all on function private.is_admin_or_owner() from public;
grant execute on function private.is_admin_or_owner() to authenticated;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
  v_is_student boolean;
begin
  v_display_name := nullif(
    trim(
      coalesce(
        new.raw_user_meta_data ->> 'display_name',
        new.raw_user_meta_data ->> 'full_name',
        split_part(coalesce(new.email, ''), '@', 1)
      )
    ),
    ''
  );

  v_is_student := lower(coalesce(new.raw_user_meta_data ->> 'is_student', 'false')) = 'true';

  insert into public.user_profiles (
    user_id,
    email,
    display_name,
    app_role
  )
  values (
    new.id,
    lower(new.email),
    v_display_name,
    'customer'
  )
  on conflict (user_id) do update
    set email = excluded.email,
        display_name = coalesce(public.user_profiles.display_name, excluded.display_name),
        updated_at = now();

  insert into public.members (
    user_id,
    member_type,
    student_status
  )
  values (
    new.id,
    case
      when v_is_student then 'student'::public.member_type
      else 'standard'::public.member_type
    end,
    case
      when v_is_student then 'pending'::public.student_verification_status
      else 'not_submitted'::public.student_verification_status
    end
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;

-- Ordinary POS staff must not receive a bulk customer directory. Later POS
-- lookup gets a bounded capability/RPC. Customers retain owner-only reads;
-- admin/owner accounts can support the Admin Members surface.
drop policy if exists user_profiles_select_own_or_staff on public.user_profiles;
drop policy if exists user_profiles_select_own_or_admin on public.user_profiles;
create policy user_profiles_select_own_or_admin
on public.user_profiles
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or (select private.is_admin_or_owner())
);

drop policy if exists members_select_own_or_staff on public.members;
drop policy if exists members_select_own_or_admin on public.members;
create policy members_select_own_or_admin
on public.members
for select
to authenticated
using (
  (select auth.uid()) = user_id
  or (select private.is_admin_or_owner())
);

create or replace function public.list_admin_members()
returns table (
  member_id uuid,
  user_id uuid,
  member_code text,
  display_name text,
  email text,
  member_type public.member_type,
  student_status public.student_verification_status,
  is_active boolean,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then
    raise exception 'forbidden'
      using errcode = '42501';
  end if;

  return query
    select
      member.id,
      member.user_id,
      member.member_code,
      profile.display_name,
      profile.email::text,
      member.member_type,
      member.student_status,
      member.is_active,
      member.created_at
    from public.members member
    join public.user_profiles profile on profile.user_id = member.user_id
    order by member.created_at desc, member.id;
end;
$$;

revoke all on function public.list_admin_members() from public;
revoke all on function public.list_admin_members() from anon;
grant execute on function public.list_admin_members() to authenticated;
