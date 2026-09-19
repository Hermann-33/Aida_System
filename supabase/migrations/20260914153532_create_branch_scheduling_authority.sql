create table public.branch_ordering_policies (
  branch_id uuid primary key references public.branches(id) on delete cascade,
  asap_enabled boolean not null default true,
  schedule_enabled boolean not null default true,
  minimum_lead_minutes integer not null default 15,
  preparation_lead_minutes integer not null default 15,
  slot_interval_minutes integer not null default 15,
  maximum_advance_days integer not null default 7,
  slot_capacity_orders integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branch_ordering_minimum_lead_check check (minimum_lead_minutes between 0 and 1440),
  constraint branch_ordering_preparation_lead_check check (preparation_lead_minutes between 0 and 1440),
  constraint branch_ordering_preparation_vs_minimum_check check (preparation_lead_minutes <= minimum_lead_minutes),
  constraint branch_ordering_slot_interval_check check (slot_interval_minutes between 5 and 240),
  constraint branch_ordering_horizon_check check (maximum_advance_days between 1 and 31),
  constraint branch_ordering_capacity_check check (slot_capacity_orders is null or slot_capacity_orders between 1 and 10000)
);

create table public.branch_service_windows (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete cascade,
  weekday smallint not null,
  is_all_day boolean not null default false,
  opens_at time without time zone,
  closes_at time without time zone,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branch_service_windows_weekday_check check (weekday between 0 and 6),
  constraint branch_service_windows_shape_check check (
    (is_all_day and opens_at is null and closes_at is null)
    or
    (not is_all_day and opens_at is not null and closes_at is not null and opens_at < closes_at)
  ),
  constraint branch_service_windows_unique unique (branch_id, weekday, is_all_day, opens_at, closes_at)
);

create index branch_service_windows_branch_day_idx
  on public.branch_service_windows (branch_id, weekday, is_active, opens_at);

create table public.branch_service_exceptions (
  branch_id uuid not null references public.branches(id) on delete cascade,
  service_date date not null,
  is_closed boolean not null default false,
  is_all_day boolean not null default false,
  opens_at time without time zone,
  closes_at time without time zone,
  slot_capacity_orders integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (branch_id, service_date),
  constraint branch_service_exceptions_shape_check check (
    (is_closed and not is_all_day and opens_at is null and closes_at is null)
    or
    (not is_closed and is_all_day and opens_at is null and closes_at is null)
    or
    (not is_closed and not is_all_day and opens_at is null and closes_at is null)
    or
    (not is_closed and not is_all_day and opens_at is not null and closes_at is not null and opens_at < closes_at)
  ),
  constraint branch_service_exceptions_capacity_check check (slot_capacity_orders is null or slot_capacity_orders between 1 and 10000)
);

create trigger branch_ordering_policies_set_updated_at
before update on public.branch_ordering_policies
for each row execute function public.set_updated_at();

create trigger branch_service_windows_set_updated_at
before update on public.branch_service_windows
for each row execute function public.set_updated_at();

create trigger branch_service_exceptions_set_updated_at
before update on public.branch_service_exceptions
for each row execute function public.set_updated_at();

insert into public.branch_ordering_policies (
  branch_id,
  asap_enabled,
  schedule_enabled,
  minimum_lead_minutes,
  preparation_lead_minutes,
  slot_interval_minutes,
  maximum_advance_days,
  slot_capacity_orders
)
select
  b.id,
  true,
  s.schedule_enabled,
  s.minimum_lead_minutes,
  s.preparation_lead_minutes,
  s.slot_interval_minutes,
  s.maximum_advance_days,
  null
from public.branches b
cross join public.order_schedule_settings s
where s.id = 1
on conflict (branch_id) do nothing;

insert into public.branch_service_windows (branch_id, weekday, is_all_day, is_active)
select b.id, d.weekday, true, true
from public.branches b
cross join generate_series(0, 6) as d(weekday)
on conflict do nothing;

alter table public.branch_ordering_policies enable row level security;
alter table public.branch_ordering_policies force row level security;
alter table public.branch_service_windows enable row level security;
alter table public.branch_service_windows force row level security;
alter table public.branch_service_exceptions enable row level security;
alter table public.branch_service_exceptions force row level security;

revoke all on table public.branch_ordering_policies from public, anon, authenticated;
revoke all on table public.branch_service_windows from public, anon, authenticated;
revoke all on table public.branch_service_exceptions from public, anon, authenticated;

grant select on table public.branch_ordering_policies to anon, authenticated;
grant select on table public.branch_service_windows to anon, authenticated;
grant select on table public.branch_service_exceptions to anon, authenticated;

create policy branch_ordering_policies_active_read
on public.branch_ordering_policies
for select
to anon, authenticated
using (exists (
  select 1 from public.branches b
  where b.id = branch_ordering_policies.branch_id and b.is_active
));

create policy branch_ordering_policies_admin_read
on public.branch_ordering_policies
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy branch_service_windows_active_read
on public.branch_service_windows
for select
to anon, authenticated
using (exists (
  select 1 from public.branches b
  where b.id = branch_service_windows.branch_id and b.is_active
));

create policy branch_service_windows_admin_read
on public.branch_service_windows
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy branch_service_exceptions_active_read
on public.branch_service_exceptions
for select
to anon, authenticated
using (exists (
  select 1 from public.branches b
  where b.id = branch_service_exceptions.branch_id and b.is_active
));

create policy branch_service_exceptions_admin_read
on public.branch_service_exceptions
for select
to authenticated
using ((select private.is_admin_or_owner()));

comment on table public.branch_ordering_policies is
  'Server-owned per-branch ASAP/scheduled pickup policy and optional scheduled-order slot capacity.';
comment on table public.branch_service_windows is
  'Server-owned recurring weekly branch pickup service windows in branch local time.';
comment on table public.branch_service_exceptions is
  'Server-owned dated closure/hour/capacity overrides for branch pickup service.';
