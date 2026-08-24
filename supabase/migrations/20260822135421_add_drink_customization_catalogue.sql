-- TASK-MENU-CUSTOMIZATION-001
-- Add reusable drink option groups with per-item availability/default/label/price overrides.
-- Existing add-ons remain catalogue items linked to individual parent products.

alter table public.catalogue_items
  add column if not exists is_drink boolean not null default false;

create table public.catalogue_option_groups (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_option_groups_code_format
    check (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint catalogue_option_groups_name_length
    check (char_length(btrim(name)) between 1 and 80)
);

create table public.catalogue_option_values (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.catalogue_option_groups(id) on delete cascade,
  code text not null,
  label text not null,
  default_price_delta_sen integer not null default 0,
  is_default boolean not null default false,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_option_values_group_code_unique unique (group_id, code),
  constraint catalogue_option_values_id_group_unique unique (id, group_id),
  constraint catalogue_option_values_code_format
    check (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint catalogue_option_values_label_length
    check (char_length(btrim(label)) between 1 and 80),
  constraint catalogue_option_values_price_check
    check (default_price_delta_sen between -10000000 and 10000000)
);

create unique index catalogue_option_values_one_default_idx
  on public.catalogue_option_values (group_id)
  where is_default;

create table public.catalogue_item_option_values (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.catalogue_items(id) on delete cascade,
  group_id uuid not null references public.catalogue_option_groups(id) on delete restrict,
  option_value_id uuid not null,
  label_override text,
  price_delta_sen integer not null default 0,
  is_available boolean not null default true,
  is_default boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_item_option_values_item_option_unique
    unique (item_id, option_value_id),
  constraint catalogue_item_option_values_option_group_fk
    foreign key (option_value_id, group_id)
    references public.catalogue_option_values(id, group_id) on delete restrict,
  constraint catalogue_item_option_values_label_length
    check (
      label_override is null
      or char_length(btrim(label_override)) between 1 and 80
    ),
  constraint catalogue_item_option_values_price_check
    check (price_delta_sen between -10000000 and 10000000)
);

create index catalogue_item_option_values_item_group_idx
  on public.catalogue_item_option_values (item_id, group_id, sort_order);
create index catalogue_item_option_values_option_idx
  on public.catalogue_item_option_values (option_value_id);
create unique index catalogue_item_option_values_one_default_idx
  on public.catalogue_item_option_values (item_id, group_id)
  where is_default;

alter table public.catalogue_option_groups enable row level security;
alter table public.catalogue_option_groups force row level security;
alter table public.catalogue_option_values enable row level security;
alter table public.catalogue_option_values force row level security;
alter table public.catalogue_item_option_values enable row level security;
alter table public.catalogue_item_option_values force row level security;

revoke all on public.catalogue_option_groups from anon, authenticated;
revoke all on public.catalogue_option_values from anon, authenticated;
revoke all on public.catalogue_item_option_values from anon, authenticated;

grant select on public.catalogue_option_groups to anon, authenticated;
grant select on public.catalogue_option_values to anon, authenticated;
grant select, insert, update, delete on public.catalogue_item_option_values to authenticated;

create policy catalogue_option_groups_anon_read
  on public.catalogue_option_groups
  for select to anon
  using (is_active);
create policy catalogue_option_groups_authenticated_read
  on public.catalogue_option_groups
  for select to authenticated
  using (is_active or (select private.is_admin_or_owner()));

create policy catalogue_option_values_anon_read
  on public.catalogue_option_values
  for select to anon
  using (
    is_active
    and exists (
      select 1
      from public.catalogue_option_groups g
      where g.id = catalogue_option_values.group_id and g.is_active
    )
  );
create policy catalogue_option_values_authenticated_read
  on public.catalogue_option_values
  for select to authenticated
  using (
    (select private.is_admin_or_owner())
    or (
      is_active
      and exists (
        select 1
        from public.catalogue_option_groups g
        where g.id = catalogue_option_values.group_id and g.is_active
      )
    )
  );

create policy catalogue_item_option_values_anon_read
  on public.catalogue_item_option_values
  for select to anon
  using (
    is_available
    and exists (
      select 1
      from public.catalogue_items i
      join public.catalogue_categories c on c.id = i.category_id
      join public.catalogue_option_groups g on g.id = catalogue_item_option_values.group_id
      join public.catalogue_option_values ov on ov.id = catalogue_item_option_values.option_value_id
      where i.id = catalogue_item_option_values.item_id
        and i.kind = 'product'
        and i.is_drink
        and i.is_published
        and c.is_active
        and g.is_active
        and ov.is_active
    )
  );
create policy catalogue_item_option_values_authenticated_read
  on public.catalogue_item_option_values
  for select to authenticated
  using (
    (select private.is_admin_or_owner())
    or (
      is_available
      and exists (
        select 1
        from public.catalogue_items i
        join public.catalogue_categories c on c.id = i.category_id
        join public.catalogue_option_groups g on g.id = catalogue_item_option_values.group_id
        join public.catalogue_option_values ov on ov.id = catalogue_item_option_values.option_value_id
        where i.id = catalogue_item_option_values.item_id
          and i.kind = 'product'
          and i.is_drink
          and i.is_published
          and c.is_active
          and g.is_active
          and ov.is_active
      )
    )
  );
create policy catalogue_item_option_values_admin_insert
  on public.catalogue_item_option_values
  for insert to authenticated
  with check ((select private.is_admin_or_owner()));
create policy catalogue_item_option_values_admin_update
  on public.catalogue_item_option_values
  for update to authenticated
  using ((select private.is_admin_or_owner()))
  with check ((select private.is_admin_or_owner()));
create policy catalogue_item_option_values_admin_delete
  on public.catalogue_item_option_values
  for delete to authenticated
  using ((select private.is_admin_or_owner()));

insert into public.catalogue_option_groups (code, name, sort_order, is_active)
values
  ('temperature', 'Temperature', 10, true),
  ('sweetness', 'Sweetness', 20, true)
on conflict (code) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    is_active = excluded.is_active;

insert into public.catalogue_option_values (
  group_id, code, label, default_price_delta_sen, is_default, is_active, sort_order
)
select g.id, v.code, v.label, 0, v.is_default, true, v.sort_order
from public.catalogue_option_groups g
join (values
  ('temperature', 'hot', 'Hot', true, 10),
  ('temperature', 'iced', 'Iced', false, 20),
  ('sweetness', 'regular', 'Regular', true, 10),
  ('sweetness', 'less-sweet', 'Less sweet', false, 20),
  ('sweetness', 'least-sweet', 'Least sweet', false, 30)
) as v(group_code, code, label, is_default, sort_order)
  on v.group_code = g.code
on conflict (group_id, code) do update
set label = excluded.label,
    default_price_delta_sen = excluded.default_price_delta_sen,
    is_default = excluded.is_default,
    is_active = excluded.is_active,
    sort_order = excluded.sort_order;

-- Existing beverage categories are initial production data. Future products are
-- explicitly marked as drinks by Admin rather than inferred from a name.
update public.catalogue_items i
set is_drink = true
from public.catalogue_categories c
where c.id = i.category_id
  and i.kind = 'product'
  and c.slug in ('coffee', 'iced-drinks');

insert into public.catalogue_item_option_values (
  item_id, group_id, option_value_id, label_override, price_delta_sen,
  is_available, is_default, sort_order
)
select i.id, ov.group_id, ov.id, null, ov.default_price_delta_sen,
       true, ov.is_default, ov.sort_order
from public.catalogue_items i
cross join public.catalogue_option_values ov
join public.catalogue_option_groups g on g.id = ov.group_id
where i.kind = 'product'
  and i.is_drink
  and ov.is_active
  and g.is_active
on conflict (item_id, option_value_id) do nothing;

-- Existing iced-drink products are iced-only by default; Admin may later change
-- this per drink. Clear the template Hot default before promoting Iced.
update public.catalogue_item_option_values iv
set is_available = false,
    is_default = false
from public.catalogue_items i,
     public.catalogue_categories c,
     public.catalogue_option_values ov,
     public.catalogue_option_groups g
where iv.item_id = i.id
  and i.category_id = c.id
  and iv.option_value_id = ov.id
  and iv.group_id = g.id
  and ov.group_id = g.id
  and c.slug = 'iced-drinks'
  and g.code = 'temperature'
  and ov.code = 'hot';

update public.catalogue_item_option_values iv
set is_available = true,
    is_default = true
from public.catalogue_items i,
     public.catalogue_categories c,
     public.catalogue_option_values ov,
     public.catalogue_option_groups g
where iv.item_id = i.id
  and i.category_id = c.id
  and iv.option_value_id = ov.id
  and iv.group_id = g.id
  and ov.group_id = g.id
  and c.slug = 'iced-drinks'
  and g.code = 'temperature'
  and ov.code = 'iced';

create or replace function public.get_catalogue()
returns jsonb
language sql
stable
set search_path to 'public', 'pg_temp'
as $function$
  select jsonb_build_object(
    'revision', coalesce((select revision from public.catalogue_revision where id = 1), 0),
    'categories', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', c.id,
          'slug', c.slug,
          'name', c.name,
          'imageUrl', c.image_url,
          'sortOrder', c.sort_order,
          'isActive', c.is_active,
          'itemCount', (
            select count(*)::integer from public.catalogue_items ci
            where ci.category_id = c.id
          )
        ) order by c.sort_order, c.name
      )
      from public.catalogue_categories c
    ), '[]'::jsonb),
    'items', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', i.id,
          'categoryId', i.category_id,
          'categoryName', c.name,
          'slug', i.slug,
          'sku', i.sku,
          'kind', i.kind,
          'name', i.name,
          'description', i.description,
          'basePriceSen', i.base_price_sen,
          'isAvailable', i.is_available,
          'isPublished', i.is_published,
          'isFeatured', i.is_featured,
          'isBestSeller', i.is_best_seller,
          'isStudentEligible', i.is_student_eligible,
          'isDrink', i.is_drink,
          'imageUrl', i.image_url,
          'volumeMl', i.volume_ml,
          'prepRoute', i.prep_route,
          'sortOrder', i.sort_order,
          'variants', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', v.id,
                'code', v.code,
                'label', v.label,
                'priceDeltaSen', v.price_delta_sen,
                'isDefault', v.is_default,
                'isAvailable', v.is_available,
                'sortOrder', v.sort_order
              ) order by v.sort_order, v.label
            )
            from public.catalogue_item_variants v
            where v.item_id = i.id
          ), '[]'::jsonb),
          'compatibleAddOnIds', coalesce((
            select jsonb_agg(a.addon_item_id order by a.sort_order)
            from public.catalogue_item_addons a
            where a.parent_item_id = i.id
          ), '[]'::jsonb),
          'customizationGroups', case when i.is_drink then coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', g.id,
                'code', g.code,
                'name', g.name,
                'sortOrder', g.sort_order,
                'options', coalesce((
                  select jsonb_agg(
                    jsonb_build_object(
                      'id', ov.id,
                      'code', ov.code,
                      'label', coalesce(iv.label_override, ov.label),
                      'priceDeltaSen', iv.price_delta_sen,
                      'isDefault', iv.is_default,
                      'isAvailable', iv.is_available,
                      'sortOrder', iv.sort_order
                    ) order by iv.sort_order, coalesce(iv.label_override, ov.label)
                  )
                  from public.catalogue_item_option_values iv
                  join public.catalogue_option_values ov on ov.id = iv.option_value_id
                  where iv.item_id = i.id and iv.group_id = g.id
                ), '[]'::jsonb)
              ) order by g.sort_order, g.name
            )
            from public.catalogue_option_groups g
            where exists (
              select 1 from public.catalogue_item_option_values iv
              where iv.item_id = i.id and iv.group_id = g.id
            )
          ), '[]'::jsonb) else '[]'::jsonb end
        ) order by c.sort_order, i.sort_order, i.name
      )
      from public.catalogue_items i
      join public.catalogue_categories c on c.id = i.category_id
    ), '[]'::jsonb)
  );
