-- TASK-AUTH-001 security hardening.
-- Keep RLS in force when the authenticated admin directory RPC reads member data.

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
security invoker
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
      member.active,
      member.created_at
    from public.members member
    join public.user_profiles profile on profile.user_id = member.user_id
    order by member.created_at desc, member.id;
end;
$$;

revoke all on function public.list_admin_members() from public;
revoke all on function public.list_admin_members() from anon;
grant execute on function public.list_admin_members() to authenticated;
