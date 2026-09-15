-- TASK-OPS-006 / Phase 6 — Admin/Owner loyalty support and reward configuration.
-- Public mutation RPCs remain SECURITY INVOKER. Private helpers independently
-- verify Admin/Owner authority and bind actor identity to auth.uid().

alter table public.loyalty_program_config
  drop constraint loyalty_program_stamps_rate_check,
  add constraint loyalty_program_stamps_rate_check check (stamps_per_qualifying_order = 1);

create or replace function private.require_loyalty_admin(p_actor_user_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_actor_user_id is null or p_actor_user_id is distinct from (select auth.uid()) then
    raise exception 'authenticated actor mismatch' using errcode='42501';
  end if;
  if not (select private.is_admin_or_owner()) then
    raise exception 'Admin or Owner role required' using errcode='42501', detail='LOYALTY_ADMIN_REQUIRED';
  end if;
end;
$$;
revoke all on function private.require_loyalty_admin(uuid) from public, anon, authenticated;

create or replace function private.get_loyalty_admin_state_impl(p_actor_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_result jsonb;
begin
  perform private.require_loyalty_admin(p_actor_user_id);
  select jsonb_build_object(
    'program',(
      select jsonb_build_object(
        'pointsPerRinggit',c.points_per_ringgit,
        'stampsPerQualifyingOrder',c.stamps_per_qualifying_order,
        'stampGoal',c.stamp_goal,
        'stampRewardId',c.stamp_reward_id,
        'updatedAt',c.updated_at
      ) from public.loyalty_program_config c where c.id=1
    ),
    'rewards',coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',r.id,'code',r.code,'name',r.name,'rewardType',r.reward_type,
        'pointsCost',r.points_cost,'fixedAmountSen',r.fixed_amount_sen,
        'eligibleCategorySlugs',r.eligible_category_slugs,
        'eligibleItemSkus',r.eligible_item_skus,'expiryDays',r.expiry_days,
        'isPointsRedeemable',r.is_points_redeemable,'isActive',r.is_active,
        'updatedAt',r.updated_at
      ) order by r.code)
      from public.reward_catalogue r
    ),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;
revoke all on function private.get_loyalty_admin_state_impl(uuid) from public, anon, authenticated;

