-- TASK-OPS-009 / Phase 9 true refund contention fixture.
-- Runs on the disposable local CI database and intentionally persists fixtures
-- for the companion multi-session shell regression.

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('99300000-0000-0000-0000-000000000001','phase9-concurrency-customer@example.test','{}'::jsonb,now(),now()),
 ('99300000-0000-0000-0000-000000000002','phase9-concurrency-admin@example.test','{}'::jsonb,now(),now());

update public.user_profiles
set app_role='admin'
where user_id='99300000-0000-0000-0000-000000000002';

insert into public.payment_provider_configs(
  provider_key,display_name,environment,is_active,customer_enabled,pos_enabled,supports_refunds
) values (
  'phase9_concurrency','Phase 9 Concurrency Provider','test',true,true,true,true
);

insert into public.orders(
  id,source,customer_user_id,member_id,created_by_user_id,
  client_request_id,request_hash,fulfillment_type,status,
  subtotal_sen,discount_sen,total_sen,branch_id
) values (
  '99310000-0000-0000-0000-000000000001','customer',
  '99300000-0000-0000-0000-000000000001'::uuid,
  (select id from public.members where user_id='99300000-0000-0000-0000-000000000001'::uuid),
  '99300000-0000-0000-0000-000000000001'::uuid,
  '99311000-0000-0000-0000-000000000001'::uuid,
  md5('phase9 refund contention order'),'asap','confirmed',1000,0,1000,private.default_branch_id()
);

set role authenticated;
select set_config(
  'request.jwt.claims',
  jsonb_build_object('sub','99300000-0000-0000-0000-000000000001'::uuid,'role','authenticated')::text,
  false
);
select public.request_external_payment(
  '99310000-0000-0000-0000-000000000001',
  '99312000-0000-0000-0000-000000000001'
);
reset role;

set role service_role;
select public.apply_payment_provider_event(jsonb_build_object(
  'providerKey','phase9_concurrency',
  'providerEventId','phase9-concurrency-capture',
  'paymentIntentId',(
    select id from public.payment_intents
    where order_id='99310000-0000-0000-0000-000000000001'::uuid
    order by created_at desc,id desc limit 1
  ),
  'eventType','captured',
  'providerPaymentId','phase9-concurrency-payment',
  'payloadSha256',repeat('9',64)
));
reset role;

do $$
begin
  if not exists (
    select 1 from public.orders
    where id='99310000-0000-0000-0000-000000000001'::uuid
      and tender_type='external'
      and payment_state='paid'
      and refunded_sen=0
  ) then
    raise exception 'Phase 9 concurrency fixture did not reach paid state';
  end if;
end;
$$;
