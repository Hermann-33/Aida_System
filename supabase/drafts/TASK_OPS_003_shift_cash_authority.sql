-- TASK-OPS-003 / Phase 2 — trusted shift and cash authority.
-- Staged draft. Promote to canonical migration after successful live application.
--
-- Authority chain:
-- branch -> sales point -> terminal -> employee -> shift -> POS order / cash ledger
--
-- Non-goals: external payment processor settlement, refunds, accounting export,
-- inventory, employee credential provisioning, hardware drawer integration.

create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  sales_point_id uuid not null,
  terminal_id uuid not null,
  opened_by_user_id uuid not null references auth.users(id) on delete restrict,
  operator_user_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'open',
  status_version bigint not null default 1,
  opening_float_sen bigint not null,
  opened_at timestamptz not null default now(),
  locked_at timestamptz,
  last_resumed_at timestamptz,
  closed_at timestamptz,
  closing_expected_cash_sen bigint,
  closing_actual_cash_sen bigint,
  cash_variance_sen bigint,
  close_notes text,
  handover_notes text,
  closed_by_user_id uuid references auth.users(id) on delete restrict,
  approved_by_user_id uuid references auth.users(id) on delete restrict,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint shifts_status_check check (status in ('open', 'locked', 'closed')),
  constraint shifts_version_check check (status_version >= 1),
  constraint shifts_opening_float_check check (opening_float_sen between 0 and 100000000),
  constraint shifts_close_notes_check check (close_notes is null or char_length(close_notes) <= 500),
  constraint shifts_handover_notes_check check (handover_notes is null or char_length(handover_notes) <= 500),
  constraint shifts_sales_point_branch_fk
    foreign key (sales_point_id, branch_id)
    references public.sales_points(id, branch_id)
    on delete restrict,
  constraint shifts_terminal_sales_point_fk
    foreign key (terminal_id, sales_point_id)
    references public.terminals(id, sales_point_id)
    on delete restrict,
  constraint shifts_close_shape_check check (
    (status <> 'closed'
      and closed_at is null
      and closing_expected_cash_sen is null
      and closing_actual_cash_sen is null
      and cash_variance_sen is null
      and closed_by_user_id is null)
    or
    (status = 'closed'
      and closed_at is not null
      and closing_expected_cash_sen is not null
      and closing_actual_cash_sen is not null
      and cash_variance_sen is not null
      and closed_by_user_id is not null)
  ),
  constraint shifts_approval_shape_check check (
    (approved_by_user_id is null and approved_at is null)
    or (approved_by_user_id is not null and approved_at is not null)
  )
);

create unique index shifts_identity_topology_unique
  on public.shifts (id, terminal_id, sales_point_id, branch_id);
create unique index shifts_one_live_per_terminal_idx
  on public.shifts (terminal_id)
  where status in ('open', 'locked');
create unique index shifts_one_live_per_operator_idx
  on public.shifts (operator_user_id)
  where status in ('open', 'locked');
create index shifts_branch_opened_idx
  on public.shifts (branch_id, opened_at desc);
create index shifts_operator_opened_idx
  on public.shifts (operator_user_id, opened_at desc);
create index shifts_closed_by_idx
  on public.shifts (closed_by_user_id)
  where closed_by_user_id is not null;
create index shifts_approved_by_idx
  on public.shifts (approved_by_user_id)
  where approved_by_user_id is not null;

create table public.cash_movements (
  id uuid primary key default gen_random_uuid(),
  shift_id uuid not null references public.shifts(id) on delete restrict,
  movement_type text not null,
  amount_sen bigint not null,
  reason text not null,
  actor_user_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint cash_movements_type_check check (movement_type in ('cash_in', 'cash_out')),
  constraint cash_movements_amount_check check (amount_sen between 1 and 100000000),
  constraint cash_movements_reason_check check (char_length(btrim(reason)) between 3 and 200)
);

create index cash_movements_shift_created_idx
  on public.cash_movements (shift_id, created_at, id);
