-- TASK-OPS-009 / Phase 9 reporting/provider-capability regression.
-- Transactional: all synthetic payment/refund facts are rolled back.

begin;

do $$
begin
  if not has_function_privilege('authenticated','public.get_payment_provider_admin_state()','execute')
     or not has_function_privilege('authenticated','public.get_admin_payment_audit_events(jsonb)','execute') then
    raise exception 'Phase 9 provider/reporting grants are incomplete';
  end if;
  if has_function_privilege('anon','public.get_payment_provider_admin_state()','execute')
     or has_function_privilege('anon','public.get_admin_payment_audit_events(jsonb)','execute') then
    raise exception 'Phase 9 provider/reporting authority exposed to anon';
  end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('99400000-0000-0000-0000-000000000001','phase9-report-customer@example.test','{}'::jsonb,now(),now()),
 ('99400000-0000-0000-0000-000000000002','phase9-report-admin@example.test','{}'::jsonb,now(),now());

update public.user_profiles set app_role='admin'
where user_id='99400000-0000-0000-0000-000000000002';

-- The true-concurrency fixture intentionally persists on the disposable CI
-- database for its companion shell test. Isolate this transactional regression
-- from that prior active provider without weakening the one-active-provider rule.
update public.payment_provider_configs
set is_active=false, customer_enabled=false, pos_enabled=false
where is_active or customer_enabled or pos_enabled;

insert into public.payment_provider_configs(
  provider_key,display_name,environment,is_active,customer_enabled,pos_enabled,supports_refunds
) values ('phase9_report','Phase 9 Reporting Provider','test',true,true,false,false);

select set_config(
  'test.phase9report.member_id',
  (select id::text from public.members where user_id='99400000-0000-0000-0000-000000000001'::uuid),
  false
);

insert into public.orders(
  id,source,customer_user_id,member_id,created_by_user_id,
  client_request_id,request_hash,fulfillment_type,status,
  subtotal_sen,discount_sen,total_sen,branch_id
) values (
  '99410000-0000-0000-0000-000000000001','customer',
  '99400000-0000-0000-0000-000000000001'::uuid,
  current_setting('test.phase9report.member_id')::uuid,
  '99400000-0000-0000-0000-000000000001'::uuid,
  '99420000-0000-0000-0000-000000000001'::uuid,
  md5('phase9 reporting payment order'),'asap','confirmed',
  1000,0,1000,private.default_branch_id()
);

set local role authenticated;
do $$
declare
  v_state jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub','99400000-0000-0000-0000-000000000001'::uuid,'role','authenticated')::text,
    true
  );
  select public.request_external_payment(
    '99410000-0000-0000-0000-000000000001',
    '99430000-0000-0000-0000-000000000001'
  ) into v_state;
  perform set_config('test.phase9report.intent_id',v_state#>>'{latestIntent,id}',false);
end;
$$;
reset role;

set local role service_role;
select public.apply_payment_provider_event(jsonb_build_object(
  'providerKey','phase9_report',
  'providerEventId','phase9-report-capture',
  'paymentIntentId',current_setting('test.phase9report.intent_id'),
  'eventType','captured',
  'providerPaymentId','phase9-report-payment',
  'payloadSha256',repeat('a',64)
));
reset role;

set local role authenticated;
do $$
declare
  v_detail text;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub','99400000-0000-0000-0000-000000000002'::uuid,'role','authenticated')::text,
    true
  );
  begin
    perform public.request_external_refund(jsonb_build_object(
      'orderId','99410000-0000-0000-0000-000000000001',
      'idempotencyKey','99440000-0000-0000-0000-000000000001',
      'amountSen',400,
      'reason','provider capability negative test'
    ));
    raise exception 'provider without refund capability accepted a refund';
  exception when object_not_in_prerequisite_state then
    get stacked diagnostics v_detail=PG_EXCEPTION_DETAIL;
    if v_detail is distinct from 'REFUND_PROVIDER_UNSUPPORTED' then
      raise exception 'unexpected unsupported-refund detail: %',v_detail;
    end if;
  end;
end;
$$;
reset role;

update public.payment_provider_configs
set supports_refunds=true
where provider_key='phase9_report';

set local role authenticated;
do $$
declare
  v_state jsonb;
  v_refund_id text;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub','99400000-0000-0000-0000-000000000002'::uuid,'role','authenticated')::text,
    true
  );
  select public.request_external_refund(jsonb_build_object(
    'orderId','99410000-0000-0000-0000-000000000001',
    'idempotencyKey','99440000-0000-0000-0000-000000000002',
    'amountSen',400,
    'reason','reporting refund'
  )) into v_state;

  select refund->>'id' into strict v_refund_id
  from jsonb_array_elements(v_state->'refunds') refund
  where refund->>'reason'='reporting refund';

  perform set_config('test.phase9report.refund_id',v_refund_id,false);
