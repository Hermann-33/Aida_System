# Product Requirements Document — Aida Counter and Aida Office

| Field | Value |
|---|---|
| **Product** | Aida Café Rewards — Staff POS and Management Admin |
| **Products** | Aida Counter · Aida Office · Employee Access |
| **Document** | React UI Product Requirements Document |
| **Version** | 0.2 |
| **Date** | 21 July 2026 |
| **Status** | Expanded requirements approved for UI design; implementation and backend integration remain phased |
| **Audience** | Product stakeholders, Team 1 UI, Team 2 backend/mobile, QA and management |
| **React path** | `apps/pos-admin-web` |
| **UI branch** | `team1/aida-pos-admin-ui` |
| **Base branch** | `feature/aida-cafe-production-rewire-phase3a` |
| **Current release type** | High-fidelity UI preview using sample data; not production cutover |

---

## 1. Document purpose

This PRD defines the complete target user experience for:

1. **Employee Access** — terminal activation, employee authentication and role routing.
2. **Aida Counter** — staff point-of-sale and shift operations.
3. **Aida Office** — management dashboard, reporting, operations, catalogue, inventory, rewards, campaigns and system controls.

The UI serves two purposes:

- Provide accurate visual progress evidence for stakeholders.
- Provide Team 2 with a workflow and data benchmark for backend implementation.

The presence of a screen in the UI preview does not mean that its backend capability is complete. Preview-driven screens must be labelled clearly and must not be presented as production functionality.

This document supplements the master product PRD at the repository root. Approved business rules in the master PRD remain authoritative where they conflict with sample preview data.

---

## 2. Version 0.2 changes

Version 0.2 expands the earlier UI PRD with:

- Complete payment states, cash tender and change.
- Order types and kitchen/bar routing.
- Void, cancellation, comp and refund workflows.
- Printer, cash drawer, payment terminal and KDS status.
- Offline mode and reconciliation requirements.
- Complete Admin dashboard and report catalogue.
- Multi-branch and sales-point management.
- Menu publishing, variants, modifiers and channel availability.
- Inventory, recipe, wastage and stock-control requirements.
- Versioned rewards, offers, vouchers and student rules.
- Mobile-app advertisement and campaign publishing.
- Employee permissions, session control and audit requirements.
- A formal screenshot evidence and progress-report standard.
- Correction of discrepancies discovered in the first screenshot package.

---

## 3. Team ownership

The current team split overrides older documentation that uses different ownership.

| Team | Responsibility |
|---|---|
| **Team 1** | React UI/UX for Employee Access, Aida Counter and Aida Office; sample-data preview; responsive states; tests; screenshots; UI/backend benchmark documentation |
| **Team 2** | Entire backend, API, database, migrations, authentication implementation, server-side permissions, reports queries, business rules, integrations, mobile app connection and production deployment |
| **Joint/Product** | Business-rule approval, acceptance criteria, modifier/reward definitions, payment provider, offline policy, hardware decisions and UAT |

### 3.1 Team 1 restrictions

Team 1 must not:

- Create or modify API routes.
- Create or apply database migrations.
- Connect directly to Neon/PostgreSQL.
- Implement server-authoritative prices, discounts, rewards or financial reports.
- Change `openapi.yaml` without Team 2 contract review.
- Enable production feature flags.
- Deploy to production.

New capabilities may be demonstrated through typed, development-only fixture repositories. Preview mode must fail closed in a production build.

---

## 4. Product definitions

| Product | Route | Primary user | Purpose |
|---|---|---|---|
| **Employee Access** | `/employee` | Staff and management | Activate terminal, authenticate employee and route by server-confirmed role |
| **Aida Counter** | `/pos` | Counter staff | Open shift, take orders, apply approved rewards, accept payment and close shift |
| **Aida Office** | `/admin` | Managers/admins | Monitor, report, configure and govern café operations |
| **Unauthorised** | `/unauthorized` | Invalid or disallowed user | Explain denial and provide safe recovery |

### 4.1 Separation rules

- Staff must not see Admin navigation or management reports.
- Admin must not see or use a POS checkout cart.
- Dual-role employees must be explicitly enabled and choose a workspace.
- Empty branch access must never mean global access.
- Global management access requires an explicit global-manager flag.
- Product routing and permissions must be confirmed by the backend, not selected freely by the client.

---

## 5. Business hierarchy

The product must support:

```text
Organisation
  └── Branch
       └── Sales Point
            └── Terminal
```

Current example:

