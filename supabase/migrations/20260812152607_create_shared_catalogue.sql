-- TASK-MENU-001 — shared catalogue/menu persistence.
-- Canonical migration ownership: Hermann-33/Aida_System/supabase/.

create table public.catalogue_categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  image_url text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_categories_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint catalogue_categories_name_length check (char_length(btrim(name)) between 1 and 80)
);

create table public.catalogue_items (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.catalogue_categories(id) on delete restrict,
  slug text not null unique,
  sku text not null unique,
  kind text not null default 'product',
  name text not null,
  description text not null default '',
  base_price_sen integer not null,
  is_available boolean not null default true,
  is_published boolean not null default true,
  is_featured boolean not null default false,
  is_best_seller boolean not null default false,
  is_student_eligible boolean not null default false,
  image_url text,
  volume_ml integer,
  prep_route text not null default 'bar',
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_items_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint catalogue_items_sku_format check (sku ~ '^[A-Z0-9][A-Z0-9-]{1,31}$'),
  constraint catalogue_items_kind_check check (kind in ('product', 'addon')),
  constraint catalogue_items_name_length check (char_length(btrim(name)) between 1 and 120),
  constraint catalogue_items_description_length check (char_length(description) <= 1000),
  constraint catalogue_items_price_check check (base_price_sen between 0 and 10000000),
  constraint catalogue_items_volume_check check (volume_ml is null or volume_ml between 1 and 10000),
  constraint catalogue_items_prep_route_check check (prep_route in ('bar', 'kitchen'))
);

create unique index catalogue_items_single_featured_idx
  on public.catalogue_items ((is_featured))
  where is_featured;
create index catalogue_items_category_sort_idx
  on public.catalogue_items (category_id, sort_order, name);
create index catalogue_items_publication_idx
  on public.catalogue_items (is_published, is_available);

