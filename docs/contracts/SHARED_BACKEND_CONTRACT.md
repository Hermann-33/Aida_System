# Shared Backend Contract

Updated: 2026-08-20

## Authority

Supabase Auth/Postgres/RLS plus controlled BFF/RPC operations are authoritative. Canonical executable migrations live only in `Hermann-33/Aida_System/supabase/` unless a future accepted ADR changes ownership.

Clients are never authority for identity, role, member IDs/codes, catalogue IDs/prices, order totals, order numbers, scheduling preparation authority, fulfilment status, payment state, loyalty value, inventory or reporting truth.

## Identity/member contract

- Supabase Auth identity is the trusted user identity.
- `user_profiles.app_role` plus `disabled_at` are trusted employee/admin authorization state.
- `members` is the trusted customer membership record.
- Public signup cannot self-assign employee/admin role, member code, verification result or other privileged state.
- Customer reads remain owner-scoped; staff/admin access uses explicit trusted boundaries.
- Employee identities are distinct from customer/member records.

The current trusted staff account can authenticate independently of deferred terminal/branch/shift domains. UI terminal/shift state must not become an authorization substitute.

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

Clients must not submit or trust their own `prepareAt`, `scheduleState`, item names, prices, subtotals, totals, order numbers, customer/member identity or fulfilment status.

`quote_order(jsonb)` remains the shared pricing/schedule validator for customer and POS channels. It re-checks current catalogue publication/availability, active category state, variant ownership/availability, compatible add-ons, quantity/note bounds and customer-selectable scheduling policy. Client-supplied price/total fields are ignored.

Customer placement uses `place_customer_order(jsonb)` and derives customer/member identity from the authenticated session plus active member record.

POS placement uses `place_pos_order(jsonb)` and requires staff-or-above. Current POS placement remains a guest-order boundary; customer/member attachment is not client-invented.

Persisted `orders`, `order_lines` and `order_line_addons` contain server-owned order identity and immutable commercial/scheduling snapshots so later catalogue or preparation-policy edits cannot rewrite historical order truth.

## Scheduling contract

Current live server policy:

- timezone `Asia/Kuala_Lumpur`;
- scheduled ordering enabled;
- customer minimum lead 15 minutes;
- operational preparation lead 15 minutes;
- 15-minute pickup slots;
- maximum advance 7 days.

The backend validates server-relative lead/horizon and local slot alignment. Branch-specific opening hours/closures/capacity are not authoritative yet and must not be invented by clients.

### Minimum lead versus preparation lead

`minimumLeadMinutes` controls the earliest pickup time that may be selected.

`preparationLeadMinutes` controls the server-owned operational preparation window and is constrained by:

```text
0 <= preparationLeadMinutes <= minimumLeadMinutes
```

Admin/owner may update the singleton through the trusted `save_ordering_policy(jsonb)` boundary. Staff may not change policy.

### Per-order preparation snapshot

For scheduled orders the backend persists immutable:

```text
prepareAt = requestedPickupAt - preparationLeadMinutes
```

`prepareAt` is null for ASAP orders and cannot be rewritten later by browser state or by a subsequent policy edit.

Authorized order snapshots expose backend-owned:

- `prepareAt`;
- `serverNow`;
- `scheduleState = future | due | overdue | null`.

For persisted scheduled orders:

```text
requestedPickupAt < serverNow  -> overdue
prepareAt <= serverNow          -> due
otherwise                       -> future
```

This is operational classification only. It is not a new persisted lifecycle status and does not prove that staff started preparation.

## Fulfilment contract

Persisted states remain:

`confirmed`, `scheduled`, `preparing`, `ready`, `completed`, `cancelled`.

Legal staff transitions remain:

```text
confirmed -> preparing | cancelled
scheduled -> preparing | cancelled
preparing -> ready | cancelled
ready -> completed
```

`completed` and `cancelled` are terminal. Status mutation requires staff-or-above and an expected `statusVersion`; stale concurrent transitions fail.

Reaching `prepareAt` must never auto-write `preparing`. A staff action still explicitly persists **Start preparing** through the accepted status RPC.

`order_events` remains append-only evidence for creation/status changes.

## Realtime contract

`supabase_realtime` publishes the mutable invalidation/status surfaces required by current clients:

- `catalogue_revision`;
- `orders`.

After an authorized `orders` change, customer clients re-fetch the full authorized snapshot. Immutable line/add-on tables are not separately published.

The Dashboard does not expose the employee access token to React for direct Supabase Realtime. It uses same-origin BFF polling/refetch for employee order work.

## Dashboard BFF contract

Privileged Dashboard browser flows use the same-origin BFF from ADR-0008:

- HttpOnly employee access/refresh cookies;
- Secure cookies on HTTPS;
- server validation of trusted employee role/disabled state;
- caller JWT forwarded to Supabase;
- same-origin protection for state-changing requests;
- no browser-readable staff bearer-token persistence;
- no service-role credential in Vite/browser code.

Current trusted order endpoints remain:

- `GET /api/v1/orders/policy`;
- `GET /api/v1/orders`;
- `GET /api/v1/orders/detail?id=<uuid>`;
- `POST /api/v1/orders/quote`;
- `POST /api/v1/orders/place`;
- `POST /api/v1/orders/status`;
- `POST /api/v1/admin/orders/policy`.

Dashboard React must consume `preparationLeadMinutes`, `prepareAt`, `serverNow` and `scheduleState` from these trusted responses rather than manufacture preparation authority from local time.

The accepted current order scope is single-café/global staff visibility because branch assignment, terminal authority, sales points and shifts are still deferred. Those missing domains must not block the already-trusted employee Auth + Sale + Orders path, and preview fixtures must not be promoted into production truth.

## Customer client contract

Customer Flutter:

- uses only public/publishable Supabase configuration;
- quotes before placement;
- treats server totals as authority;
- reuses one `clientRequestId` for retry of the same intended placement;
- derives ASAP/scheduled choices from server policy;
- clears the cart only after persisted placement;
- reads persisted order number/history/detail/status;
- uses owner-scoped `orders` Realtime as invalidation and then calls authorized `get_order`/history RPCs;
- does not manufacture fulfilment progress with a local timer.

The additional scheduling snapshot fields are backward-compatible with the current customer decoder; they do not transfer operational or fulfilment authority into Flutter.

## Payment boundary

There is no trusted payment processor/payment state in the current tranche. Frontends use an explicit `Pay at counter`/unpaid path and must not claim that Card, E-wallet, Student Wallet or any other processor transaction succeeded.

Order completion currently means fulfilment completion, not verified payment settlement.

## Validation evidence

TASK-CLOSEOUT-001 remains the credential-backed cross-client proof for the original order lifecycle using retained order `100006`.

TASK-SCHEDULED-OPS-001 adds live backend verification that:

- preparation policy and per-order `prepareAt` are server-owned;
- existing scheduled orders can be classified `overdue` without changing their persisted status;
- idempotent retry preserves original `prepareAt`;
- only Admin/Owner may alter preparation policy;
- invalid preparation lead is rejected;
- later policy changes do not rewrite accepted orders.

Canonical focused regression:

`supabase/tests/scheduled_order_operations_integration.sql`

Result: PASS transactionally against the live project.

## Deferred downstream authority

The following remain separate bounded tasks:

- payment capture/refunds;
- loyalty earning/redemption;
- inventory depletion;
- promotions/discount engine;
- tax/accounting;
- revenue/reporting;
- branch-specific scheduling/capacity and branch-scoped access;
- terminal/sales-point authority;
- shifts/cash reconciliation;
- delivery;
- hosted production deployment/release operations.
