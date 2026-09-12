-- TASK-OPS-001 — trusted branch/location authority foundation.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/.
--
-- Applied to the live AIDA Supabase project as migration 20260910014434.
-- Existing clients remain compatible: orders are
-- assigned to the active default branch server-side until explicit branch
-- selection is introduced in a later bounded task.

create table public.branches (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  timezone text not null default 'Asia/Kuala_Lumpur',
  address_text text,
  phone text,
  is_active boolean not null default true,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint branches_code_check check (code ~ '^[A-Z0-9][A-Z0-9-]{1,23}$'),
  constraint branches_name_check check (char_length(btrim(name)) between 1 and 120),
  constraint branches_address_check check (
    address_text is null or char_length(btrim(address_text)) between 1 and 500
  ),
  constraint branches_phone_check check (
    phone is null or char_length(btrim(phone)) between 1 and 32
  ),
  constraint branches_default_active_check check (not is_default or is_active)
);

create unique index branches_single_default_idx
  on public.branches (is_default)
  where is_default;

create table public.employee_branch_assignments (
  user_id uuid not null references public.user_profiles(user_id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete restrict,
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(),
  primary key (user_id, branch_id)
);

create index employee_branch_assignments_branch_idx
  on public.employee_branch_assignments (branch_id, user_id);

create trigger branches_set_updated_at
before update on public.branches
for each row execute function public.set_updated_at();

create or replace function private.validate_branch_timezone()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from pg_catalog.pg_timezone_names
    where name = new.timezone
  ) then
    raise exception 'invalid branch timezone' using errcode = '22023';
  end if;
  return new;
end;
$$;

revoke all on function private.validate_branch_timezone() from public, anon, authenticated;

create trigger branches_validate_timezone
before insert or update of timezone on public.branches
for each row execute function private.validate_branch_timezone();

insert into public.branches (
  code, name, timezone, is_active, is_default
) values (
  'BR-MAIN', 'Main Café', 'Asia/Kuala_Lumpur', true, true
);

create or replace function private.default_branch_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select b.id
  from public.branches b
  where b.is_default and b.is_active
  order by b.created_at, b.id
  limit 1;
$$;

create or replace function private.can_operate_branch(p_branch_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when p_branch_id is null or (select auth.uid()) is null then false
    when (select private.current_app_role()) in ('admin', 'owner') then true
    when (select private.current_app_role()) = 'staff' then exists (
      select 1
      from public.employee_branch_assignments a
      where a.user_id = (select auth.uid())
        and a.branch_id = p_branch_id
    )
    else false
  end;
$$;

revoke all on function private.default_branch_id() from public, anon, authenticated;
revoke all on function private.can_operate_branch(uuid) from public, anon, authenticated;
grant execute on function private.default_branch_id() to authenticated;
grant execute on function private.can_operate_branch(uuid) to authenticated;

insert into public.employee_branch_assignments (user_id, branch_id, assigned_by)
select p.user_id, (select private.default_branch_id()), null
from public.user_profiles p
where p.app_role in ('staff', 'admin', 'owner')
on conflict do nothing;

create or replace function private.sync_employee_branch_assignment()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_default_branch_id uuid;
begin
  if new.app_role = 'customer' then
    delete from public.employee_branch_assignments
    where user_id = new.user_id;
    return new;
  end if;

  if not exists (
    select 1
    from public.employee_branch_assignments a
    where a.user_id = new.user_id
  ) then
    select private.default_branch_id() into v_default_branch_id;
    if v_default_branch_id is null then
      raise exception 'default branch is unavailable for employee assignment'
        using errcode = '55000';
    end if;

    insert into public.employee_branch_assignments (
      user_id, branch_id, assigned_by
    ) values (
      new.user_id, v_default_branch_id, null
    )
    on conflict do nothing;
  end if;

  return new;
end;
$$;

revoke all on function private.sync_employee_branch_assignment()
from public, anon, authenticated;

create trigger user_profiles_sync_employee_branch_assignment
after insert or update of app_role on public.user_profiles
for each row execute function private.sync_employee_branch_assignment();

alter table public.orders
  add column branch_id uuid default private.default_branch_id();

update public.orders
set branch_id = private.default_branch_id()
where branch_id is null;

alter table public.orders
  alter column branch_id set not null,
  add constraint orders_branch_id_fkey
    foreign key (branch_id) references public.branches(id) on delete restrict;

create index orders_branch_active_queue_idx
  on public.orders (branch_id, status, requested_pickup_at, created_at)
  where status not in ('completed', 'cancelled');

create index orders_branch_created_idx
  on public.orders (branch_id, created_at desc);

alter table public.branches enable row level security;
alter table public.branches force row level security;
alter table public.employee_branch_assignments enable row level security;
alter table public.employee_branch_assignments force row level security;

grant select on table public.branches to anon, authenticated;
grant select on table public.employee_branch_assignments to authenticated;

create policy branches_public_active_read
on public.branches
for select
to anon
using (is_active);

create policy branches_authenticated_read
on public.branches
for select
to authenticated
using (is_active or (select private.is_admin_or_owner()));

create policy employee_branch_assignments_own_or_admin_read
on public.employee_branch_assignments
for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_admin_or_owner())
);

