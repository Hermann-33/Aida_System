-- TASK-OPS-006 / Phase 6 — expose the trusted discount/voucher snapshot without
-- rewriting the mature Phase 1-5 order snapshot implementation.

do $$
begin
  if to_regprocedure('private.order_snapshot_phase5(uuid)') is null then
    alter function private.order_snapshot(uuid) rename to order_snapshot_phase5;
  end if;
end;
$$;
revoke all on function private.order_snapshot_phase5(uuid) from public, anon, authenticated;
grant execute on function private.order_snapshot_phase5(uuid) to authenticated;

create or replace function private.order_snapshot(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when base.snapshot is null then null
    else base.snapshot || jsonb_build_object(
      'discountSen', o.discount_sen,
      'voucher', case
        when va.id is null then null
        else jsonb_build_object(
          'code', va.voucher_code_snapshot,
          'rewardCode', va.reward_code_snapshot,
          'rewardName', va.reward_name_snapshot,
          'rewardType', va.reward_type_snapshot,
          'discountSen', va.discount_sen,
          'appliedAt', va.applied_at
        )
      end
    )
  end
  from public.orders o
  cross join lateral (
    select private.order_snapshot_phase5(o.id) as snapshot
  ) base
  left join public.voucher_order_applications va on va.order_id=o.id
  where o.id=p_order_id;
$$;
revoke all on function private.order_snapshot(uuid) from public, anon, authenticated;
grant execute on function private.order_snapshot(uuid) to authenticated;

comment on function private.order_snapshot(uuid) is
  'Phase 6 trusted order snapshot: Phase 5 order contract plus immutable discount/voucher application facts.';
