-- Phase 4 compatibility: the pre-Phase-4 global schedule policy allowed
-- preparationLeadMinutes to exceed minimumLeadMinutes. Preserve that contract
-- rather than invalidating existing policy writes and historical expectations.
-- Both values remain independently bounded to 0..1440 minutes.

alter table public.branch_ordering_policies
  drop constraint if exists branch_ordering_preparation_vs_minimum_check;
