# POS/Admin Backend Integration Plan

Updated: 2026-08-17

## Deployment/Auth boundary

The validated current demo topology is local Dashboard PC → cloud Supabase → installed Android customer app.

Employee/Admin authentication uses the same-origin BFF with HttpOnly cookies, trusted profile role/disabled-state validation and caller-JWT Supabase access. No service-role key or browser-local employee bearer token is required or allowed.

A historical Vercel `READY` deployment exists, but hosted BFF runtime configuration is not complete. Hosted deployment remains **DEFERRED** and is not a blocker for the accepted local-demo tranche.

## Members — integrated and validated

Protected Admin Members uses the same-origin BFF/RLS path. Preview mode does not fabricate or request privileged member data.

Physical validation proved a new Android customer signup → trusted profile/member provisioning → the new member appearing in Dashboard Members.

## Admin + POS catalogue — integrated and validated

Admin Menu uses the shared catalogue BFF for trusted management. POS browsing uses the same published catalogue for categories, availability, base display prices, per-item variants and compatible add-ons. There is no runtime preview-catalogue fallback.

A real Owner changed a catalogue price through Admin Menu and the installed Android customer app observed the changed value after the revision/refetch flow.

## Orders and scheduled pickup — integrated and validated

ADR-0010 and `docs/contracts/ORDER_AND_SCHEDULING_CONTRACT.md` are authoritative.

Same-origin endpoints:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

All employee mutations validate the HttpOnly employee session, forward the caller JWT and require same origin.

### POS integration

The active POS order path:

1. keeps cart/customization as selection state only;
2. sends catalogue item/variant/add-on IDs, quantities and notes;
3. offers ASAP/Schedule for later from `/api/v1/orders/policy`;
4. derives schedule slots from server time/policy;
5. renders `/api/v1/orders/quote` as commercial authority;
6. keeps one UUID `clientRequestId` across retries of the same placement;
7. persists through `/api/v1/orders/place`;
8. clears the sale only after successful persistence;
9. uses server order number/total/schedule/status;
10. uses explicit `Pay at counter`/unpaid semantics.

Current POS placement is a guest-order boundary; the browser does not invent customer/member association.

### Live staff order board

`/api/v1/orders` is the live queue source. The board presents persisted Scheduled/Confirmed/Preparing/Ready states and terminal history where appropriate.

Staff actions call `/api/v1/orders/status` with current `statusVersion` as `expectedVersion`. HTTP 409 version conflict triggers refetch rather than stale overwrite.

### Queue refresh model

The employee JWT remains HttpOnly. React does not open a direct caller-authenticated Supabase Realtime connection.

The implemented board:

- uses TanStack Query against `/api/v1/orders`;
- refetches every 2.5 seconds while active;
- invalidates after place/status mutations;
- refetches on supported focus/reconnection paths;
- never exposes/copies the employee access token to browser JavaScript.

Customer Flutter uses owner-scoped `orders` Realtime and authorized refetch.

## Final cross-client order validation

On 2026-08-17 the supported live path completed:

- customer authenticated with one active member;
- Sandwich quoted ASAP at 1,290 sen;
- `place_customer_order` persisted order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) as `confirmed` v1;
- authenticated Owner Dashboard queue observed the exact order;
- Dashboard persisted `preparing` v2, `ready` v3 and `completed` v4;
- customer-authorized `get_order` reads observed every transition.

One completed order remains retained as closeout evidence.

## Validation baseline

Final Dashboard closeout checks:

- lint: PASS with two established Fast Refresh warnings;
- typecheck: PASS;
- Vitest: PASS, 25 files / 111 tests;
- build: PASS;
- Playwright: PASS, 8/8;
- `npm audit`: PASS, 0 vulnerabilities;
- `git diff --check`: PASS;
- credential/secret safety checks: PASS.

## Scheduling policy

Current defaults:

- timezone `Asia/Kuala_Lumpur`
- 15-minute minimum lead
- 15-minute slots
- 7-day maximum advance

Branch opening hours/closures/capacity are not modeled.

## Payment boundary

No real payment processor exists. The authoritative current path is `Pay at counter`/unpaid. Fulfilment completion is not proof of payment settlement.

## Deferred Dashboard domains

Trusted payment/refunds, loyalty, inventory, branch scope/hours/capacity, shifts/cash authority, reporting/revenue, promotions/marketing publication, tax/accounting, delivery and hosted production deployment remain separate bounded tasks.
