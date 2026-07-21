# POS / Admin UI Closure Gate

## Scope

Frontend-only closure of the Aida Café React POS/Admin preview under `apps/pos-admin-web` inside **Aida_System**.

This gate validates Employee Access, Aida Counter (POS), and Aida Office (Admin) as an interactive **UI PREVIEW — SAMPLE DATA** surface. No backend, database, payments, loyalty mutations, or deployments are included.

## Branch and commit baseline

| Item | Value |
|---|---|
| Repository | `Aida_System` (`https://github.com/devlabmy/Aida_System.git`) |
| Branch | `team1/aida-pos-admin-ui` |
| Default branch | `master` |
| Migration baseline | `02bde1e93e5d930a4dc9e0baed72fb4a5a94cf24` |
| Mode | `VITE_UI_PREVIEW_MODE=true` |

## UI modules completed

1. **Employee Access** — terminal activation, password and badge/PIN login, dual-role selection, unauthorized, preview banner, logout
2. **Aida Counter (POS)** — open/close shift, menu, modifiers, cart, member/rewards preview, cash/card payment states, receipt, offline/terminal health
3. **Aida Office (Admin)** — dashboard (today/month), reports, branches, sales points, terminals, staff, menu editor, modifiers, loyalty, campaigns, ad publishing, members, audit, settings

## Preview / demo accounts

Documented in `apps/pos-admin-web/src/preview/demoAccounts.ts` (UI preview only):

| Account | Username | Password | Role |
|---|---|---|---|
| Staff | `preview.staff` | `preview123` | POS |
| Admin | `preview.admin` | `preview123` | Admin |
| Dual | `preview.dual` | `preview123` | Role select |
| Enrolment | `AIDA-482731` | — | Terminal activate |

## Routes validated

- `/employee`, `/employee/select-role`, `/unauthorized`
- `/pos`
- `/admin` and Admin nav routes including `/admin/operations/sales-points`, `/admin/rewards/ads`

## Network-isolation evidence

Runtime request monitoring during closure screenshot capture and Playwright preview e2e:

- Forbidden hits to `/api`, `:3001`, `:3011`, Neon, Render, Railway: **0**
- External fonts observed (allowed): Google Fonts (`fonts.googleapis.com`, `fonts.gstatic.com`)
- Vite API proxy is disabled in this Aida_System copy

## Test counts

| Suite | Count | Result |
|---|---|---|
| Vitest test files | 12 | pass |
| Vitest tests (unit/integration) | 41 | pass |
| Playwright e2e files (preview) | 1 (`preview-closure.spec.ts`) | pass |
| Playwright e2e tests | 6 | pass |
| API-backed e2e (`critical-flows.spec.ts`) | skipped in preview gate | N/A |
| Typecheck | `npm run typecheck` | pass |
| Production build | `npm run build` | pass |

## Screenshot evidence

| Item | Result |
|---|---|
| Folder | `apps/pos-admin-web/docs/screenshots/closure-gate/` |
| Captures | **38** |
| Unique SHA-256 hashes | **38** |
| Failed / skipped | **0** |
| Duplicate-hash result | **PASS** |
| Manifest | `docs/pos-admin-ui/POS_ADMIN_SCREENSHOT_MANIFEST.md` |

## Accessibility result

- Preview e2e and capture flows exercise labelled enrolment/login inputs, headings, and primary actions
- Existing unit coverage includes employee a11y smoke (`employeeA11y.test.tsx`)
- Known gap: full WCAG audit not automated in this gate; focus indicators and 48px targets are design-system intent, not exhaustively measured for every control

## Responsive result

- POS capture viewport: **1366×768**
- Admin capture viewport: **1440×900**
- Tablet smoke during capture: **1024×768** (open-shift path exercised without crash)
- Known gap: dedicated tablet screenshot set not archived as named evidence files

## Known frontend gaps

- Kitchen/bar routing is presentation-only on order/receipt copy
- Inventory/recipes/wastage and some report exports are fixture/disabled-control surfaces
- Idle-lock is implemented but not part of the numbered closure screenshot set
- API-backed Playwright suite remains for a future Team 2 environment (`npm run test:e2e:api`)

## Backend-dependent items

- Real terminal OTC enrolment cookies
- Real employee auth sessions
- Persisted sales, payments, loyalty, inventory, audit, and exports
- Customer-app campaign/ad publish integration
- Production fail-closed deployment wiring

## Production untouched

Confirmed:

- No `production/` tree in Aida_System
- `apps/customer` not modified for this gate
- CityCafePrototype not modified
- No merge to `master`
- No deployment performed
