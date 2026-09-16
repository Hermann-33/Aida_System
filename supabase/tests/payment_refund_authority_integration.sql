-- TASK-OPS-009 / Phase 9 provider-neutral payment/refund regression.
-- Transactional: all fixtures are rolled back.
begin;

do $$
begin
  if not has_function_privilege('authenticated','public.get_order_payment_state(uuid)','execute')
     or not has_function_privilege('authenticated','public.request_external_payment(uuid,uuid)','execute')
     or not has_function_privilege('authenticated','public.request_external_refund(jsonb)','execute') then
    raise exception 'authenticated Phase 9 grants are incomplete';
  end if;
  if has_function_privilege('anon','public.get_order_payment_state(uuid)','execute')
     or has_function_privilege('anon','public.request_external_payment(uuid,uuid)','execute')
     or has_function_privilege('authenticated','public.apply_payment_provider_event(jsonb)','execute')
     or has_function_privilege('authenticated','public.apply_refund_provider_event(jsonb)','execute') then
    raise exception 'Phase 9 provider truth is exposed to a normal client';
  end if;
  if not has_function_privilege('service_role','public.apply_payment_provider_event(jsonb)','execute')
     or not has_function_privilege('service_role','public.apply_refund_provider_event(jsonb)','execute') then
    raise exception 'service-role provider adapter grants are missing';
  end if;
  if exists (
    select 1 from (values
      ('payment_provider_configs'),('payment_intents'),('payment_events'),
      ('payment_refunds'),('payment_refund_events'),('payment_webhook_receipts')
    ) t(name)
    where has_table_privilege('authenticated','public.'||t.name,'select')
       or has_table_privilege('authenticated','public.'||t.name,'insert')
       or has_table_privilege('authenticated','public.'||t.name,'update')
       or has_table_privilege('authenticated','public.'||t.name,'delete')
       or has_table_privilege('anon','public.'||t.name,'select')
  ) then
    raise exception 'Phase 9 tables expose direct client authority';
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

select set_config('test.phase9.member_id',(
 select id::text from public.members where user_id='99000000-0000-0000-0000-000000000001'::uuid
),false);

insert into public.orders(
 id,order_number,source,customer_user_id,member_id,created_by_user_id,
 client_request_id,request_hash,fulfillment_type,status,
 subtotal_sen,discount_sen,total_sen,branch_id
) values (
 '99100000-0000-0000-0000-000000000001',990000001,'customer',
 '99000000-0000-0000-0000-000000000001'::uuid,current_setting('test.phase9.member_id')::uuid,
 '99000000-0000-0000-0000-000000000001'::uuid,
 '99110000-0000-0000-0000-000000000001'::uuid,md5('phase9 order'),
 'asap','confirmed',1000,0,1000,private.default_branch_id()
);