```text
Aida Café
  └── Main Café (BR-MAIN)
       ├── Main Counter (SP-MAIN)
       │    └── POS-MAIN-01
       └── Snack Station (SP-SNACK)
            └── POS-SNACK-01
```

Current inventory decision: Main Counter and Snack Station share the existing `INV-MAIN` inventory relationship. A separate Snack Station inventory must not be assumed unless management approves it later.

---

## 6. Users and access model

| Role | Default product | Key capabilities |
|---|---|---|
| Staff | Aida Counter | Shift, order entry, permitted member/reward actions, payment, receipt and own operational information |
| Manager/Admin | Aida Office | Authorised reports, operations, catalogue, rewards, campaigns, employees, terminals and audit |
| Dual-role | Role selection | Aida Counter only when dual-role POS capability is explicitly enabled; otherwise Aida Office |
| Customer/member | Customer mobile app | Must not authenticate through employee access |

### 6.1 Fine-grained permissions

The design must accommodate separate permissions for:

- Cash drawer access.
- Manual discount.
- Apply reward/voucher.
- View other employees' orders.
- Cancel or void order.
- Refund payment.
- Reprint receipt.
- Close shift with variance.
- Approve variance.
- View branch or global reports.
- Export reports.
- Edit menu.
- Publish menu.
- Edit rewards.
- Publish rewards/campaigns.
- Manage employees.
- Manage terminals.
- View audit log.

Every sensitive action requires backend permission enforcement, an appropriate reason and an audit event.

---

## 7. Aida visual identity

The system must be recognisably connected to the Aida Rewards customer application.

| Token | Value |
|---|---|
| Ivory | `#FFF9F6` |
| Cream | `#F6ECE6` |
| Surface | `#FFFCFA` |
| Espresso | `#2C171B` |
| Burgundy | `#541A28` |
| Rose | `#C92F50` |
| Floral Pink | `#DE8D9D` |
| Blush | `#F4D4DB` |
| Gold | `#C8A345` — accent only |
| Success | `#36735B` |
| Warning | `#B7782F` |
| Error | `#B63B45` |

Typography:

- Editorial serif display style for primary headings.
- Highly legible sans-serif type for operational UI.
- Existing approved Aida logo/wordmark must be reused without redrawing.

Design requirements:

- Minimum 48×48px primary POS touch targets.
- WCAG 2.2 AA target.
- Visible keyboard focus.
- No status communicated by colour alone.
- Reduced-motion support.
- No emoji iconography.
- Product imagery should align with the customer application while retaining an optional compact service mode.
- Empty, loading, offline, failure, permission-denied and retry states must be designed.

---

## 8. Responsive targets

| Product | Primary size | Minimum | Large |
|---|---:|---:|---:|
| Aida Counter | 1366×768 | 1024×768 | 1920×1080 |
| Aida Office | 1440×900 | 1024×768 | 1920×1080 |

Critical authentication, terminal activation, modifier selection and payment actions must fit within 768px height without requiring full-page scrolling. Long modal content may use an internal scroll region with sticky primary actions.

---

## 9. Shared status labels

Each preview capability must use one of these statuses in UI documentation:

| Status | Meaning |
|---|---|
| Connected to existing API | Existing endpoint is used without expanding Team 1 backend scope |
| Feature-flagged | Backend capability exists but remains disabled outside authorised environments |
| UI preview — Team 2 backend pending | Interactive sample workflow using fixtures |
| UI benchmark — contract decision pending | Team 1 demonstrates intended behaviour; Team 2 and product must approve contract |
| Future | Not part of the current implementation phase |

Sample-data screens must display:

```text
UI PREVIEW — SAMPLE DATA
```

---

## 10. Employee Access requirements

### 10.1 Terminal activation

| ID | Requirement |
|---|---|
| EA-T01 | An unenrolled device must be blocked from employee login and POS/Admin entry. |
| EA-T02 | The activation screen accepts a manager-issued, expiring, single-use enrolment code. |
| EA-T03 | Invalid, expired, already-used and server-failure states must be distinct. |
| EA-T04 | Successful activation displays branch, sales point and terminal assigned by the backend. |
| EA-T05 | Staff cannot change terminal attribution from a dropdown. |
| EA-T06 | Terminal secrets must never appear in JSON or browser-readable storage. |
| EA-T07 | Fingerprint/device information is telemetry only and cannot authenticate. |
| EA-T08 | Preview activation may use `AIDA-482731` only in development and must be visibly labelled sample data. |

### 10.2 Employee authentication

