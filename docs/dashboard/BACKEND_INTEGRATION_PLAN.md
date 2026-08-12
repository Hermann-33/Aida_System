# POS/Admin Backend Integration Plan

Updated: 2026-08-13

## Deployment/Auth boundary

The Vercel project and a clean `READY` preview deployment exist. Its BFF remains unavailable there until an operator configures `AIDA_SUPABASE_URL` and `AIDA_SUPABASE_PUBLISHABLE_KEY`. No service-role key is required or allowed.

For local demo/frontend work, the dashboard can run locally against the same cloud Supabase once an approved employee identity exists. Preserve the existing same-origin HttpOnly session model; never add browser-local employee bearer tokens for convenience.

## Admin + POS catalogue — integrated

Admin Menu uses the shared catalogue BFF for trusted management. POS browsing uses the same published catalogue for categories, availability, base display prices, per-item variants and compatible add-ons. There is no runtime preview-catalogue fallback.

## Orders and scheduled pickup — BFF ready, React integration next

ADR-0010 and `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` are authoritative.

New same-origin endpoints:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

All employee mutations validate the existing HttpOnly employee session, forward the caller JWT to Supabase and require same origin. No service-role credential or browser-readable employee JWT is part of the integration.

### POS integration

1. Keep current POS cart/customization interaction as **selection state**.
2. Build quote payloads from shared catalogue item/variant/add-on IDs, quantities and notes only.
3. Offer ASAP / Schedule for later using `/api/v1/orders/policy`.
4. Generate schedule slots from backend `serverNow` + timezone/lead/interval/horizon rather than a browser-clock-only hardcode.
5. POST the selections to `/api/v1/orders/quote` and render the returned authoritative subtotal/total/line breakdown.
6. On place, generate a UUID `clientRequestId`. Reuse it for retries of the same intended order; use a new UUID for a new order.
7. POST to `/api/v1/orders/place`. Persisted order number, total, schedule and status come from the response.
8. Do not persist preview/local cart totals as trusted order totals.
9. Clear/reset the sale only after the backend confirms successful placement.

Current POS placement is a guest-order boundary. Do not invent customer/member association from browser input in this frontend task.

### Live staff order board

Use `/api/v1/orders` as the queue source and display the persisted statuses:

- Scheduled
- Confirmed/New
- Preparing
- Ready

Completed/cancelled orders may be presented in an existing history/secondary surface if it fits the current UI; do not redesign the entire POS around them.

Scheduled entries should visibly show their requested pickup time and be ordered using the server response order. Staff actions must call `/api/v1/orders/status` with the current `statusVersion` as `expectedVersion`.

Handle `ORDER_VERSION_CONFLICT` (HTTP 409) by refetching the order/queue and telling the staff member the order changed; never overwrite with a stale UI state.

### Queue refresh model

The employee JWT intentionally remains HttpOnly, so React cannot safely open a caller-authenticated Supabase Realtime channel without breaking ADR-0008.

For this demo frontend:

- use TanStack Query/the existing query layer against `/api/v1/orders`;
- use a short, reasonable refetch interval such as 2–3 seconds while the order board is active;
- invalidate/refetch immediately after local place/status mutations;
- do not expose or copy the employee access token into browser JavaScript merely for Realtime.

Customer Flutter uses direct owner-scoped `orders` Realtime, so staff status updates still appear immediately on the customer side.

## Scheduling policy

Current backend defaults:

- timezone `Asia/Kuala_Lumpur`
- 15-minute minimum lead
- 15-minute slots
- 7-day maximum advance

Branch opening hours/closures/capacity are not modeled. Do not add UI claims that a slot is branch-capacity-approved.

Admin schedule-policy mutation is already available at `/api/v1/admin/orders/policy`. A dedicated settings UI is optional for the demo unless it fits an existing Admin settings surface cleanly; do not create a major new settings redesign just to expose it.

## Payment boundary

No real payment processor exists. The frontend should use an explicit `Pay at counter`/unpaid demo path and remove/disable transaction copy that implies Card/E-wallet/Student Wallet has been successfully settled.

Fulfilment completion is not proof of payment settlement.

## Design constraint

This task is a **frontend integration, not a visual redesign**. Before editing, inspect the existing POS/Admin theme tokens, component primitives, cards, tables/queues, dialogs/sheets, buttons, status badges, spacing/radii/shadows, responsive behavior and Playwright/component tests. New order/schedule surfaces must look native to the existing AIDA dashboard.

Do not introduce a second design system, new global palette, arbitrary status colors, unrelated iconography, typography replacements, or broad layout restyling.

## Validation after frontend implementation

Run at minimum:

- `npm ci`
- `npm run lint`
- `npm run typecheck`
- `npm test`
- `npm run build`
- `npm run test:e2e`
- focused order BFF/client/queue/status/checkout tests
- `git diff --check`

Also confirm legacy token/localStorage assertions still pass and no service-role/browser staff token was introduced.
