-- TASK-OPS-006 / Phase 6 loyalty/rewards/vouchers regression.
-- Transactional: no synthetic identity/order/loyalty data survives.

begin;

do $$
declare v_table text;
begin
  foreach v_table in array array[
    'reward_catalogue','loyalty_program_config','member_loyalty_accounts',
    'loyalty_order_awards','loyalty_point_ledger','loyalty_stamp_ledger',
    'member_vouchers','voucher_order_applications'
  ] loop
    if not exists (
      select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
      where n.nspname='public' and c.relname=v_table and c.relrowsecurity and c.relforcerowsecurity
    ) then raise exception '% does not have FORCE RLS',v_table; end if;
  end loop;

  if has_table_privilege('authenticated','public.member_loyalty_accounts','update')
     or has_table_privilege('authenticated','public.loyalty_point_ledger','insert')
     or has_table_privilege('authenticated','public.loyalty_stamp_ledger','insert')
     or has_table_privilege('authenticated','public.member_vouchers','insert')
     or has_table_privilege('authenticated','public.reward_catalogue','update') then
    raise exception 'authenticated role has direct loyalty/reward write authority';
  end if;

  if has_function_privilege('anon','public.get_my_loyalty_wallet()','execute')
     or has_function_privilege('anon','public.redeem_my_reward(uuid)','execute') then
    raise exception 'anonymous role has customer loyalty RPC authority';
  end if;
  if not has_function_privilege('authenticated','public.get_my_loyalty_wallet()','execute')
     or not has_function_privilege('authenticated','public.redeem_my_reward(uuid)','execute') then
    raise exception 'authenticated customer loyalty RPC grants are missing';
  end if;
  if has_function_privilege('authenticated','private.issue_member_voucher(uuid,uuid,text,bigint,uuid)','execute')
     or has_function_privilege('authenticated','private.ensure_loyalty_account(uuid)','execute')
     or has_function_privilege('authenticated','private.consume_voucher_for_order(uuid,uuid,uuid,uuid)','execute') then
    raise exception 'authenticated role can execute unchecked private loyalty helpers';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('get_my_loyalty_wallet','redeem_my_reward','quote_order','place_customer_order') and p.prosecdef
  ) then raise exception 'public Phase 6 RPC unexpectedly uses SECURITY DEFINER'; end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values ('66000000-0000-0000-0000-000000000001','phase6-customer@example.test','{}'::jsonb,now(),now());

set local role authenticated;
do $$
declare
  v_customer uuid := '66000000-0000-0000-0000-000000000001';
  v_branch uuid;
  v_item uuid;
  v_variant uuid;
  v_order jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select id into strict v_branch from public.branches where is_default and is_active limit 1;
  select id into strict v_item from public.catalogue_items where sku='CF-LAT';
  select id into strict v_variant from public.catalogue_item_variants where item_id=v_item and code='medium';

  begin
    insert into public.member_loyalty_accounts(member_id)
    select id from public.members where user_id=v_customer;
    raise exception 'customer direct loyalty balance insert unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId','66100000-0000-0000-0000-000000000001',
    'branchId',v_branch,
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object('itemId',v_item,'variantId',v_variant,'addOnIds','[]'::jsonb,'quantity',1))
  )) into v_order;
  if nullif(v_order->>'id','') is null then raise exception 'customer order did not return id'; end if;
  if (v_order->>'discountSen')::bigint <> 0 then raise exception 'order without voucher unexpectedly has a discount'; end if;
end;
$$;
reset role;

-- Drive the persisted order to completed under database-owner authority. The
-- earning trigger is the subject here; legal staff transition behavior is
-- already covered by the order/shift regressions.
do $$
declare v_order_id uuid;
begin
  select id into strict v_order_id from public.orders where client_request_id='66100000-0000-0000-0000-000000000001';
  update public.orders set status='completed',completed_at=now(),status_updated_at=now(),status_version=status_version+1 where id=v_order_id;

  if (select count(*) from public.loyalty_order_awards where order_id=v_order_id) <> 1 then
    raise exception 'completed order award idempotency anchor missing';
  end if;
  if (select points_awarded from public.loyalty_order_awards where order_id=v_order_id) <> 10 then
    raise exception 'completed RM10.50 order should earn 10 points';
  end if;
  if (select stamps_awarded from public.loyalty_order_awards where order_id=v_order_id) <> 1 then
    raise exception 'completed qualifying order should earn one stamp';
  end if;

  update public.orders set status='completed' where id=v_order_id;
  if (select count(*) from public.loyalty_order_awards where order_id=v_order_id) <> 1 then
    raise exception 'repeated completed update duplicated loyalty award';
  end if;
end;
$$;

-- Add a low-cost test reward as privileged fixture data so redemption can be
-- exercised without manufacturing many orders.
insert into public.reward_catalogue(code,name,reward_type,points_cost,fixed_amount_sen,expiry_days,is_points_redeemable,is_active)
values('P6_TEST_RM1','Phase 6 Test RM1','fixed_amount',5,100,7,true,true);

