# Shared Backend Contract

Updated: 2026-08-12

## Authority

Supabase Auth/Postgres/RLS plus controlled BFF/RPC operations are authoritative. Canonical migrations live in `Hermann-33/Aida_System/supabase/`.

## Catalogue contract

- Category/item/variant/add-on IDs are server-owned UUIDs.
- Catalogue prices and variant deltas are integer sen.
- Customer/public reads use `get_catalogue()` under RLS.
- Public/customer clients see active categories and published items only.
- Admin/owner writes use `save_catalogue_category(jsonb)` and `save_catalogue_item(jsonb)` with caller JWT; frontend-provided IDs/prices are input, not authority until validated/persisted by the server.
- `catalogue_revision` is an invalidation signal. Clients re-fetch authoritative state after it changes.
- Unpublished items are not customer-visible; availability is a distinct sold-out state.
- Compatible add-ons are normalized server links; category names never authorize add-ons.
- Ratings and loyalty bonus values are not catalogue fields.

## Security

No service-role key, DB secret or privileged bearer token enters a client bundle. Admin route guards are UX only; BFF checks, trusted roles and RLS/RPC checks are authoritative.

## Pricing boundary

Displaying catalogue prices does not make the client cart an authoritative quote. Future order creation must revalidate item publication, availability, variant/add-on compatibility and final price server-side.
