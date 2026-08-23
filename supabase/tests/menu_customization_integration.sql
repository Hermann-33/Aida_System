-- TASK-MENU-CUSTOMIZATION-001
-- Transactional regression for shared drink customization / option pricing.
-- Intended to run with the same privileged SQL test runner used by the other
-- canonical Supabase integration tests. All catalogue mutations roll back.

begin;

do $$
declare
  v_invalid integer;
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'catalogue_items'
      and column_name = 'is_drink'
  ) then
    raise exception 'catalogue_items.is_drink is missing';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'order_lines'
      and column_name = 'option_total_sen'
  ) then
    raise exception 'order_lines.option_total_sen is missing';
  end if;

  if to_regclass('public.catalogue_option_groups') is null
     or to_regclass('public.catalogue_option_values') is null
     or to_regclass('public.catalogue_item_option_values') is null
     or to_regclass('public.order_line_options') is null then
    raise exception 'drink customization tables are incomplete';
  end if;

  select count(*) into v_invalid
  from (
    select i.id, g.id
    from public.catalogue_items i
    join public.catalogue_item_option_values iv on iv.item_id = i.id
    join public.catalogue_option_groups g on g.id = iv.group_id and g.is_active
    join public.catalogue_option_values ov on ov.id = iv.option_value_id and ov.is_active
    where i.kind = 'product' and i.is_drink
    group by i.id, g.id
    having count(*) filter (where iv.is_available) < 1
       or count(*) filter (where iv.is_available and iv.is_default) <> 1
  ) invalid;

  if v_invalid <> 0 then
    raise exception 'one or more drink groups have invalid available/default state';
  end if;

  if not has_function_privilege('anon', 'public.get_catalogue()', 'execute')
     or not has_function_privilege('anon', 'public.quote_order(jsonb)', 'execute')
     or not has_function_privilege('authenticated', 'public.quote_order(jsonb)', 'execute') then
    raise exception 'public quote/catalogue execute grants are incomplete';
  end if;

  if not has_table_privilege('anon', 'public.catalogue_option_groups', 'select')
     or not has_table_privilege('anon', 'public.catalogue_option_values', 'select')
     or not has_table_privilege('anon', 'public.catalogue_item_option_values', 'select') then
    raise exception 'anonymous option catalogue read grants are incomplete';
  end if;

  if has_table_privilege('authenticated', 'public.order_line_options', 'select') then
    raise exception 'authenticated role unexpectedly has direct order_line_options SELECT';
  end if;
end;
$$;

-- Make one explicit option delta non-zero inside this transaction so the
-- authoritative pricing contribution can be asserted. This is rolled back.
update public.catalogue_item_option_values iv
set price_delta_sen = 75
from public.catalogue_items i,
     public.catalogue_option_values ov,
     public.catalogue_option_groups g
where iv.item_id = i.id
  and iv.option_value_id = ov.id
  and iv.group_id = g.id
  and i.sku = 'CF-AME'
  and i.kind = 'product'
  and g.code = 'temperature'
  and ov.code = 'iced';

set local role anon;

do $$
declare
  v_catalogue jsonb;
  v_item_id uuid;
  v_variant_id uuid;
  v_iced_id uuid;
  v_less_sweet_id uuid;
  v_addon_id uuid;
  v_addon_price integer;
  v_default_quote jsonb;
  v_explicit_quote jsonb;
  v_two_line_quote jsonb;
  v_line jsonb;
  v_base integer;
  v_variant_delta integer;
