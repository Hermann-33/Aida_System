-- TASK-OPS-006 / Phase 6 — cover loyalty foreign keys reported by the live
-- Supabase performance advisor. Nullable references use partial indexes.

create index loyalty_point_ledger_actor_user_idx
  on public.loyalty_point_ledger(actor_user_id)
  where actor_user_id is not null;

create index loyalty_point_ledger_reward_fk_idx
  on public.loyalty_point_ledger(reward_id)
  where reward_id is not null;

create index loyalty_program_config_stamp_reward_fk_idx
  on public.loyalty_program_config(stamp_reward_id);

create index loyalty_program_config_updated_by_idx
  on public.loyalty_program_config(updated_by_user_id)
  where updated_by_user_id is not null;

create index loyalty_stamp_ledger_actor_user_idx
  on public.loyalty_stamp_ledger(actor_user_id)
  where actor_user_id is not null;

create index loyalty_stamp_ledger_reward_fk_idx
  on public.loyalty_stamp_ledger(reward_id)
  where reward_id is not null;
