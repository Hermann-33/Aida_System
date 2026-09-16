-- TASK-OPS-009 / Phase 9 provider-neutral payment/refund regression.
-- Transactional: all provider/user/order/payment fixtures roll back.

begin;

do $$
begin
  if not has_function_privilege('authenticated','public.get_order_payment_state(uuid)','execute')
     or not has_function_privilege('authenticated','public.request_external_payment(uuid,uuid)','execute')
     or not has_function_privilege('authenticated','public.request_external_refund(jsonb)','execute')
     or not has_function_privilege('authenticated','public.refund_cash_order(jsonb,text)','execute') then
    raise exception 'Phase 9 authenticated RPC grants are incomplete';
  end if;

  if has_function_privilege('anon','public.get_order_payment_state(uuid)','execute')
     or has_function_privilege('anon','public.request_external_payment(uuid,uuid)','execute')
     or has_function_privilege('anon','public.request_external_refund(jsonb)','execute')
     or has_function_privilege('anon','public.refund_cash_order(jsonb,text)','execute') then
    raise exception 'anonymous role unexpectedly has Phase 9 payment/refund authority';
  end if;

  if has_function_privilege('authenticated','public.apply_payment_provider_event(jsonb)','execute')
     or has_function_privilege('authenticated','public.apply_refund_provider_event(jsonb)','execute')
     or has_function_privilege('anon','public.apply_payment_provider_event(jsonb)','execute')
     or has_function_privilege('anon','public.apply_refund_provider_event(jsonb)','execute') then
    raise exception 'normal clients can apply provider truth';
  end if;

  if not has_function_privilege('service_role','public.apply_payment_provider_event(jsonb)','execute')
     or not has_function_privilege('service_role','public.apply_refund_provider_event(jsonb)','execute') then
    raise exception 'service-role provider adapter grants are missing';
  end if;

  if exists (
    select 1
    from (values
      ('payment_provider_configs'),('payment_intents'),('payment_events'),
      ('payment_refunds'),('payment_refund_events'),('payment_webhook_receipts')
    ) t(table_name)
    where has_table_privilege('authenticated','public.'||t.table_name,'select')
       or has_table_privilege('authenticated','public.'||t.table_name,'insert')
       or has_table_privilege('authenticated','public.'||t.table_name,'update')
       or has_table_privilege('authenticated','public.'||t.table_name,'delete')
       or has_table_privilege('anon','public.'||t.table_name,'select')
  ) then
    raise exception 'Phase 9 tables expose direct client authority';
  end if;

  if exists (
    select 1
    from (values
      ('payment_provider_configs'),('payment_intents'),('payment_events'),
      ('payment_refunds'),('payment_refund_events'),('payment_webhook_receipts')
    ) t(table_name)
    join pg_class c on c.relname=t.table_name
    join pg_namespace n on n.oid=c.relnamespace and n.nspname='public'
    where not c.relrowsecurity or not c.relforcerowsecurity
  ) then
    raise exception 'Phase 9 table is missing RLS/FORCE RLS';
  end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
  ('99000000-0000-0000-0000-000000000001','phase9-customer@example.test','{}'::jsonb,now(),now()),
  ('99000000-0000-0000-0000-000000000002','phase9-admin@example.test','{}'::jsonb,now(),now());

update public.user_profiles set app_role='admin'
where user_id='99000000-0000-0000-0000-000000000002';

insert into public.payment_provider_configs(
  provider_key,display_name,environment,is_active,customer_enabled,pos_enabled,supports_refunds
) values ('phase9_test','Phase 9 Test Provider','test',true,true,true,true);

select set_config(
  'test.phase9.member_id',
  (select id::text from public.members where user_id='99000000-0000-0000-0000-000000000001'::uuid),
  false
);

insert into public.orders(
  id,order_number,source,customer_user_id,member_id,created_by_user_id,
  client_request_id,request_hash,fulfillment_type,status,
  subtotal_sen,discount_sen,total_sen,branch_id
) values (
  '99100000-0000-0000-0000-000000000001',990000001,'customer',
  '99000000-0000-0000-0000-000000000001'::uuid,
  current_setting('test.phase9.member_id')::uuid,
  '99000000-0000-0000-0000-000000000001'::uuid,
  '99110000-0000-0000-0000-000000000001'::uuid,
  md5('phase9 external order'),
  'asap','confirmed',1000,0,1000,private.default_branch_id()
);

