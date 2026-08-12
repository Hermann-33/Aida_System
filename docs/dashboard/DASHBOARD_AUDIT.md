# POS/Admin Dashboard Audit

**Source audit:** TASK-MENU-001 validation, 2026-08-13, commit `238e0ff211fe550f42ec4d4423724e3642282295`
**Repository:** `Hermann-33/Aida_System-Dashboard`
**Verdict:** shared catalogue browsing/administration integrated; broader dashboard remains preview and not production-transactional.

## Runtime

React 19.2.7, TypeScript 6.0.3, Vite 8.1.5, React Router DOM 7.18.1, Tailwind CSS 4, Radix/shadcn-style components, TanStack Query provider/Table, Vitest and Playwright. npm with lockfile.

## Major surfaces

- Employee access, terminal enrolment and role selection.
- POS sale/cart/modifiers/member lookup/rewards/payments/receipts/orders/shifts/terminal/help.
- Admin overview, sales/transactions/member reports, branches/locations, terminals, shifts, employees/access, menu/catalogue, inventory, loyalty, marketing, audit, integrations and settings.

## Current data model

The app is intentionally preview-first outside catalogue. Admin and POS catalogue browsing use the shared Supabase catalogue through the same-origin BFF, and Admin mutations use the authenticated caller JWT. No runtime fallback to `PREVIEW_MENU`, `PREVIEW_CATEGORIES`, or `PREVIEW_MODIFIER_GROUPS` remains. Most other operational data comes from deterministic fixtures, component/module memory or `sessionStorage`.

The browser does not receive a service-role credential or call Supabase directly. The BFF uses the publishable key/caller session and RLS/security-invoker RPCs.

## Critical non-authoritative behavior

- Client-calculated POS price/reward outcomes.
- Local/generated receipt/order IDs.
- Simulated member QR scan.
- Simulated cash/non-cash payment state.
- Preview manager PIN approval and local action log.
- Non-durable orders, shifts, cash moves and held tickets.
- Session-only admin mutations for employees/branches/terminals/inventory/marketing.
- Fixture reports, statistics, audit rows and loyalty balances.

## Verification baseline

- lint passed;
- typecheck passed;
- 85 tests passed;
- build passed;
- preview E2E 6/6 passed;
- public catalogue BFF returned 4 categories / 16 items / 27 variants;
- anonymous Admin endpoints returned 401, cross-origin mutations returned 403, and authenticated non-admin catalogue mutation was rejected;
- Supabase security advisor returned 0 lints;
- deployed Auth/Menu cross-client E2E was not run because real identities and deployment are absent.

## Backend dependency

Real operation still requires shared server authority for employee/session/branch/terminal scope, trusted quote/order pricing, orders, payments/refunds, member lookup, loyalty/vouchers, shifts/cash, inventory, marketing, reporting and immutable audit. The integrated browsing catalogue does not make preview checkout/totals/orders/payments authoritative. See `BACKEND_INTEGRATION_PLAN.md` and `SHARED_BACKEND_CONTRACT.md`.
