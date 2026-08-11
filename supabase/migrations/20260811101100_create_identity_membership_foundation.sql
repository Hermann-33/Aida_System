-- TASK-DB-001: AIDA Café identity and membership foundation
-- Trusted boundary: Supabase Auth + Postgres/RLS.
-- Non-goal: frontend wiring, menu/order/loyalty/POS schema.

create extension if not exists pgcrypto with schema extensions;

create type public.app_user_role as enum ('customer', 'staff', 'admin', 'owner');
create type public.member_type as enum ('standard', 'student', 'staff');
create type public.student_verification_status as enum ('not_submitted', 'pending', 'verified', 'rejected', 'expired');

create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  display_name text,
  phone text,
  avatar_url text,
  app_role public.app_user_role not null default 'customer',
  disabled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint user_profiles_email_not_blank check (btrim(email) <> ''),
  constraint user_profiles_display_name_length check (display_name is null or char_length(display_name) between 1 and 120),
  constraint user_profiles_phone_length check (phone is null or char_length(phone) <= 32),
  constraint user_profiles_avatar_url_length check (avatar_url is null or char_length(avatar_url) <= 2048)
);

create table public.members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.user_profiles(user_id) on delete cascade,
  member_code text not null unique,
  member_type public.member_type not null default 'standard',
  student_status public.student_verification_status not null default 'not_submitted',
  qr_payload_version integer not null default 1,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint members_member_code_format check (member_code ~ '^AIDA-[A-Z0-9]{10}$'),
  constraint members_qr_payload_version_positive check (qr_payload_version > 0)
);

create table public.student_verifications (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  campus_id text not null,
  status public.student_verification_status not null default 'pending',
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references public.user_profiles(user_id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint student_verifications_campus_id_not_blank check (btrim(campus_id) <> ''),
  constraint student_verifications_campus_id_length check (char_length(campus_id) <= 64),
  constraint student_verifications_review_note_length check (review_note is null or char_length(review_note) <= 500),
  constraint student_verifications_review_consistency check (
    (status in ('verified', 'rejected', 'expired') and reviewed_at is not null)
    or (status = 'pending' and reviewed_at is null)
  )
);

create index user_profiles_app_role_idx on public.user_profiles(app_role);
create index members_user_id_idx on public.members(user_id);
create index members_member_code_idx on public.members(member_code);
create index members_student_status_idx on public.members(student_status);
create index student_verifications_member_id_idx on public.student_verifications(member_id);
create index student_verifications_status_idx on public.student_verifications(status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.generate_member_code()
returns text
language plpgsql
set search_path = public, extensions, pg_temp
as $$
declare
  candidate text;
begin
  loop
    candidate := 'AIDA-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));
    exit when not exists (select 1 from public.members where member_code = candidate);
  end loop;
  return candidate;
end;
$$;

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  candidate_name text;
begin
  candidate_name := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))), '');

  insert into public.user_profiles (user_id, email, display_name)
  values (new.id, coalesce(new.email, ''), candidate_name)
  on conflict (user_id) do nothing;

  insert into public.members (user_id, member_code)
  values (new.id, public.generate_member_code())
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.current_app_role()
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

create or replace function public.is_staff_or_above()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.current_app_role() in ('staff', 'admin', 'owner');
$$;

create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

create trigger set_members_updated_at
before update on public.members
for each row execute function public.set_updated_at();

create trigger set_student_verifications_updated_at
before update on public.student_verifications
for each row execute function public.set_updated_at();

drop trigger if exists on_auth_user_created_aida_profile on auth.users;
create trigger on_auth_user_created_aida_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user();

alter table public.user_profiles enable row level security;
alter table public.members enable row level security;
alter table public.student_verifications enable row level security;

alter table public.user_profiles force row level security;
alter table public.members force row level security;
alter table public.student_verifications force row level security;

revoke all on public.user_profiles from anon, authenticated;
revoke all on public.members from anon, authenticated;
revoke all on public.student_verifications from anon, authenticated;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.generate_member_code() from public, anon, authenticated;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
grant execute on function public.current_app_role() to authenticated;
grant execute on function public.is_staff_or_above() to authenticated;

grant select on public.user_profiles to authenticated;
grant update (display_name, phone, avatar_url) on public.user_profiles to authenticated;

grant select on public.members to authenticated;

grant select, insert on public.student_verifications to authenticated;
grant update (status, reviewed_by, reviewed_at, review_note) on public.student_verifications to authenticated;

create policy "user_profiles_select_own_or_staff"
on public.user_profiles
for select
to authenticated
using (user_id = auth.uid() or public.is_staff_or_above());

create policy "user_profiles_update_own_basic_fields"
on public.user_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "members_select_own_or_staff"
on public.members
for select
to authenticated
using (user_id = auth.uid() or public.is_staff_or_above());

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
  or public.is_staff_or_above()
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
      and m.user_id = auth.uid()
  )
);

create policy "student_verifications_staff_review"
on public.student_verifications
for update
to authenticated
using (public.is_staff_or_above())
with check (public.is_staff_or_above());

comment on table public.user_profiles is 'Trusted user profile and application role record created from Supabase Auth users.';
comment on table public.members is 'AIDA member identity record with server-issued stable member code and QR payload version.';
comment on table public.student_verifications is 'Student status submission/review records. Student benefits are not granted by client-side declaration.';
comment on function public.current_app_role() is 'Returns trusted application role for the authenticated user from public.user_profiles.';
comment on function public.is_staff_or_above() is 'True when the authenticated user has staff, admin, or owner role.';
