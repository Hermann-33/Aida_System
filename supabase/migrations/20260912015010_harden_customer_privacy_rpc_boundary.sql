-- TASK-PRIVACY-001 / Phase 3 — keep exposed RPC wrappers SECURITY INVOKER.
-- Privileged table/Auth mutations remain in private SECURITY DEFINER helpers
-- that bind every operation to the current auth.uid().

create or replace function private.get_my_privacy_preferences_impl(p_actor_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_row public.customer_privacy_preferences%rowtype;
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
      and p.disabled_at is null
  ) then
    raise exception 'active customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  select * into v_row
  from public.customer_privacy_preferences
  where user_id = p_actor_user_id;

  return jsonb_build_object(
    'marketingNotificationsEnabled', coalesce(v_row.marketing_notifications_enabled, false),
    'transactionalNotificationsEnabled', coalesce(v_row.transactional_notifications_enabled, true),
    'updatedAt', v_row.updated_at
  );
end;
$$;

create or replace function private.save_my_privacy_preferences_impl(
  p_actor_user_id uuid,
  p_marketing_notifications_enabled boolean,
  p_transactional_notifications_enabled boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.customer_privacy_preferences%rowtype;
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
    p_actor_user_id,
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

create or replace function private.delete_own_account_impl(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_deleted_at timestamptz := now();
  v_retained_order_count integer := 0;
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
      and p.disabled_at is null
  ) then
    raise exception 'active customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
  end if;

  select m.id into v_member_id
  from public.members m
  where m.user_id = p_actor_user_id
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
    and customer_user_id = p_actor_user_id
    and member_id = v_member_id
    and created_by_user_id = p_actor_user_id
    and customer_deleted_at is null;

  get diagnostics v_retained_order_count = row_count;
  perform set_config('aida.internal_customer_anonymize', 'off', true);

  if exists (
    select 1
    from public.orders o
    where o.customer_user_id = p_actor_user_id
       or o.member_id = v_member_id
       or o.created_by_user_id = p_actor_user_id
  ) then
    raise exception 'customer identity could not be fully anonymized'
      using errcode = '55000', detail = 'CUSTOMER_ANONYMIZATION_INCOMPLETE';
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

create or replace function public.get_my_privacy_preferences()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select private.get_my_privacy_preferences_impl((select auth.uid()));
$$;

create or replace function public.save_my_privacy_preferences(
  p_marketing_notifications_enabled boolean,
  p_transactional_notifications_enabled boolean
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_my_privacy_preferences_impl(
    (select auth.uid()),
    p_marketing_notifications_enabled,
    p_transactional_notifications_enabled
  );
$$;

create or replace function public.delete_own_account()
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.delete_own_account_impl((select auth.uid()));
$$;

revoke all on function private.get_my_privacy_preferences_impl(uuid) from public, anon, authenticated;
revoke all on function private.save_my_privacy_preferences_impl(uuid, boolean, boolean) from public, anon, authenticated;
revoke all on function private.delete_own_account_impl(uuid) from public, anon, authenticated;

grant usage on schema private to authenticated;
grant execute on function private.get_my_privacy_preferences_impl(uuid) to authenticated;
grant execute on function private.save_my_privacy_preferences_impl(uuid, boolean, boolean) to authenticated;
grant execute on function private.delete_own_account_impl(uuid) to authenticated;

revoke all on function public.get_my_privacy_preferences() from public, anon, authenticated;
revoke all on function public.save_my_privacy_preferences(boolean, boolean) from public, anon, authenticated;
revoke all on function public.delete_own_account() from public, anon, authenticated;

grant execute on function public.get_my_privacy_preferences() to authenticated;
grant execute on function public.save_my_privacy_preferences(boolean, boolean) to authenticated;
grant execute on function public.delete_own_account() to authenticated;
