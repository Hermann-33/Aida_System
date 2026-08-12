# AIDA Café Security Review

Updated: 2026-08-12
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
- Live Supabase security advisor: 0 lints after forward RLS hardening.

## Remaining release gates

Client analyzer/lint/typecheck/tests/build and deployed cross-client E2E remain deferred. Quote/order/payment authority is not implemented; local cart totals cannot be trusted for payment/order persistence. Auth deployment/admin bootstrap validation also remains open.
