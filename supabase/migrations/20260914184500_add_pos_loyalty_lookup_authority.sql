-- TASK-OPS-006 / Phase 6 — shift-bound POS member loyalty lookup.
-- Staff may inspect only the minimal loyalty wallet needed to attach a member
-- and choose an issued voucher while operating an enrolled terminal with an
-- open shift. The reusable terminal credential is supplied server-side by the
-- Dashboard BFF and the employee actor remains bound to auth.uid().

create or replace function private.get_pos_member_loyalty_impl(
  p_member_code text,
  p_terminal_credential text,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_shift jsonb;
  v_member_id uuid;
  v_account public.member_loyalty_accounts%rowtype;
  v_result jsonb;
begin
  if p_actor_user_id is null
     or p_actor_user_id is distinct from (select auth.uid())
     or not (select private.is_staff_or_above()) then
    raise exception 'employee authentication required for POS loyalty lookup'
      using errcode='42501', detail='EMPLOYEE_REQUIRED';
  end if;

  -- This validates terminal credential, terminal state, branch assignment,
  -- operator ownership and that the shift is currently OPEN (not locked).
  v_shift := private.require_open_shift_impl(p_terminal_credential,p_actor_user_id);

  select m.id into v_member_id
  from public.members m
  where m.member_code = upper(btrim(coalesce(p_member_code,'')))
    and m.active
  limit 1;

  if v_member_id is null then
    raise exception 'member code is unavailable'
      using errcode='22023', detail='LOYALTY_MEMBER_NOT_FOUND';
  end if;

  select * into v_account
  from public.member_loyalty_accounts
  where member_id=v_member_id;

  select jsonb_build_object(
    'memberCode',m.member_code,
    'pointsBalance',coalesce(v_account.points_balance,0),
    'stampBalance',coalesce(v_account.stamp_balance,0),
    'program',(
      select jsonb_build_object(
        'pointsPerRinggit',c.points_per_ringgit,
        'stampsPerQualifyingOrder',c.stamps_per_qualifying_order,
        'stampGoal',c.stamp_goal
      )
      from public.loyalty_program_config c where c.id=1
    ),
    'vouchers',coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',v.id,
        'code',v.code,
        'rewardCode',v.reward_code_snapshot,
        'rewardName',v.reward_name_snapshot,
        'rewardType',v.reward_type_snapshot,
        'fixedAmountSen',v.fixed_amount_sen_snapshot,
        'eligibleCategorySlugs',v.eligible_category_slugs_snapshot,
        'eligibleItemSkus',v.eligible_item_skus_snapshot,
        'expiresAt',v.expires_at
      ) order by v.issued_at desc)
      from public.member_vouchers v
      where v.member_id=v_member_id
        and v.status='active'
        and v.expires_at>now()
    ),'[]'::jsonb),
    'shiftId',v_shift->>'id'
  ) into v_result
  from public.members m
  where m.id=v_member_id;

  return v_result;
end;
$$;

revoke all on function private.get_pos_member_loyalty_impl(text,text,uuid) from public,anon,authenticated;
grant execute on function private.get_pos_member_loyalty_impl(text,text,uuid) to authenticated;

create or replace function public.get_pos_member_loyalty(
  p_member_code text,
  p_terminal_credential text
)
returns jsonb
language plpgsql
stable
security invoker
set search_path=public,pg_temp
as $$
begin
  return private.get_pos_member_loyalty_impl(
    p_member_code,
    p_terminal_credential,
    (select auth.uid())
  );
end;
$$;

revoke all on function public.get_pos_member_loyalty(text,text) from public,anon,authenticated;
grant execute on function public.get_pos_member_loyalty(text,text) to authenticated;

comment on function public.get_pos_member_loyalty(text,text) is
  'Shift-bound POS lookup of minimal member loyalty/voucher state. Employee identity is auth.uid(); terminal credential is expected from the same-origin HttpOnly BFF, never browser JS.';
