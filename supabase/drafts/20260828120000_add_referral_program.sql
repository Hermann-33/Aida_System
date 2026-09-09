-- TASK-REFERRAL-001: customer "Invite a friend" referral program.
--
-- Points move from purely-mocked to real here, but only the points balance
-- itself — stamps, the rewards catalogue, vouchers and offers stay on
-- MockMemberRepository until their own tasks land. Scope is deliberately
-- narrow: just enough real ledger for a referral bonus to mean something.
--
-- Flow: a member shares their existing member_code as their referral code
-- (no separate code to generate/manage). A new signup can optionally supply
-- it; handle_new_auth_user() records a *pending* referral. The reward only
-- fires once the referred member's first order reaches 'completed' — proof
-- of a genuine purchase, not just a throwaway signup — at which point both
-- sides get a points bonus and the referral is marked rewarded.

alter table public.members
  add column points_balance bigint not null default 0,
  add constraint members_points_balance_nonnegative check (points_balance >= 0);

create table public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_member_id uuid not null references public.members(id) on delete cascade,
  referred_member_id uuid not null unique references public.members(id) on delete cascade,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  rewarded_at timestamptz,
  constraint referrals_status_check check (status in ('pending', 'rewarded')),
  constraint referrals_no_self_referral check (referrer_member_id <> referred_member_id),
  constraint referrals_rewarded_at_shape check (
    (status = 'rewarded') = (rewarded_at is not null)
  )
);

create index referrals_referrer_member_id_idx on public.referrals (referrer_member_id);

-- No policies granted: every access path is through the security-definer
-- functions below (or the signup trigger). Nothing here is client-readable
-- or client-writable directly, same as members' own lack of an update
-- policy.
alter table public.referrals enable row level security;

-- Extends the existing signup trigger (see
-- 20260812192500_fix_signup_member_code_generation.sql) to also record a
-- pending referral when the signup metadata carries a referral_code. An
-- unrecognized or self-referral code never fails the signup itself — it
-- just means no referral gets recorded.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
  v_is_student boolean;
  v_new_member_id uuid;
  v_referral_code text;
  v_referrer_member_id uuid;
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
  on conflict (user_id) do nothing
  returning id into v_new_member_id;

  if v_new_member_id is not null then
    v_referral_code := nullif(upper(trim(coalesce(new.raw_user_meta_data ->> 'referral_code', ''))), '');
    if v_referral_code is not null then
      select id into v_referrer_member_id
      from public.members
      where member_code = v_referral_code;

      if v_referrer_member_id is not null and v_referrer_member_id <> v_new_member_id then
        insert into public.referrals (referrer_member_id, referred_member_id)
        values (v_referrer_member_id, v_new_member_id)
        on conflict (referred_member_id) do nothing;
      end if;
    end if;
  end if;

  return new;
end;
$$;

-- Extends the existing order-status transition (see
-- 20260812182212_create_authoritative_orders_and_scheduling.sql) to award
-- the referral bonus at the moment it's earned: the referred member's
-- first-ever completed order. Runs inside the same function/transaction as
-- the status change itself, after the order row and its status_version are
-- already updated, so "first completed order" reads the post-update state.
create or replace function private.transition_order_status_impl(
  p_order_id uuid,
  p_to_status text,
  p_expected_version bigint,
  p_reason text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_now timestamptz := now();
  v_referral public.referrals%rowtype;
  v_completed_orders integer;
  v_referral_bonus constant bigint := 50;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version < 1 then
    raise exception 'expected status version is required' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(btrim(p_reason)) > 300 then
    raise exception 'status reason must be 300 characters or fewer' using errcode = '22023';
  end if;

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'order not found' using errcode = 'P0002';
  end if;
  if v_order.status_version <> p_expected_version then
    raise exception 'order status changed; refresh before retrying' using errcode = '40001';
  end if;
  if not (
    (v_order.status = 'scheduled' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'confirmed' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'preparing' and p_to_status in ('ready', 'cancelled'))
    or (v_order.status = 'ready' and p_to_status = 'completed')
  ) then
    raise exception 'illegal order status transition from % to %', v_order.status, p_to_status
      using errcode = '22023';
  end if;

  update public.orders
  set status = p_to_status,
      status_version = status_version + 1,
      status_updated_at = v_now,
      preparing_at = case when p_to_status = 'preparing' then coalesce(preparing_at, v_now) else preparing_at end,
      ready_at = case when p_to_status = 'ready' then coalesce(ready_at, v_now) else ready_at end,
      completed_at = case when p_to_status = 'completed' then coalesce(completed_at, v_now) else completed_at end,
      cancelled_at = case when p_to_status = 'cancelled' then coalesce(cancelled_at, v_now) else cancelled_at end
  where id = p_order_id;

  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, reason, details
  ) values (
    p_order_id, 'status_changed', p_actor_user_id, v_order.status, p_to_status,
    nullif(btrim(coalesce(p_reason, '')), ''),
    jsonb_build_object('previousVersion', v_order.status_version, 'newVersion', v_order.status_version + 1)
  );

  if p_to_status = 'completed' and v_order.member_id is not null then
    select * into v_referral
    from public.referrals
    where referred_member_id = v_order.member_id
      and status = 'pending'
    for update;

    if found then
      select count(*) into v_completed_orders
      from public.orders
      where member_id = v_order.member_id
        and status = 'completed';

      if v_completed_orders = 1 then
        update public.members
        set points_balance = points_balance + v_referral_bonus
        where id in (v_referral.referrer_member_id, v_referral.referred_member_id);

        update public.referrals
        set status = 'rewarded', rewarded_at = v_now
        where id = v_referral.id;
      end if;
    end if;
  end if;

  return private.order_snapshot(p_order_id);
end;
$$;

revoke all on function private.transition_order_status_impl(uuid, text, bigint, text, uuid)
  from public, anon, authenticated;
grant execute on function private.transition_order_status_impl(uuid, text, bigint, text, uuid)
  to authenticated;
