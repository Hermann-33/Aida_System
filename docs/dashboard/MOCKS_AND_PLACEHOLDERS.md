# POS/Admin Mocks and Placeholders Register

Everything below is non-production until a later task proves a trusted backend path.

## Fixture/local data

- Products, categories, modifiers, prices, availability and routing.
- Members, student verification states, points/stamps/reward eligibility.
- Employees, roles, branch assignments and global-manager flags.
- Branches/sales points, terminals and terminal health.
- Transactions, receipts, payment mix and report aggregates.
- Shifts, cash variance, inventory, recipes and alerts.
- Marketing creatives, loyalty program rules and audit rows.

## Simulated operations

- QR scanning selects a fixture member after a delay.
- Cash/non-cash payment processing is browser simulation; non-cash references are preview values.
- Receipt/order IDs and cart-line IDs are generated client-side.
- Manager approval is a preview/local PIN/action process.
- Void/refund/cancel do not mutate authoritative order/payment records.
- Held tickets, orders, cash moves and shifts are non-durable.
- Branch/employee/terminal/menu/inventory/marketing edits are session/component state.
- Reports multiply/derive sample transaction data rather than query trusted aggregates.

## Disabled/placeholder operations

Examples include production publishing/saving/export, integration configuration and settings actions. The dashboard import audit is the detailed source register.

## Production move

Promote none of these values mechanically. Stable IDs, branch scope, prices, role permissions, reward rules, payment semantics, inventory units and report definitions require explicit backend/domain decisions.