| ID | Requirement |
|---|---|
| EA-A01 | Support employee username/password authentication. |
| EA-A02 | Support approved badge + PIN authentication. |
| EA-A03 | Wrong credentials, inactive employee, locked account, rate limit and server failure must be distinguishable safely. |
| EA-A04 | Customers must be rejected from employee authentication. |
| EA-A05 | Employee sessions must use secure cookies; no employee token in localStorage. |
| EA-A06 | Idle lock requires reauthentication but does not silently close the shift. |
| EA-A07 | Logout revokes/clears the employee session. |
| EA-A08 | Dual-role selection must be explicitly authorised and audited. |

---

## 11. Aida Counter requirements

### 11.1 POS shell

The open-shift POS uses three zones:

| Zone | Purpose |
|---|---|
| Aida Rail | New Sale, Orders, Member/Rewards, Shift, Terminal and Help |
| Menu Gallery | Search, categories, product cards, availability and customisation |
| Order Ribbon | Cart, member, pricing summary and payment |

The context bar must identify employee, role, branch, sales point, terminal, shift status, shift start and connection state. Dense identifiers may be grouped into accessible status chips with detailed information available on demand.

### 11.2 Shift and cash management

| ID | Requirement |
|---|---|
| POS-S01 | Block order entry until a valid terminal and open/resumed shift exist. |
| POS-S02 | Open shift with opening float and confirmation. |
| POS-S03 | Lock and resume shift with employee reauthentication. |
| POS-S04 | Record controlled cash paid-in, paid-out, cash drop and no-sale drawer events with reason. |
| POS-S05 | Close shift with actual cash, notes, handover and confirmation. |
| POS-S06 | Calculate/show expected cash, actual cash and variance according to approved blind-close policy. |
| POS-S07 | Escalate variance above a configured threshold for manager review. |
| POS-S08 | Closed-shift summary includes opening float, cash sales, non-cash sales, cash events, expected, actual and variance. |

### 11.3 Order creation

| ID | Requirement |
|---|---|
| POS-O01 | Start a new order and select Dine-in, Takeaway or Pickup where enabled. |
| POS-O02 | Search menu by name/SKU and filter by category. |
| POS-O03 | Product cards show image or compact mode, name, price-from, availability and relevant markers. |
| POS-O04 | Sold-out and unavailable items cannot be added. |
| POS-O05 | Add item with required variant and modifier selections. |
| POS-O06 | Support quantity, item note, repeat item, edit and remove. |
| POS-O07 | Show server-authoritative subtotal, discount, configured tax/charge and total. |
| POS-O08 | Clear order requires confirmation when the cart is non-empty. |
| POS-O09 | Branch, employee, terminal and shift attribution cannot be overridden by the client. |
| POS-O10 | Prevent duplicate sale submission through idempotent server behaviour. |

### 11.4 Variants and modifiers

| ID | Requirement |
|---|---|
| POS-M01 | Support variants such as Small, Medium and Large. |
| POS-M02 | Support required and optional modifier groups. |
| POS-M03 | Support milk, sugar, temperature, extra shots and paid add-ons where configured. |
| POS-M04 | Display minimum/maximum selection rules. |
| POS-M05 | Display unavailable modifier options without allowing selection. |
| POS-M06 | Display backend-provided price adjustments. |
| POS-M07 | Show selected variant/modifiers in cart, kitchen ticket and receipt. |
| POS-M08 | Modifier dialog uses internal scrolling with sticky item total and Add to Order action. |
| POS-M09 | Order-time names and prices must be snapshotted by Team 2. |

### 11.5 Member and Aida Rewards

| ID | Requirement |
|---|---|
| POS-R01 | Make member QR/student ID scan the primary attachment method. |
| POS-R02 | Allow minimal authorised manual lookup as fallback. |
| POS-R03 | Show only staff-permitted member fields. |
| POS-R04 | Display member name, status and student verification status. |
| POS-R05 | Display Aida Points, stamp progress, eligible offers and available rewards. |
| POS-R06 | Show eligible, selected, applied and rejected reward states. |
| POS-R07 | Staff-controlled redemption requires explicit confirmation. |
| POS-R08 | Display expiry and usage limitations. |
| POS-R09 | Receipt shows points/stamps before, earned/redeemed and resulting balance from Team 2. |
| POS-R10 | Staff cannot export the member directory or unrestricted purchase history. |
| POS-R11 | Daily streaks or membership tiers remain excluded unless separately approved. |
| POS-R12 | Preview reward names and thresholds must match approved customer-app business rules. |

### 11.6 Payment