set local role authenticated;
do $$
declare
 v_actor uuid:='99000000-0000-0000-0000-000000000001';
 v_state jsonb;
 v_retry jsonb;
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor,'role','authenticated')::text,true);
 select public.request_external_payment(
   '99100000-0000-0000-0000-000000000001','99120000-0000-0000-0000-000000000001'
 ) into v_state;
 if v_state->>'tenderType'<>'external'
    or v_state->>'paymentState'<>'pending'
    or v_state#>>'{latestIntent,state}'<>'created'
    or (v_state->>'refundedSen')::bigint<>0 then
   raise exception 'external intent did not project pending state: %',v_state;
 end if;
 perform set_config('test.phase9.intent_id',v_state#>>'{latestIntent,id}',false);
 select public.request_external_payment(
   '99100000-0000-0000-0000-000000000001','99120000-0000-0000-0000-000000000001'
 ) into v_retry;
 if v_retry#>>'{latestIntent,id}'<>current_setting('test.phase9.intent_id') then
   raise exception 'payment idempotency retry changed intent';
 end if;
end;
$$;
reset role;

set local role service_role;
do $$
declare v_state jsonb; v_intent uuid:=current_setting('test.phase9.intent_id')::uuid;
begin
 select public.apply_payment_provider_event(jsonb_build_object(
   'providerKey','phase9_test','providerEventId','evt-auth-1','paymentIntentId',v_intent,
   'eventType','authorized','providerPaymentId','pay-phase9-1','payloadSha256',repeat('1',64)
 )) into v_state;
 if v_state#>>'{latestIntent,state}'<>'authorized' or v_state->>'paymentState'<>'pending' then
   raise exception 'authorization incorrectly projected state: %',v_state;
 end if;

 select public.apply_payment_provider_event(jsonb_build_object(
   'providerKey','phase9_test','providerEventId','evt-cap-1','paymentIntentId',v_intent,
   'eventType','captured','providerPaymentId','pay-phase9-1','payloadSha256',repeat('2',64)
 )) into v_state;
 if v_state#>>'{latestIntent,state}'<>'captured'
    or v_state->>'paymentState'<>'paid'
    or v_state->>'paidAt' is null then
   raise exception 'capture did not become paid state: %',v_state;
 end if;

 -- Exact replay is idempotent.
 perform public.apply_payment_provider_event(jsonb_build_object(
   'providerKey','phase9_test','providerEventId','evt-cap-1','paymentIntentId',v_intent,
   'eventType','captured','providerPaymentId','pay-phase9-1','payloadSha256',repeat('2',64)
 ));

 begin
   perform public.apply_payment_provider_event(jsonb_build_object(
     'providerKey','phase9_test','providerEventId','evt-cap-1','paymentIntentId',v_intent,
     'eventType','captured','providerPaymentId','pay-phase9-1','payloadSha256',repeat('3',64)
   ));
   raise exception 'provider event replay accepted a different digest';
 exception when unique_violation then
   if sqlerrm not ilike '%different content%' then raise; end if;
 end;

 select public.apply_payment_provider_event(jsonb_build_object(
   'providerKey','phase9_test','providerEventId','evt-settle-1','paymentIntentId',v_intent,
   'eventType','settled','providerPaymentId','pay-phase9-1','payloadSha256',repeat('4',64)
 )) into v_state;
 if v_state#>>'{latestIntent,settlementState}'<>'settled' then
   raise exception 'settlement was not kept distinct from capture: %',v_state;
 end if;
end;
$$;
reset role;

set local role authenticated;
do $$
declare v_actor uuid:='99000000-0000-0000-0000-000000000002'; v_state jsonb;
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor,'role','authenticated')::text,true);
 select public.request_external_refund(jsonb_build_object(
   'orderId','99100000-0000-0000-0000-000000000001',
   'idempotencyKey','99130000-0000-0000-0000-000000000001',
   'amountSen',400,'reason','partial refund'
 )) into v_state;
 if v_state->>'paymentState'<>'paid' or (v_state->>'refundedSen')::bigint<>0 then
   raise exception 'requested refund falsely became succeeded: %',v_state;
 end if;
 perform set_config('test.phase9.refund1_id',(
   select id::text from public.payment_refunds
   where order_id='99100000-0000-0000-0000-000000000001'::uuid
     and idempotency_key='99130000-0000-0000-0000-000000000001'::uuid
 ),false);
 begin
   perform public.request_external_refund(jsonb_build_object(
     'orderId','99100000-0000-0000-0000-000000000001',
     'idempotencyKey','99130000-0000-0000-0000-000000000002',
     'amountSen',700,'reason','over reserve'
   ));
   raise exception 'refund reservations exceeded order total';
 exception when invalid_parameter_value then
   if sqlerrm not ilike '%exceeds refundable%' then raise; end if;
 end;
end;
$$;
reset role;

set local role service_role;
select public.apply_refund_provider_event(jsonb_build_object(
 'providerKey','phase9_test','providerEventId','evt-ref-1',
 'refundId',current_setting('test.phase9.refund1_id'),
 'eventType','succeeded','providerRefundId','refund-phase9-1','payloadSha256',repeat('5',64)
));
reset role;

