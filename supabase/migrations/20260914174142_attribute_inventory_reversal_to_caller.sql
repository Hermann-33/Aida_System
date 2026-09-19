create or replace function private.restore_cancelled_order_inventory()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_movement public.inventory_movements%rowtype;
  v_actor uuid := auth.uid();
begin
  if old.status is distinct from 'cancelled' and new.status = 'cancelled' then
    for v_movement in
      select m.*
      from public.inventory_movements m
      where m.order_id = new.id
        and m.movement_kind = 'order_consumption'
        and not exists (
          select 1
          from public.inventory_movements r
          where r.reversal_of_movement_id = m.id
        )
      order by m.id
    loop
      perform private.apply_inventory_movement_impl(
        v_movement.branch_id,
        v_movement.inventory_item_id,
        -v_movement.delta_milli,
        'order_reversal',
        v_actor,
        new.id,
        v_movement.order_line_id,
        v_movement.id,
        'Cancelled order reversal'
      );
    end loop;
  end if;
  return new;
end;
$$;
revoke all on function private.restore_cancelled_order_inventory() from public, anon, authenticated;
