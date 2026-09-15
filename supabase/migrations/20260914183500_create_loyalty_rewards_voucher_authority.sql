-- TASK-OPS-006 / Phase 6 — loyalty, rewards and voucher authority foundation.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/migrations/.
--
-- This migration establishes server-owned balances, append-only ledgers,
-- reward definitions, voucher issuance and idempotent completed-order earning.
-- Voucher application to order pricing is integrated by a later Phase 6 migration.

create table public.reward_catalogue (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  reward_type text not null,
  points_cost bigint not null,
  fixed_amount_sen bigint,
  eligible_category_slugs text[] not null default '{}'::text[],
  eligible_item_skus text[] not null default '{}'::text[],
  expiry_days integer not null default 30,
  is_points_redeemable boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reward_catalogue_code_check check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,39}$'),
  constraint reward_catalogue_name_check check (char_length(btrim(name)) between 1 and 120),
  constraint reward_catalogue_type_check check (reward_type in ('fixed_amount', 'free_item')),
  constraint reward_catalogue_points_cost_check check (points_cost between 0 and 100000000),
  constraint reward_catalogue_expiry_days_check check (expiry_days between 1 and 3650),
  constraint reward_catalogue_shape_check check (
    (reward_type = 'fixed_amount'
      and fixed_amount_sen between 1 and 100000000
      and cardinality(eligible_category_slugs) = 0
      and cardinality(eligible_item_skus) = 0)
    or
    (reward_type = 'free_item'
      and fixed_amount_sen is null
      and (cardinality(eligible_category_slugs) > 0 or cardinality(eligible_item_skus) > 0))
  )
);

create table public.loyalty_program_config (
  id smallint primary key,
  points_per_ringgit integer not null default 1,
  stamps_per_qualifying_order integer not null default 1,
  stamp_goal integer not null default 10,
  stamp_reward_id uuid not null references public.reward_catalogue(id) on delete restrict,
  updated_by_user_id uuid references public.user_profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint loyalty_program_config_singleton check (id = 1),
  constraint loyalty_program_points_rate_check check (points_per_ringgit between 0 and 100),
  constraint loyalty_program_stamps_rate_check check (stamps_per_qualifying_order between 1 and 10),
  constraint loyalty_program_stamp_goal_check check (stamp_goal between 2 and 100)
);

create table public.member_loyalty_accounts (
  member_id uuid primary key references public.members(id) on delete cascade,
  points_balance bigint not null default 0,
  stamp_balance integer not null default 0,
  lifetime_points_earned bigint not null default 0,
  lifetime_stamps_earned bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_loyalty_points_nonnegative check (points_balance >= 0),
  constraint member_loyalty_stamps_nonnegative check (stamp_balance >= 0),
  constraint member_loyalty_lifetime_points_nonnegative check (lifetime_points_earned >= 0),
  constraint member_loyalty_lifetime_stamps_nonnegative check (lifetime_stamps_earned >= 0)
);

create table public.loyalty_order_awards (
  order_id uuid primary key references public.orders(id) on delete restrict,
  member_id uuid references public.members(id) on delete set null,
  points_awarded bigint not null,
  stamps_awarded integer not null,
  awarded_at timestamptz not null default now(),
  constraint loyalty_order_awards_points_check check (points_awarded >= 0),
  constraint loyalty_order_awards_stamps_check check (stamps_awarded >= 0)
);

create table public.loyalty_point_ledger (
  id bigint generated always as identity primary key,
  member_id uuid not null references public.members(id) on delete cascade,
  delta_points bigint not null,
  event_kind text not null,
  order_id uuid references public.orders(id) on delete restrict,
  reward_id uuid references public.reward_catalogue(id) on delete set null,
  reason text,
  actor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint loyalty_point_ledger_delta_check check (delta_points <> 0),
  constraint loyalty_point_ledger_kind_check check (event_kind in ('earn', 'redeem', 'adjust')),
  constraint loyalty_point_ledger_reason_check check (reason is null or char_length(reason) <= 300)
);