create or replace function private.protect_order_commercial_fields()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.order_number is distinct from old.order_number
     or new.source is distinct from old.source
     or new.customer_user_id is distinct from old.customer_user_id
     or new.member_id is distinct from old.member_id
     or new.created_by_user_id is distinct from old.created_by_user_id
     or new.branch_id is distinct from old.branch_id
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
      select jsonb_agg(jsonb_build_object(
        'id', l.id,
        'lineNumber', l.line_number,
        'itemId', l.catalogue_item_id,
        'sku', l.sku_snapshot,
        'name', l.name_snapshot,
        'prepRoute', l.prep_route_snapshot,
        'basePriceSen', l.base_price_sen,
        'variant', case when l.variant_id is null then null else jsonb_build_object(
          'id', l.variant_id,
          'code', l.variant_code_snapshot,
          'label', l.variant_label_snapshot,
          'priceDeltaSen', l.variant_price_delta_sen
        ) end,
        'addOns', coalesce((
          select jsonb_agg(jsonb_build_object(
            'itemId', a.catalogue_addon_item_id,
            'sku', a.sku_snapshot,
            'name', a.name_snapshot,
            'priceSen', a.price_sen
          ) order by a.created_at, a.id)
          from public.order_line_addons a
          where a.order_line_id = l.id
        ), '[]'::jsonb),
        'addOnTotalSen', l.addon_total_sen,
        'options', coalesce((
          select jsonb_agg(jsonb_build_object(
            'groupId', x.catalogue_option_group_id,
            'groupCode', x.group_code_snapshot,
            'groupName', x.group_name_snapshot,
            'optionValueId', x.catalogue_option_value_id,
            'optionCode', x.option_code_snapshot,
            'optionLabel', x.option_label_snapshot,
            'priceDeltaSen', x.price_delta_sen
          ) order by x.created_at, x.id)
          from public.order_line_options x
          where x.order_line_id = l.id
        ), '[]'::jsonb),
        'optionTotalSen', l.option_total_sen,
        'unitPriceSen', l.unit_price_sen,
        'quantity', l.quantity,
        'lineTotalSen', l.line_total_sen,
        'note', l.note
      ) order by l.line_number)
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

create or replace function public.list_orders(
  p_statuses text[] default null,
  p_limit integer default 100
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 250));
  v_result jsonb;
begin
  if (select auth.uid()) is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if p_statuses is not null and exists (
    select 1 from unnest(p_statuses) status_value
    where status_value not in (
      'confirmed', 'scheduled', 'preparing', 'ready', 'completed', 'cancelled'
    )
  ) then
    raise exception 'invalid order status filter' using errcode = '22023';
  end if;

  select coalesce(jsonb_agg(
    private.order_snapshot(x.id)
    order by case when x.status = 'scheduled' then x.requested_pickup_at end asc nulls last,
             x.created_at asc
  ), '[]'::jsonb)
  into v_result
  from (
    select o.id, o.status, o.requested_pickup_at, o.created_at
    from public.orders o
    where (
      (
        (p_statuses is null and o.status not in ('completed', 'cancelled'))
        or (p_statuses is not null and o.status = any(p_statuses))
      )
      and (select private.can_operate_branch(o.branch_id))
    )
    order by case when o.status = 'scheduled' then o.requested_pickup_at end asc nulls last,
             o.created_at asc
    limit v_limit
  ) x;

  return v_result;
