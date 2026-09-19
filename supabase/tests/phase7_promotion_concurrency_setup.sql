\set ON_ERROR_STOP on

-- Disposable local-Supabase fixture for true concurrent promotion usage.
insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('77700000-0000-0000-0000-000000000001','phase7-conc-one@example.test','{}'::jsonb,now(),now()),
 ('77700000-0000-0000-0000-000000000002','phase7-conc-two@example.test','{}'::jsonb,now(),now());

insert into public.promotions(
  code,name,discount_type,fixed_amount_sen,priority,stacking_mode,
  allow_with_voucher,global_usage_limit,is_active
)
values('P7_CONC_LAST_USE','Phase 7 Concurrent Last Use','fixed',100,1,'exclusive',false,1,true);

insert into public.promotion_items(promotion_id,catalogue_item_id)
select p.id,i.id from public.promotions p cross join public.catalogue_items i
where p.code='P7_CONC_LAST_USE' and i.sku='FD-MUF';