create table public.catalogue_item_variants (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null references public.catalogue_items(id) on delete cascade,
  code text not null,
  label text not null,
  price_delta_sen integer not null default 0,
  is_default boolean not null default false,
  is_available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalogue_item_variants_code_format check (code ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint catalogue_item_variants_label_length check (char_length(btrim(label)) between 1 and 80),
  constraint catalogue_item_variants_delta_check check (price_delta_sen between -10000000 and 10000000),
  constraint catalogue_item_variants_item_code_unique unique (item_id, code)
);

create unique index catalogue_item_variants_one_default_idx
  on public.catalogue_item_variants (item_id)
  where is_default;
create index catalogue_item_variants_item_sort_idx
  on public.catalogue_item_variants (item_id, sort_order, label);

create table public.catalogue_item_addons (
  parent_item_id uuid not null references public.catalogue_items(id) on delete cascade,
  addon_item_id uuid not null references public.catalogue_items(id) on delete restrict,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  primary key (parent_item_id, addon_item_id),
  constraint catalogue_item_addons_no_self check (parent_item_id <> addon_item_id)
);

create index catalogue_item_addons_addon_idx
  on public.catalogue_item_addons (addon_item_id);

create table public.catalogue_revision (
  id smallint primary key,
  revision bigint not null default 1,
  updated_at timestamptz not null default now(),
  constraint catalogue_revision_singleton check (id = 1),
  constraint catalogue_revision_nonnegative check (revision >= 0)
);

insert into public.catalogue_revision (id, revision) values (1, 1);

create table public.catalogue_audit_events (
  id bigint generated always as identity primary key,
  actor_user_id uuid,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  snapshot jsonb not null,
  created_at timestamptz not null default now(),
  constraint catalogue_audit_events_action_check check (action in ('insert', 'update', 'delete'))
);

create index catalogue_audit_events_entity_idx
  on public.catalogue_audit_events (entity_type, entity_id, created_at desc);
create index catalogue_audit_events_actor_idx
  on public.catalogue_audit_events (actor_user_id, created_at desc);

-- Reuse the established updated_at trigger helper.
create trigger catalogue_categories_set_updated_at
before update on public.catalogue_categories
for each row execute function public.set_updated_at();

create trigger catalogue_items_set_updated_at
before update on public.catalogue_items
for each row execute function public.set_updated_at();

create trigger catalogue_item_variants_set_updated_at
before update on public.catalogue_item_variants
for each row execute function public.set_updated_at();

-- Seed exactly the menu currently visible in the customer app. Dashboard-only
-- preview rows/modifier concepts are deliberately not promoted to business data.
insert into public.catalogue_categories (slug, name, sort_order)
values
  ('coffee', 'Coffee', 10),
  ('iced-drinks', 'Iced Drinks', 20),
  ('food', 'Food', 30),
  ('add-ons', 'Add-ons', 40);

insert into public.catalogue_items (
  category_id, slug, sku, kind, name, description, base_price_sen,
  is_available, is_published, is_featured, is_best_seller,
  is_student_eligible, image_url, volume_ml, prep_route, sort_order
)
select c.id, v.slug, v.sku, v.kind, v.name, v.description, v.base_price_sen,
       v.is_available, true, v.is_featured, v.is_best_seller,
       v.is_student_eligible, v.image_url, v.volume_ml, v.prep_route, v.sort_order
from public.catalogue_categories c
join (values
  ('coffee','salted-caramel-latte','CF-SCL','product','Salted Caramel Latte','Silky espresso, caramel, a pinch of sea salt',1290,true,true,true,true,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=900&q=80',240,'bar',10),
  ('coffee','latte','CF-LAT','product','Latte','Espresso and steamed milk, softly balanced',1050,true,false,false,true,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=900&q=80',240,'bar',20),
  ('coffee','americano','CF-AME','product','Americano','Espresso lengthened with hot water',850,true,false,false,true,'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=900&q=80',240,'bar',30),
  ('coffee','cappuccino','CF-CAP','product','Cappuccino','Smooth espresso with rich, velvety foam',950,true,false,true,true,'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=900&q=80',240,'bar',40),
  ('coffee','mocha','CF-MOC','product','Mocha','Espresso, chocolate, and steamed milk',1150,true,false,false,false,'https://images.unsplash.com/photo-1572490122747-3969b75c2f42?w=900&q=80',240,'bar',50),
  ('iced-drinks','iced-coffee','IC-COF','product','Iced Coffee','Cold, clean, and straight to the point',900,true,false,false,true,'https://images.unsplash.com/photo-1517701551477-081fb5d9e6e2?w=900&q=80',350,'bar',10),
  ('iced-drinks','iced-latte','IC-LAT','product','Iced Latte','Chilled, creamy, and endlessly refreshing',1050,true,false,true,true,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=900&q=80',350,'bar',20),
  ('iced-drinks','matcha-latte','IC-MAT','product','Matcha Latte','Stone-ground matcha, gently sweetened',1190,true,false,true,false,'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=900&q=80',350,'bar',30),
  ('iced-drinks','chocolate-ice','IC-CHO','product','Chocolate Ice','Dark chocolate over ice, not too sweet',1090,true,false,false,false,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=900&q=80',350,'bar',40),
  ('food','sandwich','FD-SAN','product','Sandwich','Toasted, generously filled, made to order',1290,true,false,false,true,'https://images.unsplash.com/photo-1528735602782-2552fd46c207?w=900&q=80',null,'kitchen',10),
  ('food','butter-croissant','FD-CRO','product','Butter Croissant','Flaky, buttery, baked this morning',750,false,false,true,false,'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=900&q=80',null,'kitchen',20),
  ('food','muffin','FD-MUF','product','Muffin','Blueberry, still warm from the oven',690,true,false,false,false,'https://images.unsplash.com/photo-1607958996338-010a2fbfad75?w=900&q=80',null,'kitchen',30),
  ('food','chicken-wrap','FD-WRP','product','Chicken Wrap','Grilled chicken, crisp greens, house sauce',1390,true,false,false,true,'https://images.unsplash.com/photo-1626700051175-6818033a6e2a?w=900&q=80',null,'kitchen',40),
  ('add-ons','extra-shot','AD-SHT','addon','Extra Shot','One more shot of espresso',300,true,false,false,false,null,null,'bar',10),
  ('add-ons','oat-milk','AD-OAT','addon','Oat Milk','Swap in oat milk for any drink',250,true,false,false,false,null,null,'bar',20),
  ('add-ons','whipped-cream','AD-CRM','addon','Whipped Cream','A generous swirl on top',200,true,false,false,false,null,null,'bar',30)
) as v(category_slug,slug,sku,kind,name,description,base_price_sen,is_available,is_featured,is_best_seller,is_student_eligible,image_url,volume_ml,prep_route,sort_order)
  on c.slug = v.category_slug;

-- Preserve the current customer-app size behavior as editable per-item data.
insert into public.catalogue_item_variants (
  item_id, code, label, price_delta_sen, is_default, is_available, sort_order
)
select i.id, v.code, v.label, v.price_delta_sen, v.is_default, true, v.sort_order
from public.catalogue_items i
cross join (values
  ('small','Small',-100,false,10),
  ('medium','Medium',0,true,20),
  ('large','Large',150,false,30)
) as v(code,label,price_delta_sen,is_default,sort_order)
where i.sku in ('CF-SCL','CF-LAT','CF-AME','CF-CAP','CF-MOC','IC-COF','IC-LAT','IC-MAT','IC-CHO');

-- Preserve the current drink -> add-on compatibility without using category
-- names as business logic.
insert into public.catalogue_item_addons (parent_item_id, addon_item_id, sort_order)
select parent.id, addon.id,
  case addon.sku when 'AD-SHT' then 10 when 'AD-OAT' then 20 else 30 end
from public.catalogue_items parent
cross join public.catalogue_items addon
where parent.sku in ('CF-SCL','CF-LAT','CF-AME','CF-CAP','CF-MOC','IC-COF','IC-LAT','IC-MAT','IC-CHO')
  and addon.sku in ('AD-SHT','AD-OAT','AD-CRM');

-- Catalogue-wide change signal. Clients subscribe only to this singleton and
-- re-read the RLS-filtered snapshot, which also handles publish/unpublish.
create or replace function private.bump_catalogue_revision()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  update public.catalogue_revision
  set revision = revision + 1,
      updated_at = now()
  where id = 1;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.bump_catalogue_revision() from public, anon, authenticated;

create or replace function private.capture_catalogue_audit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_snapshot jsonb;
  v_entity_id uuid;
begin
  if tg_op = 'DELETE' then
    v_snapshot := to_jsonb(old);
  else
    v_snapshot := to_jsonb(new);
  end if;

  v_entity_id := coalesce(
    nullif(v_snapshot ->> 'id', '')::uuid,
    nullif(v_snapshot ->> 'parent_item_id', '')::uuid
  );

  insert into public.catalogue_audit_events (
    actor_user_id, action, entity_type, entity_id, snapshot
  ) values (
    auth.uid(), lower(tg_op), tg_table_name, v_entity_id, v_snapshot
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function private.capture_catalogue_audit() from public, anon, authenticated;

create or replace function private.validate_catalogue_addon_link()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.catalogue_items
    where id = new.addon_item_id and kind = 'addon'
  ) then
    raise exception 'compatible add-on must reference an addon catalogue item'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

revoke all on function private.validate_catalogue_addon_link() from public, anon, authenticated;

create trigger catalogue_item_addons_validate
before insert or update on public.catalogue_item_addons
for each row execute function private.validate_catalogue_addon_link();

create trigger catalogue_categories_revision
after insert or update or delete on public.catalogue_categories
for each statement execute function private.bump_catalogue_revision();
create trigger catalogue_items_revision
after insert or update or delete on public.catalogue_items
for each statement execute function private.bump_catalogue_revision();
create trigger catalogue_item_variants_revision
after insert or update or delete on public.catalogue_item_variants
for each statement execute function private.bump_catalogue_revision();
create trigger catalogue_item_addons_revision
after insert or update or delete on public.catalogue_item_addons
for each statement execute function private.bump_catalogue_revision();

create trigger catalogue_categories_audit
after insert or update or delete on public.catalogue_categories
for each row execute function private.capture_catalogue_audit();
create trigger catalogue_items_audit
after insert or update or delete on public.catalogue_items
for each row execute function private.capture_catalogue_audit();
create trigger catalogue_item_variants_audit
after insert or update or delete on public.catalogue_item_variants
for each row execute function private.capture_catalogue_audit();
create trigger catalogue_item_addons_audit
after insert or update or delete on public.catalogue_item_addons
for each row execute function private.capture_catalogue_audit();

-- RLS: public clients may read only the published catalogue. Admin/owner gets
-- complete read/write access through the same caller JWT used by the BFF.
alter table public.catalogue_categories enable row level security;
alter table public.catalogue_categories force row level security;
alter table public.catalogue_items enable row level security;
alter table public.catalogue_items force row level security;
alter table public.catalogue_item_variants enable row level security;
alter table public.catalogue_item_variants force row level security;
alter table public.catalogue_item_addons enable row level security;
alter table public.catalogue_item_addons force row level security;
alter table public.catalogue_revision enable row level security;
alter table public.catalogue_revision force row level security;
alter table public.catalogue_audit_events enable row level security;
alter table public.catalogue_audit_events force row level security;

create policy catalogue_categories_public_read
on public.catalogue_categories
for select
to anon, authenticated
using (is_active);

create policy catalogue_categories_admin_read
on public.catalogue_categories
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_categories_admin_insert
on public.catalogue_categories
for insert
to authenticated
with check ((select private.is_admin_or_owner()));

create policy catalogue_categories_admin_update
on public.catalogue_categories
for update
to authenticated
using ((select private.is_admin_or_owner()))
with check ((select private.is_admin_or_owner()));

create policy catalogue_items_public_read
on public.catalogue_items
for select
to anon, authenticated
using (
  is_published
  and exists (
    select 1 from public.catalogue_categories c
    where c.id = catalogue_items.category_id and c.is_active
  )
);

create policy catalogue_items_admin_read
on public.catalogue_items
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_items_admin_insert
on public.catalogue_items
for insert
to authenticated
with check ((select private.is_admin_or_owner()));

create policy catalogue_items_admin_update
on public.catalogue_items
for update
to authenticated
using ((select private.is_admin_or_owner()))
with check ((select private.is_admin_or_owner()));

create policy catalogue_item_variants_public_read
on public.catalogue_item_variants
for select
to anon, authenticated
using (
  is_available
  and exists (
    select 1
    from public.catalogue_items i
    join public.catalogue_categories c on c.id = i.category_id
    where i.id = catalogue_item_variants.item_id
      and i.is_published
      and c.is_active
  )
);

create policy catalogue_item_variants_admin_read
on public.catalogue_item_variants
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_item_variants_admin_insert
on public.catalogue_item_variants
for insert
to authenticated
with check ((select private.is_admin_or_owner()));

create policy catalogue_item_variants_admin_update
on public.catalogue_item_variants
for update
to authenticated
using ((select private.is_admin_or_owner()))
with check ((select private.is_admin_or_owner()));

create policy catalogue_item_variants_admin_delete
on public.catalogue_item_variants
for delete
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_item_addons_public_read
on public.catalogue_item_addons
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.catalogue_items parent
    join public.catalogue_categories pc on pc.id = parent.category_id
    join public.catalogue_items addon on addon.id = catalogue_item_addons.addon_item_id
    join public.catalogue_categories ac on ac.id = addon.category_id
    where parent.id = catalogue_item_addons.parent_item_id
      and parent.is_published
      and addon.is_published
      and parent.is_available
      and addon.is_available
      and pc.is_active
      and ac.is_active
  )
);

create policy catalogue_item_addons_admin_read
on public.catalogue_item_addons
for select
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_item_addons_admin_insert
on public.catalogue_item_addons
for insert
to authenticated
with check ((select private.is_admin_or_owner()));

create policy catalogue_item_addons_admin_update
on public.catalogue_item_addons
for update
to authenticated
using ((select private.is_admin_or_owner()))
with check ((select private.is_admin_or_owner()));

create policy catalogue_item_addons_admin_delete
on public.catalogue_item_addons
for delete
to authenticated
using ((select private.is_admin_or_owner()));

create policy catalogue_revision_public_read
on public.catalogue_revision
for select
to anon, authenticated
using (true);

-- Explicit grants are required; do not rely on implicit Data API grants.
revoke all on public.catalogue_categories from anon, authenticated;
revoke all on public.catalogue_items from anon, authenticated;
revoke all on public.catalogue_item_variants from anon, authenticated;
revoke all on public.catalogue_item_addons from anon, authenticated;
revoke all on public.catalogue_revision from anon, authenticated;
revoke all on public.catalogue_audit_events from anon, authenticated;

grant select on public.catalogue_categories to anon, authenticated;
grant select on public.catalogue_items to anon, authenticated;
grant select on public.catalogue_item_variants to anon, authenticated;
grant select on public.catalogue_item_addons to anon, authenticated;
grant select on public.catalogue_revision to anon, authenticated;

grant insert, update on public.catalogue_categories to authenticated;
grant insert, update on public.catalogue_items to authenticated;
grant insert, update, delete on public.catalogue_item_variants to authenticated;
grant insert, update, delete on public.catalogue_item_addons to authenticated;

-- One stable snapshot contract for both customer and dashboard. RLS determines
-- whether the caller sees only active/published rows or the admin view.
create or replace function public.get_catalogue()
returns jsonb
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
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
          ), '[]'::jsonb)
        ) order by c.sort_order, i.sort_order, i.name
      )
      from public.catalogue_items i
      join public.catalogue_categories c on c.id = i.category_id
    ), '[]'::jsonb)
  );