create table public.loyalty_stamp_ledger (
  id bigint generated always as identity primary key,
  member_id uuid not null references public.members(id) on delete cascade,
  delta_stamps integer not null,
  event_kind text not null,
  order_id uuid references public.orders(id) on delete restrict,
  reward_id uuid references public.reward_catalogue(id) on delete set null,
  reason text,
  actor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint loyalty_stamp_ledger_delta_check check (delta_stamps <> 0),
  constraint loyalty_stamp_ledger_kind_check check (event_kind in ('earn', 'milestone_redeem', 'adjust')),
  constraint loyalty_stamp_ledger_reason_check check (reason is null or char_length(reason) <= 300)
);

create table public.member_vouchers (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references public.members(id) on delete cascade,
  reward_id uuid references public.reward_catalogue(id) on delete set null,
  code text not null unique,
  source text not null,
  status text not null default 'active',
  reward_code_snapshot text not null,
  reward_name_snapshot text not null,
  reward_type_snapshot text not null,
  fixed_amount_sen_snapshot bigint,
  eligible_category_slugs_snapshot text[] not null default '{}'::text[],
  eligible_item_skus_snapshot text[] not null default '{}'::text[],
  points_spent bigint not null default 0,
  source_order_id uuid references public.orders(id) on delete set null,
  used_order_id uuid references public.orders(id) on delete set null,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  used_at timestamptz,
  voided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint member_vouchers_code_check check (code ~ '^AIDA-V-[A-Z0-9]{12}$'),
  constraint member_vouchers_source_check check (source in ('points_redemption', 'stamp_milestone', 'admin')),
  constraint member_vouchers_status_check check (status in ('active', 'used', 'expired', 'void')),
  constraint member_vouchers_reward_type_check check (reward_type_snapshot in ('fixed_amount', 'free_item')),
  constraint member_vouchers_points_spent_check check (points_spent >= 0),
  constraint member_vouchers_expiry_check check (expires_at > issued_at),
  constraint member_vouchers_status_shape_check check (
    (status = 'active' and used_at is null and used_order_id is null and voided_at is null)
    or (status = 'used' and used_at is not null and used_order_id is not null and voided_at is null)
    or (status = 'expired' and used_at is null and used_order_id is null and voided_at is null)
    or (status = 'void' and used_at is null and used_order_id is null and voided_at is not null)
  )
);

create table public.voucher_order_applications (
  id bigint generated always as identity primary key,
  order_id uuid not null unique references public.orders(id) on delete restrict,
  member_voucher_id uuid references public.member_vouchers(id) on delete set null,
  voucher_code_snapshot text not null,
  reward_code_snapshot text not null,
  reward_name_snapshot text not null,
  reward_type_snapshot text not null,
  discount_sen bigint not null,
  applied_at timestamptz not null default now(),
  constraint voucher_order_applications_discount_check check (discount_sen >= 0),
  constraint voucher_order_applications_type_check check (reward_type_snapshot in ('fixed_amount', 'free_item'))
);

create index loyalty_order_awards_member_idx on public.loyalty_order_awards(member_id, awarded_at desc) where member_id is not null;
create index loyalty_point_ledger_member_idx on public.loyalty_point_ledger(member_id, created_at desc, id desc);
create index loyalty_point_ledger_order_idx on public.loyalty_point_ledger(order_id) where order_id is not null;
create index loyalty_stamp_ledger_member_idx on public.loyalty_stamp_ledger(member_id, created_at desc, id desc);
create index loyalty_stamp_ledger_order_idx on public.loyalty_stamp_ledger(order_id) where order_id is not null;
create index member_vouchers_member_status_idx on public.member_vouchers(member_id, status, expires_at);
create index member_vouchers_reward_idx on public.member_vouchers(reward_id) where reward_id is not null;
create index member_vouchers_source_order_idx on public.member_vouchers(source_order_id) where source_order_id is not null;
create index member_vouchers_used_order_idx on public.member_vouchers(used_order_id) where used_order_id is not null;
create index voucher_order_applications_voucher_idx on public.voucher_order_applications(member_voucher_id) where member_voucher_id is not null;