-- Customer creates an idempotent external payment intent. The provider remains
-- the only authority that can advance authorization/capture truth.
set local role authenticated;
do $$
declare
  v_customer uuid:='99000000-0000-0000-0000-000000000001';
  v_payment jsonb;
  v_retry jsonb;
  v_intent uuid;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);

  select public.request_external_payment(
    '99100000-0000-0000-0000-000000000001',
    '99120000-0000-0000-0000-000000000001'
  ) into v_payment;

  if v_payment->>'tenderType'<>'external'
     or v_payment->>'paymentState'<>'pending'
     or (v_payment->>'refundedSen')::bigint<>0
     or v_payment#>>'{latestIntent,state}'<>'created'
     or not (v_payment->>'providerAvailable')::boolean then
    raise exception 'external payment request did not project pending state: %',v_payment;
  end if;

  v_intent := (v_payment#>>'{latestIntent,id}')::uuid;
  perform set_config('test.phase9.intent_id',v_intent::text,false);

  select public.request_external_payment(
    '99100000-0000-0000-0000-000000000001',
    '99120000-0000-0000-0000-000000000001'
  ) into v_retry;
  if v_retry#>>'{latestIntent,id}'<>v_intent::text then
    raise exception 'payment idempotency retry created a different intent';
  end if;

  begin
    perform public.apply_payment_provider_event(jsonb_build_object(
      'providerKey','phase9_test','providerEventId','evt-client-denied',
      'paymentIntentId',v_intent,'eventType','captured',
      'payloadSha256',repeat('a',64)
    ));
    raise exception 'authenticated customer applied provider truth';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

set local role service_role;
do $$
declare
  v_intent uuid:=current_setting('test.phase9.intent_id')::uuid;
  v_state jsonb;
begin
  select public.apply_payment_provider_event(jsonb_build_object(
    'providerKey','phase9_test','providerEventId','evt-auth-1',
    'paymentIntentId',v_intent,'eventType','authorized',
    'providerPaymentId','pay-phase9-1','payloadSha256',repeat('1',64),
    'occurredAt',now()
  )) into v_state;
  if v_state#>>'{latestIntent,state}'<>'authorized' or v_state->>'paymentState'<>'pending' then
    raise exception 'authorized event incorrectly projected order state: %',v_state;
  end if;

  select public.apply_payment_provider_event(jsonb_build_object(
    'providerKey','phase9_test','providerEventId','evt-capture-1',
    'paymentIntentId',v_intent,'eventType','captured',
    'providerPaymentId','pay-phase9-1','payloadSha256',repeat('2',64),
    'occurredAt',now()
  )) into v_state;
  if v_state#>>'{latestIntent,state}'<>'captured'
     or v_state->>'paymentState'<>'paid'
     or v_state->>'tenderType'<>'external'
     or v_state->>'paidAt' is null then
    raise exception 'capture did not become trusted paid state: %',v_state;
  end if;

  -- Same provider event + digest is a no-op/idempotent retry.
  perform public.apply_payment_provider_event(jsonb_build_object(
    'providerKey','phase9_test','providerEventId','evt-capture-1',
    'paymentIntentId',v_intent,'eventType','captured',
    'providerPaymentId','pay-phase9-1','payloadSha256',repeat('2',64),
    'occurredAt',now()
  ));

  begin
    perform public.apply_payment_provider_event(jsonb_build_object(
      'providerKey','phase9_test','providerEventId','evt-capture-1',
      'paymentIntentId',v_intent,'eventType','captured',
      'providerPaymentId','pay-phase9-1','payloadSha256',repeat('3',64)
    ));
    raise exception 'provider event id accepted a different digest';
  exception when unique_violation then
    if sqlerrm not ilike '%different content%' then raise; end if;
  end;

  select public.apply_payment_provider_event(jsonb_build_object(
    'providerKey','phase9_test','providerEventId','evt-settle-1',
    'paymentIntentId',v_intent,'eventType','settled',
    'providerPaymentId','pay-phase9-1','payloadSha256',repeat('4',64)
  )) into v_state;
  if v_state#>>'{latestIntent,settlementState}'<>'settled' then
    raise exception 'settlement fact was not kept distinct from capture: %',v_state;
  end if;
end;
$$;
reset role;

-- Admin requests an external refund. Requesting reserves refundable balance but
-- does not yet claim that money was refunded.
set local role authenticated;
do $$
declare
  v_admin uuid:='99000000-0000-0000-0000-000000000002';
  v_state jsonb;
  v_refund uuid;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);

  select public.request_external_refund(jsonb_build_object(
    'orderId','99100000-0000-0000-0000-000000000001',
    'idempotencyKey','99130000-0000-0000-0000-000000000001',
    'amountSen',400,
    'reason','Phase 9 partial external refund'
  )) into v_state;
  if v_state->>'paymentState'<>'paid' or (v_state->>'refundedSen')::bigint<>0 then
    raise exception 'requested refund was falsely projected as succeeded: %',v_state;
  end if;

  select id into v_refund from public.payment_refunds
  where order_id='99100000-0000-0000-0000-000000000001' and idempotency_key='99130000-0000-0000-0000-000000000001';
  perform set_config('test.phase9.refund1_id',v_refund::text,false);

  begin
    perform public.request_external_refund(jsonb_build_object(
      'orderId','99100000-0000-0000-0000-000000000001',
      'idempotencyKey','99130000-0000-0000-0000-000000000002',
      'amountSen',700,
      'reason','Over reserve'
    ));
    raise exception 'refund reservations exceeded accepted order total';
  exception when invalid_parameter_value then
    if sqlerrm not ilike '%exceeds refundable%' then raise; end if;
  end;
end;
$$;
reset role;