end;
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
      'previousVersion', v_order.status_version,
      'newVersion', v_order.status_version + 1
    )
  );

  return private.order_snapshot(p_order_id);
end;
$$;

create or replace function public.place_pos_order(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_branch_id uuid := (select private.default_branch_id());
begin
  if v_user_id is null or not (select private.is_staff_or_above()) then
    raise exception 'staff access required' using errcode = '42501';
  end if;
  if v_branch_id is null then
    raise exception 'default branch is unavailable' using errcode = '55000';
  end if;
  if not (select private.can_operate_branch(v_branch_id)) then
    raise exception 'branch access required' using errcode = '42501';
  end if;

  return private.create_order_impl(
    p_payload, 'pos', null, null, v_user_id
  );
end;
$$;

drop policy if exists orders_authenticated_read on public.orders;
create policy orders_authenticated_read
on public.orders
for select
to authenticated
using (
  customer_user_id = (select auth.uid())
  or (select private.can_operate_branch(branch_id))
);

drop policy if exists order_lines_authenticated_read on public.order_lines;
create policy order_lines_authenticated_read
on public.order_lines
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_lines.order_id
      and (
        o.customer_user_id = (select auth.uid())
        or (select private.can_operate_branch(o.branch_id))
      )
  )
);

drop policy if exists order_line_addons_authenticated_read
on public.order_line_addons;
create policy order_line_addons_authenticated_read
on public.order_line_addons
for select
to authenticated
using (
  exists (
    select 1
    from public.order_lines l
    join public.orders o on o.id = l.order_id
    where l.id = order_line_addons.order_line_id
      and (
        o.customer_user_id = (select auth.uid())
        or (select private.can_operate_branch(o.branch_id))
      )
  )
);

drop policy if exists order_line_options_authenticated_read
on public.order_line_options;
create policy order_line_options_authenticated_read
on public.order_line_options
for select
to authenticated
using (
  exists (
    select 1
    from public.order_lines l
    join public.orders o on o.id = l.order_id
    where l.id = order_line_options.order_line_id
      and (
        o.customer_user_id = (select auth.uid())
        or (select private.can_operate_branch(o.branch_id))
      )
  )
);

drop policy if exists order_events_staff_read on public.order_events;
create policy order_events_staff_read
on public.order_events
for select
to authenticated
using (
  exists (
    select 1
    from public.orders o
    where o.id = order_events.order_id
      and (select private.can_operate_branch(o.branch_id))
  )
);

