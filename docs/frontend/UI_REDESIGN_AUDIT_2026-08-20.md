# Customer UI Redesign Post-Merge Audit

Updated: 2026-08-20

Task: `TASK-UI-REDESIGN-003 — post-merge customer redesign audit, regression verification and release build`

This audit supplements `UI_REDESIGN_SPEC.md`. It checks the merged redesign against the implemented Auth/member, catalogue, order/scheduling, Realtime, offline-member and deferred-loyalty boundaries. It documents runtime impact rather than visual intent.

## Audited baseline

- Customer default branch audited after PR #15 integration.
- Merge commit: `dcc97c481ae446d76b25bf8f91850e1d829c56f5`.
- Redesign surfaces: Menu, Item detail, Cart, Checkout sheet and Rewards.
- Shared presentation changes: floating cart, `NeumorphicControl`, AIDA logo asset, success tint.
- Indirectly affected surface: Membership QR, because it already consumes the shared `AidaLogo` widget.

No Supabase migration, RPC, RLS policy, repository interface, provider binding, Auth lifecycle, order model or trusted business-state implementation was changed by the redesign merge.

## Backend-impact verdict by boundary

| Boundary | Redesign effect | Authority verdict |
|---|---|---|
| Supabase Auth/session | No auth/login/provider change | Preserved |
| Profile/member provisioning | No write/read contract change | Preserved |
| Offline member code / QR | Shared logo changed visually; member code and QR payload unchanged | Preserved |
| Shared catalogue | Menu layout changed; data still comes from `get_catalogue()` and Realtime invalidation/refetch | Preserved |
| Catalogue product imagery | Menu rows use server `imageUrl` first and bundled category art only as fallback | Preserved after integration correction |
| Variants/add-ons | Item detail still uses server item variants and compatible add-on IDs | Preserved |
| Cart | Presentation and remove gesture changed; cart remains local selection/estimate state | Preserved |
| Quote authority | Checkout still calls `quote_order()` and displays `Server total` | Preserved |
| Scheduling | Wheel interaction changed; selectable timestamps come only from `derivePickupSlots(OrderingPolicy)` | Preserved after integration correction |
| Placement/idempotency | `OrderCheckoutSession` and retry-stable `clientRequestId` unchanged | Preserved |
| Order persistence/status | Place/history/detail/Realtime repository boundaries unchanged | Preserved |
| Payment | Still explicitly `Pay at the counter`; no processor/payment state introduced | Preserved |
| Loyalty/rewards | Rewards presentation changed, but points/rewards/vouchers remain preview-backed | Still deferred; no authority added |
| Inventory/promotions/reporting/branch capacity | No implementation added | Still deferred |

## Auth and membership

The redesign does not touch `main.dart`, `AuthGate`, `authStateProvider`, `SupabaseMemberRepository`, trusted profile/member provisioning or logout cache cleanup.

`MembershipCardScreen` is indirectly affected because `AidaLogo` now renders the bundled real logo instead of the previous placeholder. This is visual only. The QR still encodes `member.memberCode`, owner-scoped member/profile reads remain the online source, and the minimum per-user offline cache remains the fallback for membership identity. The new logo is bundled in the APK, so it does not introduce a network dependency into the offline membership-card path.

## Catalogue and Menu

The redesign replaces the Menu grid with `MenuCategoryRail` + `MenuListItem`. The authority chain remains:

```text
catalogue_revision Realtime
 -> catalogueProvider refetch
 -> menuItemsProvider/categoriesProvider
 -> MenuScreen
 -> MenuListItem / ItemDetailScreen
```

`MenuListItem` renders `item.imageUrl` through `ProductImage` when present. Bundled category artwork is only `assetFallback`; it is not a catalogue value and does not override live product photography.

Availability, IDs, prices, variants, add-on compatibility and merchandising flags still originate in the shared catalogue snapshot. No hardcoded commercial fallback was reintroduced.

## Item detail and cart

The redesign consolidates the item-detail bottom actions into one `Add to cart · <local total>` control and changes the cart presentation to flat rows with swipe-to-remove.

The data boundary is unchanged:

```text
server catalogue item + variant/add-on IDs
 -> local CartLineItem
 -> local estimate only
 -> OrderSelectionLine IDs/quantity/note
```

The cart does not submit trusted names, prices, subtotal or total. Swipe removal calls the existing local cart notifier only. Cart clearing still occurs only after `OrderSnapshot` placement success.

## Checkout and scheduling