set local role service_role;
do $$
declare
  v_refund uuid:=current_setting('test.phase9.refund1_id')::uuid;
  v_state jsonb;
begin
  select public.apply_refund_provider_event(jsonb_build_object(
    'providerKey','phase9_test','providerEventId','evt-refund-1',
    'refundId',v_refund,'eventType','succeeded',
    'providerRefundId','refund-phase9-1','payloadSha256',repeat('5',64)
  )) into v_state;
  if v_state->>'paymentState'<>'partially_refunded'
     or (v_state->>'refundedSen')::bigint<>400
     or (v_state->>'refundableSen')::bigint<>600 then
    raise exception 'succeeded refund projection is wrong: %',v_state;
  end if;
end;
$$;
reset role;

set local role authenticated;
do $$
declare
  v_admin uuid:='99000000-0000-0000-0000-000000000002';
  v_state jsonb;
  v_refund uuid;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);

  -- Partially refunded paid order is still protected from cancellation.
  begin
    perform public.transition_order_status(
      '99100000-0000-0000-0000-000000000001','cancelled',1,'should fail'
    );
    raise exception 'partially refunded order cancelled before full refund';
  exception when insufficient_privilege then
    if sqlerrm not ilike '%fully refunded%' then raise; end if;
  end;

  select public.request_external_refund(jsonb_build_object(
    'orderId','99100000-0000-0000-0000-000000000001',
    'idempotencyKey','99130000-0000-0000-0000-000000000003',
    'amountSen',600,
    'reason','Phase 9 remaining external refund'
  )) into v_state;
  select id into v_refund from public.payment_refunds
  where order_id='99100000-0000-0000-0000-000000000001' and idempotency_key='99130000-0000-0000-0000-000000000003';
  perform set_config('test.phase9.refund2_id',v_refund::text,false);
end;
$$;
reset role;

set local role service_role;
select public.apply_refund_provider_event(jsonb_build_object(
  'providerKey','phase9_test','providerEventId','evt-refund-2',
  'refundId',current_setting('test.phase9.refund2_id'),'eventType','succeeded',
  'providerRefundId','refund-phase9-2','payloadSha256',repeat('6',64)
));
reset role;

set local role authenticated;
do $$
declare
  v_admin uuid:='99000000-0000-0000-0000-000000000002';
  v_state jsonb;
  v_order jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  select public.get_order_payment_state('99100000-0000-0000-0000-000000000001') into v_state;
  if v_state->>'paymentState'<>'refunded'
     or (v_state->>'refundedSen')::bigint<>1000
     or (v_state->>'refundableSen')::bigint<>0 then
    raise exception 'full refund did not reconcile exactly: %',v_state;
  end if;

  select public.transition_order_status(
    '99100000-0000-0000-0000-000000000001','cancelled',1,'fully refunded cancellation'
  ) into v_order;
  if v_order->>'status'<>'cancelled' then
    raise exception 'fully refunded order could not cancel: %',v_order;
  end if;
end;
$$;
reset role;

-- Disabling the non-secret provider config must fail closed: the app is not
-- allowed to show/create a fictional external processor payment.
update public.payment_provider_configs set is_active=false,customer_enabled=false,pos_enabled=false
where provider_key='phase9_test';

insert into public.orders(
  id,order_number,source,customer_user_id,member_id,created_by_user_id,
  client_request_id,request_hash,fulfillment_type,status,
  subtotal_sen,discount_sen,total_sen,branch_id
) values (
  '99100000-0000-0000-0000-000000000002',990000002,'customer',
  '99000000-0000-0000-0000-000000000001'::uuid,
  current_setting('test.phase9.member_id')::uuid,
  '99000000-0000-0000-0000-000000000001'::uuid,
  '99110000-0000-0000-0000-000000000002'::uuid,
  md5('phase9 provider unavailable'),
  'asap','confirmed',500,0,500,private.default_branch_id()
);

set local role authenticated;
do $$
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub','99000000-0000-0000-0000-000000000001'::uuid,'role','authenticated')::text,true);
  begin
    perform public.request_external_payment(
      '99100000-0000-0000-0000-000000000002','99120000-0000-0000-0000-000000000002'
    );
    raise exception 'external payment started without active provider';
  exception when object_not_in_prerequisite_state then
    if sqlerrm not ilike '%not configured%' then raise; end if;
  end;
end;
$$;
reset role;

-- Append-only event history remains immutable even to owner-level SQL paths.
do $$
begin
  begin
    update public.payment_events set details='{"tampered":true}'::jsonb limit 1;
    raise exception 'payment event history was mutable';
  exception when syntax_error then
    -- UPDATE ... LIMIT is not PostgreSQL syntax; use deterministic row below.
    null;
  end;

  begin
    update public.payment_events
    set details='{"tampered":true}'::jsonb
    where id=(select id from public.payment_events order by created_at,id limit 1);
    raise exception 'payment event history was mutable';
  exception when insufficient_privilege then
    if sqlerrm not ilike '%append-only%' then raise; end if;
  end;
end;
$$;

rollback;
