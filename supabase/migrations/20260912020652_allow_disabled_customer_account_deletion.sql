-- TASK-PRIVACY-001 / Phase 3 — account deletion is a customer right, not
-- an active-feature privilege. A trusted customer profile may delete its own
-- account even when the application profile has been disabled. Staff/Admin
-- identities remain excluded by trusted app_role.

create or replace function private.delete_own_account_impl(p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
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
  ) then
    raise exception 'customer profile required'
      using errcode = '42501', detail = 'CUSTOMER_PROFILE_REQUIRED';
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
    and created_by_user_id = p_actor_user_id
    and customer_deleted_at is null;

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
