# Aida Café React UI Correction Prompt for Cursor

Copy everything below this line into a **new Cursor Agent chat** opened in the existing `CityCafePrototype` repository.

---

You are acting as a senior React product engineer and UI/UX engineer inside the existing Aida Café repository.

Your task is to correct and complete the Aida Counter POS and Aida Office Admin UI according to the updated requirements and engineering gap analysis. This is Team 1 UI work only.

Do not treat the current preview as finished. Inspect it, preserve what is correct, repair the identified problems and produce reliable screenshot evidence for the progress report and Team 2 backend benchmark.

## 1. Mandatory documents

Read these completely before changing code:

1. `AIDA_REACT_UI_PRD_v0.2.md`
2. `AIDA_REACT_UI_PRD.md` if the earlier version remains
3. `PRD.md`
4. `openapi.yaml` — read-only reference
5. `docs/AIDA_POS_ADMIN_UI_SPEC.md`
6. `docs/AIDA_UI_SCREEN_AND_PERMISSION_MAP.md`
7. `docs/AIDA_UI_API_CAPABILITY_MATRIX.md`
8. `docs/AIDA_UI_BACKEND_BENCHMARK.md`
9. `docs/AIDA_REPORT_CATALOGUE.md`
10. `docs/AIDA_UI_VALIDATION.md`
11. `docs/ROLE_PERMISSION_MATRIX.md`
12. `docs/BRANCH_SALES_POINT_MODEL.md`
13. `apps/pos-admin-web/README.md`
14. `apps/pos-admin-web/package.json`
15. All current files under `apps/pos-admin-web/src`
16. The current screenshot capture script and tests

If `AIDA_REACT_UI_PRD_v0.2.md` is not present, stop and report that it must be added before implementation. Do not use the old PRD alone.

## 2. Current team ownership

This ownership overrides older repository wording:

- **Team 1:** React UI/UX for Employee Access, Aida Counter and Aida Office; preview fixtures; UI tests; screenshots; backend benchmark documentation.
- **Team 2:** Entire backend, API, database, migrations, server-side authentication and permissions, reports queries, integrations, mobile-app connection and deployment.

Team 1 must not implement or repair backend functionality.

## 3. Allowed and prohibited files

### Allowed

- `apps/pos-admin-web/**`
- UI-specific documentation under `docs/**`
- Screenshot evidence under `apps/pos-admin-web/docs_screenshots/**`
- The updated UI PRD only if formatting/status corrections are needed

### Prohibited

Do not modify:

- `production/api/**`
- `production/database/**`
- Any SQL or migration
- `openapi.yaml`
- Root legacy/customer `index.html`
- Customer/mobile application code
- Production environment configuration
- Neon or any database

Do not deploy, migrate, push, merge or open a pull request.

Before implementation, run:

```powershell
git branch --show-current
git status --short
git diff --name-only
```

The expected branch is:

```text
team1/aida-pos-admin-ui
```

If there are unrelated changes, preserve them and report the conflict. Do not delete or overwrite another person's work.

## 4. Preview-mode rule

All new functionality in this task is an interactive UI benchmark unless an existing, already-approved API adapter is present.

Requirements:

- Use typed development-only fixture repositories.
- Preserve existing working API adapters without expanding backend scope.
- Display `UI PREVIEW — SAMPLE DATA` whenever fixtures are active.
- Never mix sample and live data.
- Preview mode must remain impossible in a production build.
- Do not create fake API URLs or modify OpenAPI.
- Document Team 2 requirements for every new workflow.

## 5. Known defects that must be corrected

The previous screenshot archive had these verified problems:

1. All 20 Admin screenshots were byte-for-byte identical and showed Employee Access instead of Admin pages.
2. `11-pos-counter-new-sale.png` and `12-pos-menu-coffee.png` were identical.
3. Employee login/enrolment pages exceeded a 768px viewport height.
4. The modifier modal hid the primary Add to Order action below the viewport.
5. The completed-sale receipt retained the cart with an active Pay button.
6. Payment lacked cash received, change due, processing, decline, timeout and retry states.
7. Admin modules did not have sufficient visual evidence or operational depth.
8. Preview reward rules did not clearly match the approved customer-app/master PRD rules.

Fix all eight items. Do not merely rename screenshot files.

## 6. Implementation sequence

