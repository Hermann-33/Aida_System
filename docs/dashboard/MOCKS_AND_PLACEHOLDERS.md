# POS/Admin Mocks and Placeholders Register

Everything below is non-production until a bounded task proves a trusted backend path.

## Member area changed by TASK-AUTH-001

The Admin Members tab no longer uses `PREVIEW_MEMBERS` and has no fixture fallback. It now requests the intended same-origin `GET /api/v1/admin/members` contract.

That does **not** make the path production-complete: the trusted staff/admin BFF/session and the endpoint are not implemented yet. Until TASK-AUTH-002 closes that gap, the Members tab will fail closed rather than invent member rows.

Points, stamps and reward activity are not shown as trusted member-directory data. The separate Rewards Activity tab remains explicitly preview-only because loyalty persistence has not been implemented.

## Still fixture/local data

- Products, categories, modifiers, prices, availability and routing.
- Loyalty points/stamps/reward rules and transaction/reward activity.
- Employees, roles, branch assignments and global-manager flags.
- Branches/sales points, terminals and terminal health.
- Transactions, receipts, payment mix and report aggregates.
- Shifts, cash variance, inventory, recipes and alerts.
- Marketing creatives and audit rows.

## Still simulated operations

QR/member lookup, tender/payment, receipt/order generation, manager approval, void/refund/cancel, shifts/cash moves, catalogue/inventory/marketing edits and reporting remain preview/local until their respective backend tasks.
