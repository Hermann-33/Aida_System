# POS/Admin Backend Integration Plan

This is a needs map, not a table-by-table schema prescription.

| Area | Required trusted behavior | Priority |
|---|---|---|
| Employee auth | authenticate/revoke staff/admin, rate limits, disabled state, trusted roles | MVP |
| Branch/role scope | employee assignments, global-manager rules, server authorization | MVP |
| Terminals | enrolment codes, secure terminal credential, branch/sales-point binding, revoke/health | MVP |
| Shifts/cash | open/lock/resume/close, cash movements, variance, manager controls, audit | MVP for POS |
| Catalogue | same published items/variants/modifiers/prices as customer app; privileged edits | MVP |
| Quote/POS cart | validate configurations and authoritative totals | MVP |
| Orders/KDS | idempotent create, queue/routing, legal status transitions, receipts | MVP |
| Payments | provider/device transaction, cash record, failure/retry, refunds/void, reconciliation | MVP / provider decision |
| Member/QR | authorized member-code lookup, minimal data, verification and abuse controls | MVP |
| Loyalty/vouchers | current balance/eligibility, atomic issue/redeem/consume linked to order | MVP |
| Employees/admin | controlled role/branch/status mutation, reauth/approval, audit | MVP/important |
| Inventory | stock ledger, units, recipes, depletion, counts, wastage, transfers | Important |
| Marketing | media/placement/audience/windows, draft/publish/expire, audit | Important |
| Reporting | trusted business-day/branch/payment/refund/loyalty aggregates and export | Important |
| Audit | immutable/equivalently protected privileged-action trail | MVP foundation |
| Integrations/settings | protected configuration/secrets, versioning and audit | Later/confirmed scope |

## Integration sequencing

1. Shared identity/role/branch/terminal decisions.
2. Shared catalogue contract.
3. POS quote/order/payment and customer order interoperability.
4. Loyalty/member operations.
5. Inventory and advanced operations.
6. Marketing/reporting/integrations/hardening.

Do not implement a dashboard-only catalogue/order/loyalty backend. Every shared concept must align with `docs/contracts/SHARED_BACKEND_CONTRACT.md` and customer requirements.