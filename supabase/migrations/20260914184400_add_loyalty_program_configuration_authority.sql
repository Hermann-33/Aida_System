-- TASK-OPS-006 / Phase 6 — Admin/Owner loyalty program configuration.
-- Canonical executable migration: Aida_System only.

create or replace function private.save_loyalty_program_config_impl(
  p_points_per_ringgit integer,
  p_stamp_goal integer,
  p_stamp_reward_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reward public.reward_catalogue%rowtype;
  v_result jsonb;
begin
  perform private.require_loyalty_admin(p_actor_user_id);

  if p_points_per_ringgit is null or p_points_per_ringgit < 0 or p_points_per_ringgit > 100 then
    raise exception 'pointsPerRinggit must be between 0 and 100' using errcode='22023', detail='LOYALTY_POINTS_RATE_INVALID';
  end if;
  if p_stamp_goal is null or p_stamp_goal < 2 or p_stamp_goal > 100 then
    raise exception 'stampGoal must be between 2 and 100' using errcode='22023', detail='LOYALTY_STAMP_GOAL_INVALID';
  end if;

  select * into v_reward
  from public.reward_catalogue
  where id=p_stamp_reward_id and is_active
  for share;
  if not found then
    raise exception 'stamp reward is unavailable' using errcode='22023', detail='LOYALTY_STAMP_REWARD_UNAVAILABLE';
  end if;
  if v_reward.reward_type <> 'free_item' then
    raise exception 'stamp reward must be a free-item reward' using errcode='22023', detail='LOYALTY_STAMP_REWARD_INVALID';
  end if;

  update public.loyalty_program_config
  set points_per_ringgit=p_points_per_ringgit,
      stamps_per_qualifying_order=1,
      stamp_goal=p_stamp_goal,
      stamp_reward_id=p_stamp_reward_id,
      updated_by_user_id=p_actor_user_id,
      updated_at=now()
  where id=1;

  select jsonb_build_object(
    'pointsPerRinggit',c.points_per_ringgit,
    'stampsPerQualifyingOrder',c.stamps_per_qualifying_order,
    'stampGoal',c.stamp_goal,
    'stampRewardId',c.stamp_reward_id,
    'updatedAt',c.updated_at
  ) into v_result
  from public.loyalty_program_config c
  where c.id=1;

  return v_result;
end;
$$;

revoke all on function private.save_loyalty_program_config_impl(integer,integer,uuid,uuid) from public,anon,authenticated;
grant execute on function private.save_loyalty_program_config_impl(integer,integer,uuid,uuid) to authenticated;

create or replace function public.save_loyalty_program_config(
  p_points_per_ringgit integer,
  p_stamp_goal integer,
  p_stamp_reward_id uuid
)
returns jsonb
language plpgsql
security invoker
set search_path=public,pg_temp
as $$
begin
  return private.save_loyalty_program_config_impl(
    p_points_per_ringgit,
    p_stamp_goal,
    p_stamp_reward_id,
    (select auth.uid())
  );
end;
$$;

revoke all on function public.save_loyalty_program_config(integer,integer,uuid) from public,anon,authenticated;
grant execute on function public.save_loyalty_program_config(integer,integer,uuid) to authenticated;

comment on function public.save_loyalty_program_config(integer,integer,uuid) is
  'Admin/Owner-only mutation of server-authoritative loyalty earning/stamp configuration. Caller identity is bound to auth.uid().';
