-- Phase 1–3 Codex audit remediation / Phase 6 cumulative compatibility.
-- Restore the narrowly scoped Phase 3 customer-anonymization transition after
-- later commercial immutability hardening, and remove the retained digest of
-- the original customer payload so deleted free text cannot be dictionary-
-- tested against orders.request_hash.

create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_internal_finalize boolean :=
    coalesce(current_setting('aida.internal_order_shift_finalize', true), '') = 'on';
  v_internal_anonymize boolean :=
    coalesce(current_setting('aida.internal_customer_anonymize', true), '') = 'on';
  v_identity_changed boolean :=
    new.customer_user_id is distinct from old.customer_user_id
    or new.member_id is distinct from old.member_id
    or new.created_by_user_id is distinct from old.created_by_user_id
    or new.customer_deleted_at is distinct from old.customer_deleted_at;
  v_request_hash_changed boolean :=
    new.request_hash is distinct from old.request_hash;
  v_valid_anonymize boolean :=
    v_internal_anonymize
    and old.source = 'customer'
    and old.customer_user_id is not null
    and old.member_id is not null
    and old.created_by_user_id = old.customer_user_id
    and old.customer_deleted_at is null
    and new.customer_user_id is null
    and new.member_id is null
    and new.created_by_user_id is null
    and new.customer_deleted_at is not null
    and new.request_hash = md5('deleted:' || old.id::text);
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.branch_id is distinct from old.branch_id
     or new.sales_point_id is distinct from old.sales_point_id
     or new.terminal_id is distinct from old.terminal_id
     or new.sales_point_code_snapshot is distinct from old.sales_point_code_snapshot
     or new.sales_point_name_snapshot is distinct from old.sales_point_name_snapshot
     or new.terminal_code_snapshot is distinct from old.terminal_code_snapshot
     or new.client_request_id is distinct from old.client_request_id
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.discount_sen is distinct from old.discount_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;

  if (v_identity_changed or v_request_hash_changed) and not v_valid_anonymize then
    raise exception 'persisted order customer identity fields are immutable'
      using errcode = '42501';
  end if;

  if new.shift_id is distinct from old.shift_id
     or new.tender_type is distinct from old.tender_type
     or new.payment_state is distinct from old.payment_state
     or new.paid_at is distinct from old.paid_at then
    if not v_internal_finalize
       or old.source <> 'pos'
       or old.shift_id is not null
       or new.shift_id is null
       or old.tender_type <> 'unpaid'
       or old.payment_state <> 'unpaid'
       or old.paid_at is not null then
      raise exception 'persisted order shift/payment fields are immutable'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

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

  select coalesce(array_agg(o.id), array[]::uuid[])
  into v_order_ids
  from public.orders o
  where o.source = 'customer'
    and o.customer_user_id = p_actor_user_id
    and o.created_by_user_id = p_actor_user_id
    and o.customer_deleted_at is null;

  update public.order_lines
  set note = null
  where order_id = any(v_order_ids)
    and note is not null;

  update public.order_events
  set reason = null
  where order_id = any(v_order_ids)
    and reason is not null;

  perform set_config('aida.internal_customer_anonymize', 'on', true);

  update public.orders
  set customer_user_id = null,
      member_id = null,
      created_by_user_id = null,
      customer_deleted_at = v_deleted_at,
      request_hash = md5('deleted:' || id::text),
      updated_at = now()
  where id = any(v_order_ids);

  get diagnostics v_retained_order_count = row_count;
  perform set_config('aida.internal_customer_anonymize', 'off', true);

  if exists (
    select 1
    from public.orders o
    where o.customer_user_id = p_actor_user_id
       or o.created_by_user_id = p_actor_user_id
       or o.member_id in (
         select m.id
         from public.members m
         where m.user_id = p_actor_user_id
       )
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