set local role authenticated;
do $$
declare
  v_customer uuid := '66000000-0000-0000-0000-000000000001';
  v_member uuid;
  v_reward uuid;
  v_wallet jsonb;
  v_redeemed jsonb;
  v_voucher_id uuid;
  v_branch uuid;
  v_item uuid;
  v_variant uuid;
  v_payload jsonb;
  v_quote jsonb;
  v_order jsonb;
  v_retry jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select id into strict v_member from public.members where user_id=v_customer;
  select id into strict v_reward from public.reward_catalogue where code='P6_TEST_RM1';
  select id into strict v_branch from public.branches where is_default and is_active limit 1;
  select id into strict v_item from public.catalogue_items where sku='CF-LAT';
  select id into strict v_variant from public.catalogue_item_variants where item_id=v_item and code='medium';

  select public.get_my_loyalty_wallet() into v_wallet;
  if (v_wallet->>'pointsBalance')::bigint <> 10 or (v_wallet->>'stampBalance')::integer <> 1 then
    raise exception 'wallet balances do not match completed-order earning: %',v_wallet;
  end if;

  select public.redeem_my_reward(v_reward) into v_redeemed;
  if (v_redeemed->>'pointsBalance')::bigint <> 5 then raise exception 'reward redemption did not debit points atomically'; end if;
  v_voucher_id := nullif(v_redeemed->>'issuedVoucherId','')::uuid;
  if v_voucher_id is null then raise exception 'reward redemption did not issue voucher'; end if;
  if (select count(*) from public.member_vouchers where member_id=v_member and reward_id=v_reward and status='active') <> 1 then
    raise exception 'active redeemed voucher missing';
  end if;
  if (select count(*) from public.loyalty_point_ledger where member_id=v_member and event_kind='earn') <> 1
     or (select count(*) from public.loyalty_point_ledger where member_id=v_member and event_kind='redeem') <> 1 then
    raise exception 'points ledger does not contain exactly one earn and one redemption';
  end if;

  begin
    perform public.redeem_my_reward((select id from public.reward_catalogue where code='POINTS_RM5'));
    raise exception 'insufficient-points redemption unexpectedly succeeded';
  exception when invalid_parameter_value then
    if sqlerrm <> 'insufficient loyalty points' then raise; end if;
  end;

  v_payload := jsonb_build_object(
    'clientRequestId','66100000-0000-0000-0000-000000000002',
    'branchId',v_branch,
    'fulfillmentType','asap',
    'voucherId',v_voucher_id,
    'items',jsonb_build_array(jsonb_build_object('itemId',v_item,'variantId',v_variant,'addOnIds','[]'::jsonb,'quantity',1))
  );

  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'subtotalSen')::bigint <> 1050
     or (v_quote->>'discountSen')::bigint <> 100
     or (v_quote->>'totalSen')::bigint <> 950 then
    raise exception 'trusted voucher quote is incorrect: %',v_quote;
  end if;

  select public.place_customer_order(v_payload) into v_order;
  if (v_order->>'subtotalSen')::bigint <> 1050
     or (v_order->>'discountSen')::bigint <> 100
     or (v_order->>'totalSen')::bigint <> 950
     or v_order->'voucher' is null then
    raise exception 'accepted order did not preserve voucher commercial snapshot: %',v_order;
  end if;
  if (select status from public.member_vouchers where id=v_voucher_id) <> 'used' then
    raise exception 'accepted voucher was not consumed';
  end if;
  if (select count(*) from public.voucher_order_applications where order_id=(v_order->>'id')::uuid and discount_sen=100) <> 1 then
    raise exception 'accepted order voucher application snapshot missing';
  end if;

  select public.place_customer_order(v_payload) into v_retry;
  if v_retry->>'id' is distinct from v_order->>'id' then raise exception 'idempotent voucher retry created a different order'; end if;
  if (select count(*) from public.voucher_order_applications where order_id=(v_order->>'id')::uuid) <> 1 then
    raise exception 'idempotent retry duplicated voucher consumption';
  end if;

  begin
    perform public.place_customer_order(v_payload || jsonb_build_object('clientRequestId','66100000-0000-0000-0000-000000000003'));
    raise exception 'reused voucher unexpectedly created another order';
  exception when invalid_parameter_value then
    if sqlerrm not in ('voucher is not active','voucher is no longer available') then raise; end if;
  end;
end;
$$;
reset role;

-- Privacy deletion must remove customer-owned loyalty state while allowing
-- non-identifying order/voucher commercial snapshots to survive detached.
set local role authenticated;
do $$
declare v_customer uuid := '66000000-0000-0000-0000-000000000001'; v_result jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select public.delete_own_account() into v_result;
end;
$$;
reset role;

do $$
declare v_order_id uuid; v_voucher_order_id uuid;
begin
  select id into strict v_order_id from public.orders where client_request_id='66100000-0000-0000-0000-000000000001';
  select id into strict v_voucher_order_id from public.orders where client_request_id='66100000-0000-0000-0000-000000000002';
  if exists(select 1 from public.member_loyalty_accounts) then raise exception 'customer loyalty account survived account deletion'; end if;
  if exists(select 1 from public.member_vouchers) then raise exception 'customer vouchers survived account deletion'; end if;
  if exists(select 1 from public.loyalty_point_ledger) or exists(select 1 from public.loyalty_stamp_ledger) then
    raise exception 'customer loyalty ledgers survived account deletion';
  end if;
  if not exists(select 1 from public.loyalty_order_awards where order_id=v_order_id and member_id is null) then
    raise exception 'retained loyalty award snapshot did not anonymize member identity';
  end if;
  if not exists(select 1 from public.voucher_order_applications where order_id=v_voucher_order_id and member_voucher_id is null and discount_sen=100) then
    raise exception 'retained voucher application snapshot did not detach customer voucher identity';
  end if;
end;
$$;

rollback;
