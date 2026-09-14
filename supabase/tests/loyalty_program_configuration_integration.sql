-- TASK-OPS-006 / Phase 6 loyalty program configuration regression.
-- Transactional: no synthetic identity/configuration survives.

begin;

do $$
begin
  if has_function_privilege('anon','public.save_loyalty_program_config(integer,integer,uuid)','execute') then
    raise exception 'anonymous role has loyalty program configuration authority';
  end if;
  if not has_function_privilege('authenticated','public.save_loyalty_program_config(integer,integer,uuid)','execute') then
    raise exception 'authenticated loyalty program configuration RPC grant is missing';
  end if;
  if exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='save_loyalty_program_config' and p.prosecdef
  ) then raise exception 'public loyalty program configuration RPC unexpectedly uses SECURITY DEFINER'; end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('66400000-0000-0000-0000-000000000001','phase6-config-admin@example.test','{}'::jsonb,now(),now()),
 ('66400000-0000-0000-0000-000000000002','phase6-config-customer@example.test','{}'::jsonb,now(),now());
update public.user_profiles set app_role='admin' where user_id='66400000-0000-0000-0000-000000000001';

set local role authenticated;
do $$
declare
  v_admin uuid:='66400000-0000-0000-0000-000000000001';
  v_reward uuid;
  v_result jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  select id into strict v_reward from public.reward_catalogue where code='STAMP_FREE_DRINK';
  select public.save_loyalty_program_config(2,12,v_reward) into v_result;
  if (v_result->>'pointsPerRinggit')::integer<>2 or (v_result->>'stampGoal')::integer<>12 then
    raise exception 'loyalty program configuration did not persist requested server values: %',v_result;
  end if;
  if (select updated_by_user_id from public.loyalty_program_config where id=1) is distinct from v_admin then
    raise exception 'loyalty program configuration did not preserve trusted actor';
  end if;
end;
$$;
reset role;

set local role authenticated;
do $$
declare
  v_customer uuid:='66400000-0000-0000-0000-000000000002';
  v_reward uuid;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  select id into strict v_reward from public.reward_catalogue where code='STAMP_FREE_DRINK';
  begin
    perform public.save_loyalty_program_config(3,15,v_reward);
    raise exception 'customer loyalty program configuration unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

rollback;
