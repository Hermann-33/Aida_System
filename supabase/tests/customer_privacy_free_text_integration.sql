-- TASK-PRIVACY-001 / Phase 3 retained-history free-text regression.
-- Transactional: proves account deletion keeps commercial facts while removing
-- customer-authored free text from retained order history.

begin;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values (
  '52000000-0000-0000-0000-000000000001',
  'privacy-free-text@example.test',
  '{}'::jsonb,
  now(),
  now()
);

set local role authenticated;

do $$
declare
  v_customer uuid := '52000000-0000-0000-0000-000000000001';
  v_item_id uuid;
  v_order jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_customer, 'role', 'authenticated')::text,
    true
  );

  select id into strict v_item_id
  from public.catalogue_items
  where sku = 'FD-SAN'
    and kind = 'product'
    and is_published
    and is_available;

  select public.place_customer_order(jsonb_build_object(
    'clientRequestId', '52100000-0000-0000-0000-000000000001',
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'addOnIds', '[]'::jsonb,
      'quantity', 1,
      'note', 'Customer-authored sensitive note'
    ))
  )) into v_order;

  if v_order ->> 'source' <> 'customer'
     or v_order #>> '{lines,0,note}' <> 'Customer-authored sensitive note' then
    raise exception 'free-text regression order setup failed: %', v_order;
  end if;
end;
$$;

reset role;

-- Simulate historical free text attached to an order event by trusted backend
-- code. Account deletion must scrub it along with line notes.
update public.order_events
set reason = 'Customer-authored cancellation context'
where order_id = (
  select id
  from public.orders
  where client_request_id = '52100000-0000-0000-0000-000000000001'
)
  and event_type = 'created';

set local role authenticated;

do $$
declare
  v_customer uuid := '52000000-0000-0000-0000-000000000001';
  v_delete jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object('sub', v_customer, 'role', 'authenticated')::text,
    true
  );

  select public.delete_own_account() into v_delete;
  if (v_delete ->> 'retainedOrderCount')::integer <> 1 then
    raise exception 'account deletion did not retain exactly one anonymized order: %', v_delete;
  end if;
end;
$$;

reset role;

do $$
declare
  v_order_id uuid;
begin
  select id into strict v_order_id
  from public.orders
  where client_request_id = '52100000-0000-0000-0000-000000000001';

  if exists (
    select 1
    from public.order_lines
    where order_id = v_order_id
      and note is not null
  ) then
    raise exception 'retained order line still contains customer-authored note';
  end if;

  if exists (
    select 1
    from public.order_events
    where order_id = v_order_id
      and reason is not null
  ) then
    raise exception 'retained order event still contains customer-authored reason';
  end if;

  if not exists (
    select 1
    from public.orders
    where id = v_order_id
      and source = 'customer'
      and customer_user_id is null
      and member_id is null
      and created_by_user_id is null
      and customer_deleted_at is not null
      and subtotal_sen > 0
      and total_sen > 0
  ) then
    raise exception 'retained commercial order facts were not preserved after free-text scrubbing';
  end if;
end;
$$;

rollback;