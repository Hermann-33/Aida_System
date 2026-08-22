-- Advisor cleanup for TASK-MENU-CUSTOMIZATION-001.

create policy order_line_options_authenticated_read
on public.order_line_options
for select
to authenticated
using (
  exists (
    select 1
    from public.order_lines l
    join public.orders o on o.id = l.order_id
    where l.id = order_line_options.order_line_id
      and (
        o.customer_user_id = (select auth.uid())
        or (select private.is_staff_or_above())
      )
  )
);

create index if not exists catalogue_item_option_values_group_idx
  on public.catalogue_item_option_values (group_id);

create index if not exists catalogue_item_option_values_option_group_idx
  on public.catalogue_item_option_values (option_value_id, group_id);

create index if not exists order_line_options_option_group_idx
  on public.order_line_options (catalogue_option_value_id, catalogue_option_group_id);
