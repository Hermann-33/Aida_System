# Roadmap

Updated: 2026-08-17

## Current tranche

Implemented and validated to the current closeout standard:

- governance and shared-backend ownership;
- trusted identity/member foundation;
- customer Supabase Auth/member integration and physical signup;
- same-origin employee/Admin session boundary;
- protected Dashboard Members;
- shared catalogue, protected Admin mutation, POS/customer reads and customer revision refresh;
- TASK-AUTH-005 preview/live session separation;
- Android release networking and reproducible committed build toolchain;
- authoritative quote/order/schedule/status backend;
- customer authoritative quote/place/history/detail/status frontend;
- Dashboard authoritative POS quote/place and server-policy scheduling;
- Dashboard live polled order queue and versioned fulfilment transitions;
- customer and Dashboard full local toolchain/test/build gates for the implemented tranche.

## Current status

`TASK-CLOSEOUT-001`: **PARTIAL** only because the fresh credential-backed cross-client order lifecycle has not yet been executed against the live project.

Required final proof:

customer placement
→ persisted order
→ Dashboard observation
→ preparing
→ customer authorized refresh
→ ready
→ customer authorized refresh
→ completed
→ customer authorized refresh.

Approved demo credentials must be supplied ephemerally and must not be committed.

## Merge gate

Customer PR #13 and Dashboard PR #12 are technically mergeable but remain draft until the final live order E2E is recorded and mirrored documentation/final merge-readiness checks pass.

Hosted/Vercel deployment is **DEFERRED** for the accepted local-PC + cloud-Supabase + installed-phone demo topology.

## Security operations

Current Supabase security-advisor evidence has one WARN: leaked-password protection is disabled. Enabling it is hosted Auth configuration work and does not justify weakening application Auth/RLS boundaries.

## Deferred product domains

Do not start these during closeout:

1. trusted payment capture/refunds;
2. loyalty earning/redemption and voucher lifecycle;
3. inventory/recipes/depletion;
4. promotions/discount authority;
5. tax/accounting and trusted reporting;
6. branch-scoped staff/order visibility and branch hours/capacity;
7. delivery;
8. hosted production deployment, signing/distribution and operational release work.
