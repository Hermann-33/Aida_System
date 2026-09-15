-- TASK-OPS-005 / Phase 5 inventory and recipes regression.
-- Transactional: no synthetic users, recipes, stock or orders survive.

begin;

do $$
begin
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='branch_inventory'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then raise exception 'branch_inventory does not have FORCE RLS'; end if;
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='inventory_movements'
      and c.relrowsecurity and c.relforcerowsecurity
  ) then raise exception 'inventory_movements does not have FORCE RLS'; end if;
  if has_table_privilege('authenticated','public.inventory_items','insert')
     or has_table_privilege('authenticated','public.branch_inventory','update')
     or has_table_privilege('authenticated','public.recipes','insert')
     or has_table_privilege('authenticated','public.recipe_components','insert')
     or has_table_privilege('authenticated','public.inventory_movements','insert') then
    raise exception 'authenticated role has direct inventory/recipe write authority';
  end if;
  if has_function_privilege('anon','public.save_inventory_item(jsonb)','execute')
     or has_function_privilege('anon','public.save_recipe(jsonb)','execute')
     or has_function_privilege('anon','public.record_inventory_movement(uuid,uuid,bigint,text,text)','execute') then
    raise exception 'anonymous role has inventory administration authority';
  end if;
  if not has_function_privilege('authenticated','public.save_inventory_item(jsonb)','execute')
     or not has_function_privilege('authenticated','public.save_recipe(jsonb)','execute')
     or not has_function_privilege('authenticated','public.record_inventory_movement(uuid,uuid,bigint,text,text)','execute') then
    raise exception 'authenticated inventory RPC grants are missing';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname in ('save_inventory_item','save_recipe','record_inventory_movement')
      and p.prosecdef
  ) then raise exception 'public inventory mutation RPC unexpectedly uses SECURITY DEFINER'; end if;
  if has_function_privilege('authenticated','private.save_inventory_item_impl(jsonb)','execute')
     or has_function_privilege('authenticated','private.save_recipe_impl(jsonb)','execute')
     or has_function_privilege('authenticated','private.apply_inventory_movement_impl(uuid,uuid,bigint,text,uuid,uuid,uuid,bigint,text)','execute') then
    raise exception 'authenticated role can execute unchecked private inventory write helper';
  end if;
end;
$$;

insert into auth.users (id,email,raw_user_meta_data,created_at,updated_at)
values
 ('55000000-0000-0000-0000-000000000001','phase5-admin@example.test','{}'::jsonb,now(),now()),
 ('55000000-0000-0000-0000-000000000002','phase5-customer@example.test','{}'::jsonb,now(),now());

update public.user_profiles set app_role='admin'
where user_id='55000000-0000-0000-0000-000000000001';

set local role authenticated;

do $$
declare
  v_admin uuid := '55000000-0000-0000-0000-000000000001';
  v_branch uuid;
  v_item uuid;
  v_variant uuid;
  v_addon uuid;
  v_inventory jsonb;
  v_inventory_id uuid;
  v_recipe jsonb;
  v_state jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  select id into strict v_branch from public.branches where is_default and is_active limit 1;
  select id into strict v_item from public.catalogue_items where sku='CF-LAT';
  select id into strict v_variant from public.catalogue_item_variants where item_id=v_item and code='medium';
  select id into strict v_addon from public.catalogue_items where sku='AD-SHT';

  select public.save_inventory_item(jsonb_build_object('sku','P5-MILK','name','Phase 5 Milk','baseUnit','ml','isActive',true)) into v_inventory;
  v_inventory_id := (v_inventory->>'id')::uuid;

  perform public.record_inventory_movement(v_branch,v_inventory_id,500000,'receiving','Phase 5 regression stock');

  select public.save_recipe(jsonb_build_object(
    'itemId',v_item,
    'variantId',v_variant,
    'name','Phase 5 latte recipe',
    'isActive',true,
    'components',jsonb_build_array(jsonb_build_object('inventoryItemId',v_inventory_id,'quantityMilli',100000))
  )) into v_recipe;

  perform public.save_recipe(jsonb_build_object(
    'itemId',v_addon,
    'variantId',null,
    'name','Phase 5 extra-shot recipe',
    'isActive',true,
    'components',jsonb_build_array(jsonb_build_object('inventoryItemId',v_inventory_id,'quantityMilli',50000))
  ));

  select public.list_inventory_state(v_branch) into v_state;
  if jsonb_array_length(v_state->'items') < 1 or jsonb_array_length(v_state->'recipes') < 2 then
    raise exception 'inventory state did not expose configured stock/recipes to admin';
  end if;

  begin
    insert into public.inventory_items(sku,name,base_unit) values('ILLEGAL','Illegal','unit');
    raise exception 'authenticated direct inventory insert unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end;
