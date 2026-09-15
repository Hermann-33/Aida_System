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

  if has_table_privilege('authenticated','public.reward_catalogue','select')
     or has_table_privilege('authenticated','public.loyalty_program_config','select')
     or has_table_privilege('authenticated','public.loyalty_program_config','update') then
    raise exception 'authenticated role unexpectedly has direct loyalty configuration table access';
  end if;
end;
$$;

insert into auth.users(id,email,raw_user_meta_data,created_at,updated_at)
values
 ('66400000-0000-0000-0000-000000000001','phase6-config-admin@example.test','{}'::jsonb,now(),now()),
 ('66400000-0000-0000-0000-000000000002','phase6-config-customer@example.test','{}'::jsonb,now(),now());
update public.user_profiles set app_role='admin' where user_id='66400000-0000-0000-0000-000000000001';

-- Resolve fixture authority while still database owner. The authenticated test
-- must exercise the public RPC without direct reward/config table reads.
select set_config(
  'test.phase6.stamp_reward_id',
  (select id::text from public.reward_catalogue where code='STAMP_FREE_DRINK'),
  false
);

set local role authenticated;
do $$
declare
  v_admin uuid:='66400000-0000-0000-0000-000000000001';
  v_reward uuid:=current_setting('test.phase6.stamp_reward_id')::uuid;
  v_result jsonb;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_admin,'role','authenticated')::text,true);
  select public.save_loyalty_program_config(2,12,v_reward) into v_result;
  if (v_result->>'pointsPerRinggit')::integer<>2 or (v_result->>'stampGoal')::integer<>12 then
    raise exception 'loyalty program configuration did not persist requested server values: %',v_result;
  end if;
end;
$$;
reset role;

-- Trusted actor attribution is an internal persistence assertion and is checked
-- as database owner rather than broadening authenticated table grants.
do $$
declare
  v_admin uuid:='66400000-0000-0000-0000-000000000001';
begin
  if (select updated_by_user_id from public.loyalty_program_config where id=1) is distinct from v_admin then
    raise exception 'loyalty program configuration did not preserve trusted actor';
  end if;
end;
$$;

set local role authenticated;
do $$
declare
  v_customer uuid:='66400000-0000-0000-0000-000000000002';
  v_reward uuid:=current_setting('test.phase6.stamp_reward_id')::uuid;
begin
  perform set_config('request.jwt.claims',jsonb_build_object('sub',v_customer,'role','authenticated')::text,true);
  begin
    perform public.save_loyalty_program_config(3,15,v_reward);
    raise exception 'customer loyalty program configuration unexpectedly succeeded';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

rollback;
