-- Phase 1–3 Codex audit remediation / Phase 6 privacy compatibility.
-- Whole-account deletion must remove customer-owned loyalty state before the
-- member/Auth rows disappear, while retained order-linked commercial snapshots
-- lose their customer loyalty identifiers rather than becoming mutable.

create or replace function private.prevent_loyalty_ledger_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_internal_anonymize boolean :=
    coalesce(current_setting('aida.internal_customer_anonymize', true), '') = 'on';
begin
  if v_internal_anonymize and tg_op = 'UPDATE' and tg_table_name = 'loyalty_order_awards' then
    if old.member_id is not null
       and new.member_id is null
       and new.order_id is not distinct from old.order_id
       and new.points_awarded is not distinct from old.points_awarded
       and new.stamps_awarded is not distinct from old.stamps_awarded
       and new.awarded_at is not distinct from old.awarded_at then
      return new;
    end if;
  end if;

  if v_internal_anonymize and tg_op = 'UPDATE' and tg_table_name = 'voucher_order_applications' then
    if old.member_voucher_id is not null
       and new.member_voucher_id is null
       and new.id is not distinct from old.id
       and new.order_id is not distinct from old.order_id
       and new.voucher_code_snapshot is not distinct from old.voucher_code_snapshot
       and new.reward_code_snapshot is not distinct from old.reward_code_snapshot
       and new.reward_name_snapshot is not distinct from old.reward_name_snapshot
       and new.reward_type_snapshot is not distinct from old.reward_type_snapshot
       and new.discount_sen is not distinct from old.discount_sen
       and new.applied_at is not distinct from old.applied_at then
      return new;
    end if;
  end if;

  raise exception 'loyalty ledger history is append-only' using errcode = '42501';
end;
$$;

revoke all on function private.prevent_loyalty_ledger_mutation()
from public, anon, authenticated;

create or replace function private.delete_own_account_impl(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_deleted_at timestamptz := now();
  v_retained_order_count integer := 0;
  v_order_ids uuid[] := array[]::uuid[];
  v_member_ids uuid[] := array[]::uuid[];
  v_voucher_ids uuid[] := array[]::uuid[];
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authentication required'
      using errcode = '42501', detail = 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.user_profiles p
    where p.user_id = p_actor_user_id
      and p.app_role = 'customer'
  ) then
    raise exception 'customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  select coalesce(array_agg(m.id), array[]::uuid[])
  into v_member_ids
  from public.members m
  where m.user_id = p_actor_user_id;

  select coalesce(array_agg(o.id), array[]::uuid[])
  into v_order_ids
  from public.orders o
  where o.source = 'customer'
    and o.customer_user_id = p_actor_user_id
    and o.created_by_user_id = p_actor_user_id
    and o.customer_deleted_at is null;

  select coalesce(array_agg(v.id), array[]::uuid[])
  into v_voucher_ids
  from public.member_vouchers v
  where v.member_id = any(v_member_ids);

  perform set_config('aida.internal_customer_anonymize', 'on', true);

  -- Retained commercial snapshots keep only non-identifying award/discount
  -- facts. Customer-owned mutable wallet/ledger state is deleted.
  update public.loyalty_order_awards
  set member_id = null
  where member_id = any(v_member_ids);

  update public.voucher_order_applications
  set member_voucher_id = null
  where member_voucher_id = any(v_voucher_ids);

  delete from public.loyalty_point_ledger
  where member_id = any(v_member_ids);

  delete from public.loyalty_stamp_ledger
  where member_id = any(v_member_ids);

  delete from public.member_loyalty_accounts
  where member_id = any(v_member_ids);

  delete from public.member_vouchers
  where member_id = any(v_member_ids);

  update public.order_lines
  set note = null
  where order_id = any(v_order_ids)
    and note is not null;

  update public.order_events
  set reason = null
  where order_id = any(v_order_ids)
    and reason is not null;

  update public.orders
  set customer_user_id = null,
      member_id = null,
      created_by_user_id = null,
      customer_deleted_at = v_deleted_at,
      request_hash = md5('deleted:' || id::text),
      updated_at = now()
  where id = any(v_order_ids);

  get diagnostics v_retained_order_count = row_count;

  if exists (
    select 1
    from public.member_loyalty_accounts a
    where a.member_id = any(v_member_ids)
  ) or exists (
    select 1
    from public.loyalty_point_ledger l
    where l.member_id = any(v_member_ids)
  ) or exists (
    select 1
    from public.loyalty_stamp_ledger l
    where l.member_id = any(v_member_ids)
  ) or exists (
    select 1
    from public.member_vouchers v
    where v.member_id = any(v_member_ids)
  ) then
    raise exception 'customer loyalty state could not be fully deleted'
      using errcode = '55000', detail = 'CUSTOMER_LOYALTY_DELETE_INCOMPLETE';
  end if;

  if exists (
    select 1
    from public.loyalty_order_awards a
    where a.member_id = any(v_member_ids)
  ) or exists (
    select 1
    from public.voucher_order_applications a
    where a.member_voucher_id = any(v_voucher_ids)
  ) then
    raise exception 'retained loyalty commercial snapshots still identify customer state'
      using errcode = '55000', detail = 'CUSTOMER_LOYALTY_ANONYMIZATION_INCOMPLETE';
  end if;

  if exists (
    select 1
    from public.orders o
    where o.customer_user_id = p_actor_user_id
       or o.created_by_user_id = p_actor_user_id
       or o.member_id = any(v_member_ids)
  ) then
    raise exception 'customer identity could not be fully anonymized'
      using errcode = '55000', detail = 'CUSTOMER_ANONYMIZATION_INCOMPLETE';
  end if;

  if exists (
    select 1
    from public.order_lines l
    where l.order_id = any(v_order_ids)
      and l.note is not null
  ) or exists (
    select 1
    from public.order_events e
    where e.order_id = any(v_order_ids)
      and e.reason is not null
  ) then
    raise exception 'customer free-text order data could not be scrubbed'
      using errcode = '55000', detail = 'CUSTOMER_FREE_TEXT_SCRUB_INCOMPLETE';
  end if;

  if exists (
    select 1
    from public.orders o
    where o.id = any(v_order_ids)
      and o.request_hash is distinct from md5('deleted:' || o.id::text)
  ) then
    raise exception 'customer request digest could not be anonymized'
      using errcode = '55000', detail = 'CUSTOMER_REQUEST_DIGEST_SCRUB_INCOMPLETE';
  end if;

  delete from auth.users
  where id = p_actor_user_id;

  if not found then
    raise exception 'authenticated user record not found'
      using errcode = 'P0002', detail = 'AUTH_USER_NOT_FOUND';
  end if;

  perform set_config('aida.internal_customer_anonymize', 'off', true);

  return jsonb_build_object(
    'deletedAt', v_deleted_at,
    'retainedOrderCount', v_retained_order_count
  );
end;
$$;

revoke all on function private.delete_own_account_impl(uuid)
from public, anon, authenticated;
grant execute on function private.delete_own_account_impl(uuid)
to authenticated;
