-- TASK-OPS-007 / Phase 7 — generalized promotion and discount authority.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/migrations/ only.
--
-- This migration establishes server-owned promotion configuration, caller-bound
-- Admin/Owner management, strict catalogue/branch scope, and immutable accepted
-- application history. Quote/place integration is added by subsequent Phase 7
-- migrations. Clients never author accepted discount amounts or totals.

create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  discount_type text not null,
  fixed_amount_sen bigint,
  percent_basis_points integer,
  minimum_subtotal_sen bigint not null default 0,
  maximum_discount_sen bigint,
  starts_at timestamptz,
  ends_at timestamptz,
  priority integer not null default 100,
  stacking_mode text not null default 'exclusive',
  allow_with_voucher boolean not null default false,
  requires_member boolean not null default false,
  global_usage_limit bigint,
  per_member_usage_limit integer,
  is_active boolean not null default true,
  created_by_user_id uuid references public.user_profiles(user_id) on delete set null,
  updated_by_user_id uuid references public.user_profiles(user_id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint promotions_code_check check (code ~ '^[A-Z0-9][A-Z0-9_-]{1,39}$'),
  constraint promotions_name_check check (char_length(btrim(name)) between 1 and 120),
  constraint promotions_description_check check (description is null or char_length(description) <= 1000),
  constraint promotions_discount_type_check check (discount_type in ('fixed','percent')),
  constraint promotions_discount_shape_check check (
    (discount_type='fixed' and fixed_amount_sen between 1 and 100000000 and percent_basis_points is null)
    or
    (discount_type='percent' and fixed_amount_sen is null and percent_basis_points between 1 and 10000)
  ),
  constraint promotions_minimum_subtotal_check check (minimum_subtotal_sen between 0 and 1000000000),
  constraint promotions_maximum_discount_check check (maximum_discount_sen is null or maximum_discount_sen between 1 and 1000000000),
  constraint promotions_window_check check (starts_at is null or ends_at is null or ends_at > starts_at),
  constraint promotions_priority_check check (priority between 0 and 1000000),
  constraint promotions_stacking_mode_check check (stacking_mode in ('exclusive','stackable')),
  constraint promotions_global_usage_limit_check check (global_usage_limit is null or global_usage_limit between 1 and 1000000000),
  constraint promotions_member_usage_limit_check check (per_member_usage_limit is null or per_member_usage_limit between 1 and 1000000)
);

create table public.promotion_branches (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  primary key (promotion_id, branch_id)
);

create table public.promotion_items (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  catalogue_item_id uuid not null references public.catalogue_items(id) on delete cascade,
  primary key (promotion_id, catalogue_item_id)
);

create table public.promotion_variants (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  variant_id uuid not null references public.catalogue_item_variants(id) on delete cascade,
  primary key (promotion_id, variant_id)
);

create table public.promotion_addons (
  promotion_id uuid not null references public.promotions(id) on delete cascade,
  addon_item_id uuid not null references public.catalogue_items(id) on delete restrict,
  primary key (promotion_id, addon_item_id)
);

create table public.promotion_order_applications (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  promotion_id uuid references public.promotions(id) on delete set null,
  member_id uuid references public.members(id) on delete set null,
  promotion_code_snapshot text not null,
  promotion_name_snapshot text not null,
  discount_type_snapshot text not null,
  discount_value_snapshot bigint not null,
  discount_sen bigint not null,
  priority_snapshot integer not null,
  stacking_mode_snapshot text not null,
  allow_with_voucher_snapshot boolean not null,
  applied_at timestamptz not null default now(),
  constraint promotion_application_discount_type_check check (discount_type_snapshot in ('fixed','percent')),
  constraint promotion_application_discount_value_check check (discount_value_snapshot > 0),
  constraint promotion_application_discount_sen_check check (discount_sen > 0),
  constraint promotion_application_stacking_check check (stacking_mode_snapshot in ('exclusive','stackable')),
  constraint promotion_application_order_code_unique unique (order_id, promotion_code_snapshot)
);

create index promotions_active_window_idx on public.promotions(is_active, starts_at, ends_at, priority, code);
create index promotions_created_by_idx on public.promotions(created_by_user_id);
create index promotions_updated_by_idx on public.promotions(updated_by_user_id);
create index promotion_branches_branch_idx on public.promotion_branches(branch_id);
create index promotion_items_item_idx on public.promotion_items(catalogue_item_id);
create index promotion_variants_variant_idx on public.promotion_variants(variant_id);
create index promotion_addons_addon_idx on public.promotion_addons(addon_item_id);
create index promotion_applications_promotion_idx on public.promotion_order_applications(promotion_id);
create index promotion_applications_member_idx on public.promotion_order_applications(member_id);
create index promotion_applications_order_idx on public.promotion_order_applications(order_id);

create trigger promotions_set_updated_at
before update on public.promotions
for each row execute function public.set_updated_at();

