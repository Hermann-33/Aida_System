-- TASK-MENU-001 shared catalogue regression.
-- Runs entirely in a transaction and leaves no synthetic rows behind.

begin;

do $$
begin
  if (select count(*) from public.catalogue_categories) <> 4 then
    raise exception 'expected 4 seeded categories';
  end if;
  if (select count(*) from public.catalogue_items) <> 16 then
    raise exception 'expected 16 seeded catalogue items';
  end if;
  if (select count(*) from public.catalogue_item_variants) <> 27 then
    raise exception 'expected 27 seeded item variants';
  end if;
  if (select count(*) from public.catalogue_item_addons) <> 27 then
    raise exception 'expected 27 seeded compatible add-on links';
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'catalogue_revision'
  ) then
    raise exception 'catalogue revision is not published to Supabase Realtime';
  end if;
  if has_function_privilege('anon', 'public.save_catalogue_item(jsonb)', 'execute')
     or has_function_privilege('anon', 'public.save_catalogue_category(jsonb)', 'execute') then
    raise exception 'anonymous role can execute catalogue mutation RPC';
  end if;
  if not has_function_privilege('anon', 'public.get_catalogue()', 'execute') then
    raise exception 'anonymous role cannot read published catalogue';
  end if;
end;
$$;

set local role anon;

do $$
declare
  v_snapshot jsonb;
begin
  select public.get_catalogue() into v_snapshot;
  if jsonb_array_length(v_snapshot -> 'categories') <> 4
     or jsonb_array_length(v_snapshot -> 'items') <> 16 then
    raise exception 'public catalogue snapshot does not expose 4 categories / 16 items';
  end if;
  if exists (
    select 1 from jsonb_array_elements(v_snapshot -> 'items') item
    where (item ->> 'isPublished')::boolean is not true
  ) then
    raise exception 'public catalogue exposed an unpublished item';
  end if;
end;
$$;

reset role;

insert into auth.users (id, email, raw_user_meta_data, created_at, updated_at)
values
  ('20000000-0000-0000-0000-000000000001', 'catalogue-admin@example.test', '{}'::jsonb, now(), now()),
  ('20000000-0000-0000-0000-000000000002', 'catalogue-customer@example.test', '{}'::jsonb, now(), now());

update public.user_profiles
set app_role = 'admin'
where user_id = '20000000-0000-0000-0000-000000000001';

set local role authenticated;

do $$
declare
  v_category_id uuid;
  v_item_id uuid;
  v_before_revision bigint;
  v_after_revision bigint;
  v_snapshot jsonb;
begin
  perform set_config(
    'request.jwt.claims',
    '{"sub":"20000000-0000-0000-0000-000000000001","role":"authenticated"}',
    true
  );

  select revision into v_before_revision
  from public.catalogue_revision where id = 1;

  select public.save_catalogue_category(
    '{"name":"Regression Category","sortOrder":999,"isActive":true}'::jsonb
  ) into v_category_id;

  select public.save_catalogue_item(
    jsonb_build_object(
      'categoryId', v_category_id,
      'name', 'Regression Drink',
      'sku', 'RG-DRK',
      'kind', 'product',
      'description', 'Temporary catalogue regression item',
      'basePriceSen', 1234,
      'isAvailable', true,
      'isPublished', true,
      'isFeatured', false,
      'isBestSeller', false,
      'isStudentEligible', false,
      'prepRoute', 'bar',
      'sortOrder', 10,
      'variants', jsonb_build_array(
        jsonb_build_object(
          'code', 'regular',
          'label', 'Regular',
          'priceDeltaSen', 0,
          'isDefault', true,
          'isAvailable', true,
          'sortOrder', 10
        )
      ),
      'compatibleAddOnIds', '[]'::jsonb
    )
  ) into v_item_id;

  if v_category_id is null or v_item_id is null then
    raise exception 'admin catalogue save did not return server IDs';
  end if;

  select revision into v_after_revision
  from public.catalogue_revision where id = 1;
  if v_after_revision <= v_before_revision then
    raise exception 'catalogue revision did not advance after admin writes';
  end if;

  select public.get_catalogue() into v_snapshot;
  if not exists (
    select 1 from jsonb_array_elements(v_snapshot -> 'items') item
    where item ->> 'id' = v_item_id::text
  ) then
    raise exception 'admin catalogue snapshot did not include saved item';
  end if;

  perform public.save_catalogue_item(
    jsonb_build_object(
      'id', v_item_id,
      'categoryId', v_category_id,
      'name', 'Regression Drink',
      'sku', 'RG-DRK',
      'kind', 'product',
      'description', 'Temporary catalogue regression item',
      'basePriceSen', 1234,
      'isAvailable', true,
      'isPublished', false,
      'isFeatured', false,
      'isBestSeller', false,
      'isStudentEligible', false,
      'prepRoute', 'bar',
      'sortOrder', 10,
      'variants', jsonb_build_array(
        jsonb_build_object(
          'code', 'regular',
          'label', 'Regular',
          'priceDeltaSen', 0,
          'isDefault', true,
          'isAvailable', true,
          'sortOrder', 10
        )
      ),
      'compatibleAddOnIds', '[]'::jsonb
    )
  );

  perform set_config(
    'request.jwt.claims',
    '{"sub":"20000000-0000-0000-0000-000000000002","role":"authenticated"}',
    true
  );

  begin
    perform public.save_catalogue_category('{"name":"Forbidden Customer Category"}'::jsonb);
    raise exception 'customer unexpectedly mutated catalogue';
  exception
    when insufficient_privilege then null;
  end;

  select public.get_catalogue() into v_snapshot;
  if exists (
    select 1 from jsonb_array_elements(v_snapshot -> 'items') item
    where item ->> 'id' = v_item_id::text
  ) then
    raise exception 'customer/public catalogue exposed unpublished item';
  end if;
end;
$$;

-- Audit rows intentionally have no client table grant. Inspect them only after
-- leaving the impersonated authenticated role.
reset role;

do $$
begin
  if not exists (
    select 1 from public.catalogue_audit_events
    where actor_user_id = '20000000-0000-0000-0000-000000000001'
      and snapshot ->> 'sku' = 'RG-DRK'
  ) then
    raise exception 'catalogue writes did not create audit evidence';
  end if;
end;
$$;

rollback;
