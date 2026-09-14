-- TASK-OPS-003 / Phase 2 — shift/cash authority functions and POS integration.
-- Live migration: 20260911235626 implement_shift_cash_authority_functions.

create or replace function private.expected_shift_cash_sen(p_shift_id uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select
    s.opening_float_sen
    + coalesce((
        select sum(case m.movement_type
          when 'cash_in' then m.amount_sen
          when 'cash_out' then -m.amount_sen
          else 0
        end)
        from public.cash_movements m
        where m.shift_id = s.id
      ), 0)
    + coalesce((
        select sum(o.total_sen)
        from public.orders o
        where o.shift_id = s.id
          and o.source = 'pos'
          and o.tender_type = 'cash'
          and o.payment_state = 'paid'
      ), 0)
  from public.shifts s
  where s.id = p_shift_id;
$$;

create or replace function private.shift_cash_breakdown_impl(p_shift_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'openingFloatSen', s.opening_float_sen,
    'cashInSen', coalesce((
      select sum(m.amount_sen)
      from public.cash_movements m
      where m.shift_id = s.id and m.movement_type = 'cash_in'
    ), 0),
    'cashOutSen', coalesce((
      select sum(m.amount_sen)
      from public.cash_movements m
      where m.shift_id = s.id and m.movement_type = 'cash_out'
    ), 0),
    'cashSalesSen', coalesce((
      select sum(o.total_sen)
      from public.orders o
      where o.shift_id = s.id
        and o.source = 'pos'
        and o.tender_type = 'cash'
        and o.payment_state = 'paid'
    ), 0),
    'expectedCashSen', private.expected_shift_cash_sen(s.id)
  )
  from public.shifts s
  where s.id = p_shift_id;
$$;

create or replace function private.shift_snapshot_impl(
  p_shift_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_shift public.shifts%rowtype;
  v_role text;
  v_breakdown jsonb;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for shift access'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;

  select * into v_shift
  from public.shifts
  where id = p_shift_id;

  if not found then
    return null;
  end if;

  if not (select private.can_operate_branch(v_shift.branch_id)) then
    raise exception 'branch access required'
      using errcode = '42501', detail = 'SHIFT_BRANCH_FORBIDDEN';
  end if;

  select private.current_app_role()::text into v_role;
  if v_role = 'staff' and v_shift.operator_user_id is distinct from p_actor_user_id then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;

  select private.shift_cash_breakdown_impl(v_shift.id) into v_breakdown;

  return jsonb_build_object(
    'id', v_shift.id,
    'status', v_shift.status,
    'statusVersion', v_shift.status_version,
    'branchId', v_shift.branch_id,
    'salesPointId', v_shift.sales_point_id,
    'terminalId', v_shift.terminal_id,
    'openedByUserId', v_shift.opened_by_user_id,
    'operatorUserId', v_shift.operator_user_id,
    'canOperate', v_shift.operator_user_id = p_actor_user_id and v_shift.status in ('open', 'locked'),
    'openingFloatSen', v_shift.opening_float_sen,
    'expectedCashSen', case
      when v_shift.status = 'closed' then v_shift.closing_expected_cash_sen
      else (v_breakdown ->> 'expectedCashSen')::bigint
    end,
    'cashInSen', (v_breakdown ->> 'cashInSen')::bigint,
    'cashOutSen', (v_breakdown ->> 'cashOutSen')::bigint,
    'cashSalesSen', (v_breakdown ->> 'cashSalesSen')::bigint,
    'closingActualCashSen', v_shift.closing_actual_cash_sen,
    'cashVarianceSen', v_shift.cash_variance_sen,
    'openedAt', v_shift.opened_at,
    'lockedAt', v_shift.locked_at,
    'lastResumedAt', v_shift.last_resumed_at,
    'closedAt', v_shift.closed_at,
    'closeNotes', v_shift.close_notes,
    'handoverNotes', v_shift.handover_notes,
    'closedByUserId', v_shift.closed_by_user_id,
    'approvedByUserId', v_shift.approved_by_user_id,
    'approvedAt', v_shift.approved_at
  );
end;
$$;

create or replace function private.current_terminal_shift_impl(
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
  v_role text;
begin
  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    false,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts s
  where s.terminal_id = (v_terminal ->> 'terminalId')::uuid
    and s.status in ('open', 'locked')
  order by s.opened_at desc
  limit 1;

  if not found then
    return null;
  end if;

  select private.current_app_role()::text into v_role;
  if v_role = 'staff' and v_shift.operator_user_id is distinct from p_actor_user_id then
    raise exception 'terminal has a shift owned by another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;

  return private.shift_snapshot_impl(v_shift.id, p_actor_user_id);
end;
$$;

create or replace function private.require_open_shift_impl(
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
begin
  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    false,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts s
  where s.terminal_id = (v_terminal ->> 'terminalId')::uuid
    and s.status in ('open', 'locked')
  order by s.opened_at desc
  limit 1;

  if not found then
    raise exception 'an open shift is required before placing POS orders'
      using errcode = '42501', detail = 'SHIFT_OPEN_REQUIRED';
  end if;

  if v_shift.operator_user_id is distinct from p_actor_user_id then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;

  if v_shift.status <> 'open' then
    raise exception 'shift is locked'
      using errcode = '42501', detail = 'SHIFT_LOCKED';
  end if;

  return private.shift_snapshot_impl(v_shift.id, p_actor_user_id);
end;
$$;

create or replace function private.open_shift_impl(
  p_terminal_credential text,
  p_opening_float_sen bigint,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift_id uuid;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required to open shift'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;

  if p_opening_float_sen is null
     or p_opening_float_sen < 0
     or p_opening_float_sen > 100000000 then
    raise exception 'opening float must be a valid non-negative sen amount'
      using errcode = '22023', detail = 'SHIFT_OPENING_FLOAT_INVALID';
  end if;

  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    true,
    p_actor_user_id
  );

  if exists (
    select 1 from public.shifts
    where terminal_id = (v_terminal ->> 'terminalId')::uuid
      and status in ('open', 'locked')
  ) then
    raise exception 'terminal already has an active shift'
      using errcode = '23505', detail = 'SHIFT_TERMINAL_ALREADY_ACTIVE';
  end if;

  if exists (
    select 1 from public.shifts
    where operator_user_id = p_actor_user_id
      and status in ('open', 'locked')
  ) then
    raise exception 'employee already has an active shift'
      using errcode = '23505', detail = 'SHIFT_OPERATOR_ALREADY_ACTIVE';
  end if;

  insert into public.shifts (
    branch_id,
    sales_point_id,
    terminal_id,
    opened_by_user_id,
    operator_user_id,
    status,
    opening_float_sen
  ) values (
    (v_terminal ->> 'branchId')::uuid,
    (v_terminal ->> 'salesPointId')::uuid,
    (v_terminal ->> 'terminalId')::uuid,
    p_actor_user_id,
    p_actor_user_id,
    'open',
    p_opening_float_sen
  )
  returning id into v_shift_id;

  return private.shift_snapshot_impl(v_shift_id, p_actor_user_id);
exception
  when unique_violation then
    raise exception 'terminal or employee already has an active shift'
      using errcode = '23505', detail = 'SHIFT_ALREADY_ACTIVE';
end;
$$;

create or replace function private.transition_shift_impl(
  p_shift_id uuid,
  p_terminal_credential text,
  p_to_status text,
  p_expected_version bigint,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for shift transition'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;
  if p_to_status not in ('open', 'locked') then
    raise exception 'invalid shift transition target'
      using errcode = '22023', detail = 'SHIFT_TRANSITION_INVALID';
  end if;
  if p_expected_version is null or p_expected_version < 1 then
    raise exception 'expected shift version is required'
      using errcode = '22023', detail = 'SHIFT_VERSION_REQUIRED';
  end if;

  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    true,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts
  where id = p_shift_id
  for update;

  if not found then
    raise exception 'shift not found' using errcode = 'P0002', detail = 'SHIFT_NOT_FOUND';
  end if;
  if v_shift.terminal_id is distinct from (v_terminal ->> 'terminalId')::uuid then
    raise exception 'shift does not belong to this terminal'
      using errcode = '42501', detail = 'SHIFT_TERMINAL_MISMATCH';
  end if;
  if v_shift.operator_user_id is distinct from p_actor_user_id then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;
  if v_shift.status_version <> p_expected_version then
    raise exception 'shift changed; refresh before retrying'
      using errcode = '40001', detail = 'SHIFT_VERSION_CONFLICT';
  end if;
  if not (
    (v_shift.status = 'open' and p_to_status = 'locked')
    or (v_shift.status = 'locked' and p_to_status = 'open')
  ) then
    raise exception 'illegal shift transition from % to %', v_shift.status, p_to_status
      using errcode = '22023', detail = 'SHIFT_TRANSITION_INVALID';
  end if;

  update public.shifts
  set status = p_to_status,
      status_version = status_version + 1,
      locked_at = case when p_to_status = 'locked' then v_now else locked_at end,
      last_resumed_at = case when p_to_status = 'open' then v_now else last_resumed_at end,
      updated_at = v_now
  where id = p_shift_id;

  return private.shift_snapshot_impl(p_shift_id, p_actor_user_id);
end;
$$;

create or replace function private.record_cash_movement_impl(
  p_shift_id uuid,
  p_terminal_credential text,
  p_movement_type text,
  p_amount_sen bigint,
  p_reason text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
  v_movement_id uuid;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_expected bigint;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for cash movement'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;
  if p_movement_type not in ('cash_in', 'cash_out') then
    raise exception 'cash movement type must be cash_in or cash_out'
      using errcode = '22023', detail = 'CASH_MOVEMENT_TYPE_INVALID';
  end if;
  if p_amount_sen is null or p_amount_sen < 1 or p_amount_sen > 100000000 then
    raise exception 'cash movement amount is invalid'
      using errcode = '22023', detail = 'CASH_MOVEMENT_AMOUNT_INVALID';
  end if;
  if char_length(v_reason) < 3 or char_length(v_reason) > 200 then
    raise exception 'cash movement reason must be 3 to 200 characters'
      using errcode = '22023', detail = 'CASH_MOVEMENT_REASON_INVALID';
  end if;

  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    true,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts
  where id = p_shift_id
  for update;

  if not found then
    raise exception 'shift not found' using errcode = 'P0002', detail = 'SHIFT_NOT_FOUND';
  end if;
  if v_shift.terminal_id is distinct from (v_terminal ->> 'terminalId')::uuid then
    raise exception 'shift does not belong to this terminal'
      using errcode = '42501', detail = 'SHIFT_TERMINAL_MISMATCH';
  end if;
  if v_shift.operator_user_id is distinct from p_actor_user_id then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;
  if v_shift.status <> 'open' then
    raise exception 'cash movement requires an open shift'
      using errcode = '42501', detail = 'SHIFT_OPEN_REQUIRED';
  end if;

  if p_movement_type = 'cash_out' then
    select private.expected_shift_cash_sen(p_shift_id) into v_expected;
    if p_amount_sen > v_expected then
      raise exception 'cash out exceeds expected drawer cash'
        using errcode = '22023', detail = 'CASH_MOVEMENT_EXCEEDS_EXPECTED_CASH';
    end if;
  end if;

  insert into public.cash_movements (
    shift_id, movement_type, amount_sen, reason, actor_user_id
  ) values (
    p_shift_id, p_movement_type, p_amount_sen, v_reason, p_actor_user_id
  )
  returning id into v_movement_id;

  return jsonb_build_object(
    'movement', jsonb_build_object(
      'id', v_movement_id,
      'shiftId', p_shift_id,
      'type', p_movement_type,
      'amountSen', p_amount_sen,
      'reason', v_reason,
      'actorUserId', p_actor_user_id,
      'createdAt', now()
    ),
    'shift', private.shift_snapshot_impl(p_shift_id, p_actor_user_id)
  );
end;
$$;

create or replace function private.shift_reconciliation_impl(
  p_shift_id uuid,
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
  v_role text;
begin
  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    false,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts
  where id = p_shift_id;

  if not found then
    raise exception 'shift not found' using errcode = 'P0002', detail = 'SHIFT_NOT_FOUND';
  end if;
  if v_shift.terminal_id is distinct from (v_terminal ->> 'terminalId')::uuid then
    raise exception 'shift does not belong to this terminal'
      using errcode = '42501', detail = 'SHIFT_TERMINAL_MISMATCH';
  end if;

  select private.current_app_role()::text into v_role;
  if v_shift.operator_user_id is distinct from p_actor_user_id
     and v_role not in ('admin', 'owner') then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;

  return private.shift_cash_breakdown_impl(p_shift_id);
end;
$$;

create or replace function private.close_shift_impl(
  p_shift_id uuid,
  p_terminal_credential text,
  p_actual_cash_sen bigint,
  p_notes text,
  p_handover_notes text,
  p_expected_version bigint,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_terminal jsonb;
  v_shift public.shifts%rowtype;
  v_expected bigint;
  v_variance bigint;
  v_role text;
  v_now timestamptz := now();
  v_notes text := nullif(btrim(coalesce(p_notes, '')), '');
  v_handover text := nullif(btrim(coalesce(p_handover_notes, '')), '');
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required to close shift'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;
  if p_actual_cash_sen is null or p_actual_cash_sen < 0 or p_actual_cash_sen > 1000000000 then
    raise exception 'actual cash amount is invalid'
      using errcode = '22023', detail = 'SHIFT_ACTUAL_CASH_INVALID';
  end if;
  if p_expected_version is null or p_expected_version < 1 then
    raise exception 'expected shift version is required'
      using errcode = '22023', detail = 'SHIFT_VERSION_REQUIRED';
  end if;
  if v_notes is not null and char_length(v_notes) > 500 then
    raise exception 'close notes must be 500 characters or fewer'
      using errcode = '22023', detail = 'SHIFT_NOTES_INVALID';
  end if;
  if v_handover is not null and char_length(v_handover) > 500 then
    raise exception 'handover notes must be 500 characters or fewer'
      using errcode = '22023', detail = 'SHIFT_HANDOVER_INVALID';
  end if;

  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    true,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts
  where id = p_shift_id
  for update;

  if not found then
    raise exception 'shift not found' using errcode = 'P0002', detail = 'SHIFT_NOT_FOUND';
  end if;
  if v_shift.terminal_id is distinct from (v_terminal ->> 'terminalId')::uuid then
    raise exception 'shift does not belong to this terminal'
      using errcode = '42501', detail = 'SHIFT_TERMINAL_MISMATCH';
  end if;
  if v_shift.status = 'closed' then
    raise exception 'shift is already closed'
      using errcode = '22023', detail = 'SHIFT_ALREADY_CLOSED';
  end if;
  if v_shift.status_version <> p_expected_version then
    raise exception 'shift changed; refresh before retrying'
      using errcode = '40001', detail = 'SHIFT_VERSION_CONFLICT';
  end if;

  select private.current_app_role()::text into v_role;
  if v_shift.operator_user_id is distinct from p_actor_user_id
     and v_role not in ('admin', 'owner') then
    raise exception 'shift belongs to another operator'
      using errcode = '42501', detail = 'SHIFT_OPERATOR_MISMATCH';
  end if;

  select private.expected_shift_cash_sen(v_shift.id) into v_expected;
  v_variance := p_actual_cash_sen - v_expected;

  if v_variance <> 0 and v_role not in ('admin', 'owner') then
    raise exception 'non-zero cash variance requires Admin or Owner approval'
      using errcode = '42501', detail = 'SHIFT_VARIANCE_APPROVAL_REQUIRED';
  end if;

  update public.shifts
  set status = 'closed',
      status_version = status_version + 1,
      closed_at = v_now,
      closing_expected_cash_sen = v_expected,
      closing_actual_cash_sen = p_actual_cash_sen,
      cash_variance_sen = v_variance,
      close_notes = v_notes,
      handover_notes = v_handover,
      closed_by_user_id = p_actor_user_id,
      approved_by_user_id = case when v_variance <> 0 then p_actor_user_id else null end,
      approved_at = case when v_variance <> 0 then v_now else null end,
      updated_at = v_now
  where id = v_shift.id;

  return private.shift_snapshot_impl(v_shift.id, p_actor_user_id);
end;
$$;

create or replace function private.list_admin_shifts_impl(
  p_limit integer,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required'
      using errcode = '42501', detail = 'ADMIN_REQUIRED';
  end if;
  if p_limit is null or p_limit < 1 or p_limit > 250 then
    raise exception 'shift limit must be between 1 and 250'
      using errcode = '22023', detail = 'SHIFT_LIMIT_INVALID';
  end if;

  select coalesce(jsonb_agg(private.shift_snapshot_impl(x.id, p_actor_user_id) order by x.opened_at desc), '[]'::jsonb)
  into v_result
  from (
    select id, opened_at
    from public.shifts
    order by opened_at desc
    limit p_limit
  ) x;

  return v_result;
end;
$$;

create or replace function private.finalize_pos_order_shift_impl(
  p_order_id uuid,
  p_shift_id uuid,
  p_tender_type text,
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_shift public.shifts%rowtype;
  v_terminal jsonb;
  v_tender text := lower(btrim(coalesce(p_tender_type, 'unpaid')));
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for POS finalization'
      using errcode = '42501', detail = 'EMPLOYEE_REQUIRED';
  end if;
  if v_tender not in ('unpaid', 'cash') then
    raise exception 'tenderType must be unpaid or cash'
      using errcode = '22023', detail = 'ORDER_TENDER_INVALID';
  end if;

  v_terminal := private.terminal_context_impl(
    p_terminal_credential,
    false,
    p_actor_user_id
  );

  select * into v_shift
  from public.shifts
  where id = p_shift_id
  for share;

  if not found
     or v_shift.status <> 'open'
     or v_shift.operator_user_id is distinct from p_actor_user_id
     or v_shift.terminal_id is distinct from (v_terminal ->> 'terminalId')::uuid then
    raise exception 'valid open shift is required for POS placement'
      using errcode = '42501', detail = 'SHIFT_OPEN_REQUIRED';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found
     or v_order.source <> 'pos'
     or v_order.created_by_user_id is distinct from p_actor_user_id
     or v_order.terminal_id is distinct from v_shift.terminal_id
     or v_order.sales_point_id is distinct from v_shift.sales_point_id
     or v_order.branch_id is distinct from v_shift.branch_id then
    raise exception 'order operational context does not match shift'
      using errcode = '42501', detail = 'ORDER_SHIFT_MISMATCH';
  end if;

  if v_order.shift_id is not null then
    if v_order.shift_id is distinct from p_shift_id
       or v_order.tender_type is distinct from v_tender
       or (v_tender = 'cash' and (v_order.payment_state <> 'paid' or v_order.paid_at is null))
       or (v_tender = 'unpaid' and (v_order.payment_state <> 'unpaid' or v_order.paid_at is not null)) then
      raise exception 'idempotent order belongs to a different shift or tender'
        using errcode = '23505', detail = 'ORDER_SHIFT_IDEMPOTENCY_CONFLICT';
    end if;
    return;
  end if;

  if v_order.created_at < v_shift.opened_at then
    raise exception 'existing order predates the active shift'
      using errcode = '23505', detail = 'ORDER_SHIFT_IDEMPOTENCY_CONFLICT';
  end if;

  perform set_config('aida.internal_order_shift_finalize', 'on', true);
  update public.orders
  set shift_id = p_shift_id,
      tender_type = v_tender,
      payment_state = case when v_tender = 'cash' then 'paid' else 'unpaid' end,
      paid_at = case when v_tender = 'cash' then now() else null end,
      updated_at = now()
  where id = p_order_id;
  perform set_config('aida.internal_order_shift_finalize', 'off', true);
end;
$$;

create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_internal_finalize boolean := coalesce(current_setting('aida.internal_order_shift_finalize', true), '') = 'on';
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.customer_user_id is distinct from old.customer_user_id
     or new.member_id is distinct from old.member_id
     or new.created_by_user_id is distinct from old.created_by_user_id
     or new.branch_id is distinct from old.branch_id
     or new.sales_point_id is distinct from old.sales_point_id
     or new.terminal_id is distinct from old.terminal_id
     or new.sales_point_code_snapshot is distinct from old.sales_point_code_snapshot
     or new.sales_point_name_snapshot is distinct from old.sales_point_name_snapshot
     or new.terminal_code_snapshot is distinct from old.terminal_code_snapshot
     or new.client_request_id is distinct from old.client_request_id
     or new.request_hash is distinct from old.request_hash
     or new.fulfillment_type is distinct from old.fulfillment_type
     or new.requested_pickup_at is distinct from old.requested_pickup_at
     or new.prepare_at is distinct from old.prepare_at
     or new.currency is distinct from old.currency
     or new.pricing_version is distinct from old.pricing_version
     or new.subtotal_sen is distinct from old.subtotal_sen
     or new.total_sen is distinct from old.total_sen
     or new.created_at is distinct from old.created_at then
    raise exception 'persisted order commercial fields are immutable'
      using errcode = '42501';
  end if;

  if new.shift_id is distinct from old.shift_id
     or new.tender_type is distinct from old.tender_type
     or new.payment_state is distinct from old.payment_state
     or new.paid_at is distinct from old.paid_at then
    if not v_internal_finalize
       or old.source <> 'pos'
       or old.shift_id is not null
       or new.shift_id is null
       or old.tender_type <> 'unpaid'
       or old.payment_state <> 'unpaid'
       or old.paid_at is not null then
      raise exception 'persisted order shift/payment fields are immutable'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'orderNumber', o.order_number,
    'source', o.source,
    'customerUserId', o.customer_user_id,
    'memberId', o.member_id,
    'branchId', o.branch_id,
    'branch', jsonb_build_object(
      'id', b.id,
      'code', b.code,
      'name', b.name,
      'timezone', b.timezone
    ),
    'salesPointId', o.sales_point_id,
    'salesPoint', case
      when o.sales_point_id is null then null
      else jsonb_build_object(
        'id', o.sales_point_id,
        'code', o.sales_point_code_snapshot,
        'name', o.sales_point_name_snapshot
      )
    end,
    'terminalId', o.terminal_id,
    'terminal', case
      when o.terminal_id is null then null
      else jsonb_build_object(
        'id', o.terminal_id,
        'code', o.terminal_code_snapshot
      )
    end,
    'shiftId', o.shift_id,
    'tenderType', o.tender_type,
    'paymentState', o.payment_state,
    'paidAt', o.paid_at,
    'fulfillmentType', o.fulfillment_type,
    'requestedPickupAt', o.requested_pickup_at,
    'prepareAt', o.prepare_at,
    'serverNow', now(),
    'scheduleState', case
      when o.fulfillment_type = 'scheduled' and o.status = 'scheduled' then
        case
          when o.requested_pickup_at < now() then 'overdue'
          when o.prepare_at <= now() then 'due'
          else 'future'
        end
      else null
    end,
    'status', o.status,
    'statusVersion', o.status_version,
    'currency', o.currency,
    'pricingVersion', o.pricing_version,
    'subtotalSen', o.subtotal_sen,
    'totalSen', o.total_sen,
    'createdAt', o.created_at,
    'updatedAt', o.updated_at,
    'statusUpdatedAt', o.status_updated_at,
    'preparingAt', o.preparing_at,
    'readyAt', o.ready_at,
    'completedAt', o.completed_at,
    'cancelledAt', o.cancelled_at,
    'lines', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', l.id,
          'lineNumber', l.line_number,
          'itemId', l.catalogue_item_id,
          'sku', l.sku_snapshot,
          'name', l.name_snapshot,
          'prepRoute', l.prep_route_snapshot,
          'basePriceSen', l.base_price_sen,
          'variant', case
            when l.variant_id is null then null
            else jsonb_build_object(
              'id', l.variant_id,
              'code', l.variant_code_snapshot,
              'label', l.variant_label_snapshot,
              'priceDeltaSen', l.variant_price_delta_sen
            )
          end,
          'addOns', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'itemId', a.catalogue_addon_item_id,
                'sku', a.sku_snapshot,
                'name', a.name_snapshot,
                'priceSen', a.price_sen
              )
              order by a.created_at, a.id
            )
            from public.order_line_addons a
            where a.order_line_id = l.id
          ), '[]'::jsonb),
          'addOnTotalSen', l.addon_total_sen,
          'options', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'groupId', x.catalogue_option_group_id,
                'groupCode', x.group_code_snapshot,
                'groupName', x.group_name_snapshot,
                'optionValueId', x.catalogue_option_value_id,
                'optionCode', x.option_code_snapshot,
                'optionLabel', x.option_label_snapshot,
                'priceDeltaSen', x.price_delta_sen
              )
              order by x.created_at, x.id
            )
            from public.order_line_options x
            where x.order_line_id = l.id
          ), '[]'::jsonb),
          'optionTotalSen', l.option_total_sen,
          'unitPriceSen', l.unit_price_sen,
          'quantity', l.quantity,
          'lineTotalSen', l.line_total_sen,
          'note', l.note
        )
        order by l.line_number
      )
      from public.order_lines l
      where l.order_id = o.id
    ), '[]'::jsonb)
  )
  from public.orders o
  join public.branches b on b.id = o.branch_id
  where o.id = p_order_id
    and (
      o.customer_user_id = (select auth.uid())
      or (select private.can_operate_branch(o.branch_id))
    );
