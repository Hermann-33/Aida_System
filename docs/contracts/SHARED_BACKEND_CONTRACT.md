# Shared Backend Contract

Updated: 2026-09-15

## Authority

Supabase Auth/Postgres/FORCE-RLS plus controlled RPC/BFF operations are authoritative. Canonical executable Supabase migrations live only in `Hermann-33/Aida_System/supabase/migrations/`.

Neither frontend is authority for authenticated identity, trusted role/disabled state, membership identity, employee branch scope, branch/sales-point/terminal identity, terminal credential validity, shift/cash state, scheduling/capacity, catalogue/pricing, inventory/recipes/depletion, order totals/status, tender/payment classification, privacy preferences or account-deletion/anonymization state.

Dashboard privileged flows remain behind the same-origin BFF with HttpOnly employee and terminal credentials and caller-JWT forwarding. No service-role secret or browser-readable reusable employee bearer token/terminal credential is used. Preview fixtures never become backend authority.

## Identity and authorization

- Supabase Auth identity is trusted authentication identity.
- `user_profiles.app_role` plus `disabled_at` is trusted application authorization state.
- `members` is trusted customer membership state.
- `employee_branch_assignments` is trusted ordinary-staff operational scope.
- signup cannot self-assign employee/Admin role, member code, verification outcome or branch scope.
- employee identities remain distinct from customer/member records.
- customer-editable Auth metadata is not authorization authority.

## Catalogue and commercial order contract

Supabase owns catalogue IDs, publication/availability, modifier compatibility, integer-sen prices, authoritative quote totals and persisted commercial snapshots. Clients submit selection/fulfilment intent only.

Persisted order history includes `orders`, `order_lines`, `order_line_addons`, `order_line_options` and `order_events`. `clientRequestId` supplies idempotency. Fulfilment status changes are optimistic-versioned and server-authorized.

Customer order placement derives customer/member identity from `auth.uid()` plus trusted active membership. POS placement derives operational topology from the server-held terminal credential and caller employee scope.

## Phase 1 operational topology contract

```text
branch -> sales point -> terminal -> employee branch scope -> POS attribution
```

A sales point belongs to one branch and a terminal to one sales point. Manager-issued one-time enrolment activates a terminal. Credential resolution validates terminal/revocation, active topology, caller employee state and branch scope. Browser-supplied location IDs cannot replace terminal credential authority. Accepted branch/sales-point/terminal attribution is immutable.

## Phase 2 shift and cash contract

```text
terminal + employee -> shift -> POS order / cash ledger
```

- shift lifecycle is `open | locked | closed` with optimistic versioning;
- one live open/locked shift per terminal and per operator;
- opening float and cash movements use integer sen;
- `cash_movements` is append-only;
- expected cash and closing variance are server-derived;
- non-zero variance close requires Admin/Owner;
- new POS placement requires the caller's matching open shift;
- persisted `shift_id`, tender and payment state are protected from ordinary mutation;
- Phase 2 tender classification is `cash | unpaid` only;
- customer orders remain shift-free and unpaid.

External processor capture, settlement and refunds are not implied by Phase 2.

## Phase 3 customer privacy/account contract

`delete_own_account()` accepts no target user ID and remains caller-bound to `auth.uid()`. Before deleting Auth identity, the backend removes retained customer-authored order free text and anonymizes customer/member/Auth identity on retained customer transactions. Staff/POS audit identity and commercial facts remain. Privacy preferences are owner-bound; marketing defaults off. Existing JWTs cannot recover personalized state after profile/member ownership is removed.

Customer app exposes in-app account deletion, privacy preferences, Privacy Policy, Terms and Support. Phase 3 introduces no tracking/advertising SDK, new protected-device permission or StoreKit/IAP path for physical café goods.

## Phase 4 branch scheduling and pickup contract

Trusted chain:

```text
active branch
 -> branch timezone
 -> weekly service windows / dated exceptions
 -> ASAP or scheduled policy
 -> lead/preparation time + horizon + slot interval
 -> persisted slot capacity
 -> authoritative quote / placement acceptance
```