create or replace function private.validate_promotion_item_scope()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.catalogue_items i
    where i.id = new.catalogue_item_id and i.kind = 'product'
  ) then
    raise exception 'promotion item scope must reference a product catalogue item'
      using errcode='23514', detail='PROMOTION_ITEM_SCOPE_INVALID';
  end if;
  return new;
end;
$$;
revoke all on function private.validate_promotion_item_scope() from public, anon, authenticated;

create trigger promotion_items_validate
before insert or update on public.promotion_items
for each row execute function private.validate_promotion_item_scope();

create or replace function private.validate_promotion_addon_scope()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.catalogue_items i
    where i.id = new.addon_item_id and i.kind = 'addon'
  ) then
    raise exception 'promotion add-on scope must reference an add-on catalogue item'
      using errcode='23514', detail='PROMOTION_ADDON_SCOPE_INVALID';
  end if;
  return new;
end;
$$;
revoke all on function private.validate_promotion_addon_scope() from public, anon, authenticated;

create trigger promotion_addons_validate
before insert or update on public.promotion_addons
for each row execute function private.validate_promotion_addon_scope();

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
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;
  if not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required'
      using errcode='42501', detail='PROMOTION_ADMIN_REQUIRED';
  end if;
end;
$$;
revoke all on function private.require_promotion_admin(uuid) from public, anon, authenticated;

