# POS/Admin Dashboard Audit

## Current-state note — 2026-08-14

The original source audit below was performed during TASK-MENU-001 and is historical baseline evidence, not current product status. Current project truth is in `docs/context/ACTIVE_CONTEXT.md`, `CLOSEOUT_EVIDENCE_2026-08-14.md`, `SUPABASE_STATUS.md`, `ROADMAP.md` and the accepted ADR/contracts.

Material changes since the original audit:

- real Owner/Admin/Staff Supabase identities now exist;
- same-origin employee/Admin Auth BFF is implemented with HttpOnly session cookies;
- protected Admin Members is live and a physical Android signup has been observed there;
- shared Admin/POS catalogue integration is live and a real Owner price mutation propagated to the installed Android customer app;
- TASK-AUTH-005 fixed the preview/live Admin session-loop regression;
- authoritative order/scheduling backend and Dashboard order BFF/API endpoints are implemented;
- customer Flutter authoritative order integration is implemented;
- Dashboard React authoritative POS quote/place/order-board/status integration remains TASK-CLOSEOUT-001 work;
- current Supabase security advisor has one hosted Auth warning (`auth_leaked_password_protection`) rather than a current zero-finding result.

Do not use the historical zero-identity/revision-1 statements below as current evidence.

---

## Historical source audit — TASK-MENU-001, 2026-08-13

**Source commit:** `238e0ff211fe550f42ec4d4423724e3642282295`
**Repository:** `Hermann-33/Aida_System-Dashboard`
**Historical verdict:** shared catalogue browsing/administration integrated; broader dashboard preview-first.

### Runtime

React 19.2.7, TypeScript 6.0.3, Vite 8.1.5, React Router DOM 7.18.1, Tailwind CSS 4, Radix/shadcn-style components, TanStack Query provider/Table, Vitest and Playwright. npm with lockfile.

### Major surfaces

- Employee access, terminal enrolment and role selection.
- POS sale/cart/modifiers/member lookup/rewards/payments/receipts/orders/shifts/terminal/help.
- Admin overview, sales/transactions/member reports, branches/locations, terminals, shifts, employees/access, menu/catalogue, inventory, loyalty, marketing, audit, integrations and settings.

### Historical data model at that audit

The application was preview-first outside catalogue. Admin and POS catalogue browsing used the shared Supabase catalogue through the same-origin BFF, and Admin mutations used the authenticated caller JWT. No runtime fallback to `PREVIEW_MENU`, `PREVIEW_CATEGORIES` or `PREVIEW_MODIFIER_GROUPS` remained. Most other operational data came from deterministic fixtures, component/module memory or `sessionStorage`.

The browser did not receive a service-role credential or call Supabase directly with a privileged server token. The BFF used publishable project configuration plus caller session/RLS/security-invoker RPCs.

### Historical critical non-authoritative behavior

At that point the audit identified:

- client-calculated POS price/reward outcomes;
- local/generated receipt/order IDs;
- simulated member QR scan;
- simulated cash/non-cash payment state;
- preview manager PIN approval and local action log;
- non-durable orders, shifts, cash moves and held tickets;
- session-only admin mutations for employees/branches/terminals/inventory/marketing;
- fixture reports/statistics/audit rows/loyalty balances.

Later tasks have replaced some but not all of those boundaries. Current placeholder truth is maintained in `MOCKS_AND_PLACEHOLDERS.md` and current task/status docs.

### Historical verification baseline

- lint passed;
- typecheck passed;
- 85 tests passed;
- build passed;
- preview E2E 6/6 passed;
- public catalogue BFF returned 4 categories / 16 items / 27 variants;
- anonymous Admin endpoints returned 401, cross-origin mutations returned 403, and authenticated non-admin catalogue mutation was rejected;
- Supabase security advisor returned 0 lints at that historical time.

Those measurements remain audit history; current live counts/security state are documented separately.