| ID | Requirement |
|---|---|
| POS-P01 | Support Cash, Card and approved QR/e-wallet methods. |
| POS-P02 | Student wallet remains a pending business/integration decision. |
| POS-P03 | Cash payment provides tendered amount, quick denominations and change due. |
| POS-P04 | Non-cash payment displays Awaiting Customer, Processing, Approved, Declined, Timeout and Unknown Result. |
| POS-P05 | Unknown results must use reconciliation/check-status before allowing retry. |
| POS-P06 | External payment terminal reference/status must be displayed when available. |
| POS-P07 | Split payment remains future unless approved by contract. |
| POS-P08 | Full card number, CVV and payment credentials must never be collected or displayed. |
| POS-P09 | Complete Sale is disabled during processing and after confirmed success. |

### 11.7 Receipt and completion

| ID | Requirement |
|---|---|
| POS-C01 | Receipt includes order number, date/time, employee, branch, sales point, terminal and shift. |
| POS-C02 | Receipt includes items, variant/modifiers, quantity, discounts/rewards, configured tax/charges and total. |
| POS-C03 | Receipt includes payment method, tendered/change for cash and safe provider reference where applicable. |
| POS-C04 | Receipt includes applicable points/stamp changes. |
| POS-C05 | Support print/reprint through an approved adapter with success/failure state. |
| POS-C06 | After successful completion, clear/lock the cart and remove the active Pay action. |
| POS-C07 | A second payment cannot be initiated for the completed order. |
| POS-C08 | New Sale starts a clean order after completion. |

### 11.8 Orders, cancellation, void, comp and refund

| ID | Requirement |
|---|---|
| POS-X01 | Orders page supports order number, date/time, status, employee, payment and total. |
| POS-X02 | Search and filter by permitted criteria. |
| POS-X03 | View order detail and reprint receipt with permission. |
| POS-X04 | Cancel an unfulfilled/unpaid order with reason. |
| POS-X05 | Void an item/check before captured payment according to policy. |
| POS-X06 | Comp requires manager permission and reason where adopted. |
| POS-X07 | Refund after payment supports item, full-order or approved amount-based refund. |
| POS-X08 | Refund displays original payment, refund method, reason, actor and approver. |
| POS-X09 | All corrective actions create audit records and appear in reports. |

### 11.9 Kitchen/bar routing

| ID | Requirement |
|---|---|
| POS-K01 | Route drinks and food to configured bar/kitchen printer or KDS destination. |
| POS-K02 | Kitchen-readable tickets show order, item, variant, modifiers, quantity, notes and order type. |
| POS-K03 | Support New, Accepted, Preparing, Ready and Collected/Completed states where KDS is used. |
| POS-K04 | Display routing or printer failure and recovery action. |
| POS-K05 | Reprint/re-fire requires permission and audit to prevent duplicate preparation. |

### 11.10 Offline and degraded operation

| ID | Requirement |
|---|---|
| POS-F01 | Replace the simple Online badge with explicit Online, Degraded, Offline and Syncing states. |
| POS-F02 | Define which actions are allowed or blocked offline. |
| POS-F03 | Queued operations must display pending state and must not appear as confirmed sales. |
| POS-F04 | Reconnection provides retry, synchronisation and conflict/reconciliation status. |
| POS-F05 | Offline payment risk and time limits are provider decisions; UI must not promise acceptance. |
| POS-F06 | Prevent duplicate submission during reconnection. |

### 11.11 Terminal and Help

Terminal screen must show:

- Terminal code, branch and sales point.
- Connection and last synchronisation.
- Last heartbeat.
- Receipt printer status.
- Kitchen/bar printer or KDS status.
- Cash drawer status where available.
- External payment-device status.
- Safe diagnostic actions without displaying secrets.

Help must include recovery guidance for terminal, shift, payment, printer/KDS, offline/sync and manager escalation.

---

## 12. Aida Office information architecture

| Group | Modules |
|---|---|
| Overview | Executive Dashboard, Live Operations |
| Reports | Sales, Transactions, Products, Branches, Payments, Shifts, Rewards, Members, Voids/Refunds, Inventory, Exports |
| Operations | Branches, Sales Points, Terminals, Shifts, Employees and Access |
| Catalogue | Menu Items, Categories, Variants, Modifier Groups, Availability, Publishing |
| Inventory | Ingredients, Recipes, Stock, Counts, Adjustments, Wastage, Transfers, Suppliers/Future |
| Rewards and Content | Loyalty Rules, Stamps, Vouchers, Offers, Student Offers, App Campaigns |
| System | Audit Log, Integrations, Settings |