end;
$$;
reset role;

set local role service_role;
select public.apply_refund_provider_event(jsonb_build_object(
  'providerKey','phase9_report',
  'providerEventId','phase9-report-refund',
  'refundId',current_setting('test.phase9report.refund_id'),
  'eventType','succeeded',
  'providerRefundId','phase9-report-refund-id',
  'payloadSha256',repeat('b',64)
));
reset role;

set local role authenticated;
do $$
declare
  v_admin uuid:='99400000-0000-0000-0000-000000000002';
  v_branch uuid:=private.default_branch_id();
  v_timezone text;
  v_date text;
  v_filter jsonb;
  v_summary jsonb;
  v_transactions jsonb;
  v_payment_audit jsonb;
  v_providers jsonb;
begin
  select timezone into strict v_timezone from public.branches where id=v_branch;
  v_date:=((now() at time zone v_timezone)::date)::text;
  v_filter:=jsonb_build_object(
    'fromDate',v_date,
    'toDate',v_date,
    'branchId',v_branch,
    'pageSize',100,
    'offset',0
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );

  select public.get_payment_provider_admin_state() into v_providers;
  if not exists (
    select 1 from jsonb_array_elements(v_providers) p
    where p->>'providerKey'='phase9_report'
      and (p->>'supportsRefunds')::boolean
      and (p->>'isActive')::boolean
  ) then
    raise exception 'provider admin state omitted non-secret capability facts: %',v_providers;
  end if;

  select public.get_admin_reporting_summary(v_filter) into v_summary;
  if not (v_summary#>>'{semantics,refundDataAvailable}')::boolean
     or not (v_summary#>>'{semantics,providerSettlementStateAvailable}')::boolean
     or (v_summary#>>'{semantics,acceptedOrderValueIsSettlement}')::boolean then
    raise exception 'Phase 9 reporting semantics are misleading: %',v_summary->'semantics';
  end if;
  if (v_summary#>>'{orders,acceptedOrderValueSen}')::bigint < 1000
     or (v_summary#>>'{payments,externalCapturedSen}')::bigint < 1000
     or (v_summary#>>'{payments,succeededRefundSen}')::bigint < 400
     or (v_summary#>>'{payments,externalRefundedSen}')::bigint < 400
     or (v_summary#>>'{payments,netCapturedAfterRefundSen}')::bigint
          <> (v_summary#>>'{payments,grossCapturedSen}')::bigint
             - (v_summary#>>'{payments,succeededRefundSen}')::bigint
     or not (v_summary#>>'{payments,refundReconciled}')::boolean then
    raise exception 'Phase 9 payment summary does not reconcile: %',v_summary->'payments';
  end if;

  select public.get_admin_transaction_report(v_filter) into v_transactions;
  if not (v_transactions#>>'{semantics,refundDataAvailable}')::boolean
     or not (v_transactions#>>'{semantics,providerLifecycleAvailable}')::boolean then
    raise exception 'Phase 9 transaction semantics are missing: %',v_transactions->'semantics';
  end if;
  if not exists (
    select 1
    from jsonb_array_elements(v_transactions->'items') x
    where x->>'orderId'='99410000-0000-0000-0000-000000000001'
      and (x->>'totalSen')::bigint=1000
      and (x->>'refundedSen')::bigint=400
      and (x->>'refundableSen')::bigint=600
      and (x->>'refundReservedSen')::bigint=400
      and (x->>'refundReconciled')::boolean
      and x#>>'{latestPaymentIntent,state}'='captured'
      and jsonb_array_length(x->'refunds')=1
  ) then
    raise exception 'Phase 9 transaction report omitted payment/refund facts: %',v_transactions;
  end if;

  select public.get_admin_payment_audit_events(v_filter) into v_payment_audit;
  if (v_payment_audit->>'totalCount')::bigint < 4
     or not exists (
       select 1 from jsonb_array_elements(v_payment_audit->'items') x
       where x->>'category'='payment' and x->>'action'='captured'
     )
     or not exists (
       select 1 from jsonb_array_elements(v_payment_audit->'items') x
       where x->>'category'='refund' and x->>'action'='succeeded'
     ) then
    raise exception 'Phase 9 payment/refund audit projection is incomplete: %',v_payment_audit;
  end if;
end;
$$;
reset role;

rollback;