$$;

create or replace function private.transition_order_status_impl(
  p_order_id uuid,
  p_to_status text,
  p_expected_version bigint,
  p_reason text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_now timestamptz := now();
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if p_expected_version is null or p_expected_version < 1 then
    raise exception 'expected status version is required' using errcode = '22023';
  end if;
  if p_reason is not null and char_length(btrim(p_reason)) > 300 then
    raise exception 'status reason must be 300 characters or fewer' using errcode = '22023';
  end if;

  select * into v_order
  from public.orders
  where id = p_order_id
  for update;

  if not found then
    raise exception 'order not found' using errcode = 'P0002';
  end if;
  if not (select private.can_operate_branch(v_order.branch_id)) then
    raise exception 'branch access required' using errcode = '42501';
  end if;
  if v_order.status_version <> p_expected_version then
    raise exception 'order status changed; refresh before retrying' using errcode = '40001';
  end if;
  if v_order.tender_type = 'cash'
     and v_order.payment_state = 'paid'
     and p_to_status = 'cancelled' then
    raise exception 'cash-paid orders require a refund workflow before cancellation'
      using errcode = '42501', detail = 'PAID_ORDER_REFUND_REQUIRED';
  end if;
  if not (
    (v_order.status = 'scheduled' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'confirmed' and p_to_status in ('preparing', 'cancelled'))
    or (v_order.status = 'preparing' and p_to_status in ('ready', 'cancelled'))
    or (v_order.status = 'ready' and p_to_status = 'completed')
  ) then
    raise exception 'illegal order status transition from % to %', v_order.status, p_to_status
      using errcode = '22023';
  end if;

  update public.orders
  set status = p_to_status,
      status_version = status_version + 1,
      status_updated_at = v_now,
      preparing_at = case
        when p_to_status = 'preparing' then coalesce(preparing_at, v_now)
        else preparing_at
      end,
      ready_at = case
        when p_to_status = 'ready' then coalesce(ready_at, v_now)
        else ready_at
      end,
      completed_at = case
        when p_to_status = 'completed' then coalesce(completed_at, v_now)
        else completed_at
      end,
      cancelled_at = case
        when p_to_status = 'cancelled' then coalesce(cancelled_at, v_now)
        else cancelled_at
      end
  where id = p_order_id;

  insert into public.order_events (
    order_id, event_type, actor_user_id, from_status, to_status, reason, details
  ) values (
    p_order_id, 'status_changed', p_actor_user_id, v_order.status, p_to_status,
    nullif(btrim(coalesce(p_reason, '')), ''),
    jsonb_build_object(
      'branchId', v_order.branch_id,
      'shiftId', v_order.shift_id,
      'previousVersion', v_order.status_version,
      'newVersion', v_order.status_version + 1
    )
  );

  return private.order_snapshot(p_order_id);
end;
$$;

create or replace function public.place_customer_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_member_id uuid;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_payload ?| array['shiftId','tenderType','paymentState','paidAt'] then
    raise exception 'customer orders cannot claim shift or payment authority'
      using errcode = '22023', detail = 'CUSTOMER_PAYMENT_AUTHORITY_FORBIDDEN';
  end if;
  if (select private.current_app_role()) <> 'customer'::public.app_user_role then
    raise exception 'customer identity required' using errcode = '42501';
  end if;
  select m.id into v_member_id
  from public.members m
  where m.user_id = v_user_id and m.active
  limit 1;
  if v_member_id is null then
    raise exception 'active member record is required for customer ordering' using errcode = '42501';
  end if;
  return private.create_order_impl(p_payload, 'customer', v_user_id, v_member_id, v_user_id);
end;
$$;

create or replace function public.get_current_shift(p_terminal_credential text)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.current_terminal_shift_impl(
    p_terminal_credential,
    (select auth.uid())
  );
$$;

create or replace function public.open_shift(
  p_terminal_credential text,
  p_opening_float_sen bigint
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.open_shift_impl(
    p_terminal_credential,
    p_opening_float_sen,
    (select auth.uid())
  );
$$;

create or replace function public.lock_shift(
  p_shift_id uuid,
  p_terminal_credential text,
  p_expected_version bigint
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.transition_shift_impl(
    p_shift_id,
    p_terminal_credential,
    'locked',
    p_expected_version,
    (select auth.uid())
  );
$$;

create or replace function public.resume_shift(
  p_shift_id uuid,
  p_terminal_credential text,
  p_expected_version bigint
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.transition_shift_impl(
    p_shift_id,
    p_terminal_credential,
    'open',
    p_expected_version,
    (select auth.uid())
  );
$$;

create or replace function public.record_cash_movement(
  p_shift_id uuid,
  p_terminal_credential text,
  p_movement_type text,
  p_amount_sen bigint,
  p_reason text
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.record_cash_movement_impl(
    p_shift_id,
    p_terminal_credential,
    p_movement_type,
    p_amount_sen,
    p_reason,
    (select auth.uid())
  );
$$;

create or replace function public.get_shift_reconciliation(
  p_shift_id uuid,
  p_terminal_credential text
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.shift_reconciliation_impl(
    p_shift_id,
    p_terminal_credential,
    (select auth.uid())
  );
$$;

create or replace function public.close_shift(
  p_shift_id uuid,
  p_terminal_credential text,
  p_actual_cash_sen bigint,
  p_notes text,
  p_handover_notes text,
  p_expected_version bigint
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.close_shift_impl(
    p_shift_id,
    p_terminal_credential,
    p_actual_cash_sen,
    p_notes,
    p_handover_notes,
    p_expected_version,
    (select auth.uid())
  );
$$;

create or replace function public.list_admin_shifts(p_limit integer default 100)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.list_admin_shifts_impl(
    p_limit,
    (select auth.uid())
  );
$$;

create or replace function public.place_pos_order(
  p_payload jsonb,
  p_terminal_credential text
)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_shift jsonb;
  v_order jsonb;
  v_order_id uuid;
  v_tender text := lower(btrim(coalesce(p_payload ->> 'tenderType', 'unpaid')));
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if v_tender not in ('unpaid', 'cash') then
    raise exception 'tenderType must be unpaid or cash'
      using errcode = '22023', detail = 'ORDER_TENDER_INVALID';
  end if;

  v_shift := private.require_open_shift_impl(
    p_terminal_credential,
    v_user_id
  );

  v_order := private.create_order_impl_v2(
    p_payload,
    'pos',
    null,
    null,
    v_user_id,
    p_terminal_credential
  );

  v_order_id := (v_order ->> 'id')::uuid;

  perform private.finalize_pos_order_shift_impl(
    v_order_id,
    (v_shift ->> 'id')::uuid,
    v_tender,
    p_terminal_credential,
    v_user_id
  );

  return private.order_snapshot(v_order_id);
end;
$$;