Admin navigation must be permission-aware. Backend permission denial remains authoritative.

---

## 13. Admin Dashboard requirements

### 13.1 Filters

- Today.
- Yesterday.
- This Week.
- This Month.
- Custom date/time range.
- Authorised branch.
- Sales point.
- Terminal.
- Employee.
- Shift where relevant.

### 13.2 Primary KPIs

| ID | Metric |
|---|---|
| AD-K01 | Gross sales, only after definition is approved |
| AD-K02 | Discounts and rewards applied |
| AD-K03 | Refunds/void impact |
| AD-K04 | Net sales |
| AD-K05 | Order count |
| AD-K06 | Average order value |
| AD-K07 | Cash sales |
| AD-K08 | Non-cash sales |
| AD-K09 | Active/open shifts |
| AD-K10 | Cash variance requiring attention |

Comparison values must identify the comparison period. Profit must not be shown until reliable recipe cost/COGS data exists.

### 13.3 Dashboard visuals

- Sales trend by hour/day/week/month.
- Sales by branch and sales point.
- Sales by payment method.
- Sales by category.
- Peak service hours.
- Top-selling products.
- Reward/offer redemption overview.
- Open shifts and variance alerts.
- Terminal/KDS/payment/printer health alerts.
- Sold-out and low-stock alerts when inventory exists.

Every chart requires an accessible table or textual summary.

---

## 14. Admin report catalogue

| ID | Report | Required dimensions/measures |
|---|---|---|
| REP-01 | Daily sales summary | Gross, discount, refund, net, orders, AOV, cash/non-cash |
| REP-02 | Weekly/monthly sales | Period trend and prior-period comparison |
| REP-03 | Branch comparison | Sales, orders, AOV, payment, variance by branch |
| REP-04 | Sales-point comparison | Main Counter, Snack Station and future sales points |
| REP-05 | Hourly/peak-time analysis | Orders and sales by hour/day |
| REP-06 | Transaction detail | Order, timestamp, employee, terminal, shift, member/guest, amounts, payment, status |
| REP-07 | Product/category performance | Quantity, revenue, discounts and mix |
| REP-08 | Variant/modifier performance | Selections, quantity and revenue adjustment |
| REP-09 | Best/low-performing products | Ranked quantity/revenue with period comparison |
| REP-10 | Payment reconciliation | Method/provider, approved, failed, pending, refunded and variance |
| REP-11 | Discounts/offers | Reason/rule, amount, usage, employee and branch |
| REP-12 | Student offers | Eligibility type, usage and value |
| REP-13 | Member versus guest | Orders, sales and AOV |
| REP-14 | Loyalty points | Issued, redeemed, adjusted and outstanding liability where defined |
| REP-15 | Stamps/rewards | Stamps issued, completed cards, rewards issued/redeemed/expired |
| REP-16 | Vouchers | Issued, redeemed, expired and liability where supported |
| REP-17 | Shift/cash variance | Float, cash sales, cash events, expected, actual, variance and approval |
| REP-18 | Employee/terminal sales | Permission-limited orders and sales attribution |
| REP-19 | Void/refund/cancellation | Original order, amount/item, reason, actor, approver and status |
| REP-20 | Menu availability | Sold-out periods and availability events |
| REP-21 | Inventory | On-hand, movement, low stock, adjustment, wastage and transfer |
| REP-22 | Terminal health | Status, heartbeat, activation/revocation and incidents |
| REP-23 | Campaign performance | Impressions, taps, redemptions and attributed sales when events exist |
| REP-24 | Audit activity | Sensitive actions by actor/entity/branch/time |

### 14.1 Report behaviour

Every report must provide:

- Metric definitions.
- Applied-filter summary.
- Loading, empty and error states.
- Pagination.
- Search/sort where relevant.
- Totals matching the filtered dataset.
- Drill-down to permitted detail.
- Permission-controlled export.
- Export audit event.

Do not mix gross sales, net sales, collected cash and profit.

---

## 15. Live Operations

Live Operations must show:

- Branch and sales-point operating status.
- Open and locked shifts.
- Current employee and terminal.
- Terminal online/last heartbeat/revoked status.
- Printer, KDS and payment-device state where integrated.
- Current order count and backend-supplied sales total.
- Cash variance alerts.
- Sold-out/low-stock alerts.
- Service incidents and acknowledgement.

Polling/realtime transport is a Team 2 architecture decision. Team 1 must not simulate live data without a preview label.

---

## 16. Branches, sales points and terminals

### 16.1 Branches and sales points