$function$;

create or replace function public.save_catalogue_item(p_payload jsonb)
returns uuid
language plpgsql
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_id uuid := nullif(p_payload ->> 'id', '')::uuid;
  v_category_id uuid := nullif(p_payload ->> 'categoryId', '')::uuid;
  v_name text := btrim(coalesce(p_payload ->> 'name', ''));
  v_description text := coalesce(p_payload ->> 'description', '');
  v_base_price integer := coalesce((p_payload ->> 'basePriceSen')::integer, -1);
  v_kind text := coalesce(nullif(p_payload ->> 'kind', ''), 'product');
  v_sku text := upper(btrim(coalesce(p_payload ->> 'sku', '')));
  v_route text := coalesce(nullif(p_payload ->> 'prepRoute', ''), 'bar');
  v_is_available boolean := coalesce((p_payload ->> 'isAvailable')::boolean, true);
  v_is_published boolean := coalesce((p_payload ->> 'isPublished')::boolean, true);
  v_is_featured boolean := coalesce((p_payload ->> 'isFeatured')::boolean, false);
  v_is_best_seller boolean := coalesce((p_payload ->> 'isBestSeller')::boolean, false);
  v_is_student_eligible boolean := coalesce((p_payload ->> 'isStudentEligible')::boolean, false);
  v_is_drink boolean := coalesce((p_payload ->> 'isDrink')::boolean, false);
  v_image_url text := nullif(btrim(coalesce(p_payload ->> 'imageUrl', '')), '');
  v_volume_ml integer := nullif(p_payload ->> 'volumeMl', '')::integer;
  v_sort_order integer := coalesce((p_payload ->> 'sortOrder')::integer, 0);
  v_slug text;
  v_category_slug text;
  v_variant jsonb;
  v_variant_code text;
  v_variant_label text;
  v_variant_delta integer;
  v_variant_default boolean;
  v_variant_available boolean;
  v_variant_sort integer;
  v_variant_codes text[] := array[]::text[];
  v_default_count integer := 0;
  v_addon_text text;
  v_addon_id uuid;
  v_addon_sort integer := 0;
  v_customization jsonb;
  v_customization_id uuid;
  v_customization_label text;
  v_customization_template_label text;
  v_customization_delta integer;
  v_customization_available boolean;
  v_customization_default boolean;
  v_customization_sort integer;
