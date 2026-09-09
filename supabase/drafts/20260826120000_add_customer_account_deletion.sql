-- TASK-ACCT-001: customer self-service account deletion.
--
-- App Store / Play Store review both require an in-app path to delete an
-- account and its data for any app that offers account creation. This adds
-- that path as a single RPC a signed-in customer calls on themselves —
-- nothing here is callable against another user's id.
--
-- created_by_user_id (orders' audit trail of who placed the order) is
-- NOT NULL + ON DELETE RESTRICT by design, and for customer self-service
-- orders that is the customer themselves — so `delete from auth.users`
-- would fail outright with a foreign-key violation for anyone who has ever
-- placed an order. The fix is a permanent placeholder "deleted customer"
-- account (never logged into — no password) that a departing customer's
-- own orders are reassigned to immediately before their real account is
-- removed, so past order history/accounting stays intact with no trace of
-- who it was. Same pattern as GitHub's "ghost" user on old issues/PRs, or
-- Reddit's "[deleted]".

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values (
  '00000000-0000-0000-0000-000000000001',
  'deleted-customer@internal.aida.invalid',
  '{"display_name":"Deleted Customer"}'::jsonb,
  now(),
  now()
)
on conflict (id) do nothing;

-- The commercial-fields-immutable guarantee (see
-- 20260812182212_create_authoritative_orders_and_scheduling.sql) still
-- holds for every ordinary path — this only carves out the two exact
-- transitions account deletion needs: customer_user_id/member_id may be
-- cleared to null (what the FK's own ON DELETE SET NULL produces when the
-- customer's auth row is removed), and created_by_user_id may be
-- reassigned specifically to the deleted-customer placeholder above.
-- Nothing else about those three columns becomes mutable.
create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_deleted_customer constant uuid := '00000000-0000-0000-0000-000000000001';
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or (new.customer_user_id is distinct from old.customer_user_id and new.customer_user_id is not null)
     or (new.member_id is distinct from old.member_id and new.member_id is not null)
     or (
       new.created_by_user_id is distinct from old.created_by_user_id
       and new.created_by_user_id is distinct from v_deleted_customer
     )
     or new.client_request_id is distinct from old.client_request_id
     or new.request_hash is distinct from old.request_hash
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

-- Hard-deletes the caller's own account: reassigns their own order history
-- to the deleted-customer placeholder (satisfying created_by_user_id's
-- NOT NULL + ON DELETE RESTRICT), then deletes their auth.users row, which
-- cascades to user_profiles -> members -> student_verifications and sets
-- orders.customer_user_id / orders.member_id / order_events.actor_user_id
-- to null automatically via their existing ON DELETE SET NULL.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_deleted_customer constant uuid := '00000000-0000-0000-0000-000000000001';
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if v_uid = v_deleted_customer then
    raise exception 'this account cannot be deleted' using errcode = '42501';
  end if;

  update public.orders
  set created_by_user_id = v_deleted_customer
  where created_by_user_id = v_uid;

  delete from auth.users where id = v_uid;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
