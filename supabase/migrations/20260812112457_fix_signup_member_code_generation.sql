-- TASK-AUTH-001 corrective migration.
-- Restore explicit server-side member code generation in the auth trigger.

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
  v_display_name := nullif(trim(coalesce(
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'full_name',
    split_part(coalesce(new.email, ''), '@', 1)
  )), '');
  v_is_student := lower(coalesce(new.raw_user_meta_data ->> 'is_student', 'false')) = 'true';

  insert into public.user_profiles (user_id, email, display_name, app_role)
  values (new.id, lower(new.email), v_display_name, 'customer')
  on conflict (user_id) do update
    set email = excluded.email,
        display_name = coalesce(public.user_profiles.display_name, excluded.display_name),
        updated_at = now();

  insert into public.members (user_id, member_code, member_type, student_status)
  values (
    new.id,
    public.generate_member_code(),
    case when v_is_student then 'student'::public.member_type else 'standard'::public.member_type end,
    case when v_is_student then 'pending'::public.student_verification_status else 'not_submitted'::public.student_verification_status end
  )
  on conflict (user_id) do nothing;

  return new;
end;
$$;
