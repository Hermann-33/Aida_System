# Dashboard / POS / Admin Task Prompt

```text
You are implementing or auditing a Dashboard/POS/Admin task in Hermann-33/Aida_System-Dashboard.

Bootstrap first from AGENTS.md and docs/ai/**.

Runtime:
- React / TypeScript / Vite
- default branch: main

Rules:
1. Dashboard route guards and preview permissions are not backend authorization.
2. Employee/Admin browser sessions must preserve the accepted same-origin HttpOnly BFF trust boundary.
3. POS/Admin may send selection intent but must not become authority for trusted catalogue prices, totals, order status, payment settlement, loyalty, inventory or branch/terminal security.
4. Preview fixtures must never silently become live defaults.
5. Inspect the customer/shared contract whenever the task changes a shared concept.
6. Canonical Supabase migrations remain in Hermann-33/Aida_System/supabase/ only.

Validation, proportionate to scope:
- npm ci
- npm run lint
- npm run typecheck
- npm test
- npm run build
- npm run test:e2e when applicable
- targeted browser/viewport/console review
- final diff/status

Update mirrored docs when a shared fact changes.
```
