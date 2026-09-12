-- TASK-PRIVACY-001 / Phase 3 — customer privacy and whole-account deletion.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/migrations/.
--
-- Retention boundary:
-- - delete customer identity/profile/member/student/preference records;
-- - retain immutable commercial/operational order history without stable
--   customer/member/Auth identifiers;
-- - do not create a synthetic permanent Auth user for deleted customers.
--
-- Non-goals: external payment processors/refunds, inventory, branch hours,
-- loyalty, marketing delivery providers, or deployment-heavy integration work.

alter table public.orders
  add column customer_deleted_at timestamptz;

alter table public.orders
  alter column created_by_user_id drop not null;

alter table public.orders
  drop constraint orders_customer_owner_check;

alter table public.orders
  add constraint orders_customer_owner_check check (
    (source = 'pos' and customer_deleted_at is null)
    or
    (
      source = 'customer'
      and (
        (
          customer_user_id is not null
          and member_id is not null
          and created_by_user_id is not null
          and customer_deleted_at is null
        )
        or
        (
          customer_user_id is null
          and member_id is null
          and created_by_user_id is null
          and customer_deleted_at is not null
        )
      )
    )
  );

create index orders_customer_deleted_idx
  on public.orders (customer_deleted_at, created_at desc)
  where source = 'customer' and customer_deleted_at is not null;

create table public.customer_privacy_preferences (
  user_id uuid primary key references public.user_profiles(user_id) on delete cascade,
  marketing_notifications_enabled boolean not null default false,
  transactional_notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger customer_privacy_preferences_set_updated_at
before update on public.customer_privacy_preferences
for each row execute function public.set_updated_at();

alter table public.customer_privacy_preferences enable row level security;
alter table public.customer_privacy_preferences force row level security;

revoke all on table public.customer_privacy_preferences from public, anon, authenticated;

create policy customer_privacy_preferences_select_own
on public.customer_privacy_preferences
for select
to authenticated
using (user_id = (select auth.uid()));

create policy customer_privacy_preferences_insert_own
on public.customer_privacy_preferences
for insert
to authenticated
with check (user_id = (select auth.uid()));

create policy customer_privacy_preferences_update_own
on public.customer_privacy_preferences
for update
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

-- Preserve every Phase 2 commercial/topology/shift/payment immutability rule.
-- The only new exception is the single, one-way internal transition that
-- anonymizes retained customer orders during authenticated whole-account
-- deletion.
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
  v_valid_anonymize boolean :=
    v_internal_anonymize
    and old.source = 'customer'
    and old.customer_user_id is not null
    and old.member_id is not null
    and old.created_by_user_id is not null
    and old.customer_deleted_at is null
    and new.customer_user_id is null
    and new.member_id is null
    and new.created_by_user_id is null
    and new.customer_deleted_at is not null;
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
     or new.request_hash is distinct from old.request_hash
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;

  if v_identity_changed and not v_valid_anonymize then
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

create or replace function public.get_my_privacy_preferences()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_row public.customer_privacy_preferences%rowtype;
begin
  if v_uid is null then
    raise exception 'authentication required'
      using errcode = '42501', detail = 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.user_profiles p
    where p.user_id = v_uid
      and p.app_role = 'customer'
      and p.disabled_at is null
  ) then
    raise exception 'active customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  select * into v_row
  from public.customer_privacy_preferences
  where user_id = v_uid;

  return jsonb_build_object(
    'marketingNotificationsEnabled', coalesce(v_row.marketing_notifications_enabled, false),
    'transactionalNotificationsEnabled', coalesce(v_row.transactional_notifications_enabled, true),
    'updatedAt', v_row.updated_at
  );
end;
$$;

create or replace function public.save_my_privacy_preferences(
  p_marketing_notifications_enabled boolean,
  p_transactional_notifications_enabled boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_row public.customer_privacy_preferences%rowtype;
begin
  if v_uid is null then
    raise exception 'authentication required'
      using errcode = '42501', detail = 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.user_profiles p
    where p.user_id = v_uid
      and p.app_role = 'customer'
      and p.disabled_at is null
  ) then
    raise exception 'active customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  if p_marketing_notifications_enabled is null
     or p_transactional_notifications_enabled is null then
    raise exception 'notification preference values are required'
      using errcode = '22023', detail = 'PRIVACY_PREFERENCES_INVALID';
  end if;

  insert into public.customer_privacy_preferences (
    user_id,
    marketing_notifications_enabled,
    transactional_notifications_enabled
  ) values (
    v_uid,
    p_marketing_notifications_enabled,
    p_transactional_notifications_enabled
  )
  on conflict (user_id) do update
  set marketing_notifications_enabled = excluded.marketing_notifications_enabled,
      transactional_notifications_enabled = excluded.transactional_notifications_enabled,
      updated_at = now()
  returning * into v_row;

  return jsonb_build_object(
    'marketingNotificationsEnabled', v_row.marketing_notifications_enabled,
    'transactionalNotificationsEnabled', v_row.transactional_notifications_enabled,
    'updatedAt', v_row.updated_at
  );
