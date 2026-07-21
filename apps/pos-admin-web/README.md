# Aida Cafe — POS & Admin Web (`apps/pos-admin-web`)

React + Vite + TypeScript UI for Employee Access, Aida Counter (POS), and Aida Office (Admin).

This package is migrated into **Aida_System** as a **frontend-only** preview. Mock fixtures are used; no production API, database, payments, or loyalty mutations.

## Setup

```powershell
cd apps/pos-admin-web
copy .env.example .env.development
npm install
```

`.env.example` enables `VITE_UI_PREVIEW_MODE=true` for local demo data.

## Scripts

```powershell
npm run typecheck
npm test
npm run build
npm run dev
```

Default dev URL: `http://localhost:5173`

## Preview mode

- Banner: **UI PREVIEW — SAMPLE DATA**
- Demo accounts and fixtures live under `src/preview/`
- Production builds reject `VITE_UI_PREVIEW_MODE=true` (fail-closed in `vite.config.ts`)
- No Vite API proxy is configured in this Aida_System copy

## Docs

UI specs and validation notes: `../../docs/pos-admin-ui/`
