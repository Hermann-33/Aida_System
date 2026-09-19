-- TASK-OPS-009 / Phase 9 cash refund end-to-end regression.
-- Transactional: topology, user, shift, order, refund and cash movement fixtures roll back.
begin;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values ('99400000-0000-0000-0000-000000000001','phase9-cash-admin@example.test','{}'::jsonb,now(),now());
update public.user_profiles
set app_role='admin'
where user_id='99400000-0000-0000-0000-000000000001';

set local role authenticated;
do $$
declare
  v_actor uuid := '99400000-0000-0000-0000-000000000001';
  v_branch_id uuid := private.default_branch_id();
  v_sales_point jsonb;
  v_terminal jsonb;
  v_issue jsonb;
  v_enrol jsonb;
  v_credential text;
  v_shift jsonb;
  v_item_id uuid;
  v_order jsonb;
  v_state jsonb;
  v_retry jsonb;
  v_order_id uuid;
  v_shift_id uuid;
  v_total bigint;
  v_refund bigint;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_actor,'role','authenticated')::text,
    true
  );

  select public.save_sales_point(jsonb_build_object(
    'branchId',v_branch_id,
    'code','SP-P9-CASH',
    'name','Phase 9 Cash Refund Counter',
    'isActive',true
  )) into v_sales_point;

  select public.save_terminal(jsonb_build_object(
    'salesPointId',(v_sales_point->>'id')::uuid,
    'code','POS-P9-CASH-01',
    'name','Phase 9 Cash Refund POS'
  )) into v_terminal;

  select public.issue_terminal_enrolment_code((v_terminal->>'id')::uuid) into v_issue;
  select public.enrol_terminal(v_issue->>'code') into v_enrol;
  v_credential := v_enrol->>'credential';
  if v_credential is null then
    raise exception 'Phase 9 cash test terminal enrolment returned no credential';
  end if;

  select public.open_shift(v_credential,5000) into v_shift;
  v_shift_id := (v_shift->>'id')::uuid;

  select id into strict v_item_id
  from public.catalogue_items
  where kind='product'
    and is_published
    and is_available
    and not exists (
      select 1 from public.catalogue_item_variants v
      where v.item_id=catalogue_items.id and v.is_available
    )
    and not is_drink
  order by created_at,id
  limit 1;

  select public.place_pos_order(
    jsonb_build_object(
      'clientRequestId','99410000-0000-0000-0000-000000000001',
      'fulfillmentType','asap',
      'tenderType','cash',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,
        'addOnIds','[]'::jsonb,
        'quantity',1
      ))
    ),
    v_credential
  ) into v_order;

  v_order_id := (v_order->>'id')::uuid;
  v_total := (v_order->>'totalSen')::bigint;
  v_refund := greatest(1, floor(v_total::numeric/2)::bigint);

  select public.refund_cash_order(
    jsonb_build_object(
      'orderId',v_order_id,
      'idempotencyKey','99420000-0000-0000-0000-000000000001',
      'amountSen',v_refund,
      'reason','Phase 9 cash refund E2E'
    ),
    v_credential
  ) into v_state;

  if (v_state->>'refundedSen')::bigint <> v_refund
     or (v_state->>'refundableSen')::bigint <> v_total-v_refund
     or v_state->>'paymentState' not in ('partially_refunded','refunded') then
    raise exception 'cash refund projection mismatch: %',v_state;
  end if;

  select public.refund_cash_order(
    jsonb_build_object(
      'orderId',v_order_id,
      'idempotencyKey','99420000-0000-0000-0000-000000000001',
      'amountSen',v_refund,
      'reason','Phase 9 cash refund E2E'
    ),
    v_credential
  ) into v_retry;

  if (v_retry->>'refundedSen')::bigint <> v_refund then
    raise exception 'cash refund idempotent retry changed refund total: %',v_retry;
  end if;

  perform set_config('test.phase9.cash_order_id',v_order_id::text,false);
  perform set_config('test.phase9.cash_shift_id',v_shift_id::text,false);
  perform set_config('test.phase9.cash_refund_sen',v_refund::text,false);
end;
$$;
reset role;

do $$
declare
  v_order_id uuid := current_setting('test.phase9.cash_order_id')::uuid;
  v_shift_id uuid := current_setting('test.phase9.cash_shift_id')::uuid;
  v_refund bigint := current_setting('test.phase9.cash_refund_sen')::bigint;
  v_refund_count bigint;
  v_cash_count bigint;
  v_event_count bigint;
begin
  select count(*) into v_refund_count
  from public.payment_refunds
  where order_id=v_order_id
    and tender_type='cash'
    and state='succeeded'
    and amount_sen=v_refund;

  select count(*) into v_cash_count
  from public.cash_movements
  where shift_id=v_shift_id
    and movement_type='cash_out'
    and amount_sen=v_refund
    and reason='Phase 9 cash refund E2E';

  select count(*) into v_event_count
  from public.payment_refund_events e
  join public.payment_refunds r on r.id=e.refund_id
  where r.order_id=v_order_id
    and e.event_type='succeeded';

  if v_refund_count<>1 then
    raise exception 'cash refund idempotency created % refund rows',v_refund_count;
  end if;
  if v_cash_count<>1 then
    raise exception 'cash refund idempotency created % cash-out movements',v_cash_count;
  end if;
  if v_event_count<>1 then
    raise exception 'cash refund idempotency created % refund events',v_event_count;
  end if;
end;
$$;

rollback;