Complete the following stages in order. Keep the application runnable after each stage.

### Stage A — Evidence and route integrity

1. Inspect why Admin screenshot capture remained on Employee Access.
2. Correct preview authentication/session setup for screenshot automation without weakening production authentication.
3. Before capturing a route, assert:
   - Expected URL
   - Expected product name
   - Expected unique page heading
   - Preview-mode banner
4. Fail screenshot capture if the expected route/heading is not reached.
5. Detect unexpected duplicate screenshot hashes and fail with filenames.
6. Allow intentionally related screenshots only when they demonstrate a visibly different state.
7. Do not place preview passwords prominently in management progress screenshots.

### Stage B — Shared design and responsive corrections

1. Preserve the Aida Signature colours and typography.
2. Make Employee Access, terminal activation and role selection fit 1366×768 and 1024×768 without full-page scrolling.
3. Maintain at least 48×48px primary POS targets.
4. Simplify the dense POS context bar into readable status groups:
   - Employee and role
   - Branch/sales point/terminal
   - Shift and connection status
5. Keep the full attribution available through accessible details/popover.
6. Provide loading, empty, permission-denied, offline, failed and retry states.
7. Do not create a generic blue SaaS dashboard or copy Square/Toast/Qashier layouts.

## 7. Correct and complete Aida Counter

### 7.1 New Sale workspace

Preserve the three-zone layout:

- Aida Rail
- Menu Gallery
- Order Ribbon

Add or correct:

- Order type: Dine-in, Takeaway and Pickup where enabled.
- Category filter with genuinely different screenshot states.
- Search by product/SKU.
- Product imagery using approved/local assets, plus a compact mode for speed.
- Best seller, sold-out and unavailable states.
- Clear empty-cart state.
- Quantity, edit, remove and optional item note.
- Confirmation before clearing a non-empty sale.

### 7.2 Modifier dialog

Implement a professional modifier experience:

- Variant such as Small, Medium and Large.
- Required and optional groups.
- Milk choices, sugar, temperature, extra shot and paid add-ons where present in fixture data.
- Minimum/maximum selection help.
- Unavailable option state.
- Backend-supplied/fixture price adjustment display.
- Selected summary.
- Sticky item total.
- Sticky `Add to order` primary action that remains visible at 1024×768 and 1366×768.
- Internal scroll area for long options.

Keep this labelled as a UI benchmark awaiting Team 2 modifier contract.

### 7.3 Member and Aida Rewards

Improve the member workflow:

- Make `Scan member / Student ID` the primary action.
- Keep minimal manual lookup as fallback.
- Display member name and status.
- Display verified/pending/expired student status.
- Display Aida Points and stamp progress.
- Display eligible offers, vouchers and rewards with expiry.
- Allow staff to select and explicitly apply an eligible reward in preview.
- Show rejected/ineligible reason.
- Show selected reward in the Order Ribbon.
- Display the expected before/after points and stamps on the receipt using fixture results.
- Do not expose unrestricted member history or export.

Use the approved master PRD/customer-app reward terminology. If the final free reward or threshold is unclear, mark it `Product decision pending`; do not invent conflicting rules.

### 7.4 Payment

Create a stateful preview benchmark covering:

#### Cash

- Total due.
- Cash received.
- Quick tender buttons.
- Change due.
- Insufficient tender validation.
- Confirm payment.

#### Card/e-wallet external terminal

- Awaiting customer.
- Processing.
- Approved.
- Declined.
- Timeout.
- Unknown result requiring status check/reconciliation.
- Safe retry only after status is resolved.
- Safe provider/reference placeholder.

Do not collect or display card number or CVV. Student Wallet must be marked as a pending integration decision unless approved in the updated PRD.

### 7.5 Receipt and completed-sale state

The completed receipt must show:

- Order number.
- Date and time.
- Employee.
- Branch, sales point and terminal.
- Shift reference/status.
- Order type.
- Items, variants, modifiers, quantities and notes.
- Subtotal.
- Discounts/rewards.
- Configured tax/charges only when fixture definition exists.
- Total.
- Payment method.
- Tender/change for cash.
- Safe external reference where applicable.
- Points/stamps before, change and resulting balance where applicable.
- Print/reprint result state.

After successful payment:

