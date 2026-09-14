-- TASK-OPS-006 / Phase 6 — preserve Phase 3 whole-account deletion.
-- Customer-owned point/stamp ledgers intentionally cascade with the member.
-- Direct UPDATE/DELETE remains unavailable to anon/authenticated because table
-- grants are revoked; generic mutation triggers would incorrectly block the FK
-- cascade used by delete_own_account().

drop trigger if exists loyalty_point_ledger_append_only on public.loyalty_point_ledger;
drop trigger if exists loyalty_stamp_ledger_append_only on public.loyalty_stamp_ledger;

comment on table public.loyalty_point_ledger is
  'Application-append-only points history. Ordinary clients have no direct DML; rows cascade on whole-account deletion to preserve Phase 3 privacy semantics.';
comment on table public.loyalty_stamp_ledger is
  'Application-append-only stamp history. Ordinary clients have no direct DML; rows cascade on whole-account deletion to preserve Phase 3 privacy semantics.';
