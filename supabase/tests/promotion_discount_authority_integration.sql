-- TASK-OPS-007 / Phase 7 promotion authority foundation regression.
-- Transactional: no synthetic promotion or identity survives.

begin;

do $$
begin
  if has_table_privilege('authenticated','public.promotions','select')
     or has_table_privilege('authenticated','public.promotions','insert')
     or has_table_privilege('authenticated','public.promotion_order_applications','select') then
    raise exception 'authenticated role unexpectedly has direct Phase 7 table authority';
  end if;
  if has_function_privilege('anon','public.save_promotion(jsonb)','execute') then
    raise exception 'anonymous role unexpectedly has promotion mutation authority';
  end if;
  if not has_function_privilege('authenticated','public.save_promotion(jsonb)','execute')
     or not has_function_privilege('authenticated','public.get_promotion_admin_state()','execute') then
    raise exception 'authenticated Phase 7 RPC grants are missing';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('save_promotion','get_promotion_admin_state') and p.prosecdef
  ) then
    raise exception 'public Phase 7 wrappers unexpectedly use SECURITY DEFINER';
  end if;
  if not exists (
    select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relname='promotions' and c.relrowsecurity and c.relforcerowsecurity
  ) then raise exception 'promotions RLS/FORCE RLS boundary is missing'; end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('77500000-0000-0000-0000-000000000001','phase7-admin@example.test','{}'::jsonb,now(),now()),
 ('77500000-0000-0000-0000-000000000002','phase7-customer@example.test','{}'::jsonb,now(),now());
update public.user_profiles set app_role='admin' where user_id='77500000-0000-0000-0000-000000000001';

-- Resolve fixture IDs as database owner because direct catalogue/branch reads are
-- not what this regression is attempting to grant to ordinary authenticated users.
select set_config('test.phase7.branch_id',(select id::text from public.branches where is_default and is_active limit 1),false);
select set_config('test.phase7.item_id',(select id::text from public.catalogue_items where sku='FD-SAN'),false);
select set_config('test.phase7.variant_id',(
  select v.id::text from public.catalogue_item_variants v
  join public.catalogue_items i on i.id=v.item_id
  where i.sku='CF-LAT' and v.code='medium'
),false);
select set_config('test.phase7.addon_id',(select id::text from public.catalogue_items where sku='AD-SHT' and kind='addon'),false);

set local role authenticated;
do $$
declare
  v_admin uuid:='77500000-0000-0000-0000-000000000001';
  v_payload jsonb;
  v_saved jsonb;
  v_state jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  v_payload := jsonb_build_object(
    'code','P7_FOUNDATION_10',
    'name','Phase 7 Foundation 10 Percent',
    'description','Transactional Phase 7 authority fixture',
    'discountType','percent',
    'percentBasisPoints',1000,
    'minimumSubtotalSen',500,
    'maximumDiscountSen',500,
    'priority',25,
    'stackingMode','exclusive',
    'allowWithVoucher',false,
    'requiresMember',true,
    'globalUsageLimit',100,
    'perMemberUsageLimit',2,
    'isActive',true,
    'branchIds',jsonb_build_array(current_setting('test.phase7.branch_id')),
    'itemIds',jsonb_build_array(current_setting('test.phase7.item_id')),
    'variantIds',jsonb_build_array(current_setting('test.phase7.variant_id')),
    'addonItemIds',jsonb_build_array(current_setting('test.phase7.addon_id'))
  );
  select public.save_promotion(v_payload) into v_saved;
  if jsonb_array_length(v_saved)<>1 or v_saved#>>'{0,code}'<>'P7_FOUNDATION_10' then
    raise exception 'promotion save did not return canonical state: %',v_saved;
  end if;
  if (v_saved#>>'{0,percentBasisPoints}')::integer<>1000
     or (v_saved#>>'{0,minimumSubtotalSen}')::bigint<>500
     or jsonb_array_length(v_saved#>'{0,branchIds}')<>1
     or jsonb_array_length(v_saved#>'{0,itemIds}')<>1
     or jsonb_array_length(v_saved#>'{0,variantIds}')<>1
     or jsonb_array_length(v_saved#>'{0,addonItemIds}')<>1 then
    raise exception 'promotion state lost authoritative commercial/scope fields: %',v_saved;
  end if;
  select public.get_promotion_admin_state() into v_state;
  if not exists (
    select 1 from jsonb_array_elements(v_state) e where e->>'code'='P7_FOUNDATION_10'
  ) then raise exception 'promotion admin state omitted saved promotion'; end if;
end;
$$;
reset role;

-- Trusted actor attribution and canonical scope links are persistence assertions.
do $$
declare v_admin uuid:='77500000-0000-0000-0000-000000000001'; v_promotion uuid;
begin
  select id into strict v_promotion from public.promotions where code='P7_FOUNDATION_10';
  if (select created_by_user_id from public.promotions where id=v_promotion) is distinct from v_admin
     or (select updated_by_user_id from public.promotions where id=v_promotion) is distinct from v_admin then
    raise exception 'promotion actor attribution is not caller-bound';
  end if;
  if (select count(*) from public.promotion_branches where promotion_id=v_promotion)<>1
     or (select count(*) from public.promotion_items where promotion_id=v_promotion)<>1
     or (select count(*) from public.promotion_variants where promotion_id=v_promotion)<>1
     or (select count(*) from public.promotion_addons where promotion_id=v_promotion)<>1 then
    raise exception 'promotion scope links were not persisted canonically';
  end if;
end;
$$;

set local role authenticated;
do $$
declare v_customer uuid:='77500000-0000-0000-0000-000000000002';
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  begin
    perform public.save_promotion(jsonb_build_object(
      'code','P7_FORBIDDEN','name','Forbidden','discountType','fixed','fixedAmountSen',100
    ));
    raise exception 'customer promotion mutation unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.get_promotion_admin_state();
    raise exception 'customer promotion admin read unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

-- Scope validation must not let product/add-on roles bleed into each other.
do $$
declare v_promotion uuid; v_addon uuid; v_product uuid;
begin
  select id into strict v_promotion from public.promotions where code='P7_FOUNDATION_10';
  select id into strict v_addon from public.catalogue_items where sku='AD-SHT';
  select id into strict v_product from public.catalogue_items where sku='FD-SAN';
  begin
    insert into public.promotion_items(promotion_id,catalogue_item_id) values(v_promotion,v_addon);
    raise exception 'add-on was accepted as product promotion scope';
  exception when check_violation then null;
  end;
  begin
    insert into public.promotion_addons(promotion_id,addon_item_id) values(v_promotion,v_product);
    raise exception 'product was accepted as add-on promotion scope';
  exception when check_violation then null;
  end;
end;
$$;

rollback;