create or replace function private.save_branch_impl(
  p_payload jsonb,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_existing public.branches%rowtype;
  v_code text;
  v_name text;
  v_timezone text;
  v_address text;
  v_phone text;
  v_is_active boolean;
  v_is_default boolean;
  v_saved public.branches%rowtype;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'branch payload must be a JSON object' using errcode = '22023';
  end if;

  begin
    v_id := nullif(p_payload ->> 'id', '')::uuid;
  exception when invalid_text_representation then
    raise exception 'branch id must be a valid UUID' using errcode = '22023';
  end;

  if v_id is not null then
    select * into v_existing
    from public.branches
    where id = v_id
    for update;

    if not found then
      raise exception 'branch not found' using errcode = 'P0002';
    end if;
  end if;

  v_code := upper(btrim(coalesce(p_payload ->> 'code', v_existing.code)));
  v_name := btrim(coalesce(p_payload ->> 'name', v_existing.name));
  v_timezone := btrim(coalesce(
    nullif(p_payload ->> 'timezone', ''),
    v_existing.timezone,
    'Asia/Kuala_Lumpur'
  ));
  v_address := nullif(btrim(coalesce(
    p_payload ->> 'addressText',
    v_existing.address_text,
    ''
  )), '');
  v_phone := nullif(btrim(coalesce(
    p_payload ->> 'phone',
    v_existing.phone,
    ''
  )), '');
  v_is_active := coalesce(
    (p_payload ->> 'isActive')::boolean,
    v_existing.is_active,
    true
  );
  v_is_default := coalesce(
    (p_payload ->> 'isDefault')::boolean,
    v_existing.is_default,
    false
  );

  if v_code is null or v_code !~ '^[A-Z0-9][A-Z0-9-]{1,23}$' then
    raise exception 'branch code is invalid' using errcode = '22023';
  end if;
  if v_name is null or char_length(v_name) not between 1 and 120 then
    raise exception 'branch name is invalid' using errcode = '22023';
  end if;
  if not exists (
    select 1 from pg_catalog.pg_timezone_names where name = v_timezone
  ) then
    raise exception 'invalid branch timezone' using errcode = '22023';
  end if;
  if v_is_default and not v_is_active then
    raise exception 'default branch must be active' using errcode = '22023';
  end if;
  if v_id is not null and v_existing.is_default and not v_is_default then
    raise exception
      'set another branch as default instead of clearing the current default'
      using errcode = '22023';
  end if;
  if v_id is not null and v_existing.is_default and not v_is_active then
    raise exception 'default branch cannot be deactivated' using errcode = '22023';
  end if;

  if v_is_default then
    update public.branches
    set is_default = false
    where is_default
      and (v_id is null or id <> v_id);
  end if;

  if v_id is null then
    insert into public.branches (
      code, name, timezone, address_text, phone, is_active, is_default
    ) values (
      v_code, v_name, v_timezone, v_address, v_phone, v_is_active, v_is_default
    )
    returning * into v_saved;
  else
    update public.branches
    set code = v_code,
        name = v_name,
        timezone = v_timezone,
        address_text = v_address,
        phone = v_phone,
        is_active = v_is_active,
        is_default = v_is_default
    where id = v_id
    returning * into v_saved;
  end if;

  return jsonb_build_object(
    'id', v_saved.id,
    'code', v_saved.code,
    'name', v_saved.name,
    'timezone', v_saved.timezone,
    'addressText', v_saved.address_text,
    'phone', v_saved.phone,
    'isActive', v_saved.is_active,
    'isDefault', v_saved.is_default,
    'createdAt', v_saved.created_at,
    'updatedAt', v_saved.updated_at
  );
end;
$$;

create or replace function public.save_branch(p_payload jsonb)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_branch_impl(
    p_payload,
    (select auth.uid())
  );
$$;

create or replace function public.list_branches()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', b.id,
    'code', b.code,
    'name', b.name,
    'timezone', b.timezone,
    'addressText', b.address_text,
    'phone', b.phone,
    'isDefault', b.is_default
  ) order by b.is_default desc, b.name, b.code), '[]'::jsonb)
  from public.branches b
  where b.is_active;
$$;

create or replace function public.list_admin_branches()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
begin
  if (select auth.uid()) is null
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id', b.id,
    'code', b.code,
    'name', b.name,
    'timezone', b.timezone,
    'addressText', b.address_text,
    'phone', b.phone,
    'isActive', b.is_active,
    'isDefault', b.is_default,
    'createdAt', b.created_at,
    'updatedAt', b.updated_at
  ) order by b.is_default desc, b.name, b.code), '[]'::jsonb)
  into v_result
  from public.branches b;

  return v_result;
end;
$$;

