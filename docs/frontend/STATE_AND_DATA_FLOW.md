# Customer State and Data Flow

Updated: 2026-09-15

**Current live boundary:** customer runtime is integrated through Phase 7. Production providers use Supabase repositories; legacy preview/sample values are not production authority.

## Authentication and member identity

```text
Supabase Auth session
 -> SupabaseMemberRepository
 -> authStateProvider / memberProvider
 -> authenticated profile/member surfaces
```

Auth state changes invalidate personalized member, privacy, loyalty and order providers so one account's cached state is not carried into another session.

## Catalogue

```text
Supabase get_catalogue()
 -> SupabaseCatalogueRepository
 -> catalogueProvider
 -> Home / Menu / item detail / checkout selections
```

Catalogue Realtime is an invalidation signal only: a revision causes a fresh RLS-filtered snapshot fetch. Realtime payloads do not become catalogue authority themselves.

## Privacy and whole-account deletion

```text
Settings / Privacy
 -> SupabaseMemberRepository
 -> caller-bound privacy RPCs

Delete Account
 -> authStateProvider.deleteAccount()
 -> SupabaseMemberRepository.deleteAccount()
 -> caller-bound whole-account deletion
 -> auth/member/loyalty state removed + retained commercial history anonymised
 -> personalized providers invalidated
```

The Settings screen exposes an explicit Delete Account action. Deletion is not feature-flagged; the only preserved backend-dependent feature flag is the referral draft.

## Loyalty, rewards and vouchers

```text
SupabaseLoyaltyRepository
 -> pointsProvider
 -> stampCardProvider
 -> rewardsProvider
 -> vouchersProvider
 -> Rewards / Settings / checkout wallet presentation
```

Production loyalty does not fall back to legacy member preview values. Points/stamps, reward catalogue and vouchers are caller-bound backend state. Redemption and voucher eligibility/consumption are server-owned.

## Ordering

```text
cart + fulfilment/pickup intent + optional voucher intent
 -> SupabaseOrderRepository.quote
 -> public.quote_order
 -> authoritative lines/subtotal/schedule/inventory/voucher/promotions/total
 -> checkout UI

confirmed intent + clientRequestId
 -> place_customer_order
 -> transactional schedule + stock + voucher + promotion revalidation
 -> immutable accepted snapshot
 -> order/history providers
```

The client never submits accepted prices, promotion IDs, promotion discounts, stock result or schedule capacity.

## Phase 7 promotion data

Promotions are automatic server decisions, not a customer selection source. `OrderQuote` and `OrderSnapshot` strictly parse:

```text
voucherDiscountSen
promotionDiscountSen
discountSen
promotions[]
```

Commercial validation requires voucher + promotion components to reconcile to total discount and line totals/subtotal/total to reconcile. A voucher-compatible promotion may coexist only when its trusted snapshot allows it; an exclusive promotion cannot be presented alongside another promotion.

The existing Home promo/offer presentation may display marketing content, but it is not authoritative discount eligibility. Accepted commercial promotions come only from `quote_order`/placed-order snapshots.

## Scheduling and inventory

Branch scheduling, service windows, lead/horizon/capacity and `prepareAt` are server-derived. The app presents returned pickup choices/results; it does not infer capacity from local time.

Inventory/recipe availability is also server-owned. Quote can report current availability, while placement performs the authoritative transactional depletion. The customer app has no inventory mutation authority.

## Order updates

Order history/updates come from trusted backend snapshots. Realtime, where used, is an invalidation/refetch mechanism rather than a channel for trusting arbitrary commercial change payloads.

## Payments

Current customer ordering preserves the documented pay-at-counter/unpaid internal semantics. External processor authorization/capture/settlement/refunds remain Phase 9; the client must not imply successful external payment before that authority exists.

## Remaining/deferred customer surfaces

Referral remains explicitly draft-gated. Phase 8 is primarily Dashboard/backend reporting and should not invent new customer authority. Phase 9 may add approved external payment UX. Phase 10 owns final iOS/App Store production verification, privacy metadata, URLs, review path and release artifacts.
