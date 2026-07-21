# Aida React UI Validation

**Branch:** `team1/aida-pos-admin-ui`  
**Date:** 2026-07-21 (UI correction pass — PRD v0.2)  
**PRD:** `docs/AIDA_REACT_UI_PRD_v0.2.md`

## Ownership

Team 1 = React POS/Admin UI only. No migrations, API edits, Neon access, or live OTC generation.

## Preview terminal activation

With `VITE_UI_PREVIEW_MODE=true` (default in `.env.development`):

1. Open http://localhost:5173/employee  
2. Banner: **UI PREVIEW — SAMPLE DATA**  
3. Enrolment code: **`AIDA-482731`**  
4. Binds to Main Café · Main Counter · POS-MAIN-01  
5. Demo logins (not production auth):
   - Admin: `preview.admin` / `preview123` → Office  
   - Staff: `preview.staff` / `preview123` → Counter  
   - Dual: `preview.dual` / `preview123` → role select  

See `docs/AIDA_UI_BACKEND_BENCHMARK.md` and `docs/AIDA_PROGRESS_SCREENSHOT_INDEX.md`.

## Commands

```powershell
cd apps/pos-admin-web
npm run typecheck
npm test
npm run build
node scripts/capture-all-screens.mjs
```

Production build must fail if `VITE_UI_PREVIEW_MODE=true`.

## Screenshot package

`apps/pos-admin-web/docs_screenshots/all-screens/` — route/heading assertions; fails on unexpected duplicate hashes.
