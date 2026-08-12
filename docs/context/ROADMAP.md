# Roadmap

Updated: 2026-08-13

## Completed foundations

- Governance/import workflow foundations: COMPLETE.
- DB identity/member foundation: COMPLETE for scoped DB authority.
- Shared catalogue backend/source integration: implemented and locally validated; deployed real-identity E2E remains separate debt.

## Auth/member operational debt — TASK-AUTH-003

PARTIAL under ADR-0004. Source/toolchain validation is strong, but live Supabase still has zero approved real identities and the Vercel preview lacks its publishable Supabase runtime variables. Real deployed Auth/member/cookie/role E2E remains outstanding.

## Demo ordering — TASK-DEMO-ORDER-001

Backend milestone implemented live:

- authoritative shared quote engine;
- customer and POS order placement;
- immutable commercial snapshots;
- idempotent placement;
- ASAP and scheduled pickup policy;
- persisted fulfilment state machine;
- staff queue/read/status RPCs;
- order audit events;
- `orders` Realtime publication;
- dashboard same-origin order BFF endpoints;
- canonical live transactional order regression;
- security advisor 0 lints;
- foreign-key index hardening.

Formal product-feature status: PARTIAL because Flutter and React are intentionally not integrated in the backend task.

## Immediate next work

Continue `TASK-DEMO-ORDER-001` on `codex/task-demo-order-001-order-scheduling-backend` with frontend integration only:

1. Flutter authoritative quote + ASAP/scheduled checkout.
2. Flutter real placement/history/status and `orders` Realtime re-fetch.
3. Dashboard POS authoritative quote/place.
4. Dashboard live Scheduled/Confirmed/Preparing/Ready order board and versioned transitions.
5. Full client toolchains and cross-client E2E.

The frontend must preserve the established AIDA theme/design; this is integration work, not a redesign.

## After the demo order flow

High-impact follow-ons should consume trusted completed orders rather than client totals:

1. loyalty earning/history;
2. demo sales KPIs/recent orders;
3. trusted payment/tender lifecycle;
4. inventory depletion;
5. branch-aware hours/capacity and branch-scoped operations when branch authority is designed.
