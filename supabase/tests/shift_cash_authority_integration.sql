-- TASK-OPS-003 / Phase 2 shift and cash authority regression.
-- Transactional: all synthetic users/topology/shifts/orders are rolled back.

begin;

do $$
begin
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='shifts'
  ) then
    raise exception 'shifts table is missing';
  end if;
  if not exists (
    select 1 from information_schema.tables
    where table_schema='public' and table_name='cash_movements'
  ) then
    raise exception 'cash_movements table is missing';
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='orders' and column_name='shift_id'
  ) then
    raise exception 'orders.shift_id is missing';
  end if;

  if has_function_privilege('anon','public.open_shift(text,bigint)','execute')
     or has_function_privilege('anon','public.get_current_shift(text)','execute')
     or has_function_privilege('anon','public.record_cash_movement(uuid,text,text,bigint,text)','execute')
     or has_function_privilege('anon','public.close_shift(uuid,text,bigint,text,text,bigint)','execute') then
    raise exception 'anonymous role has Phase 2 shift/cash authority';
  end if;

  if not has_function_privilege('authenticated','public.open_shift(text,bigint)','execute')
     or not has_function_privilege('authenticated','public.get_current_shift(text)','execute')
     or not has_function_privilege('authenticated','public.record_cash_movement(uuid,text,text,bigint,text)','execute')
     or not has_function_privilege('authenticated','public.close_shift(uuid,text,bigint,text,text,bigint)','execute') then
    raise exception 'authenticated role is missing Phase 2 RPC execution';
  end if;

  if has_table_privilege('authenticated','public.shifts','insert')
     or has_table_privilege('authenticated','public.shifts','update')
     or has_table_privilege('authenticated','public.shifts','delete')
     or has_table_privilege('authenticated','public.cash_movements','insert')
     or has_table_privilege('authenticated','public.cash_movements','update')
     or has_table_privilege('authenticated','public.cash_movements','delete') then
    raise exception 'authenticated role has direct shift/cash mutation grants';
  end if;

  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='shifts'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then
    raise exception 'shifts does not have forced RLS';
  end if;
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='cash_movements'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then
    raise exception 'cash_movements does not have forced RLS';
  end if;
end;
$$;

insert into auth.users (id,email,raw_user_meta_data,created_at,updated_at)
values
  ('43000000-0000-0000-0000-000000000001','shift-staff-one@example.test','{}'::jsonb,now(),now()),
  ('43000000-0000-0000-0000-000000000002','shift-staff-two@example.test','{}'::jsonb,now(),now()),
  ('43000000-0000-0000-0000-000000000003','shift-admin@example.test','{}'::jsonb,now(),now()),
  ('43000000-0000-0000-0000-000000000004','shift-customer@example.test','{}'::jsonb,now(),now());

update public.user_profiles
set app_role='staff'
where user_id in (
  '43000000-0000-0000-0000-000000000001',
  '43000000-0000-0000-0000-000000000002'
);

update public.user_profiles
set app_role='admin'
where user_id='43000000-0000-0000-0000-000000000003';

set local role authenticated;