- Clear or permanently lock the completed cart.
- Remove/disable Pay.
- Prevent a second payment.
- Provide `New Sale` as the primary next action.

### 7.6 Orders and corrective actions

Improve Orders with:

- Search and filters.
- Order number, time, status, employee, member/guest, payment and total.
- Order detail.
- Reprint receipt where permitted.
- Cancel unpaid/unfulfilled order with reason.
- Void before captured payment with reason.
- Comp as manager-controlled preview if retained.
- Refund after payment: item/full/approved amount, reason and manager approval state.
- Audit event expectation clearly documented for Team 2.

### 7.7 Kitchen/bar routing

Add a UI benchmark for:

- Drink → bar destination.
- Food/snack → kitchen or configured printer/KDS destination.
- Ticket content with order, item, modifiers, notes and order type.
- New, Preparing, Ready and Collected states where KDS is enabled.
- Printer/KDS failure and retry/escalation state.
- Reprint/re-fire permission warning.

### 7.8 Shift, terminal and offline

Enhance Shift:

- Opening float.
- Lock/resume.
- Cash paid-in, paid-out and cash drop with reason.
- Close with actual cash, notes and handover.
- Expected/actual/variance.
- Manager review when variance exceeds sample threshold.
- Closed-shift summary.

Enhance Terminal:

- Terminal, branch and sales point.
- Online/degraded/offline/syncing.
- Last heartbeat and last sync.
- Receipt printer.
- Kitchen/bar printer or KDS.
- Cash drawer where available.
- Payment terminal.
- Safe troubleshooting actions.

Create offline/degraded UI states:

- Clear banner.
- Actions allowed/blocked.
- Pending sync state.
- Reconnection/synchronisation.
- Conflict/reconciliation state.
- Never show queued sample action as a confirmed sale.

Enhance Help with recovery guidance for terminal, shift, printer/KDS, payment and offline issues.

## 8. Build real Aida Office pages

Do not use one generic placeholder component for every Admin route. Every route must have unique content, relevant controls, realistic fixture data and correct states.

### 8.1 Executive Dashboard

Create high-fidelity Today, This Month and custom-range views.

KPIs:

- Gross sales, only with a clear definition.
- Discounts/rewards.
- Refunds/void impact.
- Net sales.
- Orders.
- Average order value.
- Cash sales.
- Non-cash sales.
- Open shifts.
- Variance alerts.

Visuals/tables:

- Sales trend.
- Sales by branch/sales point.
- Payment-method mix.
- Category mix.
- Hourly demand.
- Top products.
- Reward redemption.
- Operational alerts.

Do not show profit unless reliable COGS exists. Every chart requires an accessible table/text summary.

### 8.2 Live Operations

Show:

- Main Café, Main Counter and Snack Station.
- Open/locked shifts.
- Current employee/terminal.
- Last terminal heartbeat.
- Printer/KDS/payment status.
- Current sample order count.
- Variance, sold-out and low-stock alerts.
- Incident acknowledgement preview.

### 8.3 Required reports

Build distinct high-fidelity screens for:

1. Daily/weekly/monthly sales.
2. Branch and sales-point comparison.
3. Transactions and receipt detail.
4. Products/categories/variants/modifiers.
5. Payments and reconciliation.
6. Shifts and cash variance.
7. Discounts, student offers, vouchers and rewards.
8. Member versus guest and loyalty activity.
9. Voids, cancellations and refunds.
10. Inventory/stock/wastage.
11. Terminal health.
12. Export history/controls.

Each report must provide:

- Date and relevant authorised filters.
- Filter summary.
- KPI summary.
- Paginated/searchable/sortable table where relevant.
- Loading, empty and error states.
- Totals consistent with the fixture dataset.
- CSV/XLSX/PDF buttons only as disabled `Team 2 API pending` controls unless an approved existing adapter exists.
- No client-calculated production financial claims.

### 8.4 Branches and sales points

Design:

- Organisation → Branch → Sales Point → Terminal hierarchy.
- Main Café with Main Counter and Snack Station.
- Branch/sales-point status.
- Operating hours and enabled order types.
- Menu/price override presentation.
- Staff/terminal assignment summary.
- Inventory relationship showing shared `INV-MAIN` for current Main Counter/Snack Station.
- Future branch transfer capability marked as future.

### 8.5 Terminals, shifts and employees

