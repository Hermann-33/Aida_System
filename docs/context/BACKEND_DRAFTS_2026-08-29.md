# Backend Drafts — 2026-08-29

> **2026-09-09 preservation note:** this file is historical design evidence from the source branch. The SQL prototypes have been moved to `supabase/drafts/` and are **not canonical migrations or live Supabase state**. Runtime client hooks are preserved behind feature gates that default off. The referral-gated real-points path now returns an error on backend failure instead of silently falling back to mock points. Account deletion is also exposed through the repository interface only for the gated draft flow. Any older path names or fallback descriptions below should be read as the original 2026-08-29 draft, superseded by `docs/frontend/UI_REDESIGN_AUDIT_2026-09-09.md` for current integration truth.

Evidence for two drafted Supabase migrations sitting uncommitted on
`customer-app-redesign` as of 2026-08-29. Both changed shared-backend
authority (identity/member contract and order-completion side effects), so
per `AGENTS.md`'s shared-contract workflow they are recorded here in full
rather than folded into `docs/frontend/UI_REDESIGN_SPEC.md`, which is scoped
to presentation-layer work only.

**Environment note, relevant to both:** this task had no way to verify
either migration against the live Aida System Supabase project (ref
`eswovqxqzfevcdwwcmuh`). The only Supabase MCP connection available in this
session's environment resolves to an unrelated project ("Cheater's Market",
ref `gcqbayehikvbwvvseyoc`, region `us-east-1`) belonging to a different
Supabase organization — not Aida's. No local Postgres was available either.
Both migrations below are therefore recorded as drafted/unverified, not
applied. A future session with real access to the Aida project must run
`supabase db reset`/`supabase db lint`, apply both migrations, execute their
accompanying `supabase/tests/*.sql` files, and check the security/performance
advisors before either can be marked verified.

---

## TASK-REFERRAL-001 — customer "Invite a friend" referral program

**Verdict: PARTIAL.** Customer-side implementation and one real backend
migration exist and pass the customer toolchain; the migration itself has
never been applied to or exercised against a live database.

### What changed

**Backend** — `supabase/migrations/20260828120000_add_referral_program.sql`
(new, task ID `TASK-REFERRAL-001` per its own header comment):

- `members` gains `points_balance bigint not null default 0` plus a
  `members_points_balance_nonnegative` check constraint. This is the first
  real (non-mock) loyalty field in the schema.
- New `referrals` table: `referrer_member_id`, `referred_member_id`
  (`unique` — a member can be referred at most once), `status` (`pending` |
  `rewarded`), `created_at`, `rewarded_at`, plus checks preventing
  self-referral and enforcing `rewarded_at` is set if and only if
  `status = 'rewarded'`. RLS is enabled with **no policies** — every access
  path is through `security definer` functions, the same pattern `members`
  itself already uses.
- `handle_new_auth_user()` (the existing signup trigger) is extended: after
  inserting the new member row, it reads `raw_user_meta_data ->> 'referral_code'`,
  looks up a `members` row whose `member_code` matches (case-insensitive,
  uppercased), and inserts a `pending` `referrals` row if found and not a
  self-referral (`on conflict (referred_member_id) do nothing`). An
  unrecognized or self-referral code never fails signup — it just records no
  referral.
- `private.transition_order_status_impl()` (the existing staff order-status
  RPC implementation) is extended: after the status update and
  `order_events` insert already in that function, when the new status is
  `completed` and the order has a `member_id`, it looks up (with `for
  update`, avoiding a double-reward race) a `pending` referral for that
  member, confirms via `count(*)` that this is genuinely that member's
  *first* completed order, and if so credits **50 points** to both the
  referrer and the referred member's `points_balance`, marking the referral
  `rewarded`. The reward is server-owned and triggered by real fulfilment
  completion, not by signup or by any client call.

**Customer app** — real (non-mock) points read, referral code at signup:

- `lib/data/repository/supabase_member_repository.dart`:
  - `signUp()` now accepts `String? referralCode`; when non-empty it's sent
    as Supabase Auth metadata key `referral_code`.
  - `getPoints()` is no longer purely `_pendingFeatures.getPoints()`. It now
    queries `members.points_balance` for the current authenticated user
    directly (same RLS-protected pattern as `getMember()`), and **falls back
    to the mock balance on any query failure** — including, expectedly, the
    migration not being applied yet. The fallback is deliberate so the app
    doesn't show a blank/broken points figure on a project where this
    migration hasn't landed.
