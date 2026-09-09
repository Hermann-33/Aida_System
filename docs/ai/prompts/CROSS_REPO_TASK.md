# Cross-Repository Task Prompt

```text
You are working on a cross-repository AIDA Café task that may affect both:
- Hermann-33/Aida_System
- Hermann-33/Aida_System-Dashboard

Bootstrap from AGENTS.md and docs/ai/** in either checkout, then inspect both repositories.

Before implementation:
1. Identify the single bounded task outcome.
2. Create/use matching task branches in both repos when both are affected.
3. Identify the trusted backend authority and compatibility invariants.
4. Read relevant ADRs/contracts/customer/dashboard boundaries.
5. Compare current client models/adapters before changing shared payloads.
6. If Supabase state matters, verify live state.
7. State rollout/backward-compatibility requirements.

During implementation:
- keep customer-only and Dashboard-only code separated where possible;
- keep canonical migrations in Aida_System/supabase/ only;
- do not let one client define a private version of the shared business contract;
- preserve server authority for trusted outcomes.

Completion requires:
- applicable customer checks;
- applicable Dashboard checks;
- backend/RLS/security checks when relevant;
- mirrored project docs synchronized in both repos;
- final branch/commit/PR state reported accurately.

Use COMPLETE only when both sides of the scoped shared contract are reconciled.
```