begin
  if not private.is_admin_or_owner() then
    raise exception 'administrator access required' using errcode = '42501';
  end if;
  if v_category_id is null or not exists (
    select 1 from public.catalogue_categories where id = v_category_id
  ) then
    raise exception 'valid category is required' using errcode = '22023';
  end if;
  if char_length(v_name) not between 1 and 120 then
    raise exception 'item name must be between 1 and 120 characters' using errcode = '22023';
  end if;
  if char_length(v_description) > 1000 then
    raise exception 'description is too long' using errcode = '22023';
  end if;
  if v_base_price < 0 or v_base_price > 10000000 then
    raise exception 'base price is invalid' using errcode = '22023';
  end if;
  if v_kind not in ('product', 'addon') then
    raise exception 'invalid item kind' using errcode = '22023';
  end if;
  if v_kind <> 'product' and v_is_drink then
    raise exception 'only product items can use drink customizations' using errcode = '22023';
  end if;
  if v_route not in ('bar', 'kitchen') then
    raise exception 'invalid preparation route' using errcode = '22023';
  end if;
  if v_volume_ml is not null and (v_volume_ml < 1 or v_volume_ml > 10000) then
    raise exception 'volume is invalid' using errcode = '22023';
  end if;

  select slug into v_category_slug from public.catalogue_categories where id = v_category_id;

  if v_is_featured then
    update public.catalogue_items
    set is_featured = false
    where is_featured and (v_id is null or id <> v_id);
  end if;

  if v_id is null then
    v_slug := trim(both '-' from regexp_replace(lower(v_name), '[^a-z0-9]+', '-', 'g'));
    if v_slug = '' then v_slug := 'item'; end if;
    if exists (select 1 from public.catalogue_items where slug = v_slug) then
      v_slug := v_slug || '-' || substr(gen_random_uuid()::text, 1, 8);
    end if;

    if v_sku = '' then
      v_sku := upper(substr(regexp_replace(v_category_slug, '[^a-z0-9]', '', 'g'), 1, 2))
        || '-' || upper(substr(regexp_replace(v_name, '[^A-Za-z0-9]', '', 'g'), 1, 3));
      if char_length(v_sku) < 3 then v_sku := 'ITM-' || upper(substr(gen_random_uuid()::text, 1, 6)); end if;
      if exists (select 1 from public.catalogue_items where sku = v_sku) then
        v_sku := left(v_sku, 25) || '-' || upper(substr(gen_random_uuid()::text, 1, 4));
      end if;
    end if;

    insert into public.catalogue_items (
      category_id, slug, sku, kind, name, description, base_price_sen,
      is_available, is_published, is_featured, is_best_seller,
      is_student_eligible, is_drink, image_url, volume_ml, prep_route, sort_order
    ) values (
      v_category_id, v_slug, v_sku, v_kind, v_name, v_description, v_base_price,
      v_is_available, v_is_published, v_is_featured, v_is_best_seller,
      v_is_student_eligible, v_is_drink, v_image_url, v_volume_ml, v_route, v_sort_order
    ) returning id into v_id;
  else
    if v_sku = '' then
      select sku into v_sku from public.catalogue_items where id = v_id;
    end if;
    update public.catalogue_items
    set category_id = v_category_id,
        sku = v_sku,
        kind = v_kind,
        name = v_name,
        description = v_description,
        base_price_sen = v_base_price,
        is_available = v_is_available,
        is_published = v_is_published,
        is_featured = v_is_featured,
        is_best_seller = v_is_best_seller,
        is_student_eligible = v_is_student_eligible,
        is_drink = v_is_drink,
        image_url = v_image_url,
        volume_ml = v_volume_ml,
        prep_route = v_route,
        sort_order = v_sort_order
    where id = v_id;
    if not found then
      raise exception 'catalogue item not found' using errcode = 'P0002';
    end if;
  end if;

  if p_payload ? 'variants' then
    update public.catalogue_item_variants set is_default = false where item_id = v_id;
    for v_variant in
      select value from jsonb_array_elements(coalesce(p_payload -> 'variants', '[]'::jsonb))
    loop
      v_variant_label := btrim(coalesce(v_variant ->> 'label', ''));
      v_variant_code := coalesce(nullif(v_variant ->> 'code', ''),
        trim(both '-' from regexp_replace(lower(v_variant_label), '[^a-z0-9]+', '-', 'g')));
      v_variant_delta := coalesce((v_variant ->> 'priceDeltaSen')::integer, 0);
      v_variant_default := coalesce((v_variant ->> 'isDefault')::boolean, false);
      v_variant_available := coalesce((v_variant ->> 'isAvailable')::boolean, true);
      v_variant_sort := coalesce((v_variant ->> 'sortOrder')::integer, 0);

      if v_variant_code = '' or char_length(v_variant_label) not between 1 and 80 then
        raise exception 'variant code and label are required' using errcode = '22023';
      end if;
      if v_base_price + v_variant_delta < 0 then
        raise exception 'variant price cannot make item price negative' using errcode = '22023';
      end if;
      if v_variant_default then v_default_count := v_default_count + 1; end if;
      v_variant_codes := array_append(v_variant_codes, v_variant_code);

      insert into public.catalogue_item_variants (
        item_id, code, label, price_delta_sen, is_default, is_available, sort_order
      ) values (
        v_id, v_variant_code, v_variant_label, v_variant_delta,
        v_variant_default, v_variant_available, v_variant_sort
      )
      on conflict (item_id, code) do update
      set label = excluded.label,
          price_delta_sen = excluded.price_delta_sen,
          is_default = excluded.is_default,
          is_available = excluded.is_available,
          sort_order = excluded.sort_order;
    end loop;

    if cardinality(v_variant_codes) > 0 and v_default_count <> 1 then
      raise exception 'items with variants require exactly one default variant' using errcode = '22023';
    end if;
    if cardinality(v_variant_codes) = 0 then
      delete from public.catalogue_item_variants where item_id = v_id;
    else
      delete from public.catalogue_item_variants
      where item_id = v_id and not (code = any(v_variant_codes));
    end if;
  end if;

  if p_payload ? 'compatibleAddOnIds' then
    delete from public.catalogue_item_addons where parent_item_id = v_id;
    for v_addon_text in
      select value #>> '{}' from jsonb_array_elements(coalesce(p_payload -> 'compatibleAddOnIds', '[]'::jsonb))
    loop
      v_addon_id := v_addon_text::uuid;
      if not exists (
        select 1 from public.catalogue_items where id = v_addon_id and kind = 'addon'
      ) then
        raise exception 'compatible add-on is invalid' using errcode = '22023';
      end if;
      v_addon_sort := v_addon_sort + 10;
      insert into public.catalogue_item_addons (parent_item_id, addon_item_id, sort_order)
      values (v_id, v_addon_id, v_addon_sort);
    end loop;
  end if;

  if not v_is_drink then
    delete from public.catalogue_item_option_values where item_id = v_id;
  else
    insert into public.catalogue_item_option_values (
      item_id, group_id, option_value_id, label_override, price_delta_sen,
      is_available, is_default, sort_order
    )
    select v_id, ov.group_id, ov.id, null, ov.default_price_delta_sen,
           true, ov.is_default, ov.sort_order
    from public.catalogue_option_values ov
    join public.catalogue_option_groups g on g.id = ov.group_id
    where ov.is_active and g.is_active
    on conflict (item_id, option_value_id) do nothing;

    if p_payload ? 'customizationOptions' then
      if jsonb_typeof(p_payload -> 'customizationOptions') <> 'array' then
        raise exception 'customizationOptions must be a JSON array' using errcode = '22023';
      end if;
      if (
        select count(*) <> count(distinct value ->> 'optionValueId')
        from jsonb_array_elements(p_payload -> 'customizationOptions')
      ) then
        raise exception 'duplicate customization options are not allowed' using errcode = '22023';
      end if;

      update public.catalogue_item_option_values
      set is_default = false
      where item_id = v_id;

      for v_customization in
        select value from jsonb_array_elements(p_payload -> 'customizationOptions')
      loop
        begin
          v_customization_id := nullif(v_customization ->> 'optionValueId', '')::uuid;
        exception when invalid_text_representation then
          raise exception 'customization option IDs must be valid UUIDs' using errcode = '22023';
        end;
        if v_customization_id is null then
          raise exception 'customization option ID is required' using errcode = '22023';
        end if;

        select ov.label into v_customization_template_label
        from public.catalogue_option_values ov
        join public.catalogue_option_groups g on g.id = ov.group_id
        where ov.id = v_customization_id and ov.is_active and g.is_active;
        if not found then
          raise exception 'customization option is invalid' using errcode = '22023';
        end if;

        v_customization_label := btrim(coalesce(v_customization ->> 'label', ''));
        if v_customization_label <> '' and char_length(v_customization_label) > 80 then
          raise exception 'customization option label is too long' using errcode = '22023';
        end if;
        v_customization_delta := coalesce((v_customization ->> 'priceDeltaSen')::integer, 0);
        if v_customization_delta < -10000000 or v_customization_delta > 10000000 then
          raise exception 'customization option price delta is invalid' using errcode = '22023';
        end if;
        v_customization_available := coalesce((v_customization ->> 'isAvailable')::boolean, true);
        v_customization_default := coalesce((v_customization ->> 'isDefault')::boolean, false);
        if v_customization_default and not v_customization_available then
          raise exception 'default customization option must be available' using errcode = '22023';
        end if;
        v_customization_sort := coalesce((v_customization ->> 'sortOrder')::integer, 0);

        update public.catalogue_item_option_values
        set label_override = case
              when v_customization_label = '' or v_customization_label = v_customization_template_label then null
              else v_customization_label
            end,
            price_delta_sen = v_customization_delta,
            is_available = v_customization_available,
            is_default = v_customization_default,
            sort_order = v_customization_sort
        where item_id = v_id and option_value_id = v_customization_id;
        if not found then
          raise exception 'customization option does not belong to this drink' using errcode = '22023';
        end if;
      end loop;
    end if;

    if exists (
      select 1
      from public.catalogue_option_groups g
      where g.is_active
        and (
          (select count(*) from public.catalogue_item_option_values iv
           join public.catalogue_option_values ov on ov.id = iv.option_value_id
           where iv.item_id = v_id and iv.group_id = g.id and iv.is_available and ov.is_active) < 1
          or
          (select count(*) from public.catalogue_item_option_values iv
           join public.catalogue_option_values ov on ov.id = iv.option_value_id
           where iv.item_id = v_id and iv.group_id = g.id and iv.is_available and iv.is_default and ov.is_active) <> 1
        )
    ) then
      raise exception 'each drink customization group requires at least one available option and exactly one available default' using errcode = '22023';
    end if;
  end if;

  return v_id;
end;
$function$;