create index cash_movements_actor_idx
  on public.cash_movements (actor_user_id, created_at desc);

alter table public.shifts enable row level security;
alter table public.shifts force row level security;
alter table public.cash_movements enable row level security;
alter table public.cash_movements force row level security;

revoke all on table public.shifts from public, anon, authenticated;
revoke all on table public.cash_movements from public, anon, authenticated;

create policy shifts_scoped_read
on public.shifts
for select
to authenticated
using (
  (select private.is_admin_or_owner())
  or (
    operator_user_id = (select auth.uid())
    and (select private.can_operate_branch(branch_id))
  )
);

create policy cash_movements_scoped_read
on public.cash_movements
for select
to authenticated
using (
  exists (
    select 1
    from public.shifts s
    where s.id = cash_movements.shift_id
      and (
        (select private.is_admin_or_owner())
        or (
          s.operator_user_id = (select auth.uid())
          and (select private.can_operate_branch(s.branch_id))
        )
      )
  )
);

create or replace function private.prevent_cash_movement_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'cash movement ledger is append-only' using errcode = '42501';
end;
$$;

create trigger cash_movements_append_only
before update or delete on public.cash_movements
for each row execute function private.prevent_cash_movement_mutation();

alter table public.orders
  add column shift_id uuid,
  add column tender_type text not null default 'unpaid',
  add column payment_state text not null default 'unpaid',
  add column paid_at timestamptz;

alter table public.orders
  add constraint orders_shift_topology_fk
    foreign key (shift_id, terminal_id, sales_point_id, branch_id)
    references public.shifts(id, terminal_id, sales_point_id, branch_id)
    on delete restrict,
  add constraint orders_tender_type_check
    check (tender_type in ('unpaid', 'cash')),
  add constraint orders_payment_state_check
    check (payment_state in ('unpaid', 'paid')),
  add constraint orders_payment_shape_check check (
    (tender_type = 'unpaid' and payment_state = 'unpaid' and paid_at is null)
    or
    (tender_type = 'cash' and payment_state = 'paid' and paid_at is not null)
  ),
  add constraint orders_customer_shift_payment_check check (
    source <> 'customer'
    or (
      shift_id is null
      and tender_type = 'unpaid'
      and payment_state = 'unpaid'
      and paid_at is null
    )
  );

create index orders_shift_created_idx
  on public.orders (shift_id, created_at desc)
  where shift_id is not null;
create index orders_shift_cash_idx
  on public.orders (shift_id, tender_type, payment_state)
  where shift_id is not null;

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

  select private.current_app_role() into v_role;
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

  select private.current_app_role() into v_role;
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

  select private.current_app_role() into v_role;
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

  select private.current_app_role() into v_role;
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

-- One-time privileged finalization of shift/tender attribution after the
-- existing authoritative order creator has persisted the order atomically.
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
       or v_order.tender_type is distinct from v_tender then
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
      paid_at = case when v_tender = 'cash' then now() else null end
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

