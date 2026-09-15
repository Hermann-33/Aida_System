-- Forward hardening for TASK-MENU-001 catalogue RLS.
-- Avoid overlapping permissive SELECT policies while preserving public reads
-- and complete admin/owner reads.

-- Categories.
drop policy if exists catalogue_categories_public_read on public.catalogue_categories;
drop policy if exists catalogue_categories_admin_read on public.catalogue_categories;

create policy catalogue_categories_anon_read
on public.catalogue_categories
for select
to anon
using (is_active);

create policy catalogue_categories_authenticated_read
on public.catalogue_categories
for select
to authenticated
using (is_active or (select private.is_admin_or_owner()));

-- Items.
drop policy if exists catalogue_items_public_read on public.catalogue_items;
drop policy if exists catalogue_items_admin_read on public.catalogue_items;

create policy catalogue_items_anon_read
on public.catalogue_items
for select
to anon
using (
  is_published
  and exists (
    select 1 from public.catalogue_categories c
    where c.id = catalogue_items.category_id and c.is_active
  )
);

create policy catalogue_items_authenticated_read
on public.catalogue_items
for select
to authenticated
using (
  (select private.is_admin_or_owner())
  or (
    is_published
    and exists (
      select 1 from public.catalogue_categories c
      where c.id = catalogue_items.category_id and c.is_active
    )
  )
);

-- Variants.
drop policy if exists catalogue_item_variants_public_read on public.catalogue_item_variants;
drop policy if exists catalogue_item_variants_admin_read on public.catalogue_item_variants;

create policy catalogue_item_variants_anon_read
on public.catalogue_item_variants
for select
to anon
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

create policy catalogue_item_variants_authenticated_read
on public.catalogue_item_variants
for select
to authenticated
using (
  (select private.is_admin_or_owner())
  or (
    is_available
    and exists (
      select 1
      from public.catalogue_items i
      join public.catalogue_categories c on c.id = i.category_id
      where i.id = catalogue_item_variants.item_id
        and i.is_published
        and c.is_active
    )
  )
);

-- Add-on compatibility links.
drop policy if exists catalogue_item_addons_public_read on public.catalogue_item_addons;
drop policy if exists catalogue_item_addons_admin_read on public.catalogue_item_addons;

create policy catalogue_item_addons_anon_read
on public.catalogue_item_addons
for select
to anon
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

create policy catalogue_item_addons_authenticated_read
on public.catalogue_item_addons
for select
to authenticated
using (
  (select private.is_admin_or_owner())
  or exists (
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

-- The audit table deliberately has no client table grant. This policy records
-- the intended future trusted read scope without exposing it through Data API.
create policy catalogue_audit_events_admin_read
on public.catalogue_audit_events
for select
to authenticated
using ((select private.is_admin_or_owner()));