create trigger reward_catalogue_set_updated_at before update on public.reward_catalogue for each row execute function public.set_updated_at();
create trigger loyalty_program_config_set_updated_at before update on public.loyalty_program_config for each row execute function public.set_updated_at();
create trigger member_loyalty_accounts_set_updated_at before update on public.member_loyalty_accounts for each row execute function public.set_updated_at();
create trigger member_vouchers_set_updated_at before update on public.member_vouchers for each row execute function public.set_updated_at();

insert into public.reward_catalogue (
  code, name, reward_type, points_cost, fixed_amount_sen,
  eligible_category_slugs, eligible_item_skus, expiry_days,
  is_points_redeemable, is_active
) values
  ('STAMP_FREE_DRINK', 'Free Drink', 'free_item', 0, null, array['coffee','iced-drinks'], '{}'::text[], 30, false, true),
  ('POINTS_RM5', 'RM5 Voucher', 'fixed_amount', 100, 500, '{}'::text[], '{}'::text[], 30, true, true),
  ('POINTS_RM10', 'RM10 Voucher', 'fixed_amount', 180, 1000, '{}'::text[], '{}'::text[], 30, true, true),
  ('POINTS_FREE_PASTRY', 'Free Pastry', 'free_item', 150, null, '{}'::text[], array['FD-CRO','FD-MUF'], 30, true, true);

insert into public.loyalty_program_config (
  id, points_per_ringgit, stamps_per_qualifying_order, stamp_goal, stamp_reward_id
)
select 1, 1, 1, 10, id from public.reward_catalogue where code = 'STAMP_FREE_DRINK';

alter table public.reward_catalogue enable row level security;
alter table public.reward_catalogue force row level security;
alter table public.loyalty_program_config enable row level security;
alter table public.loyalty_program_config force row level security;
alter table public.member_loyalty_accounts enable row level security;
alter table public.member_loyalty_accounts force row level security;
alter table public.loyalty_order_awards enable row level security;
alter table public.loyalty_order_awards force row level security;
alter table public.loyalty_point_ledger enable row level security;
alter table public.loyalty_point_ledger force row level security;
alter table public.loyalty_stamp_ledger enable row level security;
alter table public.loyalty_stamp_ledger force row level security;
alter table public.member_vouchers enable row level security;
alter table public.member_vouchers force row level security;
alter table public.voucher_order_applications enable row level security;
alter table public.voucher_order_applications force row level security;

revoke all on table public.reward_catalogue from public, anon, authenticated;
revoke all on table public.loyalty_program_config from public, anon, authenticated;
revoke all on table public.member_loyalty_accounts from public, anon, authenticated;
revoke all on table public.loyalty_order_awards from public, anon, authenticated;
revoke all on table public.loyalty_point_ledger from public, anon, authenticated;
revoke all on table public.loyalty_stamp_ledger from public, anon, authenticated;
revoke all on table public.member_vouchers from public, anon, authenticated;
revoke all on table public.voucher_order_applications from public, anon, authenticated;

create or replace function private.prevent_loyalty_ledger_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'loyalty ledger history is append-only' using errcode = '42501';
end;
$$;
revoke all on function private.prevent_loyalty_ledger_mutation() from public, anon, authenticated;

create trigger loyalty_order_awards_append_only before update or delete on public.loyalty_order_awards for each row execute function private.prevent_loyalty_ledger_mutation();
create trigger loyalty_point_ledger_append_only before update or delete on public.loyalty_point_ledger for each row execute function private.prevent_loyalty_ledger_mutation();
create trigger loyalty_stamp_ledger_append_only before update or delete on public.loyalty_stamp_ledger for each row execute function private.prevent_loyalty_ledger_mutation();
create trigger voucher_order_applications_append_only before update or delete on public.voucher_order_applications for each row execute function private.prevent_loyalty_ledger_mutation();

create or replace function private.generate_voucher_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_code text;
begin
  loop
    v_code := 'AIDA-V-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12));
    exit when not exists (select 1 from public.member_vouchers v where v.code = v_code);
  end loop;
  return v_code;
end;
$$;
revoke all on function private.generate_voucher_code() from public, anon, authenticated;

