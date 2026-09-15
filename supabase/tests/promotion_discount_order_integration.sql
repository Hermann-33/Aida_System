-- TASK-OPS-007 / Phase 7 quote/place integration regression.
-- Covers scope, deterministic stacking/precedence, voucher coexistence, usage
-- limits, immutable snapshots, and idempotent placement. Transactional rollback.

begin;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('77600000-0000-0000-0000-000000000001','phase7-order-admin@example.test','{}'::jsonb,now(),now()),
 ('77600000-0000-0000-0000-000000000002','phase7-order-one@example.test','{}'::jsonb,now(),now()),
 ('77600000-0000-0000-0000-000000000003','phase7-order-two@example.test','{}'::jsonb,now(),now());
update public.user_profiles set app_role='admin' where user_id='77600000-0000-0000-0000-000000000001';

-- Stable fixture IDs are resolved as owner; ordinary customer sessions exercise
-- only public order RPCs and never gain promotion table access.
select set_config('test.p7.branch',(select id::text from public.branches where is_default and is_active limit 1),false);
select set_config('test.p7.sandwich',(select id::text from public.catalogue_items where sku='FD-SAN'),false);
select set_config('test.p7.latte',(select id::text from public.catalogue_items where sku='CF-LAT'),false);
select set_config('test.p7.medium',(
  select v.id::text from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id
  where i.sku='CF-LAT' and v.code='medium'
),false);
select set_config('test.p7.large',(
  select v.id::text from public.catalogue_item_variants v join public.catalogue_items i on i.id=v.item_id
  where i.sku='CF-LAT' and v.code='large'
),false);
select set_config('test.p7.shot',(select id::text from public.catalogue_items where sku='AD-SHT' and kind='addon'),false);

-- Configure stackable product promotions through the caller-bound Admin RPC.
set local role authenticated;
do $$
declare
  v_admin uuid:='77600000-0000-0000-0000-000000000001';
  v_branch text:=current_setting('test.p7.branch');
  v_sandwich text:=current_setting('test.p7.sandwich');
  v_medium text:=current_setting('test.p7.medium');
  v_shot text:=current_setting('test.p7.shot');
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);

  perform public.save_promotion(jsonb_build_object(
    'code','P7_STACK_10','name','Stack 10 Percent','discountType','percent','percentBasisPoints',1000,
    'priority',10,'stackingMode','stackable','allowWithVoucher',true,'requiresMember',true,
    'perMemberUsageLimit',1,'isActive',true,'branchIds',jsonb_build_array(v_branch),'itemIds',jsonb_build_array(v_sandwich)
  ));
  perform public.save_promotion(jsonb_build_object(
    'code','P7_STACK_100','name','Stack RM1','discountType','fixed','fixedAmountSen',100,
    'priority',20,'stackingMode','stackable','allowWithVoucher',true,'globalUsageLimit',1,
    'isActive',true,'branchIds',jsonb_build_array(v_branch),'itemIds',jsonb_build_array(v_sandwich)
  ));
  perform public.save_promotion(jsonb_build_object(
    'code','P7_MEDIUM_50','name','Medium RM0.50','discountType','fixed','fixedAmountSen',50,
    'priority',5,'stackingMode','stackable','allowWithVoucher',true,'isActive',true,
    'branchIds',jsonb_build_array(v_branch),'variantIds',jsonb_build_array(v_medium)
  ));
  perform public.save_promotion(jsonb_build_object(
    'code','P7_SHOT_25','name','Shot RM0.25','discountType','fixed','fixedAmountSen',25,
    'priority',6,'stackingMode','stackable','allowWithVoucher',true,'isActive',true,
    'branchIds',jsonb_build_array(v_branch),'addonItemIds',jsonb_build_array(v_shot)
  ));
end;
$$;
reset role;

-- Variant and add-on scope are evaluated from the authoritative quote, not raw
-- client price fields. Medium Latte + Extra Shot receives 50 + 25 sen.
set local role authenticated;
do $$
declare
  v_customer uuid:='77600000-0000-0000-0000-000000000002';
  v_quote jsonb;
  v_payload jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  v_payload:=jsonb_build_object(
    'branchId',current_setting('test.p7.branch')::uuid,'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',current_setting('test.p7.latte')::uuid,
      'variantId',current_setting('test.p7.medium')::uuid,
      'addOnIds',jsonb_build_array(current_setting('test.p7.shot')::uuid),'quantity',1
    ))
  );
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'promotionDiscountSen')::bigint<>75
     or jsonb_array_length(v_quote->'promotions')<>2
     or (v_quote->>'discountSen')::bigint<>75 then
    raise exception 'variant/add-on promotion scope is incorrect: %',v_quote;
  end if;

  v_payload:=jsonb_build_object(
    'branchId',current_setting('test.p7.branch')::uuid,'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',current_setting('test.p7.latte')::uuid,
      'variantId',current_setting('test.p7.large')::uuid,
      'addOnIds','[]'::jsonb,'quantity',1
    ))
  );
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'promotionDiscountSen')::bigint<>0 or jsonb_array_length(v_quote->'promotions')<>0 then
    raise exception 'nonmatching variant unexpectedly received promotion: %',v_quote;
  end if;
