# POS/Admin Fragile Boundaries

## High-risk areas

- `src/App.tsx` and `ProtectedRoute`: product routing/session assumptions; UI guard is not authorization.
- `src/auth/`: employee session, permission and terminal credential adapters; production credential semantics must not regress to browser tokens.
- `src/pages/EmployeeWelcomePage.tsx` / `PosShellPage.tsx`: live staff access must remain independent of deferred terminal/shift endpoints; preview repositories must stay behind `VITE_UI_PREVIEW_MODE`.
- `src/features/orders/orderClient.ts` / `orderWorkloads.ts`: `scheduleState` and `prepareAt` are server projections. Do not recreate them from local time, default malformed values, add statuses or auto-transition.
- `src/preview/`: fixture IDs/data shape many screens; never promote fixtures as business truth.
- POS counter/cart/modifier/payment/receipt flow: client pricing, rewards and identifiers are currently simulated.
- Manager approval/void/refund/cancel: local preview approval is not a trusted privilege boundary.
- Shift/cash state: module/local state does not survive reload and has no reconciliation.
- Member scan/search: fixture lookup and timed QR simulation can bias real privacy/lookup design.
- Admin employee/branch/terminal/menu/inventory/marketing pages: session-only mutations may imply schemas and permissions that are not approved.
- Reporting/audit pages: sample aggregates/events must not become financial/audit definitions.
- Preview/live build gates: production must remain fail-closed against preview/auth bypass.

## Cross-repo fragility

Dashboard concepts that must stay contract-compatible with the customer app include member code, verification, catalogue IDs, price/modifiers, order IDs/statuses, payment status, rewards/vouchers and promotions.

## Change rules

- Define server authority before replacing preview repositories.
- Add branch/role/terminal authorization tests before enabling mutations.
- Keep terminal/shift rails preview-only until their authoritative schema/BFF task exists; do not restore them as live POS prerequisites.
- Introduce real POS writes in slices: session/terminal -> catalogue -> quote/order -> payment/status -> loyalty.
- Preserve explicit preview labeling until each path has trusted persistence.
- Do not silently change shared lifecycle strings/IDs without a coordinated contract task.