create or replace function private.ensure_loyalty_account(p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_member_id is null or not exists (select 1 from public.members m where m.id = p_member_id and m.active) then
    raise exception 'active member is required' using errcode = '42501', detail = 'LOYALTY_MEMBER_REQUIRED';
  end if;
  insert into public.member_loyalty_accounts(member_id) values (p_member_id) on conflict (member_id) do nothing;
end;
$$;
revoke all on function private.ensure_loyalty_account(uuid) from public, anon, authenticated;

create or replace function private.issue_member_voucher(
  p_member_id uuid,
  p_reward_id uuid,
  p_source text,
  p_points_spent bigint,
  p_source_order_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare v_reward public.reward_catalogue%rowtype; v_id uuid;
begin
  select * into v_reward from public.reward_catalogue where id = p_reward_id and is_active for share;
  if not found then raise exception 'reward is unavailable' using errcode = '22023', detail = 'REWARD_UNAVAILABLE'; end if;
  if p_source not in ('points_redemption','stamp_milestone','admin') then raise exception 'invalid voucher source' using errcode = '22023'; end if;
  if p_points_spent is null or p_points_spent < 0 then raise exception 'invalid points spent' using errcode = '22023'; end if;
  insert into public.member_vouchers(
    member_id, reward_id, code, source, status,
    reward_code_snapshot, reward_name_snapshot, reward_type_snapshot,
    fixed_amount_sen_snapshot, eligible_category_slugs_snapshot, eligible_item_skus_snapshot,
    points_spent, source_order_id, expires_at
  ) values (
    p_member_id, v_reward.id, private.generate_voucher_code(), p_source, 'active',
    v_reward.code, v_reward.name, v_reward.reward_type,
    v_reward.fixed_amount_sen, v_reward.eligible_category_slugs, v_reward.eligible_item_skus,
    p_points_spent, p_source_order_id, now() + make_interval(days => v_reward.expiry_days)
  ) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function private.issue_member_voucher(uuid,uuid,text,bigint,uuid) from public, anon, authenticated;

create or replace function private.loyalty_wallet_impl(p_member_id uuid, p_actor_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_member public.members%rowtype; v_account public.member_loyalty_accounts%rowtype; v_result jsonb;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode = '42501';
  end if;
  select * into v_member from public.members where id = p_member_id and active;
  if not found then raise exception 'active member is required' using errcode = '42501', detail = 'LOYALTY_MEMBER_REQUIRED'; end if;
  if v_member.user_id is distinct from p_actor_user_id and not (select private.is_admin_or_owner()) then
    raise exception 'loyalty account access denied' using errcode = '42501', detail = 'LOYALTY_FORBIDDEN';
  end if;
  select * into v_account from public.member_loyalty_accounts where member_id = p_member_id;
  select jsonb_build_object(
    'memberId', v_member.id,
    'memberCode', v_member.member_code,
    'pointsBalance', coalesce(v_account.points_balance,0),
    'stampBalance', coalesce(v_account.stamp_balance,0),
    'lifetimePointsEarned', coalesce(v_account.lifetime_points_earned,0),
    'lifetimeStampsEarned', coalesce(v_account.lifetime_stamps_earned,0),
    'program', (select jsonb_build_object('pointsPerRinggit', c.points_per_ringgit, 'stampsPerQualifyingOrder', c.stamps_per_qualifying_order, 'stampGoal', c.stamp_goal) from public.loyalty_program_config c where c.id=1),
    'rewards', coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'code',r.code,'name',r.name,'rewardType',r.reward_type,'pointsCost',r.points_cost,'fixedAmountSen',r.fixed_amount_sen,'eligibleCategorySlugs',r.eligible_category_slugs,'eligibleItemSkus',r.eligible_item_skus,'expiryDays',r.expiry_days) order by r.points_cost,r.code) from public.reward_catalogue r where r.is_active and r.is_points_redeemable),'[]'::jsonb),
    'vouchers', coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'code',v.code,'status',case when v.status='active' and v.expires_at <= now() then 'expired' else v.status end,'rewardCode',v.reward_code_snapshot,'rewardName',v.reward_name_snapshot,'rewardType',v.reward_type_snapshot,'fixedAmountSen',v.fixed_amount_sen_snapshot,'eligibleCategorySlugs',v.eligible_category_slugs_snapshot,'eligibleItemSkus',v.eligible_item_skus_snapshot,'pointsSpent',v.points_spent,'issuedAt',v.issued_at,'expiresAt',v.expires_at,'usedAt',v.used_at) order by v.issued_at desc) from public.member_vouchers v where v.member_id=p_member_id and v.status in ('active','used') and (v.status<>'active' or v.expires_at>now()-interval '90 days')),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;
