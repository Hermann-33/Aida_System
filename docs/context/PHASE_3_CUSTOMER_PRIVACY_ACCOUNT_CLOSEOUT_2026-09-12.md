# Phase 3 — Customer Privacy and App Store Account Requirements Closeout

**Task:** `TASK-PRIVACY-001`  
**Date:** 2026-09-12  
**Verdict:** `COMPLETE`  
**Plan:** `docs/context/PHASE_3_CUSTOMER_PRIVACY_ACCOUNT_PLAN.md`

## Scope and dependency rationale

Phase 3 closes the customer-account/privacy boundary only after Phases 1–2 established authoritative order, topology, shift and payment-classification records. This matters because whole-account deletion must remove customer identity without destroying retained transaction/audit facts or weakening staff/POS authority.

External payment processors/refunds, inventory, branch scheduling, loyalty, promotions, accounting export, employee credential lifecycle, hardware integrations and deployment-heavy work remain outside this phase.

## Architecture, contracts, schema and security changes

Canonical Phase 3 migrations exist only in `Hermann-33/Aida_System/supabase/migrations/`:

```text
20260912014924 customer_privacy_account_requirements
20260912015010 harden_customer_privacy_rpc_boundary
20260912020434 allow_customer_deletion_without_member_dependency
20260912020652 allow_disabled_customer_account_deletion
20260912021143 scrub_customer_free_text_on_account_deletion
```

Phase 3 adds:

```text
public.customer_privacy_preferences
public.orders.customer_deleted_at
public.get_my_privacy_preferences()
public.save_my_privacy_preferences(boolean, boolean)
public.delete_own_account()
```

`orders.created_by_user_id` is nullable only so a retained customer transaction can lose its Auth actor after customer deletion. POS/staff orders continue requiring their trusted actor. The order immutability trigger allows exactly one narrowly scoped internal active-customer -> anonymized-retained transition; ordinary clients still cannot mutate customer identity, commercial, topology, shift, tender or payment facts.

Active customer order identity:

```text
customer_user_id != null
member_id != null
created_by_user_id != null
customer_deleted_at == null
```

Retained anonymized customer order identity:

```text
customer_user_id == null
member_id == null
created_by_user_id == null
customer_deleted_at != null
```

Retained commercial/operational facts include order number, product/option snapshots, quantities, prices/totals/currency, fulfilment/status timestamps, branch/sales-point/terminal/shift attribution and tender/payment state. Customer-authored retained free text in `order_lines.note` and `order_events.reason` is scrubbed before identity anonymization. No synthetic permanent deleted-customer Auth account is created.

The account-deletion public RPC accepts no target user ID. The exposed wrapper is `SECURITY INVOKER`; the private privileged helper is `SECURITY DEFINER`, binds the actor to `auth.uid()`, requires trusted `app_role=customer`, and cannot be used by staff/Admin identities. Deletion remains available when the trusted customer profile is disabled and does not depend on a healthy/active member row.

`customer_privacy_preferences` has FORCE RLS and no direct authenticated table grants. Customer RPCs are owner-bound. Marketing defaults `false`; transactional notifications default `true`. This phase establishes preference authority only—no notification-delivery provider or OS permission is added.

Already-issued access JWTs can remain cryptographically valid until expiry. Personalized customer RPCs therefore continue requiring trusted profile/member state, while anonymized retained orders no longer carry the deleted customer subject. Regression coverage proves a stale deleted-user identity cannot read privacy preferences, personalized order history or place new customer orders.

## Customer application implementation

The production Settings surface now includes:

- easy-to-find whole-account deletion;
- clear confirmation describing deleted identity/profile/member/student/preference data and anonymized transaction retention;
- server-success-first deletion semantics;
- best-effort local sign-out and offline membership-cache cleanup after server deletion;
- privacy notification preferences;
- Privacy Policy, Terms and Support surfaces;
- signed-out access to legal/support information.

The previous account-deletion feature gate is gone. Preview/mock repositories remain test/development substitutes only and are not backend authority.

Guest/public versus authenticated split is explicit:

```text
public/guest-capable:
  catalogue browsing
  legal/privacy/terms/support information

authenticated-only:
  membership identity / QR
  profile mutation
  customer order placement/history
  student verification
  privacy preferences tied to an account
  whole-account deletion
```

No anonymous Supabase Auth user is auto-created merely to represent a guest.

## iOS / App Store impact

`docs/context/PHASE_3_IOS_DATA_PERMISSION_AUDIT.md` is `COMPLETE` for this code boundary.

Phase 3 adds no camera, photo-library, location, contacts, microphone, Bluetooth, calendar/reminder, ATT/tracking or notification authorization request; no tracking/advertising SDK; and no StoreKit/IAP path. AIDA sells physical café goods.

The known in-app whole-account-deletion blocker is closed at the Phase 3 code/backend boundary. Final App Store submission still requires operational privacy/support URLs, correct App Privacy answers/manifests for the complete release build, usable review credentials/demo path and physical end-to-end release verification.

## Validation evidence

Implementation validation head:

```text
Aida_System
  10ca26a776994e59b76f8afbd7227e296270cd68
```

GitHub Actions:

```text
Backend database audit #90   COMPLETE
Customer release audit #182 COMPLETE
```

Backend clean-database audit passed:

```text
branch authority regression                         COMPLETE
operational topology regression                    COMPLETE
order regression                                   COMPLETE
scheduled-order operations regression              COMPLETE
shift and cash authority regression                COMPLETE
customer privacy/account deletion regression       COMPLETE
customer retained free-text deletion regression    COMPLETE
student verification deletion regression           COMPLETE
```

Customer release audit passed dependency resolution, static analysis, non-golden regressions, golden regressions, release APK assembly and artifact upload.

Dashboard Phase 3 contains governance/documentation only; Phase 3 introduces no Dashboard runtime privacy authority. Its pre-closeout head `411056a40edfb1c23fa999504b904d822e151f5d` passed Dashboard CI #66. Documentation-only final heads are revalidated after synchronized closeout commits.

Live Supabase verification confirms:

- all five canonical Phase 3 migrations are applied, including `20260912021143`;
- `authenticated` can execute own-account deletion/preferences RPCs;
- `anon` cannot execute deletion or preference mutation;
- authenticated clients have no direct preference table SELECT/UPDATE grant;
- the live deletion helper scrubs retained line notes/event reasons before anonymization.

Supabase advisor review after the Phase 3 schema changes:

- security: no Phase 3-created blocker; only the pre-existing `auth_leaked_password_protection` warning remains;
- performance: INFO-level unused-index observations only; no Phase 3-created missing-FK/index blocker.

## Deferred / non-goals

Still deferred:

- external card/e-wallet/payment-processor capture, settlement and refunds;
- branch hours/closures/capacity and explicit pickup branch;
- inventory/recipes/depletion;
- loyalty/rewards/vouchers;
- promotions/discounts;
- reporting/tax/accounting export;
- employee Auth-user/credential lifecycle;
- printer/KDS/payment-device integrations;
- notification/marketing delivery provider;
- delivery and deployment-heavy production infrastructure.

## Handoff

Phase 3 is `COMPLETE`. Phases 1, 2 and 3 remain draft and unmerged. Implementation stops here. The next boundary is the combined Phase 1–3 Astra audit; Phase 4 must not begin before that audit boundary is resolved or explicitly accepted.