Terminals:

- List/status/last heartbeat/current shift.
- Generate preview OTC.
- Revoke/replace confirmation states.
- Hardware/integration health.
- No secret display.

Shifts:

- Open/locked/closed filters.
- Employee, terminal, branch, float, sales, expected, actual and variance.
- Variance review/approval preview.

Employees:

- Staff, manager and explicit dual-role.
- Branch access.
- Explicit global-manager flag.
- Active/inactive status.
- Permission summary.
- Credential/session revoke preview without showing secrets.

### 8.6 Catalogue

Create high-fidelity pages for:

- Menu item list.
- Category list/order.
- Item editor.
- Image and description.
- Base price.
- Branch/sales-point/channel availability.
- Best seller/featured.
- Student-offer eligibility.
- Scheduled/daypart availability.
- Draft/review/scheduled/published states.
- Customer-app and POS preview.
- Variants and modifier groups with selection limits.

Publish controls must be preview-only and require confirmation. Document expected audit events.

### 8.7 Inventory and recipes

Create UI benchmark pages for:

- Ingredients and units.
- Recipe/BOM by menu item/variant.
- Modifier ingredient effect.
- Stock on hand.
- Low-stock alert.
- Receiving.
- Stock count.
- Adjustment with reason.
- Wastage/spoilage with reason.
- Shared Main Café inventory.
- Future branch transfer.

Do not present profit/food cost as reliable unless the fixture includes clearly defined ingredient cost and recipe data.

### 8.8 Rewards and campaigns

Create high-fidelity management for:

- Points rules.
- Stamp rules.
- Voucher/reward lifecycle.
- Student offers.
- Eligibility and applicability.
- Start/end schedule.
- Usage limits.
- Stacking priority.
- Draft/scheduled/active/paused/expired.
- POS/customer-app preview.
- Publish confirmation and audit expectation.

Campaigns:

- Title and internal reference.
- Banner image validation.
- Headline, copy and CTA.
- Destination/deep link.
- Audience, including all members/verified students where supported.
- Branch targeting.
- Malaysia-time scheduling.
- Draft/review/scheduled/published/paused/expired.
- Mobile preview consistent with the Aida Rewards Home screen.
- Metrics placeholders only when labelled Team 2 analytics pending.

### 8.9 Audit, integrations and settings

Audit:

- Read-only.
- Filters for date, actor, action, entity, branch and terminal.
- Safe before/after summary.
- No edit/delete.

Integrations:

- Receipt printer.
- Kitchen/bar printer or KDS.
- Payment provider.
- Customer app.
- Campaign/push delivery.
- MyInvois labelled `Pending business and API decision`.

Settings must avoid becoming a miscellaneous placeholder. Include only approved UI settings with ownership and effective scope.

## 9. Fixture consistency

Create one deterministic fixture domain used by every screen.

Requirements:

- Today/month/branch totals must reconcile with the transaction rows.
- Refund and discount totals must reconcile with the dashboard.
- Shift totals must reconcile with cash sales and cash variance.
- Member points/stamps must reconcile with sample receipt outcomes.
- Product performance must reconcile with sample order lines.
- Main Counter and Snack Station must roll up into Main Café.
- Currency uses Malaysian Ringgit.
- Display time uses Asia/Kuala_Lumpur.
- Do not mix contradictory member/reward rules.

Document fixture definitions so Team 2 understands the intended report semantics.

## 10. Screenshot deliverables

Regenerate the screenshot package after implementation.

### Required POS evidence

1. Employee welcome.
2. Password login.
3. Badge/PIN login.
4. Terminal activation.
5. Invalid/expired enrolment.
6. Role selection.
7. Open shift.
8. New sale/order type.
9. Coffee category.
10. Modifier dialog with visible Add action.
11. Cart.
12. Member/reward applied.
13. Cash tender/change.
14. Non-cash failure/retry.
15. Completed sale with no active Pay/cart.
16. Full receipt/print status.
17. Order detail.
18. Void/refund flow.
19. Shift/cash controls.
20. Close/variance.
21. Terminal/device health.
22. Offline/degraded state.

### Required Admin evidence