revoke all on function private.loyalty_wallet_impl(uuid,uuid) from public, anon, authenticated;

create or replace function private.redeem_reward_impl(p_member_id uuid, p_reward_id uuid, p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_member public.members%rowtype; v_reward public.reward_catalogue%rowtype; v_account public.member_loyalty_accounts%rowtype; v_voucher_id uuid;
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then raise exception 'authenticated actor mismatch' using errcode='42501'; end if;
  select * into v_member from public.members where id=p_member_id and active;
  if not found or v_member.user_id is distinct from p_actor_user_id then raise exception 'customer loyalty ownership required' using errcode='42501', detail='LOYALTY_FORBIDDEN'; end if;
  select * into v_reward from public.reward_catalogue where id=p_reward_id and is_active and is_points_redeemable for share;
  if not found or v_reward.points_cost <= 0 then raise exception 'reward is unavailable for points redemption' using errcode='22023', detail='REWARD_UNAVAILABLE'; end if;
  perform private.ensure_loyalty_account(p_member_id);
  select * into v_account from public.member_loyalty_accounts where member_id=p_member_id for update;
  if v_account.points_balance < v_reward.points_cost then raise exception 'insufficient loyalty points' using errcode='22023', detail='LOYALTY_POINTS_INSUFFICIENT'; end if;
  update public.member_loyalty_accounts set points_balance=points_balance-v_reward.points_cost, updated_at=now() where member_id=p_member_id;
  insert into public.loyalty_point_ledger(member_id,delta_points,event_kind,reward_id,reason,actor_user_id) values (p_member_id,-v_reward.points_cost,'redeem',v_reward.id,'Reward redemption',p_actor_user_id);
  v_voucher_id := private.issue_member_voucher(p_member_id,v_reward.id,'points_redemption',v_reward.points_cost,null);
  return private.loyalty_wallet_impl(p_member_id,p_actor_user_id) || jsonb_build_object('issuedVoucherId',v_voucher_id);
end;
$$;
revoke all on function private.redeem_reward_impl(uuid,uuid,uuid) from public, anon, authenticated;

create or replace function private.award_completed_order_loyalty()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_cfg public.loyalty_program_config%rowtype; v_inserted uuid; v_points bigint; v_account public.member_loyalty_accounts%rowtype; v_new_stamps integer; v_voucher_id uuid;
begin
  if old.status is not distinct from 'completed' or new.status <> 'completed' or new.member_id is null then return new; end if;
  select * into v_cfg from public.loyalty_program_config where id=1;
  if not found then raise exception 'loyalty program configuration is unavailable' using errcode='55000'; end if;
  v_points := floor(new.total_sen::numeric / 100)::bigint * v_cfg.points_per_ringgit;
  insert into public.loyalty_order_awards(order_id,member_id,points_awarded,stamps_awarded) values (new.id,new.member_id,v_points,v_cfg.stamps_per_qualifying_order) on conflict (order_id) do nothing returning order_id into v_inserted;
  if v_inserted is null then return new; end if;
  perform private.ensure_loyalty_account(new.member_id);
  select * into v_account from public.member_loyalty_accounts where member_id=new.member_id for update;
  if v_points > 0 then
    update public.member_loyalty_accounts set points_balance=points_balance+v_points,lifetime_points_earned=lifetime_points_earned+v_points,updated_at=now() where member_id=new.member_id;
    insert into public.loyalty_point_ledger(member_id,delta_points,event_kind,order_id,reason,actor_user_id) values (new.member_id,v_points,'earn',new.id,'Completed order earning',new.created_by_user_id);
  end if;
  update public.member_loyalty_accounts set stamp_balance=stamp_balance+v_cfg.stamps_per_qualifying_order,lifetime_stamps_earned=lifetime_stamps_earned+v_cfg.stamps_per_qualifying_order,updated_at=now() where member_id=new.member_id returning stamp_balance into v_new_stamps;
  insert into public.loyalty_stamp_ledger(member_id,delta_stamps,event_kind,order_id,reason,actor_user_id) values (new.member_id,v_cfg.stamps_per_qualifying_order,'earn',new.id,'Completed order stamp',new.created_by_user_id);
  if v_new_stamps >= v_cfg.stamp_goal then
    update public.member_loyalty_accounts set stamp_balance=stamp_balance-v_cfg.stamp_goal,updated_at=now() where member_id=new.member_id;
    insert into public.loyalty_stamp_ledger(member_id,delta_stamps,event_kind,order_id,reward_id,reason,actor_user_id) values (new.member_id,-v_cfg.stamp_goal,'milestone_redeem',new.id,v_cfg.stamp_reward_id,'Automatic stamp milestone voucher',new.created_by_user_id);
    v_voucher_id := private.issue_member_voucher(new.member_id,v_cfg.stamp_reward_id,'stamp_milestone',0,new.id);
  end if;
  return new;
end;
$$;
revoke all on function private.award_completed_order_loyalty() from public, anon, authenticated;
create trigger orders_award_completed_loyalty after update of status on public.orders for each row execute function private.award_completed_order_loyalty();

create or replace function public.get_my_loyalty_wallet()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare v_member_id uuid;
begin
  if (select auth.uid()) is null or (select private.current_app_role()) <> 'customer'::public.app_user_role then raise exception 'customer authentication required' using errcode='42501'; end if;
  select id into v_member_id from public.members where user_id=(select auth.uid()) and active limit 1;
  if v_member_id is null then raise exception 'active member is required' using errcode='42501'; end if;
  return private.loyalty_wallet_impl(v_member_id,(select auth.uid()));
end;
$$;

create or replace function public.redeem_my_reward(p_reward_id uuid)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare v_member_id uuid;
begin
  if (select auth.uid()) is null or (select private.current_app_role()) <> 'customer'::public.app_user_role then raise exception 'customer authentication required' using errcode='42501'; end if;
  select id into v_member_id from public.members where user_id=(select auth.uid()) and active limit 1;
  if v_member_id is null then raise exception 'active member is required' using errcode='42501'; end if;
  return private.redeem_reward_impl(v_member_id,p_reward_id,(select auth.uid()));
end;
$$;

revoke all on function public.get_my_loyalty_wallet() from public, anon, authenticated;
revoke all on function public.redeem_my_reward(uuid) from public, anon, authenticated;
grant execute on function public.get_my_loyalty_wallet() to authenticated;
grant execute on function public.redeem_my_reward(uuid) to authenticated;

grant usage on schema private to authenticated;
grant execute on function private.loyalty_wallet_impl(uuid,uuid) to authenticated;
grant execute on function private.redeem_reward_impl(uuid,uuid,uuid) to authenticated;
grant execute on function private.ensure_loyalty_account(uuid) to authenticated;
grant execute on function private.issue_member_voucher(uuid,uuid,text,bigint,uuid) to authenticated;

comment on table public.member_loyalty_accounts is 'Server-maintained current loyalty balances. Clients never submit resulting balances.';
comment on table public.loyalty_order_awards is 'Immutable idempotency anchor and non-identifying retained loyalty award snapshot per completed qualifying order.';
comment on table public.loyalty_point_ledger is 'Append-only customer points earning/redemption/adjustment history.';
comment on table public.loyalty_stamp_ledger is 'Append-only customer stamp earning/milestone/adjustment history.';
comment on table public.member_vouchers is 'Server-issued member voucher authority; status and expiry are not client controlled.';
comment on table public.voucher_order_applications is 'Immutable commercial snapshot of a voucher applied to an accepted order; populated by later Phase 6 order integration.';