revoke all on function private.prevent_cash_movement_mutation() from public, anon, authenticated;
revoke all on function private.expected_shift_cash_sen(uuid) from public, anon, authenticated;
revoke all on function private.shift_cash_breakdown_impl(uuid) from public, anon, authenticated;
revoke all on function private.shift_snapshot_impl(uuid, uuid) from public, anon, authenticated;
revoke all on function private.current_terminal_shift_impl(text, uuid) from public, anon, authenticated;
revoke all on function private.require_open_shift_impl(text, uuid) from public, anon, authenticated;
revoke all on function private.open_shift_impl(text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.transition_shift_impl(uuid, text, text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.record_cash_movement_impl(uuid, text, text, bigint, text, uuid) from public, anon, authenticated;
revoke all on function private.shift_reconciliation_impl(uuid, text, uuid) from public, anon, authenticated;
revoke all on function private.close_shift_impl(uuid, text, bigint, text, text, bigint, uuid) from public, anon, authenticated;
revoke all on function private.list_admin_shifts_impl(integer, uuid) from public, anon, authenticated;
revoke all on function private.finalize_pos_order_shift_impl(uuid, uuid, text, text, uuid) from public, anon, authenticated;

grant usage on schema private to authenticated;
grant execute on function private.expected_shift_cash_sen(uuid) to authenticated;
grant execute on function private.shift_cash_breakdown_impl(uuid) to authenticated;
grant execute on function private.shift_snapshot_impl(uuid, uuid) to authenticated;
grant execute on function private.current_terminal_shift_impl(text, uuid) to authenticated;
grant execute on function private.require_open_shift_impl(text, uuid) to authenticated;
grant execute on function private.open_shift_impl(text, bigint, uuid) to authenticated;
grant execute on function private.transition_shift_impl(uuid, text, text, bigint, uuid) to authenticated;
grant execute on function private.record_cash_movement_impl(uuid, text, text, bigint, text, uuid) to authenticated;
grant execute on function private.shift_reconciliation_impl(uuid, text, uuid) to authenticated;
grant execute on function private.close_shift_impl(uuid, text, bigint, text, text, bigint, uuid) to authenticated;
grant execute on function private.list_admin_shifts_impl(integer, uuid) to authenticated;
grant execute on function private.finalize_pos_order_shift_impl(uuid, uuid, text, text, uuid) to authenticated;

revoke all on function public.get_current_shift(text) from public, anon, authenticated;
revoke all on function public.open_shift(text, bigint) from public, anon, authenticated;
revoke all on function public.lock_shift(uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.resume_shift(uuid, text, bigint) from public, anon, authenticated;
revoke all on function public.record_cash_movement(uuid, text, text, bigint, text) from public, anon, authenticated;
revoke all on function public.get_shift_reconciliation(uuid, text) from public, anon, authenticated;
revoke all on function public.close_shift(uuid, text, bigint, text, text, bigint) from public, anon, authenticated;
revoke all on function public.list_admin_shifts(integer) from public, anon, authenticated;
revoke all on function public.place_pos_order(jsonb, text) from public, anon, authenticated;

grant execute on function public.get_current_shift(text) to authenticated;
grant execute on function public.open_shift(text, bigint) to authenticated;
grant execute on function public.lock_shift(uuid, text, bigint) to authenticated;
grant execute on function public.resume_shift(uuid, text, bigint) to authenticated;
grant execute on function public.record_cash_movement(uuid, text, text, bigint, text) to authenticated;
grant execute on function public.get_shift_reconciliation(uuid, text) to authenticated;
grant execute on function public.close_shift(uuid, text, bigint, text, text, bigint) to authenticated;
grant execute on function public.list_admin_shifts(integer) to authenticated;
grant execute on function public.place_pos_order(jsonb, text) to authenticated;

comment on table public.shifts is
  'Trusted POS shift lifecycle and cash reconciliation authority under a terminal.';
comment on table public.cash_movements is
  'Append-only non-sale cash drawer movement ledger in integer sen.';
comment on column public.orders.shift_id is
  'Immutable trusted shift attribution for Phase 2 POS orders; null for customer and pre-Phase-2 historical orders.';
comment on column public.orders.tender_type is
  'Internal settlement classification. Phase 2 supports unpaid or cash only; external processors remain deferred.';

do $$
begin
  if exists (
    select 1
    from public.orders
    where source = 'customer'
      and (
        shift_id is not null
        or tender_type <> 'unpaid'
        or payment_state <> 'unpaid'
        or paid_at is not null
      )
  ) then
    raise exception 'customer shift/payment invariant failed';
  end if;

  if has_table_privilege('authenticated', 'public.shifts', 'insert')
     or has_table_privilege('authenticated', 'public.cash_movements', 'insert') then
    raise exception 'authenticated role unexpectedly has direct Phase 2 mutation grants';
  end if;
end;
$$;