create or replace function private.save_promotion_impl(
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
  v_code text;
  v_name text;
  v_discount_type text;
  v_scope text;
begin
  perform private.require_promotion_admin(p_actor_user_id);

  v_code := upper(btrim(coalesce(p_payload->>'code','')));
  v_name := btrim(coalesce(p_payload->>'name',''));
  v_discount_type := lower(btrim(coalesce(p_payload->>'discountType','')));

  if v_code = '' then raise exception 'promotion code is required' using errcode='22023'; end if;
  if v_name = '' then raise exception 'promotion name is required' using errcode='22023'; end if;
  if v_discount_type not in ('fixed','percent') then
    raise exception 'promotion discountType must be fixed or percent' using errcode='22023';
  end if;

  begin
    v_id := nullif(p_payload->>'id','')::uuid;
  exception when invalid_text_representation then
    raise exception 'promotion id must be a valid UUID' using errcode='22023';
  end;

  if v_id is null then
    select p.id into v_id from public.promotions p where p.code = v_code;
  end if;

  if v_id is null then
    insert into public.promotions(
      code,name,description,discount_type,fixed_amount_sen,percent_basis_points,
      minimum_subtotal_sen,maximum_discount_sen,starts_at,ends_at,priority,
      stacking_mode,allow_with_voucher,requires_member,global_usage_limit,
      per_member_usage_limit,is_active,created_by_user_id,updated_by_user_id
    ) values (
      v_code,v_name,nullif(btrim(coalesce(p_payload->>'description','')),''),v_discount_type,
      case when v_discount_type='fixed' then (p_payload->>'fixedAmountSen')::bigint else null end,
      case when v_discount_type='percent' then (p_payload->>'percentBasisPoints')::integer else null end,
      coalesce((p_payload->>'minimumSubtotalSen')::bigint,0),
      nullif(p_payload->>'maximumDiscountSen','')::bigint,
      nullif(p_payload->>'startsAt','')::timestamptz,
      nullif(p_payload->>'endsAt','')::timestamptz,
      coalesce((p_payload->>'priority')::integer,100),
      coalesce(nullif(lower(btrim(p_payload->>'stackingMode')),''),'exclusive'),
      coalesce((p_payload->>'allowWithVoucher')::boolean,false),
      coalesce((p_payload->>'requiresMember')::boolean,false),
      nullif(p_payload->>'globalUsageLimit','')::bigint,
      nullif(p_payload->>'perMemberUsageLimit','')::integer,
      coalesce((p_payload->>'isActive')::boolean,true),
      p_actor_user_id,p_actor_user_id
    ) returning id into v_id;
  else
    update public.promotions p set
      code=v_code,
      name=v_name,
      description=nullif(btrim(coalesce(p_payload->>'description','')),''),
      discount_type=v_discount_type,
      fixed_amount_sen=case when v_discount_type='fixed' then (p_payload->>'fixedAmountSen')::bigint else null end,
      percent_basis_points=case when v_discount_type='percent' then (p_payload->>'percentBasisPoints')::integer else null end,
      minimum_subtotal_sen=coalesce((p_payload->>'minimumSubtotalSen')::bigint,0),
      maximum_discount_sen=nullif(p_payload->>'maximumDiscountSen','')::bigint,
      starts_at=nullif(p_payload->>'startsAt','')::timestamptz,
      ends_at=nullif(p_payload->>'endsAt','')::timestamptz,
      priority=coalesce((p_payload->>'priority')::integer,100),
      stacking_mode=coalesce(nullif(lower(btrim(p_payload->>'stackingMode')),''),'exclusive'),
      allow_with_voucher=coalesce((p_payload->>'allowWithVoucher')::boolean,false),
      requires_member=coalesce((p_payload->>'requiresMember')::boolean,false),
      global_usage_limit=nullif(p_payload->>'globalUsageLimit','')::bigint,
      per_member_usage_limit=nullif(p_payload->>'perMemberUsageLimit','')::integer,
      is_active=coalesce((p_payload->>'isActive')::boolean,true),
      updated_by_user_id=p_actor_user_id
    where p.id=v_id;
    if not found then raise exception 'promotion not found' using errcode='P0002'; end if;
  end if;

  delete from public.promotion_branches where promotion_id=v_id;
  delete from public.promotion_items where promotion_id=v_id;
  delete from public.promotion_variants where promotion_id=v_id;
  delete from public.promotion_addons where promotion_id=v_id;

  for v_scope in select value from jsonb_array_elements_text(coalesce(p_payload->'branchIds','[]'::jsonb)) loop
    insert into public.promotion_branches(promotion_id,branch_id) values(v_id,v_scope::uuid);
  end loop;
  for v_scope in select value from jsonb_array_elements_text(coalesce(p_payload->'itemIds','[]'::jsonb)) loop
    insert into public.promotion_items(promotion_id,catalogue_item_id) values(v_id,v_scope::uuid);
  end loop;
  for v_scope in select value from jsonb_array_elements_text(coalesce(p_payload->'variantIds','[]'::jsonb)) loop
    insert into public.promotion_variants(promotion_id,variant_id) values(v_id,v_scope::uuid);
  end loop;
  for v_scope in select value from jsonb_array_elements_text(coalesce(p_payload->'addonItemIds','[]'::jsonb)) loop
    insert into public.promotion_addons(promotion_id,addon_item_id) values(v_id,v_scope::uuid);
  end loop;

  return private.get_promotion_admin_state_impl(p_actor_user_id,v_id);
end;
$$;
revoke all on function private.save_promotion_impl(jsonb,uuid) from public, anon, authenticated;
grant execute on function private.save_promotion_impl(jsonb,uuid) to authenticated;

create or replace function private.get_promotion_admin_state_impl(
  p_actor_user_id uuid,
  p_promotion_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_result jsonb;
begin
  perform private.require_promotion_admin(p_actor_user_id);
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',p.id,
    'code',p.code,
    'name',p.name,
    'description',p.description,
    'discountType',p.discount_type,
    'fixedAmountSen',p.fixed_amount_sen,
    'percentBasisPoints',p.percent_basis_points,
    'minimumSubtotalSen',p.minimum_subtotal_sen,
    'maximumDiscountSen',p.maximum_discount_sen,
    'startsAt',p.starts_at,
    'endsAt',p.ends_at,
    'priority',p.priority,
    'stackingMode',p.stacking_mode,
    'allowWithVoucher',p.allow_with_voucher,
    'requiresMember',p.requires_member,
    'globalUsageLimit',p.global_usage_limit,
    'perMemberUsageLimit',p.per_member_usage_limit,
    'isActive',p.is_active,
    'branchIds',coalesce((select jsonb_agg(pb.branch_id order by pb.branch_id) from public.promotion_branches pb where pb.promotion_id=p.id),'[]'::jsonb),
    'itemIds',coalesce((select jsonb_agg(pi.catalogue_item_id order by pi.catalogue_item_id) from public.promotion_items pi where pi.promotion_id=p.id),'[]'::jsonb),
    'variantIds',coalesce((select jsonb_agg(pv.variant_id order by pv.variant_id) from public.promotion_variants pv where pv.promotion_id=p.id),'[]'::jsonb),
    'addonItemIds',coalesce((select jsonb_agg(pa.addon_item_id order by pa.addon_item_id) from public.promotion_addons pa where pa.promotion_id=p.id),'[]'::jsonb),
    'createdAt',p.created_at,
    'updatedAt',p.updated_at
  ) order by p.priority,p.code),'[]'::jsonb)
  into v_result
  from public.promotions p
  where p_promotion_id is null or p.id=p_promotion_id;
  return v_result;
end;
$$;
revoke all on function private.get_promotion_admin_state_impl(uuid,uuid) from public, anon, authenticated;
grant execute on function private.get_promotion_admin_state_impl(uuid,uuid) to authenticated;

create or replace function public.get_promotion_admin_state()
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
begin
  return private.get_promotion_admin_state_impl((select auth.uid()),null);
end;
$$;
revoke all on function public.get_promotion_admin_state() from public, anon, authenticated;
grant execute on function public.get_promotion_admin_state() to authenticated;

create or replace function public.save_promotion(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  return private.save_promotion_impl(p_payload,(select auth.uid()));
end;
$$;
revoke all on function public.save_promotion(jsonb) from public, anon, authenticated;
grant execute on function public.save_promotion(jsonb) to authenticated;

comment on table public.promotions is
  'Phase 7 server-owned promotion configuration. Accepted discounts are never client-authored.';
comment on table public.promotion_order_applications is
  'Immutable accepted promotion snapshots. Order integration is added by later Phase 7 migrations.';
