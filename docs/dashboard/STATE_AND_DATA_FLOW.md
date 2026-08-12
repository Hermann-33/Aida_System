# POS/Admin State and Data Flow

## Application shell

`src/App.tsx` mounts a TanStack `QueryClientProvider` and React Router. `ProtectedRoute` controls user-facing navigation for employee, POS and admin product scopes. These guards are not a backend authorization boundary.

## Current state sources

- React `useState`/`useMemo` for most page and POS workflow state.
- Module-level external employee session store consumed with `useSyncExternalStore`.
- `sessionStorage` for preview identity and terminal enrolment state.
- Module memory for preview shift state.
- Deterministic fixtures under `src/preview/`, especially catalogue/transactions/members/org data.
- TanStack Query is configured but no production query/mutation layer currently owns application data.

## POS flow today

Preview catalogue -> client modifier validation/price calculation -> local cart/held ticket -> optional fixture member/reward selection -> simulated tender/payment -> generated local receipt/order -> local orders/action state.

None of these outcomes are durable shared records.

## Admin flow today

Preview fixtures -> derived reports/tables -> selected pages copy values into React state -> local add/edit/toggle/transfer/publish simulations. Reload/remount loses many mutations.

## Employee/terminal flow

Preview identity and terminal adapters support local session simulation. Non-preview code anticipates credentialed same-origin HTTP sessions and HttpOnly terminal credentials, but a live shared backend is not currently available.

## Real connection direction

Introduce capability-specific data/services backed by the shared contract. TanStack Query can own server query/mutation cache if retained. Route guards consume verified session/role/branch state, while RLS/server operations independently authorize each request. POS mutation flows require idempotency and reconciliation semantics; admin writes require audit and stale/conflict handling.