- `lib/domain/repository/member_repository.dart` /
  `lib/data/repository/mock_member_repository.dart`: both updated to the new
  `signUp({..., String? referralCode})` signature (the mock ignores the
  parameter).
- `lib/features/auth/login_screen.dart`: new `AuthField` on the sign-up form
  — "Referral code (optional)", `TextCapitalization.characters`, submits via
  `_submitSignUp()`.
- `lib/features/auth/widgets/auth_field.dart`: gained a `textCapitalization`
  parameter (default `TextCapitalization.none`) to support the above.

**What was not built:** any UI to *display* a referral code to share (the
existing "Share" action on the membership card shares the member's own
`member_code` directly — see `docs/frontend/UI_REDESIGN_SPEC.md` §20 — a
member's referral code and member code are the same value by design, so no
separate surface was needed), any UI showing referral status/history, and no
admin/staff visibility into referrals. None of that was in scope for this
pass.

### Why PARTIAL, not COMPLETE

- The migration has never been applied to the live Aida Supabase project —
  see the environment note above. `points_balance` does not exist on the
  live `members` table as of this writing; every live read of it will fail
  and fall back to the mock balance, which is the intended, safe behavior of
  `getPoints()`'s fallback, but it means the feature is inert in production
  until someone with real Supabase access runs the migration.
- No `supabase/tests/*.sql` regression accompanies this migration (unlike
  `TASK-ACCT-001` below, which shipped with one). None was written for
  referral-specific behavior (self-referral rejection, double-reward race
  via `for update`, first-completed-order gating) — this is a real gap, not
  an oversight to gloss over.
- `docs/contracts/SHARED_BACKEND_CONTRACT.md`, `docs/context/SUPABASE_STATUS.md`,
  `docs/context/ROADMAP.md`, `docs/context/PROJECT_BRIEF.md`, and
  `docs/security/SECURITY_REVIEW.md` all currently describe "loyalty
  earning/redemption" as fully deferred, no-trusted-implementation. This
  task's own edits to those files (see each file's diff) change that
  language to "migration drafted, not yet applied/verified" — a real,
  material change to a previously-accepted fact, done as part of this
  documentation task per `AGENTS.md`'s drift rule.

### Client validation

