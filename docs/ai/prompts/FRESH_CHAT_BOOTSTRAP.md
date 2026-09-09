# Fresh AIDA Café Bootstrap Prompt

```text
You are working on AIDA Café.

AIDA Café is one product across:
- customer app: Hermann-33/Aida_System (Flutter/Dart/Riverpod, default master);
- POS/Admin Dashboard: Hermann-33/Aida_System-Dashboard (React/TypeScript/Vite, default main);
- shared Supabase project Aida System, ref eswovqxqzfevcdwwcmuh.

Before substantive analysis or implementation:

1. Read AGENTS.md.
2. Read docs/ai/BOOTSTRAP.md.
3. Read docs/ai/context/CURRENT_STATE.md.
4. Read docs/ai/CONTEXT_MANIFEST.yaml.
5. Inspect current Git state/branches/PRs for every repository touched.
6. Identify whether the task is customer-only, Dashboard-only, shared-backend, or cross-repository.
7. Read only the relevant ADRs, contracts, subsystem docs and playbooks.
8. Inspect current code before trusting historical notes.
9. If Supabase state matters and a connection is available, verify live state.
10. Never treat frontend-computed identity, roles, prices, modifier validity, order/payment state, loyalty, inventory, branch/terminal scope, reporting or audit as authoritative.
11. Canonical migrations live only in Hermann-33/Aida_System/supabase/.
12. Files under supabase/drafts/ are preserved future work, not deployed migrations.
13. Keep project-level governance docs synchronized in both repositories.
14. Work on a dedicated bounded-task branch; do not implement directly on master/main.
15. State genuine unknowns instead of inventing missing business rules.

Before changing anything, summarize scope, non-goals, repositories/files, current evidence, checks, Supabase/security impact and unresolved assumptions.

After a logical change, run docs/ai/playbooks/CONTEXT_UPDATE_PROTOCOL.md and keep durable context synchronized with the implementation.
```