do $$
declare
  v_staff_one uuid := '43000000-0000-0000-0000-000000000001';
  v_staff_two uuid := '43000000-0000-0000-0000-000000000002';
  v_admin uuid := '43000000-0000-0000-0000-000000000003';
  v_customer uuid := '43000000-0000-0000-0000-000000000004';
  v_branch jsonb;
  v_branch_id uuid;
  v_sales_point jsonb;
  v_sales_point_id uuid;
  v_terminal_one jsonb;
  v_terminal_two jsonb;
  v_terminal_one_id uuid;
  v_terminal_two_id uuid;
  v_issue jsonb;
  v_enrol jsonb;
  v_credential_one text;
  v_credential_two text;
  v_shift jsonb;
  v_shift_one_id uuid;
  v_shift_two_id uuid;
  v_version bigint;
  v_item_id uuid;
  v_order jsonb;
  v_retry jsonb;
  v_order_id uuid;
  v_total bigint;
  v_breakdown jsonb;
  v_expected bigint;
  v_movement jsonb;
  v_closed jsonb;
  v_customer_order jsonb;
  v_admin_list jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );

  select public.save_branch(jsonb_build_object(
    'code','BR-SHIFT-TEST',
    'name','Shift Test Branch',
    'timezone','Asia/Kuala_Lumpur',
    'isActive',true,
    'isDefault',false
  )) into v_branch;
  v_branch_id := (v_branch->>'id')::uuid;

  select public.save_sales_point(jsonb_build_object(
    'branchId',v_branch_id,
    'code','SP-SHIFT-TEST',
    'name','Shift Test Counter',
    'isActive',true
  )) into v_sales_point;
  v_sales_point_id := (v_sales_point->>'id')::uuid;

  select public.save_terminal(jsonb_build_object(
    'salesPointId',v_sales_point_id,
    'code','POS-SHIFT-TEST-01',
    'name','Shift Test POS 1'
  )) into v_terminal_one;
  v_terminal_one_id := (v_terminal_one->>'id')::uuid;

  select public.save_terminal(jsonb_build_object(
    'salesPointId',v_sales_point_id,
    'code','POS-SHIFT-TEST-02',
    'name','Shift Test POS 2'
  )) into v_terminal_two;
  v_terminal_two_id := (v_terminal_two->>'id')::uuid;

  perform public.save_employee_branch_assignments(
    v_staff_one,
    array[(select private.default_branch_id()),v_branch_id]
  );
  perform public.save_employee_branch_assignments(
    v_staff_two,
    array[(select private.default_branch_id()),v_branch_id]
  );

  select public.issue_terminal_enrolment_code(v_terminal_one_id) into v_issue;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_one,'role','authenticated')::text,
    true
  );
  select public.enrol_terminal(v_issue->>'code') into v_enrol;
  v_credential_one := v_enrol->>'credential';

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );
  select public.issue_terminal_enrolment_code(v_terminal_two_id) into v_issue;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_one,'role','authenticated')::text,
    true
  );
  select public.enrol_terminal(v_issue->>'code') into v_enrol;
  v_credential_two := v_enrol->>'credential';

  if v_credential_one is null or v_credential_two is null then
    raise exception 'terminal enrolment did not return credentials';
  end if;

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

  -- POS placement must fail before a trusted open shift exists.
  begin
    perform public.place_pos_order(
      jsonb_build_object(
        'clientRequestId','43100000-0000-0000-0000-000000000001',
        'fulfillmentType','asap',
        'tenderType','cash',
        'items',jsonb_build_array(jsonb_build_object(
          'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
        ))
      ),
      v_credential_one
    );
    raise exception 'POS order was accepted without an open shift';
  exception when insufficient_privilege then
    null;
  end;

  select public.open_shift(v_credential_one,10000) into v_shift;
  v_shift_one_id := (v_shift->>'id')::uuid;
  v_version := (v_shift->>'statusVersion')::bigint;

  if v_shift->>'status' <> 'open'
     or (v_shift->>'openingFloatSen')::bigint <> 10000
     or v_shift->>'terminalId' <> v_terminal_one_id::text
     or v_shift->>'operatorUserId' <> v_staff_one::text then
    raise exception 'opened shift snapshot is invalid: %',v_shift;
  end if;

  -- Same terminal cannot open a second live shift.
  begin
    perform public.open_shift(v_credential_one,10000);
    raise exception 'terminal accepted a second active shift';
  exception when unique_violation then
    null;
  end;

  -- Same operator cannot open a second live shift on another terminal.
  begin
    perform public.open_shift(v_credential_two,10000);
    raise exception 'operator accepted a second active shift';
  exception when unique_violation then
    null;
  end;

  -- Another staff employee cannot operate the current terminal shift.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_two,'role','authenticated')::text,
    true
  );
  begin
    perform public.get_current_shift(v_credential_one);
    raise exception 'another staff operator could inspect current terminal shift';
  exception when insufficient_privilege then
    null;
  end;
  begin
    perform public.place_pos_order(
      jsonb_build_object(
        'clientRequestId','43100000-0000-0000-0000-000000000002',
        'fulfillmentType','asap',
        'items',jsonb_build_array(jsonb_build_object(
          'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
        ))
      ),
      v_credential_one
    );
    raise exception 'another staff operator placed an order on the shift';
  exception when insufficient_privilege then
    null;
  end;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_one,'role','authenticated')::text,
    true
  );

  -- Lock blocks sale and cash movement; resume reopens operations.
  select public.lock_shift(v_shift_one_id,v_credential_one,v_version) into v_shift;
  v_version := (v_shift->>'statusVersion')::bigint;
  if v_shift->>'status' <> 'locked' then
    raise exception 'shift did not lock';
  end if;

  begin
    perform public.place_pos_order(
      jsonb_build_object(
        'clientRequestId','43100000-0000-0000-0000-000000000003',
        'fulfillmentType','asap',
        'items',jsonb_build_array(jsonb_build_object(
          'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
        ))
      ),
      v_credential_one
    );
    raise exception 'locked shift still accepted POS order';
  exception when insufficient_privilege then
    null;
  end;

  begin
    perform public.record_cash_movement(
      v_shift_one_id,v_credential_one,'cash_in',1000,'Locked drawer test'
    );
    raise exception 'locked shift still accepted cash movement';
  exception when insufficient_privilege then
    null;
  end;

  select public.resume_shift(v_shift_one_id,v_credential_one,v_version) into v_shift;
  v_version := (v_shift->>'statusVersion')::bigint;
  if v_shift->>'status' <> 'open' then
    raise exception 'shift did not resume';
  end if;

  select public.record_cash_movement(
    v_shift_one_id,v_credential_one,'cash_in',1000,'Additional till float'
  ) into v_movement;
  if v_movement#>>'{movement,type}' <> 'cash_in' then
    raise exception 'cash_in movement did not persist';
  end if;

  select public.record_cash_movement(
    v_shift_one_id,v_credential_one,'cash_out',500,'Petty cash purchase'
  ) into v_movement;
  if v_movement#>>'{movement,type}' <> 'cash_out' then
    raise exception 'cash_out movement did not persist';
  end if;

  begin
    perform public.record_cash_movement(
      v_shift_one_id,v_credential_one,'cash_out',99999999,'Impossible cash out'
    );
    raise exception 'cash_out exceeded expected cash';
  exception when invalid_parameter_value then
    null;
  end;

  select public.place_pos_order(
    jsonb_build_object(
      'clientRequestId','43100000-0000-0000-0000-000000000004',
      'fulfillmentType','asap',
      'tenderType','cash',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
      ))
    ),
    v_credential_one
  ) into v_order;

  v_order_id := (v_order->>'id')::uuid;
  v_total := (v_order->>'totalSen')::bigint;

  if v_order->>'shiftId' <> v_shift_one_id::text
     or v_order->>'tenderType' <> 'cash'
     or v_order->>'paymentState' <> 'paid'
     or v_order->>'paidAt' is null then
    raise exception 'cash POS order lacks trusted shift/payment attribution: %',v_order;
  end if;

  -- Same payload/request ID must not duplicate the order or expected cash.
  select public.get_shift_reconciliation(v_shift_one_id,v_credential_one)
  into v_breakdown;
  v_expected := (v_breakdown->>'expectedCashSen')::bigint;

  if v_expected <> 10000 + 1000 - 500 + v_total then
    raise exception 'expected cash calculation is incorrect: %',v_breakdown;
  end if;

  select public.place_pos_order(
    jsonb_build_object(
      'clientRequestId','43100000-0000-0000-0000-000000000004',
      'fulfillmentType','asap',
      'tenderType','cash',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
      ))
    ),
    v_credential_one
  ) into v_retry;

  if v_retry->>'id' <> v_order_id::text then
    raise exception 'idempotent retry created a new Phase 2 POS order';
  end if;

  select public.get_shift_reconciliation(v_shift_one_id,v_credential_one)
  into v_breakdown;
  if (v_breakdown->>'expectedCashSen')::bigint <> v_expected then
    raise exception 'idempotent retry duplicated expected cash';
  end if;

  -- Cash-paid order cancellation is blocked until a real refund workflow exists.
  begin
    perform public.transition_order_status(
      v_order_id,'cancelled',(v_order->>'statusVersion')::bigint,'test cancellation'
    );
    raise exception 'cash-paid order cancelled without refund authority';
  exception when insufficient_privilege then
    null;
  end;

  -- Staff cannot close a variance without manager authority.
  begin
    perform public.close_shift(
      v_shift_one_id,v_credential_one,v_expected + 100,'Variance attempt',null,v_version
    );
    raise exception 'staff closed non-zero variance without approval';
  exception when insufficient_privilege then
    null;
  end;

  -- Exact count closes normally for the operator.
  select public.close_shift(
    v_shift_one_id,v_credential_one,v_expected,'Balanced close','End of test shift',v_version
  ) into v_closed;

  if v_closed->>'status' <> 'closed'
     or (v_closed->>'expectedCashSen')::bigint <> v_expected
     or (v_closed->>'closingActualCashSen')::bigint <> v_expected
     or (v_closed->>'cashVarianceSen')::bigint <> 0
     or v_closed->>'approvedByUserId' is not null then
    raise exception 'balanced close facts are invalid: %',v_closed;
  end if;

  -- Staff two opens a fresh shift; only Admin/Owner can approve its variance.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );
  select public.issue_terminal_enrolment_code(v_terminal_one_id) into v_issue;
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_staff_two,'role','authenticated')::text,
    true
  );
  select public.enrol_terminal(v_issue->>'code') into v_enrol;
  v_credential_one := v_enrol->>'credential';

  select public.open_shift(v_credential_one,5000) into v_shift;
  v_shift_two_id := (v_shift->>'id')::uuid;
  v_version := (v_shift->>'statusVersion')::bigint;
  v_expected := (v_shift->>'expectedCashSen')::bigint;

  begin
    perform public.close_shift(
      v_shift_two_id,v_credential_one,v_expected + 125,'Variance needs approval',null,v_version
    );
    raise exception 'second staff operator self-approved variance';
  exception when insufficient_privilege then
    null;
  end;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_admin,'role','authenticated')::text,
    true
  );
  select public.close_shift(
    v_shift_two_id,v_credential_one,v_expected + 125,'Manager-approved variance','Reviewed at counter',v_version
  ) into v_closed;

  if v_closed->>'status' <> 'closed'
     or (v_closed->>'cashVarianceSen')::bigint <> 125
     or v_closed->>'approvedByUserId' <> v_admin::text
     or v_closed->>'approvedAt' is null then
    raise exception 'manager variance approval was not recorded: %',v_closed;
  end if;

  select public.list_admin_shifts(20) into v_admin_list;
  if jsonb_typeof(v_admin_list) <> 'array'
     or jsonb_array_length(v_admin_list) < 2 then
    raise exception 'Admin shift history did not include closed test shifts';
  end if;

  -- Customer orders cannot claim shift/tender authority.
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub',v_customer,'role','authenticated')::text,
    true
  );
  begin
    perform public.place_customer_order(jsonb_build_object(
      'clientRequestId','43100000-0000-0000-0000-000000000005',
      'fulfillmentType','asap',
      'tenderType','cash',
      'items',jsonb_build_array(jsonb_build_object(
        'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
      ))
    ));
    raise exception 'customer order claimed cash tender authority';
  exception when invalid_parameter_value then
    null;
  end;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId','43100000-0000-0000-0000-000000000006',
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object(
      'itemId',v_item_id,'addOnIds','[]'::jsonb,'quantity',1
    ))
  )) into v_customer_order;

  if v_customer_order->>'source' <> 'customer'
     or v_customer_order->>'shiftId' is not null
     or v_customer_order->>'tenderType' <> 'unpaid'
     or v_customer_order->>'paymentState' <> 'unpaid'
     or v_customer_order->>'paidAt' is not null then
    raise exception 'customer order received Phase 2 payment/shift authority';
  end if;
end;
$$;

-- Even the database owner cannot mutate the append-only cash ledger or
-- rewrite persisted order shift/payment authority through normal UPDATE.
reset role;

do $$
declare
  v_cash_id uuid;
  v_pos_order_id uuid;
begin
  select id into v_cash_id
  from public.cash_movements
  order by created_at
  limit 1;

  if v_cash_id is not null then
    begin
      update public.cash_movements set reason='tampered' where id=v_cash_id;
      raise exception 'cash movement append-only trigger allowed UPDATE';
    exception when insufficient_privilege then
      null;
    end;
  end if;

  select id into v_pos_order_id
  from public.orders
  where source='pos' and shift_id is not null
  order by created_at
  limit 1;

  if v_pos_order_id is not null then
    begin
      update public.orders set shift_id=null where id=v_pos_order_id;
      raise exception 'persisted order shift attribution was mutable';
    exception when insufficient_privilege then
      null;
    end;
  end if;
end;
$$;

rollback;
