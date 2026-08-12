# Customer State and Data Flow

Updated: 2026-08-13

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

Do not promote local `Money` arithmetic into persisted order authority. The local cart may show an interim estimate before a quote if necessary, but checkout/final order display must clearly switch to the backend quote and must handle catalogue drift/unavailability.

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

ASAP omits/nulls `requestedPickupAt`. Scheduled pickup sends an ISO-8601 timestamp aligned to the policy. Device clock alone is not schedule authority.

Branch hours/capacity are not modeled; do not derive fake capacity approval.

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

If transport fails after submitting placement, retry the same intended payload with the **same** `clientRequestId`. A new intended order gets a new UUID. Never generate a new idempotency key for each retry.

If placement fails validation, keep the cart and let the user correct/requote it.

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

The current local `PastOrder` list must stop being order truth once this integration lands. Historical product names/prices come from immutable backend snapshots, not current catalogue records.

## Realtime status

```text
place_customer_order returns order
 -> subscribe/read owner-visible orders row(s)

staff transition in dashboard
 -> orders row status/statusVersion changes
 -> Supabase Realtime authorized event
 -> customer provider invalidates/re-fetches get_order(orderId)
 -> confirmation/order detail renders persisted status
```

The current fixed two-second timer in `OrderConfirmationScreen` must be removed. No frontend timer may manufacture Preparing/Ready state.

The UI may compute presentation-only labels such as "scheduled in 45 min" from timestamps, but persisted fulfilment status comes only from the backend.

## Errors and offline boundaries

- Catalogue read may use existing explicit failure state; no production fixture fallback.
- Customer order placement requires an authenticated active member; do not create anonymous/guest customer placement as a frontend shortcut.
- If Realtime disconnects, manual/provider refresh may re-fetch the order; do not advance local status optimistically beyond the persisted backend response.
- Existing minimum offline member-code cache is not an offline order queue and must never become price/order authority.

## Payment boundary

The current backend has no payment-settlement state. Customer checkout should use a clear `Pay at counter`/unpaid demo path. `Payment received` must not be generated as a fake stage.
