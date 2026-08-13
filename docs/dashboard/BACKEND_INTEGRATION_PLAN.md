# POS/Admin Backend Integration Plan

Updated: 2026-08-14

## Runtime/Auth boundary — integrated for local demo

The current validated demo topology is local Dashboard PC -> cloud Supabase -> installed Android customer app.

Real trusted employee identities now exist. Owner/Admin sign-in uses the same-origin employee BFF with HttpOnly cookies; the BFF validates trusted `user_profiles.app_role`/`disabled_at` and forwards the caller JWT to Supabase. No service-role key or browser-local employee bearer token is required or allowed.

The user has validated a real Owner session by loading protected Members/Menu and mutating the shared catalogue.

A historical Vercel project/deployment exists, but hosted BFF runtime configuration was not completed. Hosted deployment is deferred operational work for the accepted local-demo closeout and must not be described as production-complete.

## Members — integrated and live-validated

Protected Admin/owner Members uses `/api/v1/admin/members` through the caller-JWT BFF/RLS path. Preview mode does not fabricate or request privileged member data.

The user physically created a new Android customer and observed that customer in Dashboard Members, proving customer Auth provisioning -> trusted member -> protected Admin directory.

## Admin + POS catalogue — integrated and live-validated

Admin Menu uses the shared catalogue BFF for trusted management. POS browsing uses the same published catalogue for categories, availability, base display prices, per-item variants and compatible add-ons. There is no runtime preview-catalogue fallback.

The user changed a real catalogue price through a trusted Owner session and observed the updated value in the installed Android customer app.

## Preview/live session separation — integrated

TASK-AUTH-005 is complete for its bounded regression:

- preview identity remains local/non-authoritative;
- live BFF 401 handling no longer destroys preview identity;
- preview Members stays mounted without a privileged member request;
- preview Menu uses public catalogue read-only with no write controls;
- real Admin session expiry still clears real employee state.

## Orders and scheduled pickup — BFF implemented, React integration is current closeout work

ADR-0010 and `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` are authoritative.

Existing same-origin endpoints:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

All employee mutations validate the existing HttpOnly employee session, forward the caller JWT to Supabase and require same origin. No service-role credential or browser-readable employee JWT is part of the integration.

### Required live POS integration

1. Keep current POS cart/customization interaction as **selection state** only.
2. Build quote payloads from shared catalogue item/variant/add-on IDs, quantities and notes only.
3. Offer ASAP / Schedule for later using `/api/v1/orders/policy`.
4. Generate schedule choices from server policy/timezone/lead/interval/horizon rather than browser-clock hardcodes.
5. POST selections to `/api/v1/orders/quote` and render the returned authoritative line/subtotal/total.
6. Create one UUID `clientRequestId` for a placement intent and reuse it for retries of that same order.
7. POST to `/api/v1/orders/place`; persisted order number, total, schedule and status come from the server response.
8. Never persist preview/local cart totals as trusted order totals.
9. Clear/reset the sale only after successful backend placement; retain it on failure.
10. Current POS placement is a guest-order boundary; do not invent member attachment from browser preview input.

### Live staff order board

The live Orders rail must use `/api/v1/orders`, not `PREVIEW_TRANSACTIONS`, and present persisted Scheduled/Confirmed/Preparing/Ready state plus terminal history where appropriate.

Staff transitions call `/api/v1/orders/status` with current `statusVersion` as `expectedVersion`.

HTTP 409 version conflict must refetch and tell the operator the order changed; stale UI state must not overwrite newer persisted state.

### Queue refresh model

The employee JWT intentionally remains HttpOnly. React must not weaken ADR-0008 to obtain direct Supabase Realtime.

For the current demo:

- use TanStack Query/existing query layer against `/api/v1/orders`;
- use short polling/refetch around 2–3 seconds while the order board is active;
- invalidate/refetch immediately after local place/status mutations;
- refetch on focus/reconnection where supported;
- never expose/copy the employee access token into browser JavaScript.

Customer Flutter uses owner-scoped `orders` Realtime, so a persisted staff transition emits the backend change the customer can refetch.

## Scheduling policy

Current backend defaults:

- timezone `Asia/Kuala_Lumpur`
- 15-minute minimum lead
- 15-minute slots
- 7-day maximum advance

Branch opening hours/closures/capacity are not modeled. Do not present any slot as branch-capacity-approved.

Admin schedule-policy mutation is available at `/api/v1/admin/orders/policy`. A new major settings redesign is not required merely to expose it during closeout.

## Payment boundary

No trusted payment processor exists. The authoritative demo order path must use explicit `Pay at counter`/unpaid semantics and must not present Card/E-wallet/Student Wallet/cash settlement/refund as completed processor truth.

Fulfilment completion is not payment-settlement evidence.

## Closeout validation

After React order integration run at minimum:

- `npm ci`
- `npm run lint`
- `npm run typecheck`
- `npm test`
- `npm run build`
- `npm run test:e2e`
- focused order client/quote/place/queue/status/version-conflict tests
- `git diff --check`
- production secret/token scans

Final tranche E2E must prove customer authoritative placement -> persisted order -> Dashboard queue/status transition -> customer authorized status refresh. Dated shared evidence is in `docs/context/CLOSEOUT_EVIDENCE_2026-08-14.md`.