begin
  select public.get_catalogue() into v_catalogue;

  if not exists (
    select 1
    from jsonb_array_elements(v_catalogue -> 'items') item
    where item ->> 'sku' = 'CF-AME'
      and (item ->> 'isDrink')::boolean
      and jsonb_array_length(item -> 'customizationGroups') >= 2
  ) then
    raise exception 'public catalogue does not expose Americano drink groups';
  end if;

  select i.id, i.base_price_sen
  into v_item_id, v_base
  from public.catalogue_items i
  where i.sku = 'CF-AME'
    and i.kind = 'product'
    and i.is_published
    and i.is_available;

  if v_item_id is null then
    raise exception 'CF-AME is unavailable for regression';
  end if;

  select v.id, v.price_delta_sen
  into v_variant_id, v_variant_delta
  from public.catalogue_item_variants v
  where v.item_id = v_item_id and v.is_available
  order by v.is_default desc, v.sort_order, v.id
  limit 1;

  if v_variant_id is null then
    raise exception 'CF-AME has no available variant for regression';
  end if;

  select ov.id into v_iced_id
  from public.catalogue_item_option_values iv
  join public.catalogue_option_values ov on ov.id = iv.option_value_id
  join public.catalogue_option_groups g on g.id = iv.group_id
  where iv.item_id = v_item_id
    and iv.is_available
    and g.code = 'temperature'
    and ov.code = 'iced';

  select ov.id into v_less_sweet_id
  from public.catalogue_item_option_values iv
  join public.catalogue_option_values ov on ov.id = iv.option_value_id
  join public.catalogue_option_groups g on g.id = iv.group_id
  where iv.item_id = v_item_id
    and iv.is_available
    and g.code = 'sweetness'
    and ov.code = 'less-sweet';

  if v_iced_id is null or v_less_sweet_id is null then
    raise exception 'expected explicit Americano option values are unavailable';
  end if;

  select a.addon_item_id, addon.base_price_sen
  into v_addon_id, v_addon_price
  from public.catalogue_item_addons a
  join public.catalogue_items addon on addon.id = a.addon_item_id
  join public.catalogue_categories category on category.id = addon.category_id
  where a.parent_item_id = v_item_id
    and addon.kind = 'addon'
    and addon.is_published
    and addon.is_available
    and category.is_active
  order by a.sort_order, addon.sku
  limit 1;

  if v_addon_id is null then
    raise exception 'CF-AME has no compatible available add-on for regression';
  end if;

  -- Legacy-style request: no optionValueIds. Server must resolve defaults.
  select public.quote_order(jsonb_build_object(
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  )) into v_default_quote;

  if (v_default_quote ->> 'pricingVersion')::integer <> 2 then
    raise exception 'quote pricingVersion is not 2';
  end if;

  v_line := v_default_quote -> 'lines' -> 0;
  if jsonb_array_length(v_line -> 'options') <> 2 then
    raise exception 'legacy/default quote did not resolve both required groups';
  end if;

  if not exists (
    select 1 from jsonb_array_elements(v_line -> 'options') option
    where option ->> 'groupCode' = 'temperature'
      and option ->> 'optionCode' = 'hot'
  ) then
    raise exception 'legacy/default quote did not resolve Hot default';
  end if;

  if not exists (
    select 1 from jsonb_array_elements(v_line -> 'options') option
    where option ->> 'groupCode' = 'sweetness'
      and option ->> 'optionCode' = 'regular'
  ) then
    raise exception 'legacy/default quote did not resolve Regular sweetness default';
  end if;

  -- Explicit request must retain the selected IDs and include the test delta.
  select public.quote_order(jsonb_build_object(
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(jsonb_build_object(
      'itemId', v_item_id,
      'variantId', v_variant_id,
      'optionValueIds', jsonb_build_array(v_iced_id, v_less_sweet_id),
      'addOnIds', '[]'::jsonb,
      'quantity', 1
    ))
  )) into v_explicit_quote;

  v_line := v_explicit_quote -> 'lines' -> 0;

  if (v_line ->> 'optionTotalSen')::integer <> 75 then
    raise exception 'explicit option price delta was not included';
  end if;

  if (v_line ->> 'unitPriceSen')::integer <> v_base + v_variant_delta + 75 then
    raise exception 'explicit option delta did not contribute to unit price';
  end if;

  if not exists (
    select 1 from jsonb_array_elements(v_line -> 'options') option
    where option ->> 'optionValueId' = v_iced_id::text
      and option ->> 'optionCode' = 'iced'
  ) then
    raise exception 'explicit Iced selection was not snapshotted in quote';
  end if;

  -- Two otherwise-equal lines with different add-ons remain independent.
  select public.quote_order(jsonb_build_object(
    'fulfillmentType', 'asap',
    'items', jsonb_build_array(
      jsonb_build_object(
        'itemId', v_item_id,
        'variantId', v_variant_id,
        'optionValueIds', jsonb_build_array(v_iced_id, v_less_sweet_id),
        'addOnIds', '[]'::jsonb,
        'quantity', 1
      ),
      jsonb_build_object(
        'itemId', v_item_id,
        'variantId', v_variant_id,
        'optionValueIds', jsonb_build_array(v_iced_id, v_less_sweet_id),
        'addOnIds', jsonb_build_array(v_addon_id),
        'quantity', 1
      )
    )
  )) into v_two_line_quote;

  if jsonb_array_length(v_two_line_quote -> 'lines') <> 2 then
    raise exception 'quote merged independent customized lines';
  end if;

  if ((v_two_line_quote -> 'lines' -> 1 ->> 'unitPriceSen')::integer
      - (v_two_line_quote -> 'lines' -> 0 ->> 'unitPriceSen')::integer) <> v_addon_price then
    raise exception 'per-line add-on price was not isolated to the selected line';
  end if;
end;
$$;

reset role;
rollback;