- Create/edit/activate/deactivate branch where authorised.
- Create sales point under a branch.
- Assign inventory location.
- Configure time zone, operating hours and supported order types.
- Configure branch/sales-point menu availability and pricing overrides.
- View consolidated or scoped performance.
- Preserve historical attribution if a branch or sales point is deactivated.

### 16.2 Terminals

- List by branch and sales point.
- Display active, offline, revoked or replacement-needed status.
- Display last heartbeat and current shift.
- Generate manager-issued one-time enrolment code.
- Revoke, replace and clear credential.
- Display hardware/integration status without revealing secrets.
- Audit enrol, replace and revoke actions.

---

## 17. Employee management

- Employee identity and employment status.
- Staff, manager and explicitly enabled dual-role status.
- Branch/sales-point access.
- Explicit global-manager flag.
- Permission assignment through approved roles/policies.
- Credential reset/revoke without showing passwords, hashes or PINs.
- Session revocation.
- Current/open shift visibility.
- Historical audit of access changes.
- Prepare for future branch managers while supporting one manager initially.

---

## 18. Catalogue management

### 18.1 Menu items and categories

- Item name, SKU/code, description and image.
- Category and display order.
- Base price represented safely in integer sen at the contract boundary.
- Best seller/featured marker.
- Student-offer eligibility.
- Branch, sales-point and channel availability.
- Scheduled/daypart availability.
- Available, sold-out, hidden and discontinued states.
- Draft, review, scheduled publish and published states.
- POS and customer-app preview.
- Historical orders remain unchanged when catalogue data changes.

### 18.2 Variants and modifier groups

- Variant names and price adjustments.
- Required and optional modifier groups.
- Minimum/maximum selection.
- Option availability by branch/channel.
- Display order.
- Kitchen-readable names.
- Draft/review/publish state.
- Order-time name/price snapshots.

### 18.3 Channel management

Availability may differ by:

- Aida Counter.
- Customer Android/iOS app.
- Future QR ordering.
- Future kiosk.
- Approved delivery/integration channels.

---

## 19. Inventory and recipe management

Inventory is required for a credible multi-branch café system, even if delivered after the first POS UI milestone.

### 19.1 Ingredients and units

- Ingredient/item code and name.
- Stock unit, recipe unit and conversion.
- Inventory location/branch ownership.
- Minimum/reorder level.
- Active/inactive status.

### 19.2 Recipes/BOM

- Menu item/variant recipe.
- Ingredient quantity and yield.
- Modifier ingredient effect.
- Effective date/version.
- Recipe cost when reliable supplier cost exists.

### 19.3 Stock operations

- Receiving.
- Stock count.
- Adjustment with reason.
- Wastage/spoilage with reason.
- Sale-driven consumption.
- Branch transfer when multiple inventories exist.
- Low-stock and stockout alerts.
- Movement history and audit.

Supplier and purchase-order workflows may be introduced in a later phase.

---

## 20. Rewards, offers and vouchers

### 20.1 Rule management

- Points earn rules.
- Stamp earn rules and completion reward.
- Student eligibility.
- Applicable items/categories/branches/channels.
- Start/end schedule in Malaysia time.
- Per-member/per-order limits.
- Stacking priority and exclusions.
- Draft, scheduled, active, paused and expired states.
- Rule versioning and audit.

### 20.2 Voucher and reward lifecycle

- Create and issue.
- Eligibility.
- Available, reserved/applied, redeemed, expired, cancelled status.
- Expiry and usage limits.
- Staff-controlled redemption where required.
- Liability report where accounting definition exists.
- Changes must not rewrite historical orders or issued/redeemed rewards.

Approved customer-app terminology and thresholds must be used consistently across Aida Counter, Aida Office and Team 2 APIs.

---

## 21. App banners, advertisements and campaigns

Aida Office must provide an authorised workflow for preparing content for the customer app through Team 2's shared API.

- Campaign title and internal reference.
- Banner image and validation.
- Headline, supporting copy and call-to-action.
- Destination/deep-link type and identifier.
- Audience such as all members or verified students.
- Branch targeting where supported.
- Start/end schedule in Malaysia time.
- Draft, review, scheduled, published, paused and expired states.
- Mobile preview matching the Aida customer Home screen.
- Publish confirmation and permission.
- Publication history and audit.
- Impressions, taps, redemptions and attributed sales only after Team 2 defines reliable events.

The Admin UI must never connect directly to the mobile application's database.

---

## 22. Audit, exports and system controls

### 22.1 Audit

