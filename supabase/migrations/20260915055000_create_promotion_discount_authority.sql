-- TASK-OPS-007 / Phase 7 — generalized promotion/discount authority foundation.
-- This migration establishes configuration, deterministic scope constraints,
-- immutable application history, and caller-bound Admin/Owner management.

create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code = upper(code) and char_length(code) between 2 and 40),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  description text,
  discount_type text not null check (discount_type in ('fixed','percent')),
  fixed_amount_sen bigint check (fixed_amount_sen is null or fixed_amount_sen > 0),
  percent_basis_points integer check (percent_basis_points is null or percent_basis_points between 1 and 10000),
  minimum_subtotal_sen bigint not null default 0 check (minimum_subtotal_sen >= 0),
  maximum_discount_sen bigint check (maximum_discount_sen is null or maximum_discount_sen > 0),
  starts_at timestamptz,
  ends_at timestamptz,
  priority integer not null default 100,
  stacking_mode text not null default 'exclusive' check (stacking_mode in ('exclusive','stackable')),
  allow_with_voucher boolean not null default false,
  requires_member boolean not null default false,
  global_usage_limit bigint check (global_usage_limit is null or global_usage_limit > 0),
  per_member_usage_limit integer check (per_member_usage_limit is null or per_member_usage_limit > 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotions_discount_shape check (
    (discount_type='fixed' and fixed_amount_sen is not null and percent_basis_points is null)
    or (discount_type='percent' and percent_basis_points is not null and fixed_amount_sen is null)
  ),
  constraint promotions_window_check check (starts_at is null or ends_at is null or ends_at > starts_at)
);

create table public.promotion_branches (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  primary key (promotion_id, branch_id)
);

create table public.promotion_items (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  item_id uuid not null references public.menu_items(id) on delete cascade,
  primary key (promotion_id, item_id)
);

create table public.promotion_variants (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  variant_id uuid not null references public.menu_item_variants(id) on delete cascade,
  primary key (promotion_id, variant_id)
);

create table public.promotion_addons (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  addon_id uuid not null references public.add_ons(id) on delete cascade,
  primary key (promotion_id, addon_id)
);

create table public.promotion_order_applications (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  promotion_id uuid references public.promotions(id) on delete set null,
  member_id uuid references public.members(id) on delete set null,
  promotion_code_snapshot text not null,
  promotion_name_snapshot text not null,
  discount_type_snapshot text not null check (discount_type_snapshot in ('fixed','percent')),
  discount_value_snapshot bigint not null check (discount_value_snapshot > 0),
  discount_sen bigint not null check (discount_sen > 0),
  priority_snapshot integer not null,
  stacking_mode_snapshot text not null check (stacking_mode_snapshot in ('exclusive','stackable')),
  applied_at timestamptz not null default now(),
  unique (order_id, promotion_code_snapshot)
);

create index promotion_branches_branch_id_idx on public.promotion_branches(branch_id);
create index promotion_items_item_id_idx on public.promotion_items(item_id);
create index promotion_variants_variant_id_idx on public.promotion_variants(variant_id);
create index promotion_addons_addon_id_idx on public.promotion_addons(addon_id);
create index promotion_applications_promotion_id_idx on public.promotion_order_applications(promotion_id);
create index promotion_applications_member_id_idx on public.promotion_order_applications(member_id);
create index promotion_applications_order_id_idx on public.promotion_order_applications(order_id);

alter table public.promotions enable row level security;
alter table public.promotions force row level security;
alter table public.promotion_branches enable row level security;
alter table public.promotion_branches force row level security;
alter table public.promotion_items enable row level security;
alter table public.promotion_items force row level security;
alter table public.promotion_variants enable row level security;
alter table public.promotion_variants force row level security;
alter table public.promotion_addons enable row level security;
alter table public.promotion_addons force row level security;
alter table public.promotion_order_applications enable row level security;
alter table public.promotion_order_applications force row level security;

revoke all on table public.promotions from public, anon, authenticated;
revoke all on table public.promotion_branches from public, anon, authenticated;
revoke all on table public.promotion_items from public, anon, authenticated;
revoke all on table public.promotion_variants from public, anon, authenticated;
revoke all on table public.promotion_addons from public, anon, authenticated;
revoke all on table public.promotion_order_applications from public, anon, authenticated;

create or replace function private.require_promotion_admin(p_actor_user_id uuid)
returns void language plpgsql stable security definer set search_path=''
as $$
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;
  if not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required' using errcode='42501', detail='PROMOTION_ADMIN_REQUIRED';
  end if;
end;
$$;
revoke all on function private.require_promotion_admin(uuid) from public,anon,authenticated;

create or replace function private.get_promotion_admin_state_impl(p_actor_user_id uuid)
returns jsonb language plpgsql stable security definer set search_path=''
as $$
declare v_result jsonb;
begin
  perform private.require_promotion_admin(p_actor_user_id);
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,'code',p.code,'name',p.name,'description',p.description,
    'discountType',p.discount_type,'fixedAmountSen',p.fixed_amount_sen,
    'percentBasisPoints',p.percent_basis_points,'minimumSubtotalSen',p.minimum_subtotal_sen,
    'maximumDiscountSen',p.maximum_discount_sen,'startsAt',p.starts_at,'endsAt',p.ends_at,
    'priority',p.priority,'stackingMode',p.stacking_mode,'allowWithVoucher',p.allow_with_voucher,
    'requiresMember',p.requires_member,'globalUsageLimit',p.global_usage_limit,
    'perMemberUsageLimit',p.per_member_usage_limit,'isActive',p.is_active,
    'branchIds',coalesce((select jsonb_agg(pb.branch_id order by pb.branch_id) from public.promotion_branches pb where pb.promotion_id=p.id),'[]'::jsonb),
    'itemIds',coalesce((select jsonb_agg(pi.item_id order by pi.item_id) from public.promotion_items pi where pi.promotion_id=p.id),'[]'::jsonb),
    'variantIds',coalesce((select jsonb_agg(pv.variant_id order by pv.variant_id) from public.promotion_variants pv where pv.promotion_id=p.id),'[]'::jsonb),
    'addonIds',coalesce((select jsonb_agg(pa.addon_id order by pa.addon_id) from public.promotion_addons pa where pa.promotion_id=p.id),'[]'::jsonb),
    'updatedAt',p.updated_at
  ) order by p.priority,p.code),'[]'::jsonb) into v_result from public.promotions p;
  return v_result;
end;
$$;
revoke all on function private.get_promotion_admin_state_impl(uuid) from public,anon,authenticated;
grant execute on function private.get_promotion_admin_state_impl(uuid) to authenticated;

create or replace function public.get_promotion_admin_state()
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp
as $$ begin return private.get_promotion_admin_state_impl((select auth.uid())); end; $$;
revoke all on function public.get_promotion_admin_state() from public,anon,authenticated;
grant execute on function public.get_promotion_admin_state() to authenticated;

comment on table public.promotions is 'Phase 7 server-owned promotion configuration. Clients never author accepted discount amounts.';
comment on table public.promotion_order_applications is 'Immutable accepted promotion snapshots. Placement integration is added by subsequent Phase 7 migrations.';
