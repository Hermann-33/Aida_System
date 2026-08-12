> Scope note: customer Flutter state/data flow. POS/Admin flow is documented under `docs/dashboard/STATE_AND_DATA_FLOW.md`.

# State and Data Flow

## Auth/member path on TASK-AUTH-001 branch

```text
Flutter Login/Signup
  -> MemberRepository
  -> SupabaseMemberRepository
  -> Supabase Auth
  -> auth.users trigger
  -> user_profiles + members
  -> owner-scoped reads under forced RLS
  -> Riverpod memberProvider
  -> widgets
```

`authStateProvider` derives from the Supabase persisted session/auth-state stream rather than a mutable demo-login boolean. Logout signs out of Supabase and invalidates user-scoped member state.

`memberProvider` loads trusted member/profile fields from Supabase. Signup does not construct a `Member` locally and does not generate member identifiers/codes.

## Remaining preview flow

For feature families not integrated yet:

```text
MockMemberRepository preview constants
  -> domain models / Result<T>
  -> Riverpod AsyncValue
  -> widgets
```

This still covers catalogue/menu, loyalty, rewards, vouchers, offers and promotions. Cart/order/payment flows remain local preview state and are not authoritative.

## Profile edits

The existing member edit overlay remains for the unimplemented profile-write task. It is UI/session state only and is cleared/invalidated across auth changes; it is not identity authority.

## Error flow

Auth adapter maps Supabase failures to controlled application failures rather than surfacing raw backend errors. Future adapters must do the same for validation/conflict/availability/payment/loyalty errors.
