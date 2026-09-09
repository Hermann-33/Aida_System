# Shared Supabase Backend Task Prompt

```text
You are changing the shared AIDA Café backend.

Bootstrap first from AGENTS.md and docs/ai/** and inspect both client consumers.

Backend:
- Supabase project: Aida System
- ref: eswovqxqzfevcdwwcmuh
- region: ap-southeast-1
- canonical migrations: Hermann-33/Aida_System/supabase/

Rules:
1. Supabase/server logic owns trusted business state.
2. RLS is mandatory on exposed tables; authentication alone is not authorization.
3. Privileged mutations must validate trusted app roles/scopes and use caller identity, not user-editable metadata.
4. Prices/totals, modifier compatibility, order status transitions, payment state, loyalty, inventory, branch/terminal scope and audit outcomes must be server-validated.
5. Applied migrations are append-only; use forward migrations.
6. Never create a second migration history in the Dashboard repo.
7. supabase/drafts/ is prototype storage only; promoting a draft requires a new canonical migration and full review.
8. Preserve backward compatibility deliberately when rolling out shared contracts.
9. Inspect both customer and Dashboard adapters before changing RPC/schema payloads.

Validation should include, as applicable:
- fresh migration replay/reset
- SQL regression tests
- RLS/privilege/role abuse cases
- idempotency/concurrency cases
- Supabase security/performance advisors
- both client contract tests
- documentation synchronization

Never claim live deployment or a fresh replay unless it actually occurred.
```
