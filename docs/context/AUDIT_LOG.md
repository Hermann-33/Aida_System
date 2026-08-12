# Audit Log

## 2026-08-11 — TASK-WF-001 — Customer frontend audit and governance baseline

**Verdict:** COMPLETE for audit/documentation; product remained prototype.

Flutter customer app audited with `MockMemberRepository`, local/mock auth/cart/orders/loyalty and the recorded analyzer/test baseline.

---

## 2026-08-11 — TASK-DB-001 — Supabase identity/membership foundation

**Verdict:** COMPLETE for scoped database foundation.

Created and remotely applied `user_profiles`, `members`, `student_verifications`, enums, auth provisioning and forced RLS. Public role-helper exposure and RLS performance warnings were hardened. Security advisor ended at 0 lints.

---

## 2026-08-12 — TASK-WF-002 — Dashboard import and audit

**Verdict:** COMPLETE.

Imported and audited the React/TypeScript/Vite POS/Admin source. Dashboard business outcomes remained fixture/local/session preview data.

---

## 2026-08-12 — TASK-WF-003 — Dual-repository context synchronization

**Verdict:** COMPLETE for scoped governance/documentation work.

Established mirrored project context, shared-backend architecture, security/workflow rules and cross-repo ADRs.

---

## 2026-08-12 — TASK-WF-004 — Setup post-merge finalization

**Verdict:** COMPLETE.

Finalized setup wording after the governance/database/import stack merged to both defaults.

---

## 2026-08-12 — TASK-AUTH-001 — Customer auth + member integration

**Verdict:** PARTIAL.

### Implemented

- Customer Flutter auth path now uses Supabase Auth for sign-up/sign-in/recovery/session restore/logout.
- Customer member/profile identity reads now come from live `user_profiles` and `members` under owner RLS.
- Local signup-generated member IDs/codes were removed from the implemented path.
- Server signup provisioning accepts only display name and student declaration as untrusted input; role, verification and member code remain trusted/server-owned.
- Added admin/owner-only member-directory capability `public.list_admin_members()` and tightened bulk profile/member reads from staff-wide to admin/owner.
- Admin Members removed `PREVIEW_MEMBERS` and now targets a same-origin credentialed API contract with no fixture fallback.
- Member points/stamps/rewards were removed from that Members tab because no trusted loyalty backend exists yet.

### Live database verification

The first provisioning test exposed a regression: the initial replacement trigger omitted explicit member-code generation and would fail signup because `members.member_code` has no column default. A forward corrective migration restored `public.generate_member_code()`; the migration history was not rewritten.

A subsequent security-advisor pass flagged the admin member-directory RPC as an authenticated `SECURITY DEFINER` function. A second forward hardening migration changed it to `SECURITY INVOKER`, retaining explicit admin/owner checks plus RLS. Security advisor returned to 0 lints.

Rolled-back live tests then verified standard signup, student-pending signup, forged role/verification/member-code rejection, admin directory access and customer rejection. Production counts remained zero after rollback.

### Remaining blocker

The dashboard has no production staff/admin BFF/session runtime. `/api/v1/admin/members` is therefore only a client contract, not an executable end-to-end endpoint. Under ADR-0004 the requested signup -> Admin Members outcome is not yet full-stack complete.

### Branches

Both repositories: `codex/task-auth-001-auth-member-integration`.

### Exact next task

`TASK-AUTH-002 — trusted staff/admin session and member-directory API`.
