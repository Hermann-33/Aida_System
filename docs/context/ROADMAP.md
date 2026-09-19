# Roadmap

Updated: 2026-09-16

## Current status

```text
Phase 1 — operational topology                         COMPLETE
Phase 2 — shift and cash authority                    COMPLETE
Phase 3 — customer privacy/account requirements       COMPLETE
Phase 4 — branch scheduling and pickup authority      COMPLETE
Phase 5 — inventory and recipes                       COMPLETE
Phase 6 — loyalty, rewards and vouchers               COMPLETE
Phase 7 — promotions and discounts                    COMPLETE
Phase 8 — reporting/accounting/audit                  COMPLETE
Phase 9 — payments/refunds/external integrations      NEXT
Phase 10 — App Store final release gate               AFTER PHASE 9
Cumulative independent audit                          AFTER PHASE 10
```

The owner explicitly approved deferring the independent/Astra/Codex audit until Phase 10 implementation is complete. Normal per-phase validation and documentation remain mandatory.

## Trusted foundation through Phase 8

AIDA has server-owned authority for identity/roles, membership/privacy deletion, catalogue/pricing, topology, terminals, shifts/cash, scheduling/capacity, inventory/recipes, loyalty/rewards/vouchers, promotions/discounts, immutable accepted commercial snapshots and read-only operational reporting/reconciliation/audit projections.

Dashboard privileged operations remain behind the same-origin HttpOnly BFF with caller-JWT forwarding. Customer Flutter submits intent through caller-bound RPCs. Preview fixtures never become backend authority.

Phase 8 is live on AIDA through `20260916013938_create_reporting_audit_authority`; repository validation and live advisors are green against the defined boundary.

## Phase 9 — payments, refunds and external integrations

Next scope:

- provider-neutral payment lifecycle and immutable/append-only event history;
- intent / authorization / capture / failure / cancellation / settlement-reconciliation separation;
- refund request / processing / success / failure separation;
- webhook idempotency and replay protection;
- order/payment reconciliation without allowing clients to self-declare paid/refunded states;
- Dashboard operational surfaces and Phase 8 report extension for trusted payment/refund facts;
- preservation of existing cash/unpaid semantics.

Processor-specific activation is not assumed. Merchant onboarding, provider credentials, webhook secrets, fees/paid services and provider-specific production calls require explicit owner approval.

## Phase 10 — App Store release gate

After Phase 9 engineering completion:

- re-check current official Apple requirements;
- final iOS release/static/test/golden build gates;
- permission/SDK/privacy-manifest and App Privacy reconciliation;
- production account-deletion verification;
- legal/privacy/support URLs;
- review credentials/demo path/notes;
- screenshots/metadata matching the binary;
- production backend/release configuration verification.

## Final audit

After Phase 10 implementation and normal validation, prepare the two-repository cumulative Phase 1–10 audit package, run the independent/Astra/Codex audit, remediate findings and rerun affected validation before final program closure.

Phase PRs remain draft/unmerged unless explicitly authorized.
