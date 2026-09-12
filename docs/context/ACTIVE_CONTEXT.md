# Active Context

**As of:** 2026-09-12  
**Current boundary:** Combined Phase 1–3 Astra audit  
**Current verdict:** `PARTIAL` — Phases 1, 2 and 3 are `COMPLETE`; combined Astra review is not yet executed/accepted.  
**Implementation state:** STOPPED before Phase 4.

## Product topology

AIDA Café is one product across:

- customer/backend: `Hermann-33/Aida_System`;
- Dashboard/Admin/POS: `Hermann-33/Aida_System-Dashboard`;
- shared Supabase project: `eswovqxqzfevcdwwcmuh`.

Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

## Completed authority through Phase 3

```text
Phase 1 COMPLETE
branch -> sales point -> terminal -> employee branch scope -> POS attribution

Phase 2 COMPLETE
terminal + employee -> shift -> POS order / cash ledger

Phase 3 COMPLETE
customer identity -> privacy preferences / customer orders
                  -> whole-account deletion
                  -> anonymized retained transaction history
```

Supabase/server owns trusted identity, role/disabled state, membership, branch/terminal/shift/payment/commercial state, privacy preferences and account-deletion/anonymization. Dashboard privileged flows stay behind the same-origin HttpOnly BFF with caller-JWT forwarding. No service-role secret or browser-readable employee bearer token/terminal credential is introduced. Preview fixtures are never backend authority.

## Phase 3 closeout

`TASK-PRIVACY-001` is `COMPLETE`.

Key properties:

- in-app whole-account deletion is production-enabled and accepts no target user ID;
- customer profile/member/student/preference identity is deleted;
- retained customer orders lose customer/member/Auth identifiers;
- retained customer-authored line/event free text is scrubbed;
- commercial/operational transaction facts remain retained;
- POS/staff audit identity remains intact;
- privacy preferences are owner-bound, FORCE-RLS protected, marketing default-off;
- stale deleted-customer JWTs cannot regain personalized order/privacy authority;
- legal/privacy/terms/support surfaces and guest/auth boundaries are explicit;
- Phase 3 adds no unnecessary iOS protected-data/tracking permission or external payment integration.

Detailed evidence: `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_CLOSEOUT_2026-09-12.md`.

Implementation validation head `10ca26a776994e59b76f8afbd7227e296270cd68`:

```text
Backend database audit #90   COMPLETE
Customer release audit #182 COMPLETE
```

Dashboard Phase 3 runtime is unchanged; pre-closeout head `411056a40edfb1c23fa999504b904d822e151f5d` passed Dashboard CI #66. Final documentation-only heads are revalidated on their PRs.

## Current Supabase state

Phase 3 live migrations include:

```text
20260912014924 customer_privacy_account_requirements
20260912015010 harden_customer_privacy_rpc_boundary
20260912020434 allow_customer_deletion_without_member_dependency
20260912020652 allow_disabled_customer_account_deletion
20260912021143 scrub_customer_free_text_on_account_deletion
```

Security advisor: no Phase 3-created blocker. The pre-existing leaked-password-protection warning remains. Performance advisor: INFO-level unused-index observations only.

## Current PR boundaries

All remain draft and unmerged:

```text
Phase 1: Aida_System #20 / Dashboard #17
Phase 2: Aida_System #21 / Dashboard #18
Phase 3: Aida_System #22 / Dashboard #19
```

Do not merge merely because implementation is complete.

## Next boundary

`docs/context/PHASE_1_3_ASTRA_AUDIT_BOUNDARY_2026-09-12.md`

Boundary verdict is `PARTIAL` until Astra review is executed/accepted. Phase 4 must not begin before that boundary is resolved or explicitly accepted.