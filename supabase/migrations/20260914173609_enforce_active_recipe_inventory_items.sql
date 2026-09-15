create or replace function private.assert_branch_inventory_payload(p_branch_id uuid, p_payload jsonb)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_req record;
begin
  for v_req in
    with requested_lines as (
      select
        (line ->> 'itemId')::uuid as item_id,
        nullif(line ->> 'variantId','')::uuid as variant_id,
        greatest(coalesce((line ->> 'quantity')::integer,1),1) as qty,
        coalesce(line -> 'addOnIds','[]'::jsonb) as addon_ids
      from jsonb_array_elements(coalesce(p_payload -> 'items','[]'::jsonb)) line
    ),
    base_requirements as (
      select rc.inventory_item_id, rc.quantity_milli * rl.qty::bigint as required_milli
      from requested_lines rl
      join lateral (select private.active_recipe_id(rl.item_id, rl.variant_id) as recipe_id) ar on ar.recipe_id is not null
      join public.recipe_components rc on rc.recipe_id = ar.recipe_id
    ),
    addon_requirements as (
      select rc.inventory_item_id, rc.quantity_milli * rl.qty::bigint as required_milli
      from requested_lines rl
      cross join lateral jsonb_array_elements_text(rl.addon_ids) addon_id
      join lateral (select private.active_recipe_id(addon_id::uuid, null) as recipe_id) ar on ar.recipe_id is not null
      join public.recipe_components rc on rc.recipe_id = ar.recipe_id
    )
    select req.inventory_item_id, sum(req.required_milli)::bigint as required_milli,
           coalesce(bi.on_hand_milli,0)::bigint as on_hand_milli,
           ii.name as item_name, ii.is_active
    from (select * from base_requirements union all select * from addon_requirements) req
    join public.inventory_items ii on ii.id=req.inventory_item_id
    left join public.branch_inventory bi on bi.branch_id=p_branch_id and bi.inventory_item_id=req.inventory_item_id
    group by req.inventory_item_id, bi.on_hand_milli, ii.name, ii.is_active
  loop
    if not v_req.is_active then
      raise exception 'inventory unavailable: % is inactive', v_req.item_name using errcode='22023', detail='INVENTORY_UNAVAILABLE';
    end if;
    if v_req.on_hand_milli < v_req.required_milli then
      raise exception 'inventory unavailable: %', v_req.item_name using errcode='22023', detail='INVENTORY_UNAVAILABLE';
    end if;
  end loop;
end;
$$;

create or replace function private.consume_recipe_inventory(
  p_branch_id uuid,
  p_item_id uuid,
  p_variant_id uuid,
  p_multiplier integer,
  p_actor_user_id uuid,
  p_order_id uuid,
  p_order_line_id uuid
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_recipe_id uuid; v_component record;
begin
  select private.active_recipe_id(p_item_id,p_variant_id) into v_recipe_id;
  if v_recipe_id is null then return; end if;
  for v_component in
    select rc.inventory_item_id, rc.quantity_milli, ii.is_active, ii.name
    from public.recipe_components rc
    join public.inventory_items ii on ii.id=rc.inventory_item_id
    where rc.recipe_id=v_recipe_id
    order by rc.inventory_item_id
  loop
    if not v_component.is_active then
      raise exception 'inventory unavailable: % is inactive', v_component.name using errcode='22023', detail='INVENTORY_UNAVAILABLE';
    end if;
    perform private.apply_inventory_movement_impl(p_branch_id,v_component.inventory_item_id,-(v_component.quantity_milli * p_multiplier::bigint),'order_consumption',p_actor_user_id,p_order_id,p_order_line_id,null,'Order recipe consumption');
  end loop;
end;
$$;

create or replace function private.save_recipe_impl(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_recipe_id uuid; v_item_id uuid; v_variant_id uuid; v_active boolean; v_name text; v_component jsonb; v_component_item uuid;
begin
  begin
    v_recipe_id:=nullif(p_payload->>'id','')::uuid;
    v_item_id:=(p_payload->>'itemId')::uuid;
    v_variant_id:=nullif(p_payload->>'variantId','')::uuid;
  exception when invalid_text_representation or null_value_not_allowed then
    raise exception 'recipe IDs must be valid UUIDs' using errcode='22023';
  end;
  v_active:=coalesce((p_payload->>'isActive')::boolean,true);
  v_name:=btrim(coalesce(nullif(p_payload->>'name',''),'Recipe'));
  if not exists (select 1 from public.catalogue_items where id=v_item_id) then raise exception 'catalogue item not found' using errcode='22023'; end if;
  if v_variant_id is not null and not exists (select 1 from public.catalogue_item_variants where id=v_variant_id and item_id=v_item_id) then raise exception 'variant does not belong to item' using errcode='22023'; end if;
  if v_active then
    update public.recipes set is_active=false
    where catalogue_item_id=v_item_id and id is distinct from v_recipe_id
      and ((variant_id is null and v_variant_id is null) or variant_id=v_variant_id) and is_active;
  end if;
  if v_recipe_id is null then
    insert into public.recipes(catalogue_item_id,variant_id,name,is_active)
    values(v_item_id,v_variant_id,v_name,v_active) returning id into v_recipe_id;
  else
    update public.recipes set catalogue_item_id=v_item_id,variant_id=v_variant_id,name=v_name,is_active=v_active where id=v_recipe_id;
    if not found then raise exception 'recipe not found' using errcode='P0002'; end if;
    delete from public.recipe_components where recipe_id=v_recipe_id;
  end if;
  if jsonb_typeof(coalesce(p_payload->'components','[]'::jsonb)) <> 'array' then raise exception 'components must be an array' using errcode='22023'; end if;
  for v_component in select value from jsonb_array_elements(coalesce(p_payload->'components','[]'::jsonb)) loop
    begin v_component_item := (v_component->>'inventoryItemId')::uuid;
    exception when invalid_text_representation or null_value_not_allowed then raise exception 'component inventoryItemId must be UUID' using errcode='22023'; end;
    if not exists(select 1 from public.inventory_items where id=v_component_item and is_active) then raise exception 'recipe component requires active inventory item' using errcode='22023'; end if;
    insert into public.recipe_components(recipe_id,inventory_item_id,quantity_milli)
    values(v_recipe_id,v_component_item,(v_component->>'quantityMilli')::bigint);
  end loop;
  if v_active and not exists(select 1 from public.recipe_components where recipe_id=v_recipe_id) then raise exception 'active recipe requires at least one component' using errcode='22023'; end if;
  return jsonb_build_object('id',v_recipe_id,'itemId',v_item_id,'variantId',v_variant_id,'name',v_name,'isActive',v_active);
end;
$$;