`flutter analyze` → 1 pre-existing issue only (`axisAlignment` deprecation in
`order_checkout_sheet.dart`, unrelated to this work — see
`docs/frontend/UI_REDESIGN_SPEC.md`'s own note on the same warning).
`flutter test` → 55/55 passed, run 2026-08-29 from `apps/customer`.

### Deferred

- Apply and verify the migration against live Supabase (grants, RLS, security
  advisor, `supabase db lint`).
- Write a `supabase/tests/referral_program_integration.sql` regression
  (self-referral rejection, double-reward-race protection, first-completed-
  order gating) before this can move past PARTIAL.
- Cross-repository documentation sync: **PENDING** — `Hermann-33/Aida_System-Dashboard`
  was not inspected or modified in this task.

---

## TASK-ACCT-001 — customer self-service account deletion

**Verdict: PARTIAL.** A complete, carefully-reasoned migration plus a full
client flow exist; the migration has never been run against a live or local
database, so its correctness is unverified beyond code review and the
written (but unexecuted, in this environment) SQL integration test.

### What changed

**Backend** —
`supabase/migrations/20260826120000_add_customer_account_deletion.sql` (new):

- Rationale recorded in the migration's own header: App Store / Play Store
  review both require an in-app path to delete an account and its data.
  `orders.created_by_user_id` is `not null` + `on delete restrict` by design
  (an audit-trail guarantee), so a bare `delete from auth.users` fails
  outright with a foreign-key violation for anyone who has ever placed an
  order.
- Inserts one permanent placeholder account,
  `00000000-0000-0000-0000-000000000001` /
  `deleted-customer@internal.aida.invalid` (never logged into, no password),
  that a departing customer's own orders are reassigned to immediately
  before their real account is deleted — the same pattern as GitHub's
  "ghost" user or Reddit's `[deleted]`, preserving order history/accounting
  with no trace of who placed it.
- `private.protect_order_commercial_fields()` (the existing trigger that
  makes persisted order commercial fields immutable) is extended with the
  two exact exceptions account deletion needs: `customer_user_id`/`member_id`
  may be cleared to null (what their own `on delete set null` FK behavior
  produces), and `created_by_user_id` may be reassigned specifically to the
  placeholder above. No other mutability is introduced.
- New `public.delete_own_account()`, `security definer`,
  `set search_path = ''`: rejects an unauthenticated caller and rejects the
  placeholder account attempting to delete itself; otherwise reassigns the
  caller's own `orders.created_by_user_id` to the placeholder, then deletes
  their `auth.users` row. That delete cascades (existing FKs) through
  `user_profiles` → `members` → `student_verifications`, and sets
  `orders.customer_user_id` / `orders.member_id` /
  `order_events.actor_user_id` to null via their existing `on delete set
  null` behavior. `execute` is revoked from `public`/`anon` and granted only
  to `authenticated` — a caller can only ever delete their own account (there
  is no target-user-id parameter).
- `supabase/tests/account_deletion_integration.sql` (new): a transactional
  (`begin`/`rollback`) integration test exercising: unauthenticated calls are
  rejected; a real customer with an existing order successfully deletes
  their account; the order's `customer_user_id`/`member_id` end up null and
  `created_by_user_id` is reassigned to the placeholder while commercial
  fields (`subtotal_sen`/`total_sen`) stay unchanged; the placeholder account
  itself cannot be deleted. This test was **written but not executed** in
  this environment (no live/local Postgres access — see the environment note
  above).

**Customer app** — full self-service flow:

- `lib/application/providers.dart`: `AuthState` gains
  `deleteAccount()`, awaiting server-side deletion (unlike `logOut()`,
  which fires-and-forgets) before flipping `state = false` and invalidating
  `memberProvider`/`orderUpdatesProvider`/`orderHistoryProvider` — a failed
  deletion must not look like a successful sign-out.
- `lib/data/repository/supabase_member_repository.dart`: new
  `deleteAccount()` calls the `delete_own_account` RPC, then signs out and
  clears the local offline member cache the same way `logOut()` does.
  **Not** part of the `MemberRepository` abstract interface — `providers.dart`
  checks `repository is! SupabaseMemberRepository` and returns a failure for
  any other repository implementation (i.e. `MockMemberRepository` has no
  deletion capability, by design).
- `lib/features/profile/settings_screen.dart` (new file — see
  `docs/frontend/UI_REDESIGN_SPEC.md` §20 for the rest of this screen's
  scope): a "Delete Account" tile opens a confirmation `AlertDialog`
  ("This permanently erases your profile, membership, points, and stamps.
  This cannot be undone."), then a non-dismissible progress dialog while
  `authStateProvider.notifier.deleteAccount()` runs. On success, `AuthGate`
  (which already reacts to `authStateProvider`) swaps to `LoginScreen` on its
  own — no explicit navigation call needed. On failure, the failure message
  is shown via `AidaPopup`.

### Why PARTIAL, not COMPLETE

- The migration, its trigger extension, and its RPC have never run against
  any real Postgres instance in this task — not the live Aida project (no
  access — see environment note), not a local one (unavailable in this
  environment). The accompanying integration test is well-constructed and
  covers the right cases, but "a test exists" is not the same as "the test
  passed."
- The client-side flow (`deleteAccount()` call, confirmation UI, provider
  wiring) is complete and covered by the customer toolchain passing, but its
  correctness against the real RPC's actual error shapes
  (`PostgrestException.message` surfaced directly to the user) has not been
  observed end-to-end.

### Client validation

`flutter analyze` → 1 pre-existing issue only (same unrelated
`axisAlignment` deprecation noted under TASK-REFERRAL-001 above).
`flutter test` → 55/55 passed, run 2026-08-29 from `apps/customer`. No
dedicated widget test exercises the delete-account confirmation flow itself
(see Deferred).

### Deferred

- Apply and execute `account_deletion_integration.sql` against the live or a
  disposable Postgres instance; fix anything it finds before calling this
  COMPLETE.
- A widget test for `settings_screen.dart`'s delete-account dialog flow
  (confirm → progress → success/failure) does not exist yet.
- Cross-repository documentation sync: **PENDING** — `Hermann-33/Aida_System-Dashboard`
  was not inspected or modified in this task. If the Dashboard/Admin side
  ever needs to see which accounts were deleted (e.g. for support), that is
  unbuilt and unscoped here — this task is customer self-service only.