end;
$$;
reset role;

-- First member gets both stackable Sandwich promotions. Percent is additive on
-- the authoritative eligible subtotal, fixed amount then applies to remaining.
set local role authenticated;
do $$
declare
  v_customer uuid:='77600000-0000-0000-0000-000000000002';
  v_payload jsonb;
  v_quote jsonb;
  v_order jsonb;
  v_retry jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  v_payload:=jsonb_build_object(
    'clientRequestId','77610000-0000-0000-0000-000000000001',
    'branchId',current_setting('test.p7.branch')::uuid,'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',current_setting('test.p7.sandwich')::uuid,'addOnIds','[]'::jsonb,'quantity',1
    ))
  );
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'subtotalSen')::bigint<>1290
     or (v_quote->>'promotionDiscountSen')::bigint<>229
     or (v_quote->>'voucherDiscountSen')::bigint<>0
     or (v_quote->>'discountSen')::bigint<>229
     or (v_quote->>'totalSen')::bigint<>1061
     or jsonb_array_length(v_quote->'promotions')<>2 then
    raise exception 'stacked promotion quote is incorrect: %',v_quote;
  end if;

  select public.place_customer_order(v_payload) into v_order;
  if (v_order->>'discountSen')::bigint<>229
     or (v_order->>'promotionDiscountSen')::bigint<>229
     or (v_order->>'voucherDiscountSen')::bigint<>0
     or (v_order->>'totalSen')::bigint<>1061
     or jsonb_array_length(v_order->'promotions')<>2
     or coalesce(v_order->'voucher','null'::jsonb) <> 'null'::jsonb then
    raise exception 'accepted promotion order snapshot is incorrect: %',v_order;
  end if;

  select public.place_customer_order(v_payload) into v_retry;
  if v_retry->>'id' is distinct from v_order->>'id' then
    raise exception 'promotion order idempotent retry created another order';
  end if;
end;
$$;
reset role;

do $$
declare v_order uuid; v_member uuid;
begin
  select id into strict v_order from public.orders where client_request_id='77610000-0000-0000-0000-000000000001';
  select id into strict v_member from public.members where user_id='77600000-0000-0000-0000-000000000002';
  if (select count(*) from public.promotion_order_applications where order_id=v_order)<>2 then
    raise exception 'promotion application snapshots missing or duplicated after retry';
  end if;
  if (select sum(discount_sen) from public.promotion_order_applications where order_id=v_order)<>229 then
    raise exception 'promotion application snapshots do not reconcile to accepted discount';
  end if;
  if (select count(*) from public.promotion_order_applications a join public.promotions p on p.id=a.promotion_id where p.code='P7_STACK_10' and a.member_id=v_member)<>1 then
    raise exception 'per-member promotion usage anchor is incorrect';
  end if;
end;
$$;

-- Usage limits are quote-visible but not reservations. After first acceptance,
-- same member loses the per-member promotion; another member can still use it,
-- while the globally-limited fixed promotion is exhausted for everyone.
set local role authenticated;
do $$
declare v_customer uuid; v_quote jsonb; v_payload jsonb;
begin
  v_customer:='77600000-0000-0000-0000-000000000002';
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  v_payload:=jsonb_build_object('branchId',current_setting('test.p7.branch')::uuid,'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object('itemId',current_setting('test.p7.sandwich')::uuid,'addOnIds','[]'::jsonb,'quantity',1)));
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'promotionDiscountSen')::bigint<>0 then
    raise exception 'per-member/global exhausted promotions remained eligible for first member: %',v_quote;
  end if;

  v_customer:='77600000-0000-0000-0000-000000000003';
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'promotionDiscountSen')::bigint<>129
     or jsonb_array_length(v_quote->'promotions')<>1
     or v_quote#>>'{promotions,0,code}'<>'P7_STACK_10' then
    raise exception 'global/member usage eligibility is incorrect for second member: %',v_quote;
  end if;
end;
$$;
reset role;

