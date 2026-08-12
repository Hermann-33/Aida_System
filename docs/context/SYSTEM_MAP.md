# AIDA Café System Map

Updated: 2026-08-12

## Source repositories

| System | Repository | Default branch | Current local directory evidence | Runtime |
|---|---|---|---|---|
| Customer app | `Hermann-33/Aida_System` | `master` | `C:\code\Aida_System` | Flutter/Dart |
| POS/Admin | `Hermann-33/Aida_System-Dashboard` | `main` | `C:\code\Aida_system Dash\pos-admin-web` | React/TypeScript/Vite |
| Shared backend | Supabase `eswovqxqzfevcdwwcmuh` | managed service | shared external project | Auth/Postgres/RLS; future Storage/Realtime/functions |

## Customer surfaces

Auth/sign-up/reset, Home, Rewards, Membership QR, Menu, item configuration, favourites, Cart, payment-method selection, order tracking/history, Profile and edit profile.

Current source of most displayed business data: `MockMemberRepository` plus Riverpod/widget memory.

## Dashboard surfaces

Employee access and terminal enrolment; POS sale/cart/modifiers/member/reward lookup/payments/receipts/orders/shifts/terminal/help; Admin executive dashboard, sales/transactions/member reporting, branches/locations, terminals, shifts, employees/access, menu/catalogue, inventory, loyalty, marketing, audit, integrations and settings.

Current source of most business data: preview fixtures, React state, module state and session storage.

## Shared domain intersections

| Shared concept | Customer today | Dashboard today | Required shared authority |
|---|---|---|---|
| User/member | mock/session member | fixture member lookup | Auth/profile/member foundation |
| Member code / QR | client/mock display | simulated scan/search | server-issued member code + authorized lookup |
| Student status | mock/session field | fixture verification status | trusted verification workflow |
| Catalogue | mock repository | preview menu fixtures | published catalogue contract |
| Price/modifiers | client mock calculation | client preview calculation | server quote/current catalogue |
| Orders | process-local | fixture/local receipts/orders | durable order + transition model |
| Payments | local method label | simulated cash/non-cash | approved payment/provider record |
| Loyalty | mock values | fixture eligibility/calculation | ledger + atomic redemption/use |
| Promotions | mock carousel | local campaign/banner state | publication/eligibility contract |
| Branch/location | absent in customer UX | preview org/branch IDs | shared branch/sales-point model |
| Inventory | absent | local preview | stock ledger/operations |
| Staff roles | absent | preview guards/roles | trusted employee/role/branch authorization |
| Reporting/audit | absent | sample aggregates/events | trusted aggregate + immutable audit |

## Data flow target

1. A client submits intent and stable IDs, never claimed authority.
2. Trusted backend authenticates identity and checks ownership/role/branch scope.
3. Backend validates current business rules and applies atomic/idempotent changes.
4. Both clients read the same resulting records/events.
5. Operational actions from POS/admin become customer-visible state only through the shared backend.

## Change-impact rule

Before changing any row in the table above, inspect both repositories. A backend change is not accepted merely because one UI compiles.