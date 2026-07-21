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
npm run build
npm run dev
```

Open the Vite URL (default `http://localhost:5173`).

- Employee Access: `/`
- POS Counter: after preview sign-in as a POS role
- Admin / Office: after preview sign-in as an admin/manager role

You should see a **UI PREVIEW — SAMPLE DATA** banner while fixtures are active.

## Documentation

- Product PRD: `Aida_System_Unified_PRD_v2.0.md`
- POS/Admin UI docs: `docs/pos-admin-ui/`

## Branch note

POS/Admin UI work lives on `team1/aida-pos-admin-ui`. Do not merge to `master` until reviewed.