end;
$$;

-- No target user id is accepted. The caller can delete only the authenticated
-- customer identity represented by auth.uid(). Historical customer orders are
-- anonymized first, then the Auth row is deleted so profile/member/student and
-- preference rows cascade away. The existing created_by_user_id FK remains
-- ON DELETE RESTRICT, protecting POS/staff audit identities outside this path.
create or replace function public.delete_own_account()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_member_id uuid;
  v_deleted_at timestamptz := now();
  v_retained_order_count integer := 0;
begin
  if v_uid is null then
    raise exception 'authentication required'
      using errcode = '42501', detail = 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from public.user_profiles p
    where p.user_id = v_uid
      and p.app_role = 'customer'
      and p.disabled_at is null
  ) then
    raise exception 'active customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  select m.id into v_member_id
  from public.members m
  where m.user_id = v_uid
    and m.active
  limit 1;

  if v_member_id is null then
    raise exception 'active member record required'
      using errcode = '42501', detail = 'CUSTOMER_MEMBER_REQUIRED';
  end if;

  perform set_config('aida.internal_customer_anonymize', 'on', true);

  update public.orders
  set customer_user_id = null,
      member_id = null,
      created_by_user_id = null,
      customer_deleted_at = v_deleted_at,
      updated_at = now()
  where source = 'customer'
    and customer_user_id = v_uid
    and member_id = v_member_id
    and created_by_user_id = v_uid
    and customer_deleted_at is null;

  get diagnostics v_retained_order_count = row_count;

  perform set_config('aida.internal_customer_anonymize', 'off', true);

  if exists (
    select 1
    from public.orders o
    where o.customer_user_id = v_uid
       or o.member_id = v_member_id
       or o.created_by_user_id = v_uid
  ) then
    raise exception 'customer identity could not be fully anonymized'
      using errcode = '55000', detail = 'CUSTOMER_ANONYMIZATION_INCOMPLETE';
  end if;

  delete from auth.users
  where id = v_uid;

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

revoke all on function public.get_my_privacy_preferences() from public, anon, authenticated;
revoke all on function public.save_my_privacy_preferences(boolean, boolean) from public, anon, authenticated;
revoke all on function public.delete_own_account() from public, anon, authenticated;

grant execute on function public.get_my_privacy_preferences() to authenticated;
grant execute on function public.save_my_privacy_preferences(boolean, boolean) to authenticated;
grant execute on function public.delete_own_account() to authenticated;

comment on table public.customer_privacy_preferences is
  'Customer-owned notification/privacy preference state. Marketing defaults off; no delivery provider is implied.';
comment on column public.orders.customer_deleted_at is
  'Set only by trusted whole-account deletion when a customer order is retained without stable customer/member/Auth identifiers.';
comment on function public.delete_own_account() is
  'Deletes the authenticated customer account after anonymizing retained customer transaction history. Accepts no target user id.';

do $$
begin
  if exists (
    select 1
    from public.orders o
    where o.source = 'customer'
      and not (
        (
          o.customer_user_id is not null
          and o.member_id is not null
          and o.created_by_user_id is not null
          and o.customer_deleted_at is null
        )
        or
        (
          o.customer_user_id is null
          and o.member_id is null
          and o.created_by_user_id is null
          and o.customer_deleted_at is not null
        )
      )
  ) then
    raise exception 'customer order identity/deletion invariant failed';
  end if;

  if has_function_privilege('anon', 'public.delete_own_account()', 'execute')
     or has_function_privilege('anon', 'public.save_my_privacy_preferences(boolean,boolean)', 'execute') then
    raise exception 'anonymous role unexpectedly has Phase 3 customer privacy mutation authority';
  end if;

  if has_table_privilege('authenticated', 'public.customer_privacy_preferences', 'insert')
     or has_table_privilege('authenticated', 'public.customer_privacy_preferences', 'update') then
    raise exception 'authenticated role unexpectedly has direct privacy preference mutation grants';
  end if;
end;
$$;