$$;

reset role;
set local role authenticated;

do $$
declare
  v_customer uuid := '55000000-0000-0000-0000-000000000002';
  v_branch uuid;
  v_item uuid;
  v_variant uuid;
  v_addon uuid;
  v_quote jsonb;
  v_order jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select id into strict v_branch from public.branches where is_default and is_active limit 1;
  select id into strict v_item from public.catalogue_items where sku='CF-LAT';
  select id into strict v_variant from public.catalogue_item_variants where item_id=v_item and code='medium';
  select id into strict v_addon from public.catalogue_items where sku='AD-SHT';

  begin
    perform public.save_inventory_item(jsonb_build_object('sku','ILLEGAL-CUSTOMER','name','Illegal customer item','baseUnit','unit','isActive',true));
    raise exception 'customer inventory administration unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;

  select public.quote_order(jsonb_build_object(
    'branchId',v_branch,
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object('itemId',v_item,'variantId',v_variant,'addOnIds',jsonb_build_array(v_addon),'quantity',2))
  )) into v_quote;
  if not coalesce((v_quote->>'inventoryChecked')::boolean,false) then
    raise exception 'authoritative quote did not report inventory check';
  end if;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId','55100000-0000-0000-0000-000000000001',
    'branchId',v_branch,
    'fulfillmentType','asap',
    'items',jsonb_build_array(jsonb_build_object('itemId',v_item,'variantId',v_variant,'addOnIds',jsonb_build_array(v_addon),'quantity',2))
  )) into v_order;
  if nullif(v_order->>'id','') is null then raise exception 'customer order did not return an id'; end if;

  begin
    perform public.quote_order(jsonb_build_object(
      'branchId',v_branch,
      'fulfillmentType','asap',
      'items',jsonb_build_array(jsonb_build_object('itemId',v_item,'variantId',v_variant,'addOnIds',jsonb_build_array(v_addon),'quantity',2))
    ));
    raise exception 'insufficient inventory quote unexpectedly succeeded';
  exception when invalid_parameter_value then
    if sqlerrm not like 'inventory unavailable:%' then raise; end if;
  end;
end;
$$;

reset role;

do $$
declare
  v_order_id uuid;
  v_branch uuid;
  v_inventory_id uuid;
  v_balance bigint;
begin
  select id into strict v_order_id from public.orders where client_request_id='55100000-0000-0000-0000-000000000001';
  select branch_id into strict v_branch from public.orders where id=v_order_id;
  select id into strict v_inventory_id from public.inventory_items where sku='P5-MILK';

  select on_hand_milli into strict v_balance from public.branch_inventory where branch_id=v_branch and inventory_item_id=v_inventory_id;
  if v_balance <> 200000 then raise exception 'order/add-on consumption balance mismatch: %',v_balance; end if;
  if (select count(*) from public.inventory_movements where order_id=v_order_id and movement_kind='order_consumption') <> 2 then
    raise exception 'base + add-on consumption movements were not recorded exactly once each';
  end if;

  update public.orders set status='cancelled', cancelled_at=now(), status_version=status_version+1, status_updated_at=now() where id=v_order_id;

  select on_hand_milli into strict v_balance from public.branch_inventory where branch_id=v_branch and inventory_item_id=v_inventory_id;
  if v_balance <> 500000 then raise exception 'cancellation did not restore inventory: %',v_balance; end if;
  if (select count(*) from public.inventory_movements where order_id=v_order_id and movement_kind='order_reversal') <> 2 then
    raise exception 'cancellation reversals were not recorded exactly once each';
  end if;

  update public.orders set status='cancelled' where id=v_order_id;
  if (select count(*) from public.inventory_movements where order_id=v_order_id and movement_kind='order_reversal') <> 2 then
    raise exception 'repeated cancellation created duplicate inventory reversal';
  end if;
end;
$$;

rollback;
