# Shared Backend Contract

Updated: 2026-08-13

## Authority

Supabase Auth/Postgres/RLS plus controlled BFF/RPC operations are authoritative. Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/` unless a future accepted ADR changes ownership.

Clients are never authority for identity, role, member IDs/codes, catalogue IDs/prices, order totals, order numbers, fulfilment status, payment state, loyalty value, inventory, or reporting truth.

## Identity/member contract

- Supabase Auth identity is the trusted user identity.
- `user_profiles.app_role` plus `disabled_at` are trusted employee/admin authorization state.
- `members` is the trusted customer membership record.
- Public signup cannot self-assign employee/admin role, member code, verification result, or other privileged state.
- Customer reads remain owner-scoped; staff/admin access uses explicit trusted boundaries.

## Catalogue contract

- Category/item/variant/add-on IDs are server-owned UUIDs.
- Catalogue prices and variant deltas are integer sen.
- Customer/public reads use `get_catalogue()` under RLS.
- Public/customer clients see active categories and published items only.
- Admin/owner writes use `save_catalogue_category(jsonb)` and `save_catalogue_item(jsonb)` with caller JWT.
- `catalogue_revision` is an invalidation signal; clients re-fetch authoritative state after it changes.
- Unpublished items are not customer-visible; availability is a distinct sold-out state.
- Compatible add-ons are normalized server links; category names never authorize add-ons.
- Ratings and loyalty bonus values are not catalogue fields.

## Order / quote contract

ADR-0010 and `ORDER_AND_SCHEDULING_CONTRACT.md` define the detailed order API.

The trusted order payload contains selection and intent only:

- `clientRequestId` for idempotent placement;
- `fulfillmentType` = `asap` or `scheduled`;
- `requestedPickupAt` only for scheduled orders;
- catalogue item ID;
- variant ID when required;
- compatible add-on IDs;
- quantity;
- optional line note.

`quote_order(jsonb)` is the shared pricing validator for customer and POS channels. It re-checks current catalogue publication/availability, active category state, variant ownership/availability, compatible add-ons, quantity/note bounds, and schedule policy. Any client-supplied name/price/subtotal/total is ignored.

Customer placement uses `place_customer_order(jsonb)` and derives customer/member identity from the authenticated session plus active member record.

POS placement uses `place_pos_order(jsonb)` and requires staff-or-above. Current POS placement is a guest-order boundary; customer/member attachment is not client-invented.

Persisted `orders`, `order_lines`, and `order_line_addons` contain server-owned order identity and immutable commercial snapshots so later catalogue edits cannot rewrite historical order content.

## Scheduling contract

Server scheduling defaults:

- timezone `Asia/Kuala_Lumpur`;
- enabled;
- minimum lead 15 minutes;
- 15-minute slots;
- maximum advance 7 days.

The backend validates server-relative lead/horizon and local slot alignment. Branch-specific opening hours/closures/capacity are not authoritative yet and must not be invented by clients.

Admin/owner may update the scheduling singleton through the trusted `save_ordering_policy(jsonb)` boundary.

## Fulfilment contract

Persisted states:

`confirmed`, `scheduled`, `preparing`, `ready`, `completed`, `cancelled`.

Legal staff transitions:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

`completed` and `cancelled` are terminal. Status mutation requires staff-or-above and an expected `statusVersion`; stale concurrent transitions fail.

`order_events` is append-only evidence for creation/status changes.

## Realtime contract

`supabase_realtime` publishes only mutable invalidation/status surfaces required by current clients:

- `catalogue_revision`
- `orders`

After an authorized `orders` change, clients re-fetch the full authorized snapshot. Immutable line/add-on tables are not separately published.

## Dashboard BFF contract

Privileged dashboard browser flows use the same-origin BFF from ADR-0008:

- HttpOnly employee access/refresh cookies;
- Secure cookies on HTTPS;
- server validation of trusted employee role/disabled state;
- caller JWT forwarded to Supabase;
- same-origin protection for state-changing requests;
- no browser-readable staff bearer-token persistence;
- no service-role credential in Vite/browser code.

Current order BFF endpoints:

- `GET /api/v1/orders/policy`
- `GET /api/v1/orders`
- `GET /api/v1/orders/detail?id=<uuid>`
- `POST /api/v1/orders/quote`
- `POST /api/v1/orders/place`
- `POST /api/v1/orders/status`
- `POST /api/v1/admin/orders/policy`

## Payment boundary

There is no trusted payment processor/payment state in TASK-DEMO-ORDER-001. A demo frontend may use an explicit `Pay at counter`/unpaid path, but it must not claim that Card, E-wallet, Student Wallet, or any other processor transaction succeeded.

Order completion currently means fulfilment completion, not verified payment settlement.

## Deferred downstream authority

The following remain separate bounded tasks and must consume trusted order/payment state later rather than browser values:

- payment capture/refunds
- loyalty earning/redemption
- inventory depletion
- promotions/discount engine
- tax/accounting
- revenue/reporting
- branch-specific scheduling/capacity
- delivery