1. Dashboard Today.
2. Dashboard This Month.
3. Live Operations.
4. Branch/sales-point comparison.
5. Sales report.
6. Transaction report/detail.
7. Product performance.
8. Payment reconciliation.
9. Shift/cash variance.
10. Reward/offer report.
11. Refund/void report.
12. Branches/sales points.
13. Terminals.
14. Shifts.
15. Employees/permissions.
16. Menu management.
17. Menu item editor.
18. Categories.
19. Variants/modifiers.
20. Inventory/recipe.
21. Stock/wastage.
22. Loyalty/stamps.
23. Offers/student offers.
24. Campaign editor.
25. Mobile campaign preview.
26. Audit log.
27. Integrations.
28. Settings.

Screenshot rules:

- POS: 1366×768 unless testing the 1024×768 minimum.
- Admin: 1440×900.
- PNG with no Cursor/IDE/browser chrome.
- Unique, descriptive filenames.
- Verify expected route and heading before capture.
- Fail on unexpected duplicate hashes.
- No real secrets.
- Preview label visible where fixtures are used.

Create/update `docs/AIDA_PROGRESS_SCREENSHOT_INDEX.md` with human-written captions containing:

- Screen.
- Role.
- What it demonstrates.
- Capability status.
- Team 2 dependency.
- Stakeholder decision where relevant.

## 11. Documentation updates

Update:

- `docs/AIDA_POS_ADMIN_UI_SPEC.md`
- `docs/AIDA_UI_SCREEN_AND_PERMISSION_MAP.md`
- `docs/AIDA_UI_API_CAPABILITY_MATRIX.md`
- `docs/AIDA_UI_BACKEND_BENCHMARK.md`
- `docs/AIDA_REPORT_CATALOGUE.md`
- `docs/AIDA_UI_VALIDATION.md`
- `docs/AIDA_PROGRESS_SCREENSHOT_INDEX.md`

Every visible action must be marked:

- Existing API connection.
- Feature-flagged existing capability.
- UI preview awaiting Team 2.
- Contract decision pending.
- Future.

Do not edit `openapi.yaml`.

## 12. Testing requirements

Preserve all existing tests and add coverage for corrections:

- Staff cannot access Admin.
- Admin cannot access POS without explicit dual-role capability.
- Empty branch access is not global.
- Staff cannot change terminal/location.
- No open shift blocks order entry.
- Modifier primary action remains visible at target viewport.
- Cash change validation.
- Payment processing disables repeat submission.
- Completed sale has no active Pay and cannot pay twice.
- Reward eligibility and rejected state.
- Void/refund permission and confirmation.
- Preview mode fails closed in production build.
- Admin routes render correct unique headings.
- Screenshot capture fails when routed to Employee Access unexpectedly.
- Unexpected duplicate screenshot hashes fail validation.
- Keyboard and accessible-name smoke tests.

Run:

```powershell
cd apps/pos-admin-web
npm run typecheck
npm test
npm run build
npm run test:e2e
node scripts/capture-all-screens.mjs
```

Report exact test counts. Do not claim a test passed if it was not run.

## 13. Completion gate

Do not call this correction complete unless:

1. All eight known defects are corrected.
2. Admin screenshots show actual, unique Admin pages.
3. POS P0 workflows are usable as an interactive preview.
4. Fixture totals reconcile across dashboard/reports/transactions/shifts.
5. Screens clearly distinguish preview from live functionality.
6. Team 2 receives updated backend benchmark documentation.
7. Typecheck, tests, build and available E2E pass.
8. Screenshot validation passes.
9. No backend, database, OpenAPI, customer app or production file changed.
10. Nothing was pushed or merged.

## 14. Final response format

When finished, respond with:

1. Pre-flight branch and working-tree findings.
2. Known defects corrected, one by one.
3. POS screens and workflows completed.
4. Admin screens and reports completed.
5. Existing API connections versus preview fixtures.
6. Fixture reconciliation results.
7. Files created/changed.
8. Dependencies added and justification.
9. Tests with exact counts.
10. Screenshot count, directories and duplicate-hash result.
11. Accessibility/responsive validation.
12. Remaining Team 2 backend requirements.
13. Remaining stakeholder decisions.
14. Confirmation that prohibited files and production were untouched.
15. Confirmation that nothing was pushed or merged.

Begin with pre-flight inspection, then implement the corrections in the stated sequence. Do not ask Team 1 to repair backend failures; use preview repositories and document the Team 2 dependency.