- Read-only interface.
- Filter by date, actor, action, entity, branch and terminal.
- Safe before/after summary.
- No secrets or excessive personal information.
- No edit/delete controls.
- Append-only enforcement belongs to Team 2/database.

### 22.2 Exports

- CSV/XLSX/PDF only where supported by Team 2.
- Permission-controlled.
- Include filter and generated-at summary.
- Large exports may require asynchronous generation.
- Export activity must be audited.

### 22.3 Integrations

Show status for approved integrations:

- Receipt printer.
- Kitchen/bar printer or KDS.
- Cash drawer.
- Payment provider/terminal.
- Customer mobile app.
- Campaign/push delivery.
- MyInvois when approved.

MyInvois must remain labelled **Pending business and API decision** until the organisation confirms its compliance path and Team 2 implements it. The UI must not claim compliance prematurely.

---

## 23. Backend benchmark requirement

For every UI screen, Team 1 must document:

- Required fields and types.
- Required read/actions.
- Success state.
- Validation errors.
- Permission-denied state.
- Conflict state.
- Server failure and retry state.
- Role and branch requirements.
- Expected audit event.
- Current capability status.

This benchmark guides Team 2 but does not authorise Team 1 to create endpoints or modify OpenAPI.

Required documentation:

- `docs/AIDA_UI_BACKEND_BENCHMARK.md`
- `docs/AIDA_UI_API_CAPABILITY_MATRIX.md`
- `docs/AIDA_REPORT_CATALOGUE.md`
- `docs/AIDA_UI_SCREEN_AND_PERMISSION_MAP.md`

---

## 24. Screenshot and progress-report requirements

### 24.1 Current evidence correction

The first submitted archive contains 20 Admin filenames whose PNG files are identical and show Employee Access rather than the intended Admin pages. `11-pos-counter-new-sale.png` and `12-pos-menu-coffee.png` are also identical. These must be regenerated before the Admin UI is reported as complete.

### 24.2 Required POS screenshots

1. Employee welcome.
2. Password login.
3. Badge/PIN login.
4. Terminal activation.
5. Invalid/expired enrolment code.
6. Dual-role selection.
7. Open shift.
8. New sale and order type.
9. Menu/category state.
10. Variant/modifier selection with visible Add action.
11. Cart with item details.
12. Member/rewards selected and reward applied.
13. Cash tender/change.
14. Non-cash processing/failure state.
15. Completed sale with cleared cart.
16. Full receipt/print state.
17. Orders/detail.
18. Void/refund permission flow.
19. Shift controls.
20. Close shift and variance.
21. Terminal/device health.
22. Offline/degraded state.

### 24.3 Required Admin screenshots

1. Executive Dashboard — Today.
2. Executive Dashboard — This Month.
3. Live Operations.
4. Branch/sales-point comparison.
5. Sales report.
6. Transaction report/detail.
7. Product/category performance.
8. Payment reconciliation.
9. Shift/cash variance.
10. Rewards/offer report.
11. Refund/void report.
12. Branches and sales points.
13. Terminals.
14. Shifts.
15. Employees and permissions.
16. Menu management.
17. Menu item editor.
18. Categories.
19. Variants/modifier groups.
20. Inventory/recipe.
21. Stock/wastage.
22. Loyalty/stamp rules.
23. Offers/student offers.
24. App campaign editor.
25. Mobile campaign preview.
26. Audit log.
27. Integrations.
28. Settings.

### 24.4 Caption standard

Each screenshot requires:

- Screen name.
- User role.
- What it demonstrates.
- Status: Connected, Feature-flagged, UI Preview or Future.
- Team 2 dependency.
- Stakeholder decision if needed.

Captions must never imply that fixture-driven functionality is production complete.

---

## 25. Validation and acceptance

### 25.1 UI validation

- Strict TypeScript passes.
- Existing unit and E2E suites remain passing.
- Staff cannot reach Admin routes.
- Admin cannot use POS unless explicit dual-role permission exists.
- Empty branch access does not become global.
- Terminal/location cannot be changed by staff.
- No open shift blocks sales.
- Preview mode cannot be enabled in production build.
- Completed sale cannot be paid twice.
- Critical actions fit 1024×768 and 1366×768.
- Keyboard and accessible-name checks pass.
- Screenshot automation reaches and validates the intended route before capture.

### 25.2 Backend acceptance

Team 2 must validate:

- Server-authoritative employee, role, branch, terminal and shift.
- Server-authoritative menu price, modifier price, discount, reward, tax/charge and total.
- Idempotent checkout.
- Payment reconciliation.
- Audit creation.
- Report definitions/totals.
- No direct client database access.
- Secure session, CSRF and rate-limit behaviour.

