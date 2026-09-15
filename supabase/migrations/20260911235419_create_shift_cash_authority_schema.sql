-- TASK-OPS-003 / Phase 2 — shift/cash authority schema.
-- Live migration: 20260911235419 create_shift_cash_authority_schema.

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
end;
$$;
