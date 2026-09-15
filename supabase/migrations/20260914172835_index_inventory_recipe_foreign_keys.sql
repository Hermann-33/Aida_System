create index branch_inventory_inventory_item_idx on public.branch_inventory (inventory_item_id);
create index inventory_movements_actor_idx on public.inventory_movements (actor_user_id) where actor_user_id is not null;
create index inventory_movements_inventory_item_idx on public.inventory_movements (inventory_item_id);
create index inventory_movements_order_line_idx on public.inventory_movements (order_line_id) where order_line_id is not null;
create index recipes_variant_idx on public.recipes (variant_id) where variant_id is not null;