create or replace function private.get_member_loyalty_by_code_impl(
  p_member_code text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare v_member_id uuid;
begin
  perform private.require_loyalty_admin(p_actor_user_id);
  select m.id into v_member_id
  from public.members m
  where m.member_code=upper(btrim(coalesce(p_member_code,''))) and m.active
  limit 1;
  if v_member_id is null then
    raise exception 'member code is unavailable' using errcode='22023', detail='LOYALTY_MEMBER_NOT_FOUND';
  end if;
  return private.loyalty_wallet_impl(v_member_id,p_actor_user_id);
end;
$$;
revoke all on function private.get_member_loyalty_by_code_impl(text,uuid) from public, anon, authenticated;

create or replace function private.adjust_member_loyalty_impl(
  p_member_code text,
  p_points_delta bigint,
  p_stamps_delta integer,
  p_reason text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_member_id uuid;
  v_account public.member_loyalty_accounts%rowtype;
  v_reason text:=nullif(btrim(coalesce(p_reason,'')),'');
begin
  perform private.require_loyalty_admin(p_actor_user_id);
  if coalesce(p_points_delta,0)=0 and coalesce(p_stamps_delta,0)=0 then
    raise exception 'at least one loyalty adjustment is required' using errcode='22023', detail='LOYALTY_ADJUSTMENT_EMPTY';
  end if;
  if abs(coalesce(p_points_delta,0))>1000000 or abs(coalesce(p_stamps_delta,0))>10000 then
    raise exception 'loyalty adjustment exceeds support limit' using errcode='22023', detail='LOYALTY_ADJUSTMENT_LIMIT';
  end if;
  if v_reason is null or char_length(v_reason)>300 then
    raise exception 'support adjustment reason is required and must be at most 300 characters' using errcode='22023', detail='LOYALTY_ADJUSTMENT_REASON';
  end if;
  select m.id into v_member_id from public.members m
  where m.member_code=upper(btrim(coalesce(p_member_code,''))) and m.active limit 1;
  if v_member_id is null then raise exception 'member code is unavailable' using errcode='22023', detail='LOYALTY_MEMBER_NOT_FOUND'; end if;
  perform private.ensure_loyalty_account(v_member_id);
  select * into strict v_account from public.member_loyalty_accounts where member_id=v_member_id for update;
  if v_account.points_balance+coalesce(p_points_delta,0)<0 or v_account.stamp_balance+coalesce(p_stamps_delta,0)<0 then
    raise exception 'loyalty adjustment would create a negative balance' using errcode='22023', detail='LOYALTY_NEGATIVE_BALANCE';
  end if;
  update public.member_loyalty_accounts
  set points_balance=points_balance+coalesce(p_points_delta,0),
      stamp_balance=stamp_balance+coalesce(p_stamps_delta,0),updated_at=now()
  where member_id=v_member_id;
  if coalesce(p_points_delta,0)<>0 then
    insert into public.loyalty_point_ledger(member_id,delta_points,event_kind,reason,actor_user_id)
    values(v_member_id,p_points_delta,'adjust',v_reason,p_actor_user_id);
  end if;
  if coalesce(p_stamps_delta,0)<>0 then
    insert into public.loyalty_stamp_ledger(member_id,delta_stamps,event_kind,reason,actor_user_id)
    values(v_member_id,p_stamps_delta,'adjust',v_reason,p_actor_user_id);
  end if;
  return private.loyalty_wallet_impl(v_member_id,p_actor_user_id);
end;
$$;
revoke all on function private.adjust_member_loyalty_impl(text,bigint,integer,text,uuid) from public, anon, authenticated;

create or replace function private.save_reward_impl(p_reward jsonb,p_actor_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_code text:=upper(btrim(coalesce(p_reward->>'code','')));
  v_name text:=btrim(coalesce(p_reward->>'name',''));
  v_type text:=lower(btrim(coalesce(p_reward->>'rewardType','')));
  v_cost bigint;
  v_fixed bigint;
  v_expiry integer;
  v_points_redeemable boolean;
  v_active boolean;
  v_categories text[]:=array[]::text[];
  v_skus text[]:=array[]::text[];
  v_result jsonb;
begin
  perform private.require_loyalty_admin(p_actor_user_id);
  begin v_id:=nullif(p_reward->>'id','')::uuid; exception when invalid_text_representation then raise exception 'reward id must be a valid UUID' using errcode='22023'; end;
  begin v_cost:=coalesce((p_reward->>'pointsCost')::bigint,0); exception when invalid_text_representation then raise exception 'pointsCost must be an integer' using errcode='22023'; end;
  begin v_fixed:=nullif(p_reward->>'fixedAmountSen','')::bigint; exception when invalid_text_representation then raise exception 'fixedAmountSen must be an integer' using errcode='22023'; end;
  begin v_expiry:=coalesce((p_reward->>'expiryDays')::integer,30); exception when invalid_text_representation then raise exception 'expiryDays must be an integer' using errcode='22023'; end;
  v_points_redeemable:=coalesce((p_reward->>'isPointsRedeemable')::boolean,true);
  v_active:=coalesce((p_reward->>'isActive')::boolean,true);
  if jsonb_typeof(coalesce(p_reward->'eligibleCategorySlugs','[]'::jsonb))<>'array'
     or jsonb_typeof(coalesce(p_reward->'eligibleItemSkus','[]'::jsonb))<>'array' then
    raise exception 'reward eligibility lists must be arrays' using errcode='22023';
  end if;
  select coalesce(array_agg(lower(btrim(value))) filter(where btrim(value)<>''),array[]::text[])
  into v_categories from jsonb_array_elements_text(coalesce(p_reward->'eligibleCategorySlugs','[]'::jsonb));
  select coalesce(array_agg(upper(btrim(value))) filter(where btrim(value)<>''),array[]::text[])
  into v_skus from jsonb_array_elements_text(coalesce(p_reward->'eligibleItemSkus','[]'::jsonb));

  if v_id is null then
    insert into public.reward_catalogue(code,name,reward_type,points_cost,fixed_amount_sen,eligible_category_slugs,eligible_item_skus,expiry_days,is_points_redeemable,is_active)
    values(v_code,v_name,v_type,v_cost,v_fixed,v_categories,v_skus,v_expiry,v_points_redeemable,v_active)
    returning id into v_id;
  else
    update public.reward_catalogue set code=v_code,name=v_name,reward_type=v_type,points_cost=v_cost,
      fixed_amount_sen=v_fixed,eligible_category_slugs=v_categories,eligible_item_skus=v_skus,
      expiry_days=v_expiry,is_points_redeemable=v_points_redeemable,is_active=v_active,updated_at=now()
    where id=v_id;
    if not found then raise exception 'reward is unavailable' using errcode='22023', detail='REWARD_UNAVAILABLE'; end if;
  end if;
  select jsonb_build_object('id',r.id,'code',r.code,'name',r.name,'rewardType',r.reward_type,'pointsCost',r.points_cost,'fixedAmountSen',r.fixed_amount_sen,'eligibleCategorySlugs',r.eligible_category_slugs,'eligibleItemSkus',r.eligible_item_skus,'expiryDays',r.expiry_days,'isPointsRedeemable',r.is_points_redeemable,'isActive',r.is_active,'updatedAt',r.updated_at)
  into v_result from public.reward_catalogue r where r.id=v_id;
  return v_result;
end;
$$;
revoke all on function private.save_reward_impl(jsonb,uuid) from public, anon, authenticated;

create or replace function public.get_loyalty_admin_state()
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp
as $$ begin return private.get_loyalty_admin_state_impl((select auth.uid())); end; $$;
create or replace function public.get_member_loyalty_by_code(p_member_code text)
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp
as $$ begin return private.get_member_loyalty_by_code_impl(p_member_code,(select auth.uid())); end; $$;
create or replace function public.adjust_member_loyalty(p_member_code text,p_points_delta bigint,p_stamps_delta integer,p_reason text)
returns jsonb language plpgsql security invoker set search_path=public,pg_temp
as $$ begin return private.adjust_member_loyalty_impl(p_member_code,p_points_delta,p_stamps_delta,p_reason,(select auth.uid())); end; $$;
create or replace function public.save_loyalty_reward(p_reward jsonb)
returns jsonb language plpgsql security invoker set search_path=public,pg_temp
as $$ begin return private.save_reward_impl(p_reward,(select auth.uid())); end; $$;

revoke all on function public.get_loyalty_admin_state() from public,anon,authenticated;
revoke all on function public.get_member_loyalty_by_code(text) from public,anon,authenticated;
revoke all on function public.adjust_member_loyalty(text,bigint,integer,text) from public,anon,authenticated;
revoke all on function public.save_loyalty_reward(jsonb) from public,anon,authenticated;
grant execute on function public.get_loyalty_admin_state() to authenticated;
grant execute on function public.get_member_loyalty_by_code(text) to authenticated;
grant execute on function public.adjust_member_loyalty(text,bigint,integer,text) to authenticated;
grant execute on function public.save_loyalty_reward(jsonb) to authenticated;

grant execute on function private.get_loyalty_admin_state_impl(uuid) to authenticated;
grant execute on function private.get_member_loyalty_by_code_impl(text,uuid) to authenticated;
grant execute on function private.adjust_member_loyalty_impl(text,bigint,integer,text,uuid) to authenticated;
grant execute on function private.save_reward_impl(jsonb,uuid) to authenticated;

comment on function public.adjust_member_loyalty(text,bigint,integer,text) is 'Admin/Owner-only support adjustment. Resulting balances are server-derived under row lock and adjustment ledgers preserve actor/reason.';
