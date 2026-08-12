# AIDA Café Implementation Roadmap

Updated: 2026-08-11

Statuses reflect this repository baseline and verified task evidence, not historical deployment claims in the PRD.

## Phase 1 — Repository documentation and frontend audit

**Goal:** establish current-reality governance before implementation.  
**Expected outcomes:** codebase map, frontend audit, ADRs, security review, workflow, and handoff.  
**Completion criteria:** all repository areas inspected; docs are file-backed; checks are recorded; no behavior/database change; diff reviewed and committed.  
**Status:** Complete for `TASK-WF-001`.  
**Risks:** documentation drift; stale PRD “Live” claims; unreviewed golden differences.

## Phase 2 — Supabase/database foundation

**Goal:** create the first verified, version-controlled persistence and security baseline.  
**Expected outcomes:** project/environment verification, migration workflow, initial identity/profile/member foundations, RLS conventions/tests, local development and type-generation commands.  
**Completion criteria:** reviewed migrations reproduce the schema; access tests cover anonymous/customer/cross-user/staff/admin cases proportionate to this phase; no secrets committed; rollback/seed strategy documented.  
**Status:** Partially complete. `TASK-DB-001` created and applied the initial identity/profile/member/student-verification foundation with RLS. Menu, order, loyalty, POS/admin and storage foundations are still not started.  
**Risks:** designing later schema from UI mocks; permissive future RLS; role data in user-editable metadata; mixing production and demo data; wiring frontend too early.

### Phase 2 completed by `TASK-DB-001`

- Verified reset Supabase state before migration.
- Added `supabase/config.toml` and migration folder.
- Created `user_profiles`, `members`, and `student_verifications`.
- Added app-role/member/student-verification enums.
- Added Auth trigger provisioning for profile/member records.
- Enabled and forced RLS on foundation tables.
- Moved role helpers to non-exposed `private` schema.
- Ran Supabase security advisor: 0 security lints after hardening.
- Added local SQL posture checks.

### Phase 2 still open

- Local `supabase db reset` validation from a developer checkout.
- Full RLS tests with seeded auth users/customer/cross-user/staff/admin cases.
- Menu/catalogue foundation.
- Server quote/order foundation.
- Loyalty ledger/voucher foundation.
- Storage/image foundation.

## Phase 3 — Auth/profile/membership integration

**Goal:** replace boolean/mock auth and profile/member identity with durable, secure sessions.  
**Expected outcomes:** sign-up/sign-in/reset, session bootstrap/refresh/logout, profile reads/edits, immutable server-issued member code, offline member-code cache, verification status.  
**Completion criteria:** auth/session failure paths tested; cache isolated on logout/user change; RLS prevents cross-user access; QR survives intended offline scenarios; generated client IDs removed.  
**Status:** Not started; UI prototype exists and database foundation now exists.  
**Risks:** account enumeration, stale authorization, shared-device leakage, QR sharing, unclear deletion/verification policy.

## Phase 4 — Menu/catalogue integration

**Goal:** replace hardcoded catalogue, pricing, availability, modifiers, promotions, and images.  
**Expected outcomes:** server-owned categories/items/variants/modifiers/availability, managed images, cache policy, admin ownership boundary.  
**Completion criteria:** UI reads real catalogue data; unavailable/changed items handled; no mock pricing/rating remains; storage policies validated.  
**Status:** Not started; UI and mock models exist. Recommended next database task.  
**Risks:** modelling current placeholder assumptions as permanent schema; image abuse; stale availability; oversized payloads.

## Phase 5 — Cart/quote/order integration

**Goal:** turn the in-memory checkout demo into authoritative ordering.  
**Expected outcomes:** client cart mapped to server quote, validated totals, idempotent order creation, schedule/pickup rules if approved, persisted history, operational status updates.  
**Completion criteria:** tampered client prices/totals are ignored; duplicate submissions are safe; order numbers/statuses are server-issued; customer and staff workflows interoperate; failure/retry tests pass.  
**Status:** Not started; local cart/checkout UI exists.  
**Risks:** price tampering, duplicate orders, stale menu configuration, payment ambiguity, no staff fulfillment surface.

## Phase 6 — Loyalty/rewards/vouchers integration

**Goal:** establish an auditable server-owned loyalty ledger and entitlement lifecycle.  
**Expected outcomes:** points/stamps ledger, balances, reward catalogue, voucher issue/use/expiry, idempotent redemption, eligibility enforcement.  
**Completion criteria:** balance derives from authoritative ledger; customers cannot self-grant value; voucher consumption is atomic and authorized; history/audit trail exists; concurrency tests pass.  
**Status:** Not started; display/redeem-placeholder UI exists.  
**Risks:** fraud, replay, double-spend, expiry disputes, inconsistent business rules, offline stale balances.

## Phase 7 — POS/admin operational integration

**Goal:** provide the trusted operational workflows needed to fulfill customer features.  
**Expected outcomes:** staff order queue/status, member lookup/QR verification, voucher use, menu availability, student verification, promotions, admin roles and audit events.  
**Completion criteria:** separate role authorization is tested; staff/admin actions are auditable; customer order/loyalty states update from real operations; deployment ownership is documented.  
**Status:** Not started; no application is present.  
**Risks:** role escalation, overly broad service access, QR impersonation, conflicting app contracts, unclear repository ownership.

## Phase 8 — reporting, marketing, hardening, UAT and deployment prep

**Goal:** make the integrated system operable, measurable, secure, and releasable.  
**Expected outcomes:** reporting/export, approved campaigns, accessibility/performance/offline review, observability, backup/restore validation, UAT, signed native builds, deployment/runbooks.  
**Completion criteria:** agreed KPIs and privacy/retention rules; security/advisor findings resolved; full suites and UAT pass; golden changes reviewed; incident/recovery/deployment handoff accepted.  
**Status:** Not started.  
**Risks:** privacy leakage, misleading analytics, untested recovery, unsigned/debug builds, visual regression drift, operational support gaps.

## Current recommended next task

`TASK-DB-002: Design and migrate the published menu/catalogue foundation with public read policy, admin ownership boundary, and image/storage decision.`

Do not start Flutter feature wiring until the target schema and RLS posture for that feature are accepted.