create or replace function private.save_employee_branch_assignments_impl(
  p_user_id uuid,
  p_branch_ids uuid[],
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role public.app_user_role;
  v_ids uuid[] := coalesce(p_branch_ids, array[]::uuid[]);
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select p.app_role
  into v_role
  from public.user_profiles p
  where p.user_id = p_user_id;

  if v_role is null or v_role = 'customer' then
    raise exception 'employee profile is required' using errcode = '22023';
  end if;

  if cardinality(v_ids) <> (
    select count(distinct branch_id)
    from unnest(v_ids) as requested(branch_id)
  ) then
    raise exception 'duplicate branch assignments are not allowed'
      using errcode = '22023';
  end if;

  if exists (
    select 1
    from unnest(v_ids) as requested(branch_id)
    where not exists (
      select 1
      from public.branches b
      where b.id = requested.branch_id
    )
  ) then
    raise exception 'branch assignment references an unknown branch'
      using errcode = '22023';
  end if;

  if v_role = 'staff' and cardinality(v_ids) = 0 then
    raise exception 'staff must be assigned to at least one branch'
      using errcode = '22023';
  end if;

  delete from public.employee_branch_assignments
  where user_id = p_user_id;

  insert into public.employee_branch_assignments (
    user_id, branch_id, assigned_by
  )
  select p_user_id, requested.branch_id, p_actor_user_id
  from unnest(v_ids) as requested(branch_id);

  return (
    select coalesce(
      jsonb_agg(a.branch_id order by b.is_default desc, b.name, b.code),
      '[]'::jsonb
    )
    from public.employee_branch_assignments a
    join public.branches b on b.id = a.branch_id
    where a.user_id = p_user_id
  );
end;
$$;

create or replace function public.save_employee_branch_assignments(
  p_user_id uuid,
  p_branch_ids uuid[]
)
returns jsonb
language sql
security invoker
set search_path = public, pg_temp
as $$
  select private.save_employee_branch_assignments_impl(
    p_user_id,
    p_branch_ids,
    (select auth.uid())
  );
$$;

create or replace function public.list_admin_employees()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_result jsonb;
begin
  if (select auth.uid()) is null
     or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'userId', p.user_id,
    'email', p.email,
    'displayName', p.display_name,
    'appRole', p.app_role,
    'disabledAt', p.disabled_at,
    'branchIds', coalesce((
      select jsonb_agg(
        a.branch_id order by b.is_default desc, b.name, b.code
      )
      from public.employee_branch_assignments a
      join public.branches b on b.id = a.branch_id
      where a.user_id = p.user_id
    ), '[]'::jsonb)
  ) order by p.app_role desc, p.email), '[]'::jsonb)
  into v_result
  from public.user_profiles p
  where p.app_role in ('staff', 'admin', 'owner');

  return v_result;
end;
$$;

revoke all on function private.save_branch_impl(jsonb, uuid)
from public, anon, authenticated;
revoke all on function private.save_employee_branch_assignments_impl(
  uuid, uuid[], uuid
) from public, anon, authenticated;

revoke all on function public.save_branch(jsonb)
from public, anon, authenticated;
revoke all on function public.list_branches()
from public, anon, authenticated;
revoke all on function public.list_admin_branches()
from public, anon, authenticated;
revoke all on function public.save_employee_branch_assignments(uuid, uuid[])
from public, anon, authenticated;
revoke all on function public.list_admin_employees()
from public, anon, authenticated;

grant execute on function public.list_branches()
to anon, authenticated;
grant execute on function public.list_admin_branches()
to authenticated;
grant execute on function public.save_branch(jsonb)
to authenticated;
grant execute on function public.save_employee_branch_assignments(uuid, uuid[])
to authenticated;
grant execute on function public.list_admin_employees()
to authenticated;

comment on table public.branches is
  'Trusted café branch/location directory. BR-MAIN preserves the current single-café operational default.';
comment on table public.employee_branch_assignments is
  'Trusted employee-to-branch operational scope. Staff order access is limited by these assignments.';
comment on column public.orders.branch_id is
  'Immutable trusted branch identity for the order. Existing clients resolve to the active default branch until explicit branch selection is introduced.';

do $$
declare
  v_default uuid;
begin
  select private.default_branch_id() into v_default;

  if v_default is null then
    raise exception 'default branch was not created';
  end if;

  if (select count(*) from public.branches where is_default) <> 1 then
    raise exception 'branch default invariant failed';
  end if;

  if exists (
    select 1
    from public.orders
    where branch_id is null
  ) then
    raise exception 'order branch backfill failed';
  end if;

  if exists (
    select 1
    from public.user_profiles p
    where p.app_role = 'staff'
      and not exists (
        select 1
        from public.employee_branch_assignments a
        where a.user_id = p.user_id
      )
  ) then
    raise exception 'staff branch assignment backfill failed';
  end if;
end;
$$;
