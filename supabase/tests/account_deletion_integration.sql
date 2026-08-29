-- TASK-ACCT-001 integration checks.
-- Run against a disposable database after migrations.

begin;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values (
  '20000000-0000-0000-0000-000000000001',
  'departing-customer@example.test',
  '{"display_name":"Departing Customer"}'::jsonb,
  now(),
  now()
);

do $$
declare
  v_member_id uuid;
  v_order_id uuid;
  v_deleted_customer constant uuid := '00000000-0000-0000-0000-000000000001';
  v_customer constant uuid := '20000000-0000-0000-0000-000000000001';
  v_row public.orders%rowtype;
begin
  select id into strict v_member_id
  from public.members
  where user_id = v_customer;

  insert into public.orders (
    source, customer_user_id, member_id, created_by_user_id,
    client_request_id, request_hash, fulfillment_type, status,
    subtotal_sen, total_sen
  ) values (
    'customer', v_customer, v_member_id, v_customer,
    gen_random_uuid(), 'test-hash', 'asap', 'confirmed',
    1500, 1500
  )
  returning id into v_order_id;

  -- Unauthenticated callers cannot invoke this at all.
  perform set_config('request.jwt.claims', '', true);
  begin
    perform public.delete_own_account();
    raise exception 'delete_own_account unexpectedly succeeded with no session';
  exception
    when others then
      if sqlerrm <> 'authentication required' then
        raise;
      end if;
  end;

  -- The departing customer deletes their own account.
  perform set_config(
    'request.jwt.claims',
    '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}',
    true
  );
  perform public.delete_own_account();

  if exists (select 1 from auth.users where id = v_customer) then
    raise exception 'auth.users row survived delete_own_account';
  end if;
  if exists (select 1 from public.members where user_id = v_customer) then
    raise exception 'members row survived delete_own_account (should cascade)';
  end if;

  select * into strict v_row from public.orders where id = v_order_id;
  if v_row.customer_user_id is not null then
    raise exception 'order customer_user_id was not cleared, got %', v_row.customer_user_id;
  end if;
  if v_row.member_id is not null then
    raise exception 'order member_id was not cleared, got %', v_row.member_id;
  end if;
  if v_row.created_by_user_id is distinct from v_deleted_customer then
    raise exception 'order created_by_user_id was not reassigned to the placeholder, got %', v_row.created_by_user_id;
  end if;
  if v_row.subtotal_sen <> 1500 or v_row.total_sen <> 1500 then
    raise exception 'order commercial fields changed unexpectedly';
  end if;

  -- The placeholder account itself can never be "deleted" again.
  perform set_config(
    'request.jwt.claims',
    '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}',
    true
  );
  begin
    perform public.delete_own_account();
    raise exception 'deleted-customer placeholder was unexpectedly deletable';
  exception
    when others then
      if sqlerrm <> 'this account cannot be deleted' then
        raise;
      end if;
  end;
end;
$$;

rollback;