$$;

revoke all on function public.get_catalogue() from public, anon, authenticated;
grant execute on function public.get_catalogue() to anon, authenticated;

create or replace function public.save_catalogue_category(p_payload jsonb)
returns uuid
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  v_id uuid := nullif(p_payload ->> 'id', '')::uuid;
  v_name text := btrim(coalesce(p_payload ->> 'name', ''));
  v_image_url text := nullif(btrim(coalesce(p_payload ->> 'imageUrl', '')), '');
  v_sort_order integer := coalesce((p_payload ->> 'sortOrder')::integer, 0);
  v_is_active boolean := coalesce((p_payload ->> 'isActive')::boolean, true);
  v_slug text;
begin
  if not private.is_admin_or_owner() then
    raise exception 'administrator access required' using errcode = '42501';
  end if;
  if char_length(v_name) not between 1 and 80 then
    raise exception 'category name must be between 1 and 80 characters' using errcode = '22023';
  end if;

  if v_id is null then
    v_slug := trim(both '-' from regexp_replace(lower(v_name), '[^a-z0-9]+', '-', 'g'));
    if v_slug = '' then v_slug := 'category'; end if;
    if exists (select 1 from public.catalogue_categories where slug = v_slug) then
      v_slug := v_slug || '-' || substr(gen_random_uuid()::text, 1, 8);
    end if;

    insert into public.catalogue_categories (slug, name, image_url, sort_order, is_active)
    values (v_slug, v_name, v_image_url, v_sort_order, v_is_active)
    returning id into v_id;
  else
    update public.catalogue_categories
    set name = v_name,
        image_url = v_image_url,
        sort_order = v_sort_order,
        is_active = v_is_active
    where id = v_id;
    if not found then
      raise exception 'catalogue category not found' using errcode = 'P0002';
    end if;
  end if;

  return v_id;
end;
$$;

revoke all on function public.save_catalogue_category(jsonb) from public, anon, authenticated;
grant execute on function public.save_catalogue_category(jsonb) to authenticated;

create or replace function public.save_catalogue_item(p_payload jsonb)
returns uuid
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
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
      is_student_eligible, image_url, volume_ml, prep_route, sort_order
    ) values (
      v_category_id, v_slug, v_sku, v_kind, v_name, v_description, v_base_price,
      v_is_available, v_is_published, v_is_featured, v_is_best_seller,
      v_is_student_eligible, v_image_url, v_volume_ml, v_route, v_sort_order
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

  return v_id;
end;
$$;

revoke all on function public.save_catalogue_item(jsonb) from public, anon, authenticated;
grant execute on function public.save_catalogue_item(jsonb) to authenticated;

-- Publish only the singleton revision signal. Subscribers re-fetch the
-- catalogue snapshot under their own RLS role after each revision change.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    execute 'alter publication supabase_realtime add table public.catalogue_revision';
  end if;
end;
$$;
