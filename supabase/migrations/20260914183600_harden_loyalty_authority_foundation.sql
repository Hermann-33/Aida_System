-- TASK-OPS-006 / Phase 6 — harden loyalty foundation before order integration.
-- Preserve privacy deletion semantics and remove unnecessary private helper grants.

-- Account deletion intentionally removes member-owned loyalty state while
-- retaining non-identifying order-award/application commercial snapshots.
-- Generic append-only triggers would block FK ON DELETE SET NULL, so use
-- narrow immutability guards that allow identity detachment only.
drop trigger if exists loyalty_order_awards_append_only on public.loyalty_order_awards;
drop trigger if exists voucher_order_applications_append_only on public.voucher_order_applications;

create or replace function private.protect_loyalty_order_award()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'loyalty order award history is append-only' using errcode = '42501';
  end if;
  if new.order_id is distinct from old.order_id
     or new.points_awarded is distinct from old.points_awarded
     or new.stamps_awarded is distinct from old.stamps_awarded
     or new.awarded_at is distinct from old.awarded_at
     or not (
       new.member_id is not distinct from old.member_id
       or (old.member_id is not null and new.member_id is null)
     ) then
    raise exception 'loyalty order award history is immutable' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.protect_loyalty_order_award() from public, anon, authenticated;
create trigger loyalty_order_awards_protect
before update or delete on public.loyalty_order_awards
for each row execute function private.protect_loyalty_order_award();

create or replace function private.protect_voucher_order_application()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'voucher application history is append-only' using errcode = '42501';
  end if;
  if new.id is distinct from old.id
     or new.order_id is distinct from old.order_id
     or new.voucher_code_snapshot is distinct from old.voucher_code_snapshot
     or new.reward_code_snapshot is distinct from old.reward_code_snapshot
     or new.reward_name_snapshot is distinct from old.reward_name_snapshot
     or new.reward_type_snapshot is distinct from old.reward_type_snapshot
     or new.discount_sen is distinct from old.discount_sen
     or new.applied_at is distinct from old.applied_at
     or not (
       new.member_voucher_id is not distinct from old.member_voucher_id
       or (old.member_voucher_id is not null and new.member_voucher_id is null)
     ) then
    raise exception 'voucher application history is immutable' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.protect_voucher_order_application() from public, anon, authenticated;
create trigger voucher_order_applications_protect
before update or delete on public.voucher_order_applications
for each row execute function private.protect_voucher_order_application();

-- Empty search_path requires explicit extension qualification.
create or replace function private.generate_voucher_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_code text;
begin
  loop
    v_code := 'AIDA-V-' || upper(substr(replace(extensions.gen_random_uuid()::text, '-', ''), 1, 12));
    exit when not exists (select 1 from public.member_vouchers v where v.code = v_code);
  end loop;
  return v_code;
end;
$$;
revoke all on function private.generate_voucher_code() from public, anon, authenticated;

-- These unchecked helpers are internal implementation details. Guarded public
-- wrappers do not require callers to execute them directly.
revoke all on function private.ensure_loyalty_account(uuid) from public, anon, authenticated;
revoke all on function private.issue_member_voucher(uuid,uuid,text,bigint,uuid) from public, anon, authenticated;

-- Guarded helpers remain the only private functions exposed to authenticated
-- callers because each independently binds p_actor_user_id to auth.uid().
grant execute on function private.loyalty_wallet_impl(uuid,uuid) to authenticated;
grant execute on function private.redeem_reward_impl(uuid,uuid,uuid) to authenticated;
