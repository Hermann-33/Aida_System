# AIDA Café Project Brief

## Product purpose

AIDA Café is intended to support café ordering and membership operations for City University Malaysia. The product direction combines a customer experience—menu discovery, ordering, QR membership, rewards, and order tracking—with future staff/POS and admin workflows.

Evidence: `Aida_System_Unified_PRD_v2.0.md` §§6–13 and `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md`.

## Problem being solved

Customers need a clear way to discover café items, identify themselves as members, see loyalty value, and place or review orders. Café staff and administrators will eventually need a shared operational record for menu availability, member verification, pricing, orders, rewards, promotions, and reporting. The current checkout-shaped UI has no shared operational record yet.

## Target users

- City University students and other café customers.
- Café staff/baristas/cashiers using a planned POS or staff workflow.
- Café owners/managers/admin users using a planned operational dashboard.

Only the customer role has an application in this repository. No staff, POS, or admin source folder was found in the 2026-08-11 inventory.

## Core scope

### Customer app

The current Flutter UI covers sign-in/sign-up, password-reset request, home and promotions, loyalty summary and local check-in interaction, rewards/vouchers, membership QR, menu/category browsing, item configuration, favorites, cart, payment-method selection, mock order tracking, session order history/receipt, profile, and session-only profile editing.

Evidence: `apps/customer/lib/features/`, `apps/customer/lib/application/providers.dart`, and `docs/frontend/UI_SCREEN_MAP.md`.

### POS, staff, and admin

The PRD describes planned POS/staff/admin capabilities, including sales, order operations, member lookup, catalogue management, verification, reporting, promotions, and loyalty administration. None is implemented in this checkout. These workflows must not be described as current repository capability.

Evidence: PRD §§9.2–9.4 and absence from the repository file inventory recorded in `docs/context/AUDIT_LOG.md`.

## Explicit non-goals for the current baseline

- Claiming that the UI is production-ready or full-stack complete.
- Preserving or assuming any historical Node/Express/Neon deployment described by the PRD.
- Inferring a Supabase schema from mock models or old database descriptions.
- Building custom payment-card processing.
- Treating the current customer-side totals, loyalty values, roles, or QR as authoritative.
- Implementing POS/admin features inside the customer app by accident.

## Current maturity

This is a polished, test-backed frontend prototype with useful domain types and a repository abstraction. It is not yet a real connected product:

- `memberRepositoryProvider` binds only `MockMemberRepository`.
- auth is a session boolean and accepts any sign-in attempt;
- cart, favorites, profile edits, check-in, and order history live in memory;
- payment, order creation, and order status are simulated;
- no Supabase package, client, config, migration, or backend exists here.

## Honest limitations

- Only Android, iOS, and web runner directories are committed; no Windows runner is present.
- The web manifest and package README still contain scaffold text.
- Product images are temporary hotlinked Unsplash images and several local cut-out/category assets; the logo is a placeholder.
- Product prices, serving sizes, add-on compatibility, ratings, voucher expiry, points/reward values, and demo identity data are not verified operational data.
- The offline QR claim is architecturally intended but not implemented with durable local storage.
- Scheduled ordering has no current screen or data flow.
- The full test command currently fails four golden comparisons; non-golden tests pass.

## Success criteria

AIDA succeeds when verified users can complete their role-appropriate flows against one authoritative system, with server-controlled price/loyalty/order rules, secure access, usable failure/offline behavior, and operational visibility for staff/admin. Repository-level success additionally requires reproducible migrations, tests, current documentation, reviewed UI baselines, and deployable target builds.
