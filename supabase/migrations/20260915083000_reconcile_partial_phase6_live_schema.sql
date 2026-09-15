-- TASK-OPS-006 / Phase 6 — reconcile the obsolete pre-canonical loyalty draft
-- that was briefly deployed to the live project before the canonical Phase 6
-- migration set was finalized.
--
-- Clean replay behavior: canonical Phase 6 has already created reward_catalogue
-- with `name` (not legacy `title`), so this migration is a no-op.
--
-- Live drift behavior: if and only if the legacy table shape is detected, the
-- migration refuses to discard any customer-owned loyalty state. The old draft
-- currently contains seeded config/reward rows only; those seeds are replaced by
-- the canonical migrations after this guarded cleanup.

do $$
declare
  v_accounts bigint;
  v_points bigint;
  v_stamps bigint;
  v_vouchers bigint;
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='reward_catalogue'
      and column_name='title'
  ) then
    return;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='reward_catalogue'
      and column_name='name'
  ) then
    raise exception 'mixed legacy/canonical Phase 6 reward catalogue shape requires manual review';
  end if;

  select count(*) into v_accounts from public.member_loyalty_accounts;
  select count(*) into v_points from public.loyalty_point_ledger;
  select count(*) into v_stamps from public.loyalty_stamp_ledger;
  select count(*) into v_vouchers from public.member_vouchers;

  if v_accounts <> 0 or v_points <> 0 or v_stamps <> 0 or v_vouchers <> 0 then
    raise exception
      'legacy Phase 6 schema contains customer loyalty data (accounts %, points %, stamps %, vouchers %); refusing destructive reconciliation',
      v_accounts, v_points, v_stamps, v_vouchers;
  end if;

  drop table public.loyalty_point_ledger cascade;
  drop table public.loyalty_stamp_ledger cascade;
  drop table public.member_vouchers cascade;
  drop table public.member_loyalty_accounts cascade;
  drop table public.loyalty_program_config cascade;
  drop table public.reward_catalogue cascade;
end;
$$;
