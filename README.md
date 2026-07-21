# Aida System

Monorepo for Aida Café frontends. Customer and POS/Admin UIs are separate apps that will share a backend later; this branch ships the React POS/Admin UI in **mock/preview mode only**.

## Apps

| App | Path | Stack |
|---|---|---|
| Customer | `apps/customer` | Flutter |
| POS / Admin | `apps/pos-admin-web` | React + Vite + TypeScript |

## Customer app

```powershell
cd apps/customer
flutter pub get
flutter run -d chrome
```

## POS / Admin UI

Runs in UI preview mode with sample data. It does **not** call a production API, database, payments, or loyalty backend.

```powershell
cd apps/pos-admin-web
copy .env.example .env.development
npm install
npm run typecheck
npm test
npm run test:e2e
npm run build
npm run dev
```

Open the Vite URL (default `http://localhost:5173`).

- Employee Access: `/employee`
- POS Counter: after preview sign-in as `preview.staff`
- Admin / Office: after preview sign-in as `preview.admin`

You should see a **UI PREVIEW — SAMPLE DATA** banner while fixtures are active.

### Closure-gate screenshots

```powershell
cd apps/pos-admin-web
# with npm run dev already running
npm run capture:closure
```

Evidence: `apps/pos-admin-web/docs/screenshots/closure-gate/`  
Manifest: `docs/pos-admin-ui/POS_ADMIN_SCREENSHOT_MANIFEST.md`  
Report: `docs/pos-admin-ui/POS_ADMIN_UI_CLOSURE_GATE.md`

## Documentation

- Product PRD: `Aida_System_Unified_PRD_v2.0.md`
- POS/Admin UI docs: `docs/pos-admin-ui/`

## Branch note

POS/Admin UI work lives on `team1/aida-pos-admin-ui`. Do not merge to `master` until reviewed.
