create or replace function private.save_inventory_item_impl(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_id uuid; v_row public.inventory_items%rowtype;
begin
  begin v_id := nullif(p_payload ->> 'id','')::uuid;
  exception when invalid_text_representation then raise exception 'id must be UUID' using errcode='22023'; end;
  if v_id is null then
    insert into public.inventory_items (sku,name,base_unit,is_active)
    values (upper(btrim(p_payload->>'sku')),btrim(p_payload->>'name'),lower(btrim(p_payload->>'baseUnit')),coalesce((p_payload->>'isActive')::boolean,true))
    returning * into v_row;
  else
    update public.inventory_items set
      sku=upper(btrim(coalesce(p_payload->>'sku',sku))),
      name=btrim(coalesce(p_payload->>'name',name)),
      base_unit=lower(btrim(coalesce(p_payload->>'baseUnit',base_unit))),
      is_active=coalesce((p_payload->>'isActive')::boolean,is_active)
    where id=v_id returning * into v_row;
    if not found then raise exception 'inventory item not found' using errcode='P0002'; end if;
  end if;
  return jsonb_build_object('id',v_row.id,'sku',v_row.sku,'name',v_row.name,'baseUnit',v_row.base_unit,'isActive',v_row.is_active);
end;
$$;
revoke all on function private.save_inventory_item_impl(jsonb) from public, anon, authenticated;
grant execute on function private.save_inventory_item_impl(jsonb) to authenticated;

create or replace function private.save_recipe_impl(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare v_recipe_id uuid; v_item_id uuid; v_variant_id uuid; v_active boolean; v_name text; v_component jsonb;
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
    insert into public.recipe_components(recipe_id,inventory_item_id,quantity_milli)
    values(v_recipe_id,(v_component->>'inventoryItemId')::uuid,(v_component->>'quantityMilli')::bigint);
  end loop;
  if v_active and not exists(select 1 from public.recipe_components where recipe_id=v_recipe_id) then raise exception 'active recipe requires at least one component' using errcode='22023'; end if;
  return jsonb_build_object('id',v_recipe_id,'itemId',v_item_id,'variantId',v_variant_id,'name',v_name,'isActive',v_active);
end;
$$;
revoke all on function private.save_recipe_impl(jsonb) from public, anon, authenticated;
grant execute on function private.save_recipe_impl(jsonb) to authenticated;

create or replace function public.save_inventory_item(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path='' as $$
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode='42501'; end if;
  return private.save_inventory_item_impl(p_payload);
end;
$$;

create or replace function public.save_recipe(p_payload jsonb)
returns jsonb language plpgsql security invoker set search_path='' as $$
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then raise exception 'administrator access required' using errcode='42501'; end if;
  return private.save_recipe_impl(p_payload);
end;
$$;

revoke all on function public.save_inventory_item(jsonb) from public, anon, authenticated;
revoke all on function public.save_recipe(jsonb) from public, anon, authenticated;
grant execute on function public.save_inventory_item(jsonb) to authenticated;
grant execute on function public.save_recipe(jsonb) to authenticated;
