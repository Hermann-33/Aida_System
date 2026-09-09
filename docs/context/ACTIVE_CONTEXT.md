# Active Context

**As of:** 2026-09-10  
**Current task:** `TASK-DOC-SYNC-001 — cross-repository governance synchronization and durable agent prompts`  
**Current verdict:** PARTIAL — documentation and AI-context content are reconciled on matching task branches in both repositories; default-branch adoption still requires merge.

## Repository state

Customer app:

- repository: `Hermann-33/Aida_System`
- default branch: `master`
- current default merge head at task start: `5dac63de972d9a0761bc817c4ae9ad5079d9385c`
- latest merged product task: PR #19 / `TASK-UI-REDESIGN-004`

Dashboard/POS/Admin:

- repository: `Hermann-33/Aida_System-Dashboard`
- default branch: `main`
- current default merge head at task start: `b8e4b11dbc093106d4f62383dbb0d13ba85001b8`
- latest merged product task: `TASK-MENU-CUSTOMIZATION-001`

Current documentation-sync branches:

`codex/task-doc-sync-001-ai-context`

in both repositories.

## Latest integrated customer state

The customer redesign is merged into `master`.

Accepted active UI includes refreshed Splash/branding, Home, Menu search, Item Detail customization presentation, Cart, Order confirmation, Membership QR, Profile, Settings, Rewards and bottom navigation.

All demo-only order/status/test tooling was dropped before merge.

Production order status remains backend-authoritative:

```text
Supabase persisted order status
  -> owner-scoped invalidation/refetch
  -> customer UI
```

Useful unfinished work is preserved without being live:

- account-deletion/referral SQL prototypes live under `supabase/drafts/`;
- `AIDA_ENABLE_ACCOUNT_DELETION_DRAFT` defaults false;
- `AIDA_ENABLE_REFERRAL_DRAFT` defaults false;
- draft SQL is not canonical migration history;
- dormant referral sharing is pinned to `share_plus 11.1.0` for compatibility with the current Android toolchain.

Customer release audit passed dependency resolution, zero-issue analysis, non-golden regressions, reviewed golden regressions, release APK assembly and artifact upload before the PR #19 merge.

Detailed evidence:

- `docs/frontend/UI_REDESIGN_AUDIT_2026-09-09.md`
- merge commit `5dac63de972d9a0761bc817c4ae9ad5079d9385c`

## Live shared backend

The implemented trusted tranche includes:

- Supabase Auth/member provisioning;
- protected employee/Admin session architecture;
- shared catalogue and catalogue revision invalidation;
- product variants;
- per-drink Temperature/Sweetness option groups;
- per-product compatible add-ons;
- authoritative quote/order pricing;
- immutable option/add-on order snapshots;
- customer and POS order placement;
- idempotency;
- customer history/detail;
- versioned legal order status transitions;
- Now/scheduled pickup;
- server-owned preparation-window classification;
- customer owner-scoped order invalidation/refetch.

Customization pricing uses `pricingVersion=2`.

Standard drink option groups currently include:

```text
Temperature: Hot | Iced
Sweetness: Regular | Less sweet | Least sweet
```

The backend validates option availability/defaults/compatibility and price deltas. Clients submit IDs and intent, not trusted commercial totals.

Payment remains **Pay at counter / unpaid**.

## Dashboard/POS/Admin state

The Dashboard consumes the same catalogue/order contract.

Admin can manage:

- drink status;
- option customer labels;
- availability;
- defaults;
- option price deltas;
- compatible add-ons.

POS maps authoritative catalogue variants/options/add-ons into per-line intent and submits IDs/quantity/note/fulfilment intent only.

Dashboard trusted employee access remains behind the accepted same-origin HttpOnly BFF boundary. Browser route guards are not server authorization.

## Security / Supabase status

RLS/FORCE-RLS and server-side authorization remain mandatory.

Last recorded live security-advisor state:

- one pre-existing warning: leaked-password protection disabled.

Last recorded performance findings were INFO-only unused-index observations on a small dataset.

Canonical executable migrations live only under:

`Hermann-33/Aida_System/supabase/migrations/`

Files under:

`Hermann-33/Aida_System/supabase/drafts/`

are preserved future work only and must not be described as deployed.

## Durable agent context

`TASK-DOC-SYNC-001` introduces a mirrored `docs/ai/` context system modeled after Cheaters Market Docs.

Canonical fresh-agent entry points:

1. `docs/ai/BOOTSTRAP.md`
2. `docs/ai/context/CURRENT_STATE.md`
3. `docs/ai/CONTEXT_MANIFEST.yaml`
4. `docs/ai/prompts/FRESH_CHAT_BOOTSTRAP.md`

Reusable prompts cover:

- customer app tasks;
- Dashboard/POS/Admin tasks;
- shared Supabase tasks;
- cross-repository tasks;
- release audits;
- documentation synchronization.

`docs/context/SESSION_BOOTSTRAP.md` remains as a compatibility pointer only.

## Still deferred production domains

- customer account deletion/anonymisation deployment;
- real loyalty ledger/rewards/referrals;
- online payment/refunds/reconciliation;
- branch/store authority and opening hours;
- terminal/sales-point lifecycle;
- shifts/cash reconciliation;
- inventory/recipes/sold-out propagation;
- promotions/discounts;
- tax/accounting/receipts;
- trusted reporting;
- push notifications;
- full student-verification workflow;
- hosted production operations;
- final iOS/App Store release work.

## Working rule

Before changing any shared concept—identity, member code, roles, catalogue, pricing, modifiers, order lifecycle, payment, loyalty, inventory, branch/terminal scope, reporting, audit or migrations—inspect both repositories and the shared backend contract.

When current code/live Supabase evidence conflicts with old task notes, accepted ADRs and current evidence win.
