# Dashboard Mocks and Placeholders Register

Updated: 2026-09-15

This register distinguishes intentional preview/presentation fixtures from live backend authority. **Preview data is never a production fallback.**

## Trusted live paths through Phase 7

The following capabilities are live and must not be documented or implemented as mock authority:

- employee authentication/session and trusted role/disabled state;
- branches, employee branch scope, sales points and terminals;
- terminal enrolment/revocation and POS terminal context;
- shifts, cash movements and reconciliation;
- shared catalogue and catalogue mutation;
- branch scheduling/pickup policy/capacity;
- authoritative order quote/place/status;
- branch inventory, recipes and movements;
- loyalty program/rewards, member wallet/support and POS member lookup;
- voucher validation/discount/one-time consumption;
- Phase 7 promotion configuration, scope, automatic order evaluation and immutable application snapshots.

## Preview-only fixtures

Preview fixtures may exist for deterministic visual development, screenshots and browser isolation tests. They are allowed only when the application is explicitly in preview mode. They may represent sample orders, members, catalogue data, reports, campaigns or settings for presentation purposes.

Preview mode must not:

- call privileged backend routes;
- create/mutate live promotions, orders, cash, inventory or loyalty state;
- provide a fallback when a live request fails;
- be interpreted as current production state.

Blocking browser coverage verifies privileged-network isolation in preview mode.

## Campaigns / promotions

Campaign presentation is no longer a placeholder in live mode. `/admin/rewards/campaigns` reads/writes server-owned promotion configuration via the same-origin BFF and caller-bound Supabase RPCs. Preview campaigns remain sample UI content only.

Order discounts are not simulated in live POS: the accepted `voucherDiscountSen`, `promotionDiscountSen`, total discount and promotion snapshots come from authoritative quote/place responses.

## Reporting/audit placeholders

Generalized sales/accounting/audit reporting remains the Phase 8 boundary. Existing report/audit screens may still contain preview-oriented presentation until Phase 8 replaces them with trusted derived backend data. They must not be represented as authoritative financial statements before that work is complete.

## Integrations / payments placeholders

External processor capture, settlement, refunds and third-party integration status remain Phase 9. Existing cash/unpaid tender behavior is live internal authority; processor-looking presentation must not imply real settlement.

## Credential/hardware placeholders

Badge/PIN credential provisioning and hardware integrations remain deferred. UI labels or mock states must not imply those credentials/devices are provisioned by the current backend.

## Release placeholders

Final hosted production URLs, App Store review metadata/screenshots/demo credentials and submission state remain Phase 10/manual release work. Do not label the app as submitted/approved until that event actually occurs.

## Governance

Phases 1–7 are `COMPLETE` against their defined runtime/live-verification boundary. Phase 8 is the next implementation boundary. Historical audit documents may describe older mock states; current runtime truth is defined by this register plus `ACTIVE_CONTEXT.md`, `SYSTEM_MAP.md`, `ARCHITECTURE.md`, and the phase closeouts.
