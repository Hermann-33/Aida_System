create table public.inventory_items (
  id uuid primary key default gen_random_uuid(),
  sku text not null unique,
  name text not null,
  base_unit text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inventory_items_sku_format check (sku ~ '^[A-Z0-9][A-Z0-9-]{1,31}$'),
  constraint inventory_items_name_length check (char_length(btrim(name)) between 1 and 120),
  constraint inventory_items_base_unit_check check (base_unit in ('g','ml','unit'))
);

create table public.branch_inventory (
  branch_id uuid not null references public.branches(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  on_hand_milli bigint not null default 0,
  updated_at timestamptz not null default now(),
  primary key (branch_id, inventory_item_id),
  constraint branch_inventory_nonnegative check (on_hand_milli >= 0)
);

create table public.recipes (
  id uuid primary key default gen_random_uuid(),
  catalogue_item_id uuid not null references public.catalogue_items(id) on delete cascade,
  variant_id uuid references public.catalogue_item_variants(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint recipes_name_length check (char_length(btrim(name)) between 1 and 120)
);

create unique index recipes_one_active_default_idx on public.recipes (catalogue_item_id) where is_active and variant_id is null;
create unique index recipes_one_active_variant_idx on public.recipes (catalogue_item_id, variant_id) where is_active and variant_id is not null;
create index recipes_item_idx on public.recipes (catalogue_item_id, variant_id, is_active);

create table public.recipe_components (
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  quantity_milli bigint not null,
  created_at timestamptz not null default now(),
  primary key (recipe_id, inventory_item_id),
  constraint recipe_components_quantity_positive check (quantity_milli > 0)
);
create index recipe_components_inventory_item_idx on public.recipe_components (inventory_item_id);

create table public.inventory_movements (
  id bigint generated always as identity primary key,
  branch_id uuid not null references public.branches(id) on delete restrict,
  inventory_item_id uuid not null references public.inventory_items(id) on delete restrict,
  delta_milli bigint not null,
  movement_kind text not null,
  actor_user_id uuid references auth.users(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  order_line_id uuid references public.order_lines(id) on delete set null,
  reversal_of_movement_id bigint references public.inventory_movements(id) on delete restrict,
  note text,
  created_at timestamptz not null default now(),
  constraint inventory_movements_delta_nonzero check (delta_milli <> 0),
  constraint inventory_movements_kind_check check (movement_kind in ('receiving','waste','adjustment','order_consumption','order_reversal')),
  constraint inventory_movements_note_length check (note is null or char_length(note) <= 300),
  constraint inventory_movements_reversal_shape check ((movement_kind = 'order_reversal' and reversal_of_movement_id is not null and delta_milli > 0) or (movement_kind <> 'order_reversal' and reversal_of_movement_id is null)),
  constraint inventory_movements_order_shape check ((movement_kind in ('order_consumption','order_reversal') and order_id is not null) or movement_kind not in ('order_consumption','order_reversal'))
);
create index inventory_movements_branch_item_created_idx on public.inventory_movements (branch_id, inventory_item_id, created_at desc);
create index inventory_movements_order_idx on public.inventory_movements (order_id, created_at, id) where order_id is not null;
create unique index inventory_movements_one_reversal_idx on public.inventory_movements (reversal_of_movement_id) where reversal_of_movement_id is not null;

create trigger inventory_items_set_updated_at before update on public.inventory_items for each row execute function public.set_updated_at();
create trigger recipes_set_updated_at before update on public.recipes for each row execute function public.set_updated_at();

create or replace function private.validate_recipe_scope()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.variant_id is not null and not exists (select 1 from public.catalogue_item_variants v where v.id = new.variant_id and v.item_id = new.catalogue_item_id) then
    raise exception 'recipe variant must belong to catalogue item' using errcode = '23514';
  end if;
  return new;
end;
$$;
revoke all on function private.validate_recipe_scope() from public, anon, authenticated;
create trigger recipes_validate_scope before insert or update on public.recipes for each row execute function private.validate_recipe_scope();

alter table public.inventory_items enable row level security;
alter table public.inventory_items force row level security;
alter table public.branch_inventory enable row level security;
alter table public.branch_inventory force row level security;
alter table public.recipes enable row level security;
alter table public.recipes force row level security;
alter table public.recipe_components enable row level security;
alter table public.recipe_components force row level security;
alter table public.inventory_movements enable row level security;
alter table public.inventory_movements force row level security;

create policy inventory_items_admin_read on public.inventory_items for select to authenticated using ((select private.is_admin_or_owner()));
create policy branch_inventory_admin_read on public.branch_inventory for select to authenticated using ((select private.is_admin_or_owner()));
create policy recipes_admin_read on public.recipes for select to authenticated using ((select private.is_admin_or_owner()));
create policy recipe_components_admin_read on public.recipe_components for select to authenticated using ((select private.is_admin_or_owner()));
create policy inventory_movements_admin_read on public.inventory_movements for select to authenticated using ((select private.is_admin_or_owner()));

revoke all on public.inventory_items, public.branch_inventory, public.recipes, public.recipe_components, public.inventory_movements from public, anon, authenticated;
grant select on public.inventory_items, public.branch_inventory, public.recipes, public.recipe_components, public.inventory_movements to authenticated;

create or replace function private.apply_inventory_movement_impl(p_branch_id uuid,p_inventory_item_id uuid,p_delta_milli bigint,p_movement_kind text,p_actor_user_id uuid,p_order_id uuid default null,p_order_line_id uuid default null,p_reversal_of_movement_id bigint default null,p_note text default null)
returns bigint language plpgsql security definer set search_path = '' as $$
declare v_id bigint;
begin
  if p_delta_milli = 0 then raise exception 'inventory movement delta must be non-zero' using errcode = '22023'; end if;
  if p_movement_kind not in ('receiving','waste','adjustment','order_consumption','order_reversal') then raise exception 'invalid inventory movement kind' using errcode = '22023'; end if;
  if p_movement_kind = 'receiving' and p_delta_milli <= 0 then raise exception 'receiving movement must be positive' using errcode = '22023'; end if;
  if p_movement_kind = 'waste' and p_delta_milli >= 0 then raise exception 'waste movement must be negative' using errcode = '22023'; end if;
  if p_movement_kind = 'order_consumption' and (p_delta_milli >= 0 or p_order_id is null) then raise exception 'order consumption must be negative and order-bound' using errcode = '22023'; end if;
  if p_movement_kind = 'order_reversal' and (p_delta_milli <= 0 or p_order_id is null or p_reversal_of_movement_id is null) then raise exception 'order reversal must be positive and reference consumption' using errcode = '22023'; end if;
  if p_delta_milli > 0 then
    insert into public.branch_inventory (branch_id, inventory_item_id, on_hand_milli) values (p_branch_id, p_inventory_item_id, p_delta_milli)
    on conflict (branch_id, inventory_item_id) do update set on_hand_milli = public.branch_inventory.on_hand_milli + excluded.on_hand_milli, updated_at = now();
  else
    update public.branch_inventory set on_hand_milli = on_hand_milli + p_delta_milli, updated_at = now()
    where branch_id = p_branch_id and inventory_item_id = p_inventory_item_id and on_hand_milli + p_delta_milli >= 0;
    if not found then raise exception 'insufficient branch inventory' using errcode = '22023', detail = 'INVENTORY_UNAVAILABLE'; end if;
  end if;
  insert into public.inventory_movements (branch_id,inventory_item_id,delta_milli,movement_kind,actor_user_id,order_id,order_line_id,reversal_of_movement_id,note)
  values (p_branch_id,p_inventory_item_id,p_delta_milli,p_movement_kind,p_actor_user_id,p_order_id,p_order_line_id,p_reversal_of_movement_id,nullif(btrim(p_note),'')) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function private.apply_inventory_movement_impl(uuid,uuid,bigint,text,uuid,uuid,uuid,bigint,text) from public, anon, authenticated;
grant usage on schema private to authenticated;

create or replace function public.save_inventory_item(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_id uuid; v_row public.inventory_items%rowtype;
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode = '42501'; end if;
  begin v_id := nullif(p_payload ->> 'id','')::uuid; exception when invalid_text_representation then raise exception 'id must be UUID' using errcode = '22023'; end;
  if v_id is null then
    insert into public.inventory_items (sku,name,base_unit,is_active) values (upper(btrim(p_payload->>'sku')),btrim(p_payload->>'name'),lower(btrim(p_payload->>'baseUnit')),coalesce((p_payload->>'isActive')::boolean,true)) returning * into v_row;
  else
    update public.inventory_items set sku=upper(btrim(coalesce(p_payload->>'sku',sku))),name=btrim(coalesce(p_payload->>'name',name)),base_unit=lower(btrim(coalesce(p_payload->>'baseUnit',base_unit))),is_active=coalesce((p_payload->>'isActive')::boolean,is_active) where id=v_id returning * into v_row;
    if not found then raise exception 'inventory item not found' using errcode='P0002'; end if;
  end if;
  return jsonb_build_object('id',v_row.id,'sku',v_row.sku,'name',v_row.name,'baseUnit',v_row.base_unit,'isActive',v_row.is_active);
end;
$$;

create or replace function public.record_inventory_movement(p_branch_id uuid,p_inventory_item_id uuid,p_delta_milli bigint,p_movement_kind text,p_note text default null)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_actor uuid := (select auth.uid()); v_id bigint; v_balance bigint;
begin
  if v_actor is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode='42501'; end if;
  if not exists (select 1 from public.branches where id=p_branch_id and is_active) then raise exception 'active branch required' using errcode='22023'; end if;
  if not exists (select 1 from public.inventory_items where id=p_inventory_item_id and is_active) then raise exception 'active inventory item required' using errcode='22023'; end if;
  if p_movement_kind not in ('receiving','waste','adjustment') then raise exception 'manual movement kind must be receiving, waste or adjustment' using errcode='22023'; end if;
  v_id := private.apply_inventory_movement_impl(p_branch_id,p_inventory_item_id,p_delta_milli,p_movement_kind,v_actor,null,null,null,p_note);
  select on_hand_milli into v_balance from public.branch_inventory where branch_id=p_branch_id and inventory_item_id=p_inventory_item_id;
  return jsonb_build_object('movementId',v_id,'branchId',p_branch_id,'inventoryItemId',p_inventory_item_id,'onHandMilli',v_balance);
end;
$$;

create or replace function public.save_recipe(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path = public, pg_temp as $$
declare v_actor uuid := (select auth.uid()); v_recipe_id uuid; v_item_id uuid; v_variant_id uuid; v_active boolean; v_name text; v_component jsonb;
begin
  if v_actor is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode='42501'; end if;
  begin v_recipe_id:=nullif(p_payload->>'id','')::uuid; v_item_id:=(p_payload->>'itemId')::uuid; v_variant_id:=nullif(p_payload->>'variantId','')::uuid; exception when invalid_text_representation or null_value_not_allowed then raise exception 'recipe IDs must be valid UUIDs' using errcode='22023'; end;
  v_active:=coalesce((p_payload->>'isActive')::boolean,true); v_name:=btrim(coalesce(nullif(p_payload->>'name',''),'Recipe'));
  if not exists (select 1 from public.catalogue_items where id=v_item_id) then raise exception 'catalogue item not found' using errcode='22023'; end if;
  if v_variant_id is not null and not exists (select 1 from public.catalogue_item_variants where id=v_variant_id and item_id=v_item_id) then raise exception 'variant does not belong to item' using errcode='22023'; end if;
  if v_active then update public.recipes set is_active=false where catalogue_item_id=v_item_id and id is distinct from v_recipe_id and ((variant_id is null and v_variant_id is null) or variant_id=v_variant_id) and is_active; end if;
  if v_recipe_id is null then insert into public.recipes (catalogue_item_id,variant_id,name,is_active) values (v_item_id,v_variant_id,v_name,v_active) returning id into v_recipe_id;
  else update public.recipes set catalogue_item_id=v_item_id,variant_id=v_variant_id,name=v_name,is_active=v_active where id=v_recipe_id; if not found then raise exception 'recipe not found' using errcode='P0002'; end if; delete from public.recipe_components where recipe_id=v_recipe_id; end if;
  if jsonb_typeof(coalesce(p_payload->'components','[]'::jsonb)) <> 'array' then raise exception 'components must be an array' using errcode='22023'; end if;
  for v_component in select value from jsonb_array_elements(coalesce(p_payload->'components','[]'::jsonb)) loop
    insert into public.recipe_components (recipe_id,inventory_item_id,quantity_milli) values (v_recipe_id,(v_component->>'inventoryItemId')::uuid,(v_component->>'quantityMilli')::bigint);
  end loop;
  if v_active and not exists (select 1 from public.recipe_components where recipe_id=v_recipe_id) then raise exception 'active recipe requires at least one component' using errcode='22023'; end if;
  return jsonb_build_object('id',v_recipe_id,'itemId',v_item_id,'variantId',v_variant_id,'name',v_name,'isActive',v_active);
end;
$$;

create or replace function public.list_inventory_state(p_branch_id uuid)
returns jsonb language sql stable security invoker set search_path = public, pg_temp as $$
  select case when (select auth.uid()) is not null and (select private.is_admin_or_owner()) then jsonb_build_object(
    'branchId',p_branch_id,
    'items',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'sku',i.sku,'name',i.name,'baseUnit',i.base_unit,'isActive',i.is_active,'onHandMilli',coalesce(bi.on_hand_milli,0)) order by i.name) from public.inventory_items i left join public.branch_inventory bi on bi.inventory_item_id=i.id and bi.branch_id=p_branch_id),'[]'::jsonb),
    'recipes',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'itemId',r.catalogue_item_id,'variantId',r.variant_id,'name',r.name,'isActive',r.is_active,'components',coalesce((select jsonb_agg(jsonb_build_object('inventoryItemId',rc.inventory_item_id,'quantityMilli',rc.quantity_milli) order by rc.inventory_item_id) from public.recipe_components rc where rc.recipe_id=r.id),'[]'::jsonb)) order by r.created_at) from public.recipes r),'[]'::jsonb)
  ) else (select null::jsonb from (select 1) x where false) end;
$$;

revoke all on function public.save_inventory_item(jsonb) from public, anon, authenticated;
revoke all on function public.record_inventory_movement(uuid,uuid,bigint,text,text) from public, anon, authenticated;
revoke all on function public.save_recipe(jsonb) from public, anon, authenticated;
revoke all on function public.list_inventory_state(uuid) from public, anon, authenticated;
grant execute on function public.save_inventory_item(jsonb) to authenticated;
grant execute on function public.record_inventory_movement(uuid,uuid,bigint,text,text) to authenticated;
grant execute on function public.save_recipe(jsonb) to authenticated;
grant execute on function public.list_inventory_state(uuid) to authenticated;
grant execute on function private.apply_inventory_movement_impl(uuid,uuid,bigint,text,uuid,uuid,uuid,bigint,text) to authenticated;

comment on table public.inventory_movements is 'Append-only inventory movement ledger; clients have no direct write authority.';
comment on table public.branch_inventory is 'Server-owned current branch stock in integer milli-units.';
comment on table public.recipes is 'Catalogue item/variant recipes. Active recipe presence opts that item into inventory control.';
