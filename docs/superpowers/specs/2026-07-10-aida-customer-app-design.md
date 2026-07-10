# Aida Café — Flutter Customer App: Design Specification

| Field | Detail |
|---|---|
| **Component** | Customer Mobile App (Flutter) |
| **Parent product** | Aida System (see `Aida_System_Unified_PRD_v2.0.md`) |
| **Spec version** | 1.0 |
| **Date** | 10 July 2026 |
| **Status** | Approved design — ready for implementation planning |
| **Target** | Real deployment at Aida Café @ City U |

---

## 1. Purpose and Boundaries

This spec covers the **customer-facing Flutter application only**. The Staff POS and Admin Dashboard are out of scope and will each get their own spec.

The backend is **deliberately undecided**. Every data access in this app sits behind a repository interface in the domain layer, with a mock implementation for development and a real implementation added once the backend stack is chosen. No screen changes when the backend is selected.

### 1.1 What v1 Ships

Every customer requirement marked **Live** in PRD §9.1, plus four screens the PRD omits (§3.2 below).

### 1.2 What v1 Explicitly Excludes

| Excluded | PRD ref | Reason |
|---|---|---|
| Order-ahead / scheduled ordering | CUS-14 | Requires collection slots, a POS prep queue, and the unresolved pay-at-pickup vs prepaid decision (PRD §24.4 #5) |
| Membership tiers | CUS-12 | Tier thresholds not finalised by the owner (PRD §24.4 #4) |
| Birthday rewards | CUS-15 | Depends on tier engine and a scheduled grant job |
| Points-to-reward equivalence indicator | CUS-13 | Cosmetic; deferred |
| Push notifications | PRD §7.3 | Roadmap Phase 10 |
| In-app payment | PRD §7.2 | The product is a soft POS; it never touches funds |

The customer **never places an order** in v1. "History" is a receipt archive of purchases the barista rang up at the POS.

---

## 2. Decisions That Supersede PRD v2.0

Four decisions taken during design conflict with the PRD as written. They are recorded here and must be reflected in the PRD.

### 2.1 The backend is rebuilt, not retained

PRD §3.3 states the live backend "should be retained," and §21.3 warns against "rewriting proven backend functionality without a measurable benefit."

**Superseded.** The source code for `production/api` is not available to this project. A backend that cannot be read, modified, or deployed to is an external dependency, not a foundation. It cannot gain the CUS-07 endpoint, cannot have its cold start fixed, and cannot undergo the `students` → `members` migration that PRD §24.3 identifies as a risk. Retention was never actually available.

**Consequence:** the backend becomes a separate project with its own spec. Its stack is undecided. This app is built against a mock repository until that decision is made.

### 2.2 Customers may redeem directly in the app

PRD §6.1, §10.1, and §23.1 all state that customers cannot directly deduct points, and that staff must confirm every redemption.

**Superseded, with the safety property preserved.** The PRD conflates two distinct actions:

1. **Converting points into an entitlement** (100 points → a RM 5 voucher).
2. **Consuming an entitlement for product** (voucher → RM 5 off a drink).

The fraud the PRD guards against is a customer granting themselves free product without staff. That risk lives entirely in (2). This design lets the customer perform (1) alone, while (2) still requires a barista to apply the voucher at checkout. This is the Starbucks / ZUS model.

**Points leave the balance at redemption time.** A voucher is issued immediately with an expiry date. An unused voucher expires and the points are **not** refunded. The expiry window is business-configurable.

Staff retain the ability to redeem on the customer's behalf at the POS. Both paths converge on the same server-side redemption operation.

### 2.3 The membership QR is static

Generated once at registration and permanent thereafter. It encodes the member identifier and is scanned by the Staff POS app.

**Accepted risk:** a screenshot can be shared, letting a third party accrue or spend another member's value. Mitigation deferred to the POS app, which displays the member's name on scan for visual verification. Revisit if abuse is observed.

**Benefit:** the membership card renders with no network connection.

### 2.4 Four screens are added

Forgot password, change password, delete account, and edit profile appear nowhere in CUS-01 → CUS-17. Account deletion is required by PRD §18 ("define retention, consent, access, and deletion processes") and by Malaysia's PDPA. Password reset is the difference between a customer temporarily forgetting a password and permanently losing their points balance.

**Backend dependency created:** password reset requires the backend to send email. The PRD does not currently list an email provider as a dependency.

---

## 3. Screens

### 3.1 Navigation

Five bottom tabs, per PRD CUS-16: **Home · Rewards · QR · Menu · Profile**. The QR tab is centred and elevated, per CUS-17.

### 3.2 Screen Inventory (23)

| # | Screen | Tab | PRD ref |
|---|---|---|---|
| 1 | Splash / session bootstrap | — | — |
| 2 | Login (multi-identifier) | — | CUS-02 |
| 3 | Register (student / general) | — | CUS-01 |
| 4 | Forgot password | — | *new* |
| 5 | Student verification pending | — | §14.2 |
| 6 | Home | Home | CUS-05 |
| 7 | Offer detail | Home | CUS-10, CUS-11 |
| 8 | Rewards catalogue | Rewards | CUS-06 |
| 9 | Redeem confirmation | Rewards | CUS-07 |
| 10 | Voucher wallet | Rewards | CUS-06 |
| 11 | Voucher detail (expiry countdown) | Rewards | §10.1 |
| 12 | Stamp card detail | Rewards | CUS-05 |
| 13 | Membership QR card | QR | CUS-04, CUS-17 |
| 14 | Menu list + categories | Menu | CUS-09 |
| 15 | Menu item detail | Menu | CUS-09 |
| 16 | Profile | Profile | CUS-03 |
| 17 | Edit profile | Profile | *new* |
| 18 | Change password | Profile | *new* |
| 19 | Delete account | Profile | *new*, §18 |
| 20 | Transaction history list | Profile | CUS-08 |
| 21 | Transaction detail / receipt | Profile | CUS-08 |
| 22 | Points ledger | Profile | CUS-08 |
| 23 | Settings | Profile | — |

---

## 4. Architecture

### 4.1 Layers

Dependencies point **downward only**. Presentation and Data never reference each other.

```
Presentation  (widgets, screens)
     │
     ▼
Application   (Riverpod providers, view models)
     │
     ▼
Domain        (pure Dart models + repository interfaces)
     ▲
     │
Data          (repository impls, DTOs, HTTP, cache, token store)
```

**Domain** imports nothing — no Flutter, no HTTP, no JSON. Unit-testable with zero mocking.

**Data** implements the domain interfaces. **This layer performs no arithmetic on money, points, or stamps.** It transports values the server computed. Writing `points - voucherCost` anywhere in Dart violates this design.

**Application** orchestrates cache-then-network and exposes loading / data / error states.

**Presentation** reads providers. It never touches a repository.

This is what makes the backend swappable: choosing Supabase or Express means writing one new class in Data and rebinding one provider. Zero screens change.

### 4.2 Rationale (PRD §16.5)

> "Points, stamps, discounts, and eligibility must not be independently recalculated using conflicting client-side logic."

The layer rule above is the mechanical enforcement of that requirement.

### 4.3 Project Structure

Feature-first, because work arrives as "change the rewards flow," not "change all the models."

```
lib/
  core/          # errors, Result type, network client, theme, router
  domain/        # models + repository interfaces (pure Dart)
  data/          # repo impls, DTOs, cache, token store
  features/
    auth/        # register, login, reset, verification pending
    home/        # greeting, points, stamps, offer highlights
    card/        # membership QR  (NO network dependency)
    rewards/     # catalogue, redeem, voucher wallet, stamp card
    menu/        # categories, items, detail
    offers/      # eligible promotions
    history/     # transactions, receipts, points ledger
    profile/     # account, edit, password, delete, settings
```

**`features/card/` must have no network dependency.** It reads the member code from local storage and renders a QR. When every other feature is failing, the membership card still works. That is the screen a customer opens with a barista waiting.

### 4.4 Domain Models

`Member`, `Points`, `StampCard`, `Voucher`, `Reward`, `MenuItem`, `Offer`, `Transaction`, `PointsLedgerEntry`.

Money is represented in **sen (integer minor units)**, never `double`. RM 5.00 is `500`. Floating-point arithmetic on currency is a defect class this design refuses to open.

---

## 5. Data Flow

### 5.1 Reads: cache-then-network

Emit cached data immediately if present → refresh over the network in the background → emit fresh data. A skeleton appears only on a genuinely cold cache. A failed refresh over good cached data is a **quiet stale indicator**, never a blocking dialog.

### 5.2 Writes: online-only, fail loudly

Registration, login, redemption, password change, and account deletion block on the server. **There is no optimistic UI for spending points.** If the network is down, the Redeem button is disabled and says so.

### 5.3 Cache Policy

| Data | Cached | Staleness | Rationale |
|---|---|---|---|
| Member code / QR payload | Forever | Infinite | Immutable after registration; must render offline |
| Points, stamps, free drinks | Yes | Shown with timestamp | A stale balance misleads, so it is dated |
| Vouchers | Yes | Shown with timestamp | Expiry computed from a stored date |
| Menu + images | Yes, long | Hours | Changes rarely; refresh on focus (CORE-07) |
| Offers | Yes, short | Minutes | Date-bounded; showing an expired offer is a bad experience |
| Transaction history | Yes, paged | Hours | Append-only; old pages never change |

### 5.4 The Stale Balance Problem

A cached balance of 240 points may be wrong if the customer spent 100 on another device.

**The redeem call transmits the voucher being purchased, never the client's belief about the balance.** The server checks the true balance. On insufficient points it returns a typed error which the app renders as "Your balance changed — you now have 140 points," then refreshes. The client never asserts a balance.

### 5.5 Cold Start

The live backend's first request after idle was measured at **~20 seconds** (Render free tier; PRD §24.3 predicts this). The network client uses a long first-request timeout with a warming indicator rather than a short timeout that fails and looks broken.

**This is a workaround, not a fix.** The fix is paid hosting, as §24.3 already concluded.

---

## 6. Security

| Concern | Decision |
|---|---|
| JWT storage | `flutter_secure_storage` — Keychain (iOS) / EncryptedSharedPreferences (Android). Never `SharedPreferences`, never the SQLite cache. |
| Token expiry | PRD §14 specifies 7 days. A `401` triggers a hard sign-out and cache wipe. |
| QR survives sign-out | The membership code is not a secret, and the customer may need it while re-authenticating. |
| Cache isolation | Cache is per-member and wiped on sign-out. Two customers sharing a phone must never see each other's points. |
| Duplicate redemption | The redeem call is **idempotent**, keyed by a client-generated request ID. The button locks while in flight. |

### 6.1 Student Verification

PRD §14.2 leaves the method open. Until it is decided:

On registration a customer **self-declares** student status and is created as a general customer carrying a `verificationPending` flag. Student-only offers remain **invisible** until an admin verifies them — PRD §11.3 requires "must not see," not merely "cannot apply." The app displays verification status honestly rather than implying a discount is forthcoming.

---

## 7. Error Handling

Typed failures, because each needs a different user-facing response. Raw exceptions never reach a widget.

| Failure | Response |
|---|---|
| `NetworkFailure` | Show cached data with a stale badge |
| `AuthFailure` | Sign out, clear cache, return to login |
| `InsufficientPointsFailure` | Refresh balance, explain the discrepancy |
| `VoucherExpiredFailure` | Remove from wallet, inform the customer |
| `ValidationFailure` | Map to the offending form field |
| `ServerFailure` | Show a retry affordance |
| Uncaught widget error | Recovery screen, not a grey box |

Driven by PRD §18: *"Errors must not fail silently."*

A customer who taps Redeem and sees nothing will tap again — which is why §6 makes redemption idempotent.

---

## 8. Testing

| Layer | Approach |
|---|---|
| Domain | Plain unit tests, no mocks. This is the payoff for keeping Flutter out of the layer. |
| Data | Tested against a fake HTTP client, **including failure paths** — the failure paths are the product here. |
| Application | In-memory fake repository, free because the interface already exists. |
| Presentation | Widget tests on the four screens where a bug costs money or trust: redeem confirmation, voucher wallet, membership QR, login. |

**One end-to-end integration test:** balance shown → redeem → points deducted → voucher appears → voucher expires. That sequence is where every architectural rule in this document either holds or does not.

**Deliberately not tested:** exact pixel layouts; anything requiring the real backend to exist.

---

## 9. Design System

Per PRD §19. Warm premium café, not a generic admin template.

Cream `#F5EFE8` background · Latte Beige `#ECDDCF` surfaces · Coffee Brown `#5F3E29` primary · Deep Espresso `#1C1108` headers · Caramel `#CDAD8E` accents · Aida Pink `#D98A8A` for student offers and brand continuity · **Reward Gold `#C99A45` reserved exclusively for points, rewards, and loyalty emphasis.**

Type: Dancing Script (brand) · Playfair Display (display) · Plus Jakarta Sans (body/UI).

Mobile-first. Accessibility per PRD §18: legible type, sufficient contrast, meaningful alt text, adequate touch targets.

---

## 10. Toolchain Constraints (observed 10 Jul 2026)

| Finding | Impact |
|---|---|
| Flutter 3.29.0 (Feb 2025, ~17 months old) | Predates current package assumptions. Upgrade deliberately before writing code against it. |
| Android licences not accepted | Blocks Android device builds. Not blocking today. |
| Xcode cannot list simulator runtimes | Blocks iOS simulator. Not blocking today. |
| Chrome device available | Development and testing proceed on web until native targets are fixed. |

Neither native target can ship to a customer's phone until resolved.

---

## 11. Open Questions

1. Which backend stack? (Blocks the real repository implementation, nothing else.)
2. What is the voucher expiry window? Owner decision. PRD §10.1 does not specify one.
3. Which email provider sends password resets?
4. Does account deletion anonymise loyalty history or hard-delete it? Affects reporting integrity.
5. Does the POS scan the QR with a camera, or does staff key in the member code? PRD POS-20 marks camera scanning **Future**, which implies manual entry today.

---

## 12. Dependencies on Other Workstreams

- **Backend:** every write path. The app cannot ship without one.
- **Staff POS:** must parse the QR payload this app generates, and must consume vouchers this app issues. The QR payload format is a contract between the two apps.
- **Admin:** must verify students, or no customer ever sees a student offer.
