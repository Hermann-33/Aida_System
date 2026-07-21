# Aida UI Progress Screenshot Index

**Branch:** `team1/aida-pos-admin-ui`  
**Package:** `apps/pos-admin-web/docs_screenshots/all-screens/`  
**Capture:** `node scripts/capture-all-screens.mjs` (asserts route + heading; fails on duplicate PNG hashes)

Capability legend: **Connected** · **Preview** · **Contract pending** · **Future**

## Employee Access

| File | Role | Demonstrates | Status | Team 2 |
|------|------|--------------|--------|--------|
| `00-employee-terminal-enrol.png` | Anonymous | Terminal OTC activation UI | Preview | Live OTC mint + enrol cookies |
| `00-employee-terminal-enrol-expired.png` | Anonymous | Expired code failure | Preview | Distinct expiry error codes |
| `00-employee-sign-in-password.png` | Anonymous | Password login | Preview / Connected adapter | Cookie session |
| `00-employee-sign-in-badge.png` | Anonymous | Badge + PIN | Preview | Badge login API |
| `00-employee-role-select.png` | Dual-role | Workspace choice | Preview | Product-select audit |

## Aida Counter

| File | Role | Demonstrates | Status | Team 2 |
|------|------|--------------|--------|--------|
| `10-pos-open-shift.png` | Staff | Open shift + float | Preview / Connected | Shifts API |
| `11-pos-counter-new-sale.png` | Staff | Three-zone New Sale + order type | Preview | Menu + sales |
| `12-pos-menu-coffee.png` | Staff | Coffee category (distinct from All) | Preview | Catalogue |
| `13-pos-modifier-sheet.png` | Staff | Sticky Add to order visible | Contract pending | Modifier OpenAPI |
| `14-pos-cart-with-item.png` | Staff | Cart with modifiers | Preview | Line snapshot |
| `15–16` member/reward | Staff | Scan + apply reward / reject | Preview | Rewards engine |
| `17–18` cash payment | Staff | Tender, change, confirm | Preview | Sales + tender |
| `19-pos-receipt-complete.png` | Staff | Receipt; Pay locked | Preview | Receipt print adapter |
| `20` non-cash fail | Staff | Decline/timeout/unknown | Preview | Payment provider |
| `21-pos-orders.png` | Staff | Orders + void/refund preview | Preview | Corrective actions + audit |
| `22–25` shift/terminal/offline/close | Staff | Cash events, health, offline, close | Preview | Shift cash + device health |

## Aida Office

| File | Role | Demonstrates | Status | Team 2 |
|------|------|--------------|--------|--------|
| `30-admin-01-dashboard-today.png` | Admin | KPI dashboard Today | Preview | Report queries |
| `30-admin-02-dashboard-month.png` | Admin | This Month period | Preview | Same |
| `30-admin-03-live-ops.png` | Admin | Live Counter/Snack Station | Preview | Heartbeat streams |
| `30-admin-04`–`11` reports | Admin | Distinct report modules | Preview | Report APIs / export |
| `30-admin-12`–`15` ops | Admin | Branches, terminals, shifts, employees | Preview | Ops APIs |
| `30-admin-16`–`18` catalogue | Admin | Menu, categories, variants | Preview / Contract pending | Catalogue publish |
| `30-admin-19`–`21` inventory | Admin | Stock, recipes, wastage | Preview | Inventory |
| `30-admin-22`–`24` rewards | Admin | Loyalty/stamps/offers/campaigns | Preview | Rewards + campaigns |
| `30-admin-25`–`27` system | Admin | Audit, integrations (MyInvois pending), settings | Preview / Future | Audit + integrations |

## Stakeholder decisions still open

- Student wallet payment method
- Modifier/variant OpenAPI contract
- MyInvois
- Offline payment acceptance policy
- Free-drink threshold remains 10 stamps per master PRD unless merchant changes it