set local role authenticated;
do $$
declare v_actor uuid:='99000000-0000-0000-0000-000000000002'; v_state jsonb;
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor,'role','authenticated')::text,true);
 select public.get_order_payment_state('99100000-0000-0000-0000-000000000001') into v_state;
 if v_state->>'paymentState'<>'partially_refunded'
    or (v_state->>'refundedSen')::bigint<>400
    or (v_state->>'refundableSen')::bigint<>600 then
   raise exception 'partial refund projection mismatch: %',v_state;
 end if;
 begin
   perform public.transition_order_status(
     '99100000-0000-0000-0000-000000000001','cancelled',1,'blocked before full refund'
   );
   raise exception 'partially refunded order cancelled';
 exception when insufficient_privilege then
   if sqlerrm not ilike '%fully refunded%' then raise; end if;
 end;
 select public.request_external_refund(jsonb_build_object(
   'orderId','99100000-0000-0000-0000-000000000001',
   'idempotencyKey','99130000-0000-0000-0000-000000000003',
   'amountSen',600,'reason','remaining refund'
 )) into v_state;
 perform set_config('test.phase9.refund2_id',(
   select id::text from public.payment_refunds
   where order_id='99100000-0000-0000-0000-000000000001'::uuid
     and idempotency_key='99130000-0000-0000-0000-000000000003'::uuid
 ),false);
end;
$$;
reset role;

set local role service_role;
select public.apply_refund_provider_event(jsonb_build_object(
 'providerKey','phase9_test','providerEventId','evt-ref-2',
 'refundId',current_setting('test.phase9.refund2_id'),
 'eventType','succeeded','providerRefundId','refund-phase9-2','payloadSha256',repeat('6',64)
));
reset role;

set local role authenticated;
do $$
declare v_actor uuid:='99000000-0000-0000-0000-000000000002'; v_state jsonb; v_order jsonb;
begin
 perform set_config('request.jwt.claims',jsonb_build_object('sub',v_actor,'role','authenticated')::text,true);
 select public.get_order_payment_state('99100000-0000-0000-0000-000000000001') into v_state;
 if v_state->>'paymentState'<>'refunded'
    or (v_state->>'refundedSen')::bigint<>1000
    or (v_state->>'refundableSen')::bigint<>0 then
   raise exception 'full refund did not reconcile: %',v_state;
 end if;
 select public.transition_order_status(
   '99100000-0000-0000-0000-000000000001','cancelled',1,'fully refunded'
 ) into v_order;
 if v_order->>'status'<>'cancelled' then raise exception 'fully refunded cancellation failed'; end if;
end;
$$;
reset role;

-- Fail closed if no external provider is configured.
update public.payment_provider_configs
set is_active=false,customer_enabled=false,pos_enabled=false where provider_key='phase9_test';
insert into public.orders(
 id,order_number,source,customer_user_id,member_id,created_by_user_id,
 client_request_id,request_hash,fulfillment_type,status,subtotal_sen,discount_sen,total_sen,branch_id
) values (
 '99100000-0000-0000-0000-000000000002',990000002,'customer',
 '99000000-0000-0000-0000-000000000001'::uuid,current_setting('test.phase9.member_id')::uuid,
 '99000000-0000-0000-0000-000000000001'::uuid,'99110000-0000-0000-0000-000000000002'::uuid,
 md5('provider unavailable'),'asap','confirmed',500,0,500,private.default_branch_id()
);
set local role authenticated;
do $$
begin
 perform set_config('request.jwt.claims',jsonb_build_object(
   'sub','99000000-0000-0000-0000-000000000001'::uuid,'role','authenticated'
 )::text,true);
 begin
   perform public.request_external_payment(
     '99100000-0000-0000-0000-000000000002','99120000-0000-0000-0000-000000000002'
   );
   raise exception 'payment started without provider';
 exception when object_not_in_prerequisite_state then
   if sqlerrm not ilike '%not configured%' then raise; end if;
 end;
end;
$$;
reset role;

-- Append-only lifecycle events cannot be rewritten.
do $$
begin
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