### 25.3 UAT scenarios

At minimum:

1. Staff starts duty, opens shift, sells to guest and closes shift.
2. Staff attaches verified student, applies eligible offer and completes sale.
3. Invalid reward is rejected with a clear reason.
4. Cash sale calculates correct change.
5. Non-cash payment declines and is retried safely.
6. Completed order cannot be paid twice.
7. Food/drink routes to the correct destination.
8. Manager reviews daily and monthly sales by branch.
9. Manager investigates variance and refund.
10. Manager publishes menu/reward/campaign under permission and audit.

---

## 26. Delivery priorities

### P0 — before presenting the complete POS/Admin design

1. Produce valid, unique Admin screens and screenshots.
2. Build Dashboard, Branch, Sales, Transaction, Payment, Shift and Refund/void reports.
3. Correct post-payment cart/Pay state.
4. Fix access and modifier layouts at 768px height.
5. Add cash tender/change and payment failure/retry states.
6. Add order type and kitchen/bar routing.
7. Add void/cancel/refund workflows.
8. Align reward rules with the customer app/master PRD.
9. Complete Team 2 benchmark fields/actions/errors for all P0 screens.

### P1 — credible pilot requirement

1. Multi-branch/sales-point management.
2. Complete menu/category/variant/modifier editors and publishing.
3. Inventory, recipe, stock and wastage design.
4. Device and integration health.
5. Offline/reconciliation UX.
6. Rewards, vouchers, offers and campaigns.
7. Employee permissions and audit UI.
8. Secure exports and comprehensive loading/error states.

### P2 — after pilot foundation

1. Supplier and purchase-order workflow.
2. Advanced campaign attribution and segmentation.
3. Forecasting and demand planning.
4. Ingredient-level profitability after reliable COGS.
5. Staff scheduling if required.
6. Approved MyInvois integration.

---

## 27. Open decisions

1. Approved payment provider and settlement flow.
2. Receipt printer, kitchen/bar printer and KDS hardware.
3. Offline sales/payment policy and risk owner.
4. Approved modifier and variant API contract.
5. Final points, stamps, free-reward and student-offer rules.
6. Reward stacking priority.
7. Blind-close versus visible expected cash policy.
8. Cash variance approval threshold.
9. Student-wallet ownership and integration.
10. Separate inventory per future branch and transfer policy.
11. Future branch-manager scope.
12. Campaign approval workflow.
13. MyInvois business/compliance path.
14. Staff scheduling scope.

---

## 28. Current honest progress wording

Until P0 Admin evidence is corrected, report the project as:

> **Aida Counter interactive React UI prototype completed for review. Aida Office Admin design and screenshot validation remain in progress. All screens using sample data are UI benchmarks for Team 2 backend implementation and are not production functionality.**

---

## 29. Benchmark references

- [Square — restaurant POS capabilities](https://squareup.com/us/en/the-bottom-line/operating-your-business/best-restaurant-pos-system)
- [Square — multi-location/channel menu management](https://squareup.com/help/us/en/article/8553/manage-your-menus-across-locations-and-sales-channels)
- [Square — restaurant inventory](https://squareup.com/us/en/inventory-management/restaurants)
- [Square — refund workflow](https://squareup.com/help/us/en/article/6116/process-refunds)
- [Square — offline payments](https://squareup.com/help/us/en/article/7777/process-card-payments-with-offline-mode)
- [Toast — voiding orders](https://doc.toasttab.com/doc/platformguide/adminVoidingOrders.html)
- [Toast — cash drawer reporting](https://doc.toasttab.com/doc/platformguide/adminGlossary.html)
- [Toast — employee permissions](https://doc.toasttab.com/doc/platformguide/adminPermissions.html)
- [StoreHub Malaysia — multi-outlet café POS](https://www.storehub.com/my/blog/how-to-select-a-pos-system-for-your-restaurant-or-cafe)
- [Qashier Malaysia — F&B POS/KDS/QR ecosystem](https://qashier.com/my/blog/2022/06/10/grabfood-qashier-official-integration-saves-time-and-money/)

---

## 30. Approval record

| Review | Name | Decision | Date | Notes |
|---|---|---|---|---|
| Product/Management |  | Pending |  |  |
| Team 1 UI Lead |  | Pending |  |  |
| Team 2 Backend Lead |  | Pending |  |  |
| QA/UAT |  | Pending |  |  |
