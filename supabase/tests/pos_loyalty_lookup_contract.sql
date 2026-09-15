-- TASK-OPS-006 / Phase 6 POS loyalty lookup contract regression.
-- Full shift/terminal runtime behavior composes private.require_open_shift_impl,
-- whose mutation/runtime semantics are already covered by the Phase 2 shift
-- regression. This test locks the new public exposure to authenticated,
-- SECURITY INVOKER access only.

begin;

do $$
begin
  if has_function_privilege('anon','public.get_pos_member_loyalty(text,text)','execute') then
    raise exception 'anonymous role has POS loyalty lookup authority';
  end if;
  if not has_function_privilege('authenticated','public.get_pos_member_loyalty(text,text)','execute') then
    raise exception 'authenticated POS loyalty lookup grant is missing';
  end if;
  if exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname='get_pos_member_loyalty'
      and p.prosecdef
  ) then
    raise exception 'public POS loyalty lookup unexpectedly uses SECURITY DEFINER';
  end if;
  if has_function_privilege('anon','private.get_pos_member_loyalty_impl(text,text,uuid)','execute')
     or has_function_privilege('authenticated','private.get_pos_member_loyalty_impl(text,text,uuid)','execute') = false then
    -- authenticated needs EXECUTE only so the invoker wrapper can cross the
    -- private schema boundary; the helper independently binds auth.uid(),
    -- staff role, terminal credential and open shift.
    if has_function_privilege('anon','private.get_pos_member_loyalty_impl(text,text,uuid)','execute') then
      raise exception 'anonymous role can execute private POS loyalty helper';
    end if;
    if not has_function_privilege('authenticated','private.get_pos_member_loyalty_impl(text,text,uuid)','execute') then
      raise exception 'authenticated wrapper cannot execute private POS loyalty helper';
    end if;
  end if;
end;
$$;

rollback;
