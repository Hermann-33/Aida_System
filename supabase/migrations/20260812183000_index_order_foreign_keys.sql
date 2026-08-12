-- TASK-DEMO-ORDER-001 performance hardening.
-- Cover foreign keys used by catalogue/member joins and referential checks.

create index order_lines_catalogue_item_idx
  on public.order_lines (catalogue_item_id);

create index order_lines_variant_idx
  on public.order_lines (variant_id);

create index order_line_addons_catalogue_item_idx
  on public.order_line_addons (catalogue_addon_item_id);

create index orders_member_idx
  on public.orders (member_id);
