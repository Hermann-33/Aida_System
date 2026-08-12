# AIDA Café Security Review

Updated: 2026-08-13
**Verdict:** catalogue authority is hardened; overall product remains pre-release and partially validated.

## Catalogue controls

- Forced RLS on all catalogue tables.
- Anonymous/customer access is read-only and publication-scoped.
- Admin/owner mutation RPCs are `SECURITY INVOKER` and explicitly check trusted DB role state.
- Dashboard mutations use the administrator caller JWT through the same-origin HttpOnly-session BFF; no service-role bypass.
- State-changing BFF catalogue routes require same origin.
- Catalogue audit table has no ordinary client table grant.
- `catalogue_revision` is read-only to clients and used only for invalidation.
- Server owns UUIDs/slugs and validates price ranges, item kinds, routes, variant defaults and add-on targets.
- Customer runtime has no hardcoded production menu fallback.
- Live Supabase security advisor: 0 lints after customer closeout validation.
- Canonical Auth/member and catalogue authorization regressions pass transactionally, including signup-metadata tamper resistance, customer mutation denial, unpublished-item hiding, audit evidence and rollback cleanup.
- Performance advisor reports six unused-index INFO notices only; none justified a validation-time index removal.

## Remaining release gates

Flutter analysis and all 32 tests pass, including reviewed visual baselines and user-isolated minimum offline member-code caching. Dashboard lint/typecheck/85 tests/build and Playwright 6/6 pass at commit `238e0ff211fe550f42ec4d4423724e3642282295`; its anonymous/cross-origin/non-admin mutation checks and security advisor also pass. Deployed customer Auth and Admin-write -> customer-Realtime E2E remain open because real identities and deployment are absent. Quote/order/payment authority is not implemented; preview checkout, totals, orders, payments, and local cart arithmetic cannot be trusted for persistence.

TASK-AUTH-003 preflight additionally confirmed that anonymous catalogue-mutation and Admin-member RPC calls fail closed with HTTP 404, and no service-role/secret-key marker exists in Flutter source/config or the compiled release web build. Customer-session authorization negatives cannot be claimed until an approved customer identity exists.
