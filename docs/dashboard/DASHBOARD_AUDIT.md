# POS/Admin Dashboard Audit

**Source audit:** TASK-WF-002, 2026-08-12
**Repository:** `Hermann-33/Aida_System-Dashboard`
**Verdict:** broad frontend preview; not backend-connected or production-transactional.

## Runtime

React 19.2.7, TypeScript 6.0.3, Vite 8.1.5, React Router DOM 7.18.1, Tailwind CSS 4, Radix/shadcn-style components, TanStack Query provider/Table, Vitest and Playwright. npm with lockfile.

## Major surfaces

- Employee access, terminal enrolment and role selection.
- POS sale/cart/modifiers/member lookup/rewards/payments/receipts/orders/shifts/terminal/help.
- Admin overview, sales/transactions/member reports, branches/locations, terminals, shifts, employees/access, menu/catalogue, inventory, loyalty, marketing, audit, integrations and settings.

## Current data model

The app is intentionally preview-first. Most operational data comes from deterministic fixtures, component/module memory or `sessionStorage`. Planned non-preview adapters expect HTTP/session/terminal APIs, but the intended shared Supabase backend is not implemented behind them.

No Supabase SDK, migration, RLS policy or direct Supabase call exists in the dashboard source.

## Critical non-authoritative behavior

- Client-calculated POS price/reward outcomes.
- Local/generated receipt/order IDs.
- Simulated member QR scan.
- Simulated cash/non-cash payment state.
- Preview manager PIN approval and local action log.
- Non-durable orders, shifts, cash moves and held tickets.
- Session-only admin mutations for employees/branches/terminals/menu/inventory/marketing.
- Fixture reports, statistics, audit rows and loyalty balances.

## Verification baseline

- lint passed with 5 warnings;
- typecheck passed;
- 62 tests across 14 files passed;
- build passed with bundle-size warning;
- preview E2E 6/6 passed;
- API-backed E2E not run because backend environment is unavailable;
- dependency audit: 1 moderate and 4 high findings, unresolved by design in import task.

## Backend dependency

Real operation requires shared server authority for employee/session/branch/terminal scope, catalogue/pricing, orders, payments/refunds, member lookup, loyalty/vouchers, shifts/cash, inventory, marketing, reporting and immutable audit. See `BACKEND_INTEGRATION_PLAN.md` and `SHARED_BACKEND_CONTRACT.md`.