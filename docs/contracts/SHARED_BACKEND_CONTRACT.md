# Shared Backend Contract

Updated: 2026-09-15

## Authority

Supabase Auth/Postgres/FORCE-RLS plus controlled RPC/BFF operations are authoritative. Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Neither frontend is authority for authenticated identity, trusted role/disabled state, membership, employee branch scope, topology, terminal credential validity, shift/cash, scheduling/capacity, catalogue/pricing, inventory/recipes/depletion, loyalty balances/reward/voucher state, order totals/status/discount, tender/payment, privacy preferences or deletion/anonymization state.

Dashboard privileged flows use a same-origin BFF with HttpOnly employee and terminal credentials and caller-JWT forwarding. No service-role secret or browser-readable reusable employee/terminal credential is part of normal runtime. Preview fixtures never become backend authority.

## Core contracts

- **Identity:** Supabase Auth identifies the caller; `user_profiles.app_role`/`disabled_at`, `members` and `employee_branch_assignments` are trusted application state. Customer-editable Auth metadata is not authorization authority.
- **Topology:** branch -> sales point -> terminal; POS topology is derived from server-held terminal credential and employee scope.
- **Shift/cash:** new POS placement requires an open caller-owned shift; cash movements are append-only; expected cash/variance is server-derived.
- **Scheduling:** customer branch/pickup input is validated intent; server owns branch calendar, lead/horizon/slots/capacity and `prepare_at`.
- **Inventory:** active recipe requirements consume non-negative branch inventory transactionally; cancellation writes compensating reversals.
- **Privacy:** customer deletion is caller-bound, scrubs retained free text/request digest, removes customer-owned state and anonymizes retained commercial history without erasing staff/POS audit identity.

## Phase 6 loyalty/reward/voucher contract

Trusted chain:

```text
member
 -> loyalty_program_config
 -> loyalty_order_awards
 -> point/stamp ledgers + member_loyalty_accounts
 -> reward_catalogue
 -> member_vouchers
 -> quote discount
 -> voucher_order_applications
```

Completed-order earning is exactly once. Current balances are server-maintained; clients cannot write resulting balances. Customer reward redemption locks trusted state, validates points and issues the voucher atomically.

Customer wallet/redeem operations derive ownership from `auth.uid()`. Admin/Owner support/configuration binds actor identity to the caller and preserves adjustment reason/actor. POS loyalty lookup additionally requires the server-held terminal credential and the caller's open shift.

Voucher use submits `voucherId` (and POS member code where applicable) as intent. Quote derives eligibility and discount; placement revalidates and consumes the voucher atomically. `orders.discount_sen` and accepted voucher application snapshots are server-derived immutable commercial facts.

Whole-account deletion deletes customer-owned wallet/ledgers/vouchers and detaches their identifiers from retained order award/voucher snapshots.

## Phase 1–3 remediation contract

The generic private order writer is not executable by ordinary authenticated callers. Matching POS idempotent retries can resolve after their original shift is later locked/closed only after current employee/terminal authority succeeds; new orders still require an open shift. The Phase 3 anonymization transition is permitted only under the narrow internal deletion flag and expected identity/request-digest shape.

## Validation/governance

Phases 1–6 are `COMPLETE`. Final Phase 6 evidence: backend #190, customer #281, Dashboard #126, live Supabase deployment and advisor checks. Phase 7 is next but not started. Completed PRs remain draft/unmerged unless explicitly authorized.