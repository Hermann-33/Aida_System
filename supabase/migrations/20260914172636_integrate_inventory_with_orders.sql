create or replace function private.active_recipe_id(p_item_id uuid, p_variant_id uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select r.id
  from public.recipes r
  where r.catalogue_item_id = p_item_id
    and r.is_active
    and (r.variant_id = p_variant_id or r.variant_id is null)
  order by (r.variant_id is not null) desc, r.created_at desc
  limit 1;
$$;
revoke all on function private.active_recipe_id(uuid,uuid) from public, anon, authenticated;

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
           ii.name as item_name
    from (select * from base_requirements union all select * from addon_requirements) req
    join public.inventory_items ii on ii.id=req.inventory_item_id and ii.is_active
    left join public.branch_inventory bi on bi.branch_id=p_branch_id and bi.inventory_item_id=req.inventory_item_id
    group by req.inventory_item_id, bi.on_hand_milli, ii.name
  loop
    if v_req.on_hand_milli < v_req.required_milli then
      raise exception 'inventory unavailable: %', v_req.item_name using errcode='22023', detail='INVENTORY_UNAVAILABLE';
    end if;
  end loop;
end;
$$;
revoke all on function private.assert_branch_inventory_payload(uuid,jsonb) from public, anon, authenticated;

do $$
begin
  if to_regprocedure('public.quote_order(jsonb)') is not null
     and to_regprocedure('private.quote_order_phase4(jsonb)') is null then
    alter function public.quote_order(jsonb) set schema private;
    alter function private.quote_order(jsonb) rename to quote_order_phase4;
  end if;
end;
$$;
revoke all on function private.quote_order_phase4(jsonb) from public, anon, authenticated;
grant execute on function private.quote_order_phase4(jsonb) to anon, authenticated;
grant execute on function private.assert_branch_inventory_payload(uuid,jsonb) to anon, authenticated;

create or replace function public.quote_order(p_payload jsonb)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare v_quote jsonb; v_branch_id uuid;
begin
  v_quote := private.quote_order_phase4(p_payload);
  v_branch_id := (v_quote ->> 'branchId')::uuid;
  perform private.assert_branch_inventory_payload(v_branch_id, p_payload);
  return v_quote || jsonb_build_object('inventoryChecked', true);
end;
$$;
revoke all on function public.quote_order(jsonb) from public, anon, authenticated;
grant execute on function public.quote_order(jsonb) to anon, authenticated;

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
  for v_component in select inventory_item_id, quantity_milli from public.recipe_components where recipe_id=v_recipe_id order by inventory_item_id loop
    perform private.apply_inventory_movement_impl(p_branch_id,v_component.inventory_item_id,-(v_component.quantity_milli * p_multiplier::bigint),'order_consumption',p_actor_user_id,p_order_id,p_order_line_id,null,'Order recipe consumption');
  end loop;
end;
$$;
revoke all on function private.consume_recipe_inventory(uuid,uuid,uuid,integer,uuid,uuid,uuid) from public, anon, authenticated;

create or replace function private.consume_order_line_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_order public.orders%rowtype;
begin
  select * into strict v_order from public.orders where id=new.order_id;
  perform private.consume_recipe_inventory(v_order.branch_id,new.catalogue_item_id,new.variant_id,new.quantity,v_order.created_by_user_id,new.order_id,new.id);
  return new;
end;
$$;
revoke all on function private.consume_order_line_inventory() from public, anon, authenticated;
create trigger order_lines_consume_inventory after insert on public.order_lines for each row execute function private.consume_order_line_inventory();

create or replace function private.consume_order_addon_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_line public.order_lines%rowtype; v_order public.orders%rowtype;
begin
  select * into strict v_line from public.order_lines where id=new.order_line_id;
  select * into strict v_order from public.orders where id=v_line.order_id;
  perform private.consume_recipe_inventory(v_order.branch_id,new.catalogue_addon_item_id,null,v_line.quantity,v_order.created_by_user_id,v_order.id,v_line.id);
  return new;
end;
$$;
revoke all on function private.consume_order_addon_inventory() from public, anon, authenticated;
create trigger order_line_addons_consume_inventory after insert on public.order_line_addons for each row execute function private.consume_order_addon_inventory();

create or replace function private.restore_cancelled_order_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_movement public.inventory_movements%rowtype;
begin
  if old.status is distinct from 'cancelled' and new.status = 'cancelled' then
    for v_movement in
      select m.* from public.inventory_movements m
      where m.order_id=new.id and m.movement_kind='order_consumption'
        and not exists (select 1 from public.inventory_movements r where r.reversal_of_movement_id=m.id)
      order by m.id
    loop
      perform private.apply_inventory_movement_impl(v_movement.branch_id,v_movement.inventory_item_id,-v_movement.delta_milli,'order_reversal',new.created_by_user_id,new.id,v_movement.order_line_id,v_movement.id,'Cancelled order reversal');
    end loop;
  end if;
  return new;
end;
$$;
revoke all on function private.restore_cancelled_order_inventory() from public, anon, authenticated;
create trigger orders_restore_inventory_on_cancel after update of status on public.orders for each row execute function private.restore_cancelled_order_inventory();

comment on function public.quote_order(jsonb) is 'Authoritative catalogue/branch quote with Phase 5 inventory sufficiency check. Quote does not reserve stock; placement remains transactional authority.';
