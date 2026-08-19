# ADR-0004: Full-stack completion gate

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

The customer app contains polished flows that resemble complete authentication, payment, ordering, tracking, history, profile, QR, and loyalty features. Code comments and the cart design spec correctly state that many are mock or in-memory, but product status can still be overstated when only the screen is inspected. The legacy PRD also contains “Live” and “Complete” claims for assets absent from this checkout.

## Decision

UI completion is not full feature completion. A feature may be called complete only when every applicable layer is implemented and verified:

1. **UI/client:** accessible success, loading, empty, error, retry, and offline states.
2. **Service/API:** explicit contract, typed failures, idempotency/concurrency behavior, and observability where needed.
3. **Data/persistence:** authoritative durable state, migrations, integrity rules, audit/retention behavior, and recovery.
4. **Security:** authentication, ownership/role authorization, RLS/policy tests, secret handling, abuse/tamper controls.
5. **Operations:** staff/admin/fulfillment capability when the customer feature depends on it.
6. **Tests:** unit, adapter, widget/integration, security, and reviewed visual tests proportionate to risk.
7. **Documentation:** active context, architecture/status, codebase map, handoff/audit log, and ADR updates.

If only a subset is in scope, use precise language such as “implemented UI,” “prototype,” “mock,” or “partially wired.”

## Verdict rules

- `COMPLETE`: the scoped task and all applicable gates pass.
- `PARTIAL`: useful work exists but a required gate or dependency remains.
- `FAIL`: the requested outcome is absent, unsafe, or verification fails materially.

A UI-only task may receive `COMPLETE` for its explicitly UI-only scope, but its report must say the product feature remains mock/partial.

## Consequences

- Checkout is not ordering completion until authoritative quote/order/fulfillment paths exist.
- QR rendering is not membership integration until identity, storage, scan verification, and authorization are verified.
- Rewards display is not loyalty completion until ledger/redemption/voucher operations are secure and atomic.
- Passing non-golden tests does not override failed visual or security gates.
- Future handoffs must name missing layers and avoid “production-ready” without evidence.

## Evidence

- Mock/session behavior in `apps/customer/lib/application/providers.dart`.
- Simulated checkout/tracking in `features/cart/cart_screen.dart` and `order_confirmation_screen.dart`.
- Mock adapter in `data/repository/mock_member_repository.dart`.
- Historical/current status conflict in `Aida_System_Unified_PRD_v2.0.md` and current repository inventory.