-- Add exclusive voucher-incompatible and voucher-compatible promotions. With a
-- voucher, the incompatible higher-priority offer must be excluded and the next
-- eligible exclusive offer wins. Existing stackables must not apply after it.
set local role authenticated;
do $$
declare v_admin uuid:='77600000-0000-0000-0000-000000000001'; v_branch text:=current_setting('test.p7.branch'); v_item text:=current_setting('test.p7.sandwich');
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  perform public.save_promotion(jsonb_build_object(
    'code','P7_NO_VOUCHER','name','No Voucher RM3','discountType','fixed','fixedAmountSen',300,
    'priority',1,'stackingMode','exclusive','allowWithVoucher',false,'isActive',true,
    'branchIds',jsonb_build_array(v_branch),'itemIds',jsonb_build_array(v_item)
  ));
  perform public.save_promotion(jsonb_build_object(
    'code','P7_WITH_VOUCHER','name','Voucher Compatible RM2','discountType','fixed','fixedAmountSen',200,
    'priority',2,'stackingMode','exclusive','allowWithVoucher',true,'isActive',true,
    'branchIds',jsonb_build_array(v_branch),'itemIds',jsonb_build_array(v_item)
  ));
end;
$$;
reset role;

-- Create one fixed RM1 voucher as privileged fixture data. Redemption mechanics
-- remain covered by Phase 6; this test isolates Phase 7 coexistence/accounting.
insert into public.reward_catalogue(code,name,reward_type,points_cost,fixed_amount_sen,expiry_days,is_points_redeemable,is_active)
values('P7_TEST_RM1','Phase 7 Test RM1','fixed_amount',0,100,7,true,true);
insert into public.member_vouchers(
  member_id,reward_id,code,source,status,reward_code_snapshot,reward_name_snapshot,
  reward_type_snapshot,fixed_amount_sen_snapshot,points_spent,expires_at
)
select m.id,r.id,'AIDA-V-P7TEST000001','admin','active',r.code,r.name,r.reward_type,r.fixed_amount_sen,0,now()+interval '7 days'
from public.members m cross join public.reward_catalogue r
where m.user_id='77600000-0000-0000-0000-000000000003' and r.code='P7_TEST_RM1';
select set_config('test.p7.voucher',(select id::text from public.member_vouchers where code='AIDA-V-P7TEST000001'),false);

set local role authenticated;
do $$
declare
  v_customer uuid:='77600000-0000-0000-0000-000000000003';
  v_payload jsonb;
  v_quote jsonb;
  v_order jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  v_payload:=jsonb_build_object(
    'clientRequestId','77610000-0000-0000-0000-000000000002',
    'branchId',current_setting('test.p7.branch')::uuid,'fulfillmentType','asap',
    'voucherId',current_setting('test.p7.voucher')::uuid,
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',current_setting('test.p7.sandwich')::uuid,'addOnIds','[]'::jsonb,'quantity',1
    ))
  );
  select public.quote_order(v_payload) into v_quote;
  if (v_quote->>'voucherDiscountSen')::bigint<>100
     or (v_quote->>'promotionDiscountSen')::bigint<>200
     or (v_quote->>'discountSen')::bigint<>300
     or (v_quote->>'totalSen')::bigint<>990
     or jsonb_array_length(v_quote->'promotions')<>1
     or v_quote#>>'{promotions,0,code}'<>'P7_WITH_VOUCHER' then
    raise exception 'voucher/promotion precedence quote is incorrect: %',v_quote;
  end if;

  select public.place_customer_order(v_payload) into v_order;
  if (v_order->>'voucherDiscountSen')::bigint<>100
     or (v_order->>'promotionDiscountSen')::bigint<>200
     or (v_order->>'discountSen')::bigint<>300
     or (v_order->>'totalSen')::bigint<>990
     or (v_order#>>'{voucher,discountSen}')::bigint<>100
     or v_order#>>'{promotions,0,discountSen}'<>'200' then
    raise exception 'accepted voucher/promotion snapshots are incorrect: %',v_order;
  end if;
end;
$$;
reset role;

do $$
declare v_order uuid;
begin
  select id into strict v_order from public.orders where client_request_id='77610000-0000-0000-0000-000000000002';
  if (select discount_sen from public.voucher_order_applications where order_id=v_order)<>100 then
    raise exception 'voucher snapshot incorrectly absorbed promotion discount';
  end if;
  if (select sum(discount_sen) from public.promotion_order_applications where order_id=v_order)<>200 then
    raise exception 'promotion snapshot does not preserve its independent discount';
  end if;
  if (select discount_sen from public.orders where id=v_order)<>300 then
    raise exception 'order total discount does not reconcile voucher + promotion';
  end if;
end;
$$;

rollback;
