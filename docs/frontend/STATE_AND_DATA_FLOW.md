# Customer State and Data Flow

Updated: 2026-08-17

## Catalogue

```text
Supabase get_catalogue()
 -> SupabaseCatalogueRepository
 -> catalogueProvider snapshot
 -> categories / featured / popular / menu providers
 -> Home + Menu + item detail

Admin DB mutation
 -> catalogue revision bump
 -> Supabase Realtime catalogue_revision event
 -> catalogueRevisionProvider
 -> catalogueProvider re-fetch
 -> UI reflects new DB state
```

Item detail uses DB variants and compatible add-on IDs. Manual pull-to-refresh invalidates the full catalogue snapshot and re-fetches from Supabase.

## Cart versus trusted quote

The cart remains client interaction state only:

```text
Menu item + variant + add-on IDs + quantity + note
 -> local cart state
 -> order payload selections
 -> quote_order()
 -> server revalidates current catalogue
 -> authoritative line/unit/subtotal/total sen
```

Local `Money` arithmetic is not persisted order authority. The cart may show an interim estimate, but checkout/final order display switches to the backend quote and handles catalogue drift/unavailability.

## ASAP / scheduled pickup

```text
get_ordering_policy()
 -> serverNow
 -> timezone Asia/Kuala_Lumpur
 -> scheduleEnabled
 -> minimumLeadMinutes
 -> slotIntervalMinutes
 -> maximumAdvanceDays
 -> UI derives selectable times
 -> user selects ASAP or scheduled timestamp
 -> quote_order validates again
```

ASAP omits/nulls `requestedPickupAt`. Scheduled pickup sends a policy-aligned timestamp. Device clock alone is not schedule authority. Branch hours/capacity are not modeled.

## Placement / idempotency

```text
successful quote + current cart selections
 -> create clientRequestId UUID once
 -> place_customer_order(payload)
 -> authenticated customer/member derived server-side
 -> server re-quotes
 -> persisted order + immutable commercial snapshots
 -> response contains server orderNumber/status/total
 -> clear cart only after success
```

A transport retry of the same intended placement reuses the same `clientRequestId`. A genuinely new intended order gets a new UUID. Validation failure retains the cart for correction/requote.

## Order history / detail

```text
get_my_orders(limit)
 -> backend order snapshots
 -> order history screen

select order
 -> get_order(orderId)
 -> backend snapshot
 -> order detail / confirmation status
```

Historical product names/prices come from immutable backend snapshots, not current catalogue records.

## Realtime status

```text
place_customer_order returns order
 -> owner-visible orders subscription

staff transition in Dashboard
 -> orders row status/statusVersion changes
 -> Supabase Realtime authorized event
 -> customer provider invalidates/re-fetches get_order(orderId)
 -> confirmation/order detail renders persisted status
```

No frontend timer manufactures Preparing/Ready state. Presentation-only relative-time labels may be computed locally, but persisted fulfilment status comes only from the backend.

The full live boundary was validated on 2026-08-17: customer order `100006` (`7cf027dc-3ff0-4604-a3fd-c7a943aac603`) was placed as `confirmed` v1; Dashboard transitions persisted `preparing` v2, `ready` v3 and `completed` v4; customer-authorized `get_order` reads observed each changed status.

## Errors and offline boundaries

- Catalogue read uses explicit failure state; no production fixture fallback.
- Customer order placement requires an authenticated active member; no anonymous/guest customer-placement shortcut.
- Realtime disconnect does not advance local status; refresh re-fetches persisted authority.
- The minimum offline member-code cache is not an offline order queue and never becomes price/order authority.
- Transport/Auth messages do not expose tokens or raw upstream stack traces.

## Payment boundary

The backend has no payment-settlement state. Customer checkout uses explicit `Pay at counter`/unpaid semantics. `Payment received` is not generated as fake backend state.
