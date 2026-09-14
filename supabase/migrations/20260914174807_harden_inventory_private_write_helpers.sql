create or replace function public.save_inventory_item(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode='42501';
  end if;
  return private.save_inventory_item_impl(p_payload);
end;
$$;

create or replace function public.save_recipe(p_payload jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode='42501';
  end if;
  return private.save_recipe_impl(p_payload);
end;
$$;

create or replace function public.record_inventory_movement(
  p_branch_id uuid,
  p_inventory_item_id uuid,
  p_delta_milli bigint,
  p_movement_kind text,
  p_note text default null
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := (select auth.uid());
  v_id bigint;
  v_balance bigint;
begin
  if v_actor is null or not (select private.is_admin_or_owner()) then
    raise exception 'administrator access required' using errcode='42501';
  end if;
  if not exists (select 1 from public.branches where id=p_branch_id and is_active) then
    raise exception 'active branch required' using errcode='22023';
  end if;
  if not exists (select 1 from public.inventory_items where id=p_inventory_item_id and is_active) then
    raise exception 'active inventory item required' using errcode='22023';
  end if;
  if p_movement_kind not in ('receiving','waste','adjustment') then
    raise exception 'manual movement kind must be receiving, waste or adjustment' using errcode='22023';
  end if;
  v_id := private.apply_inventory_movement_impl(p_branch_id,p_inventory_item_id,p_delta_milli,p_movement_kind,v_actor,null,null,null,p_note);
  select on_hand_milli into v_balance
  from public.branch_inventory
  where branch_id=p_branch_id and inventory_item_id=p_inventory_item_id;
  return jsonb_build_object('movementId',v_id,'branchId',p_branch_id,'inventoryItemId',p_inventory_item_id,'onHandMilli',v_balance);
end;
$$;

revoke all on function private.save_inventory_item_impl(jsonb) from public, anon, authenticated;
revoke all on function private.save_recipe_impl(jsonb) from public, anon, authenticated;
revoke all on function private.apply_inventory_movement_impl(uuid,uuid,bigint,text,uuid,uuid,uuid,bigint,text) from public, anon, authenticated;

revoke all on function public.save_inventory_item(jsonb) from public, anon, authenticated;
revoke all on function public.save_recipe(jsonb) from public, anon, authenticated;
revoke all on function public.record_inventory_movement(uuid,uuid,bigint,text,text) from public, anon, authenticated;
grant execute on function public.save_inventory_item(jsonb) to authenticated;
grant execute on function public.save_recipe(jsonb) to authenticated;
grant execute on function public.record_inventory_movement(uuid,uuid,bigint,text,text) to authenticated;