Customer branch choice is intent only. Server validates active branch and branch-local schedule and derives `prepare_at`. Scheduled placement serializes branch+slot capacity before acceptance. POS branch remains terminal/open-shift derived. Public pickup/quote read boundaries are invoker-side; privileged aggregate work stays narrowly private. Dashboard Admin scheduling mutation stays behind the caller-JWT BFF.

## Phase 5 inventory and recipes contract

**Verdict:** `COMPLETE`

Trusted resources:

```text
public.inventory_items
public.branch_inventory
public.inventory_movements
public.recipes
public.recipe_components
public.save_inventory_item(jsonb)
public.record_inventory_movement(...)
public.save_recipe(jsonb)
public.list_inventory_state(uuid)
```

### Quantity and stock authority

Inventory quantities use integer milli-units. Each inventory item declares base unit `g`, `ml`, or `unit`. `branch_inventory` stores current non-negative branch balances. `inventory_movements` is append-only history for receiving, waste, adjustment, order consumption and cancellation reversal.

Clients never submit authoritative resulting stock. Admin/Owner submits movement intent; the backend atomically applies the delta and writes the movement record. Ordinary direct table writes are revoked.

### Recipe authority

An active recipe maps a catalogue item, optionally one variant, to positive component quantities. Variant-specific active recipe takes precedence over the item default. A catalogue item/add-on with no active recipe is not inventory-controlled. Once a recipe is active, all its active components are required for orderability.

### Quote and placement

Quote resolves the Phase 4 trusted branch then checks aggregate recipe requirements against current branch stock. Quote does not reserve inventory.

Placement is final authority. Order-line and add-on insertion consumes recipe stock transactionally through atomic non-negative updates. If any required component cannot be consumed, the whole order transaction fails. Concurrent placement cannot oversell the same final stock. Cancellation restores accepted consumption through exactly-once compensating movements without mutating historical consumption or commercial snapshots.

### Privileged inventory administration

Public inventory Admin RPCs are caller-bound `SECURITY INVOKER` wrappers that require trusted Admin/Owner authorization. Guarded private `SECURITY DEFINER` helpers have empty search paths and independently verify the caller before invoking lower-level write helpers. The unchecked private write helpers are not executable by authenticated/anonymous roles. Dashboard mutation routes enforce same-origin and forward the caller employee JWT with the publishable key only.

## Realtime and payment boundaries

Customer Realtime is authorized invalidation followed by authoritative refetch. Dashboard privileged data does not expose employee bearer tokens for direct Realtime.

External payment capture/refunds/processor settlement remain deferred. Phase 2 cash/unpaid state is internal POS authority, not processor integration.

## Security invariants through Phase 5

- no authorization trusts customer-editable metadata or preview fixtures;
- no service-role/secret credential in Flutter/browser code;
- employee JWT and terminal credential remain HttpOnly in Dashboard live flows;
- no direct client mutation of trusted topology/shift/cash/scheduling/inventory/recipe tables where controlled authority is required;
- branch/terminal/shift/scheduling/inventory/commercial facts are derived from server-owned state;
- inventory depletion is transactionally non-negative and does not trust client stock calculations;
- customer self-deletion cannot target another user;
- retained customer transactions lose stable customer/member/Auth identity and customer-authored retained free text;
- staff/POS actor identity and commercial history remain preserved.

## Validation and governance

Phases 1–5 are `COMPLETE`. Phase 6 loyalty/rewards/vouchers is the next implementation boundary and must have a mirrored plan before code. Phase 5 evidence is in `docs/context/PHASE_5_INVENTORY_RECIPES_CLOSEOUT_2026-09-15.md`.

The independent Phase 1–3 Codex audit may run in parallel under ADR-0013. Any valid blocking finding reopens the affected earlier phase. Completed phase PRs remain draft/unmerged unless explicitly authorized.

## Deferred authority

- supplier purchasing, lot/expiry tracking, forecasting and automated procurement;
- loyalty/rewards/vouchers — Phase 6;
- promotions/discounts — Phase 7;
- reporting/tax/accounting export — Phase 8;
- external payment capture/refunds/processor settlement and deployment-heavy integrations;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integrations;
- notification/marketing delivery provider.