The stale redesign source branch originally contained two invalid assumptions: arbitrary one-minute scheduling and a client-only 08:00–17:00 window. Those changes were rejected during integration and are not present in the merged implementation.

Current flow:

```text
get_ordering_policy()
 -> derivePickupSlots(policy)
 -> wheel renders only derived timestamps
 -> user selects timestamp
 -> quote_order() validates it again
 -> place_customer_order() revalidates/persists
```

`derivePickupSlots` uses backend `serverNow`, timezone, `scheduleEnabled`, `minimumLeadMinutes`, `slotIntervalMinutes` and `maximumAdvanceDays`. The UI does not invent opening hours, branch capacity or device-clock-only validity.

A dedicated post-merge widget regression now records quote requests and asserts that selecting Schedule submits one of the slots returned by `derivePickupSlots(TestOrderRepository.policy)`.

## Order placement, history and Realtime

The redesign did not modify:

- `SupabaseOrderRepository` RPC names or payload mapping;
- `OrderRequest` / `OrderSelectionLine` trusted payload shape;
- retry-stable `clientRequestId` handling;
- owner-scoped `orders` Realtime subscription;
- `get_my_orders()` history reads;
- `get_order()` detail/status reads;
- persisted status rendering.

No local fulfilment timer or client status mutation was introduced.

## Rewards data-source clarification

The redesigned Rewards screen now has a mixed data boundary:

- `displayedMemberProvider`: real owner-scoped Supabase member/profile read, with the existing local presentation edit overlay;
- `pointsProvider`, `rewardsProvider`, `vouchersProvider`: still delegated by `SupabaseMemberRepository` to `MockMemberRepository` pending the trusted loyalty task.

Therefore the Rewards screen must not be described as wholly mock, nor as an integrated loyalty feature. The member identity shown on the balance card is real; loyalty value and redemption remain preview/deferred.

The `Redeem` action still does not mutate trusted points. It explicitly tells the user that redemption is not wired and leaves the mock balance unchanged.

## Shared-logo impact

`AidaLogo` changed from an obvious placeholder to `assets/images/aida_logo.jpg`. Existing users of the shared widget inherit that change. Today that includes Membership QR. The Rewards card also uses the asset as a decorative watermark.

This is a presentation dependency, not an identity or QR trust change. Future logo replacement should remain centralized through the shared widget/asset and must keep the membership card offline-safe.

## Test/audit gaps found after merge

The merged source branch documentation understated the verification gap. Two pre-redesign test assumptions were stale:

1. `cart_flow_test.dart` expected an old `Add to order` semantics label and old `2 items` floating-cart text that the redesign removed.
2. the Menu golden test targeted `ValueKey('menu_cat_c_coffee')`, while the new category rail initially omitted stable keys.

`TASK-UI-REDESIGN-003` corrects those testability regressions instead of weakening assertions:

- category rail tiles expose stable keys (`menu_cat_all`, `menu_cat_favorites`, `menu_cat_<category-id>`);
- cart flow uses the redesigned CTA and floating-cart key;
- a scheduling regression asserts server-policy-derived pickup selection;
- the test order adapter records quote requests for this assertion.

Golden image files are not automatically rewritten. A golden mismatch is visual evidence requiring deliberate review, not permission to replace baselines just to obtain a green suite.

## Verification gates

Required fresh-checkout gates for this task:

1. Flutter 3.44.9 dependency resolution;
2. `flutter analyze`;
3. non-golden Flutter regression suite;
4. golden suite recorded separately so intentional/stale image differences remain visible;
5. `flutter build apk --release`;
6. APK artifact retained for device transfer.

The clean CI workflow `.github/workflows/customer-release-audit.yml` performs those checks. Final PASS/FAIL evidence belongs in `ACTIVE_CONTEXT.md`, `HANDOFF.md` and `AUDIT_LOG.md` only after the run completes.

## Security assessment

No redesign change weakens RLS, exposes an employee token, adds a service-role key, changes public Auth configuration, grants direct order DML, changes member-code trust, introduces client-trusted pricing, or adds fake payment state.

The existing hosted Auth warning (`auth_leaked_password_protection`) remains unrelated operational configuration debt.

## Remaining product gaps

The redesign does not close these product domains:

- trusted loyalty ledger / points earning;
- reward redemption and voucher consumption;
- real payment/refunds;
- inventory/depletion;
- promotion/discount authority;
- tax/accounting/reporting;
- branch hours/closures/capacity and branch-scoped operations;
- notifications and several profile/settings/support flows;
- hosted production distribution/signing operations.

Visual polish must not be used as evidence that any of these are integrated.
