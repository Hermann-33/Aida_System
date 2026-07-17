# Aida System — Unified Product Requirements Document

> **Aida Café Loyalty, POS, Ordering, and Business Management Ecosystem**

| Document Field | Detail |
|---|---|
| **Product Name** | Aida System |
| **Product Subtitle** | Aida Café Loyalty, POS, Ordering, and Business Management Ecosystem |
| **Client / Initial Venue** | Aida Café @ City U, Malaysia |
| **Document Version** | 2.4 — Unified PRD, amended for Customer App build-status tracking |
| **Document Date** | 17 July 2026 |
| **Status** | Unified source of truth — current production baseline, approved product direction, and future roadmap |
| **Prepared For** | Business Owner, University Owner, Product, Design, Engineering, and Operations |
| **Supersedes** | Aida System PRD v1.0 and Aida Cafe Rewards PRD v1.5-demo-ready for product scope purposes |
| **Amendment** | v2.1 incorporated the approved Customer App design. v2.2 replaced §19.3 with the client's Core Palette. v2.3 supersedes it with the Rose Palette (red / pink / white) per client direction. v2.4 records which of the 23 designed Customer App screens are built versus outstanding. See §27 for the change log and `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md` for the full design. |

---

## Table of Contents

1. [Document Purpose and Interpretation](#1-document-purpose-and-interpretation)
2. [Executive Summary](#2-executive-summary)
3. [Product Status](#3-product-status)
4. [Business Problem and Opportunity](#4-business-problem-and-opportunity)
5. [Product Vision, Objectives, and Success Measures](#5-product-vision-objectives-and-success-measures)
6. [Users, Roles, and Personas](#6-users-roles-and-personas)
7. [Product Scope](#7-product-scope)
8. [End-to-End Product Experience](#8-end-to-end-product-experience)
9. [Functional Requirements](#9-functional-requirements)
10. [Loyalty, Rewards, and Membership Rules](#10-loyalty-rewards-and-membership-rules)
11. [Offers and Promotions Engine](#11-offers-and-promotions-engine)
12. [Menu and Product Management](#12-menu-and-product-management)
13. [Transactions, Checkout, and Payments](#13-transactions-checkout-and-payments)
14. [Authentication, Authorization, and Access Control](#14-authentication-authorization-and-access-control)
15. [Analytics, Reporting, Export, and Backup](#15-analytics-reporting-export-and-backup)
16. [System Architecture](#16-system-architecture)
17. [Data Model and API Scope](#17-data-model-and-api-scope)
18. [Non-Functional Requirements](#18-non-functional-requirements)
19. [Design System and Brand Direction](#19-design-system-and-brand-direction)
20. [Competitive Context and Product Differentiation](#20-competitive-context-and-product-differentiation)
21. [Technology and Deployment Context](#21-technology-and-deployment-context)
22. [Release History and Roadmap](#22-release-history-and-roadmap)
23. [Acceptance Criteria](#23-acceptance-criteria)
24. [Assumptions, Dependencies, Risks, and Open Decisions](#24-assumptions-dependencies-risks-and-open-decisions)
25. [Operational and Developer Notes](#25-operational-and-developer-notes)
26. [References](#26-references)
27. [Change Log](#27-change-log)

---

## 1. Document Purpose and Interpretation

This document combines the two previous Aida product definitions into one professional source of truth. It removes repeated requirements while preserving every distinct product capability, operational requirement, and future concept.

The previous documents described different layers of the same product:

- The **Aida Cafe Rewards production system** describes the working deployed application, backend, database, authentication, POS workflow, and operational capabilities.
- The **Aida System UI Direction** describes the target customer, staff, and management experience, premium visual direction, ordering expansion, and long-term café digitalization platform vision.

Where the previous documents appeared to conflict, this PRD uses the following interpretation:

| Layer | Interpretation |
|---|---|
| **Production Baseline** | The deployed system and its live backend capabilities are the current functional foundation. |
| **Experience Modernization** | The Next.js UI Direction Preview represents the target interface and design system to be applied to the production platform. |
| **Committed Product Expansion** | Approved functions such as scheduled ordering, membership tiers, and richer reporting remain part of the target Aida Café product even when not yet available in production. |
| **Future Platform Expansion** | Payments, real camera scanning, university integration, inventory, multi-branch support, white-labeling, and AI insights are roadmap capabilities, not current production claims. |

This PRD intentionally does not publish reusable passwords or secrets. Demo credentials must be maintained in a controlled handover or demonstration guide.

---

## 2. Executive Summary

Aida System is an integrated café technology ecosystem for **Aida Café @ City U**. It connects three role-specific interfaces through a shared platform and database:

1. A **Customer Mobile App / PWA** for membership, loyalty, rewards, menu browsing, offers, order-ahead, and transaction history.
2. A **Staff POS Tablet** for member recognition, order entry, discounts, checkout, reward validation, receipts, and daily sales operations.
3. An **Admin and Owner Dashboard** for sales monitoring, member management, menu management, offers, reporting, exports, system status, and business decision-making.

The product already has a deployed production foundation using a Node.js and Express API, Neon PostgreSQL, JWT authentication, and a live multi-role frontend. A separate Next.js interface preview defines the target warm, premium, and commercially polished experience for the next frontend iteration.

Aida Café is the first implementation and reference site. The longer-term opportunity is to evolve the solution into a configurable **café startup digitalization platform** for independent cafés, university cafés, kiosks, boutique brands, and future multi-branch businesses.

---

## 3. Product Status

### 3.1 Current Product Assets

| Product Asset | Status | Purpose |
|---|---|---|
| **Live production application** | Deployed and merchant demo-ready | Working multi-role customer, staff, and admin system connected to a live cloud database |
| **Production backend and database** | Deployed | API, authentication, member records, menu, orders, rewards, offers, analytics, and role-based access |
| **UI Direction Preview** | Available for stakeholder review | Defines the target premium design system and future separated customer, POS, and admin interfaces |
| **Frontend modernization** | Pending design approval and implementation planning | Connect the redesigned interfaces to the existing production platform |
| **Advanced integrations** | Roadmap | Real payments, real QR camera scanning, university SSO, inventory, notifications, and external POS integration |

### 3.2 Live and Preview Environments

| Environment | Address | Notes |
|---|---|---|
| **Production baseline** | `https://city-cafe-rewards.onrender.com` | Deployed Node.js, Express, and Neon production system |
| **UI direction preview** | `https://momenkhairalla-bit.github.io/aida-system/` | Static Next.js frontend preview using mock data |

### 3.3 Product Principle

> **Amended in v2.1.** The original principle read: *"The live backend and validated operational workflows should be retained."*

The **validated operational workflows** are retained. The **backend implementation** is not.

The source code for the deployed `production/api` service is not available to the current project team. A backend that cannot be read, modified, or deployed to is an external dependency rather than a foundation. It cannot gain the customer reward-request capability required by CUS-07, cannot have its cold-start behaviour corrected, and cannot undergo the `students` → `members` domain migration identified as a risk in §24.3. Retention was therefore never actually available as an option.

The backend will be rebuilt. Its stack is an open decision (§24.4). The workflows, data model, loyalty rules, and business logic proven in Phases 1–5 carry forward and are the specification the new backend must satisfy.

The new client applications must not treat this rebuild as licence to relax §16.5: points, stamps, discounts, and eligibility remain server-computed.

---

## 4. Business Problem and Opportunity

Manual or fragmented café operations create several problems:

- Loyalty points and stamp cards are difficult to track consistently.
- Staff may not recognize members or their eligibility quickly at the counter.
- Rewards and student discounts can be applied incorrectly or without validation.
- Customer ordering, POS sales, loyalty, menu data, and reporting may exist in separate tools.
- Owners have limited real-time visibility into sales, members, promotions, redemptions, and product performance.
- General café apps often prioritize ordering but provide weak staff and owner workflows.
- Campus-specific needs, such as verified student offers and student-wallet payment records, are not normally supported as native features.

Aida System addresses these issues by using one shared source of data for customers, staff, and management. The opportunity is not only to improve Aida Café operations, but also to establish a repeatable digital operating model that can later be adapted for other cafés and F&B startups.

---

## 5. Product Vision, Objectives, and Success Measures

### 5.1 Vision

Deliver a warm, premium, secure, and market-ready café ecosystem that makes loyalty rewarding for customers, transactions efficient for staff, and business performance clear for owners.

### 5.2 Product Objectives

1. Increase customer retention and repeat visits through points, digital stamps, vouchers, birthday rewards, and targeted offers.
2. Reduce transaction time and cashier errors using scan-first member recognition, a touch-optimized cart, automatic reward calculations, and clear checkout confirmation.
3. Provide verified student benefits without exposing student-only promotions to ineligible customers.
4. Give owners reliable visibility into revenue, orders, average order value, members, redemptions, products, and campaign performance.
5. Replace disconnected spreadsheets and manual loyalty tracking with a shared operational platform.
6. Preserve the working production backend while upgrading the frontend to a professional, premium design standard.
7. Establish Aida Café as the reference implementation for a future configurable café digitalization service.

### 5.3 Success Measures

| Measure | Target Direction |
|---|---|
| Registered and active members | Consistent month-over-month growth |
| Repeat purchase rate | Improvement after loyalty activation |
| Reward redemption rate | Measurable and attributable to repeat visits |
| POS transaction time | Lower than the manual or non-integrated process |
| Checkout correction rate | Reduced through validation and confirmation |
| Student offer utilization | Fully tracked and reportable |
| Average order value | Monitored by day, campaign, and customer type |
| Owner dashboard usage | Regular daily or weekly engagement |
| Menu and offer update time | Changes available to relevant users without manual duplication |
| System availability | Stable enough for counter operations and merchant demonstrations |

---

## 6. Users, Roles, and Personas

### 6.1 Customer

Customers are authenticated members and may belong to one of two member types:

- **Student Member:** A verified City U student eligible for student-specific benefits.
- **General Customer:** A non-student member eligible for general loyalty and promotions.

**Goals:**

- Register and access a personal account.
- Display a membership QR code, barcode, member code, or student ID.
- View points, stamps, free drinks, vouchers, membership level, and transaction history.
- Browse the menu, featured items, and eligible promotions.
- Request reward redemption for staff confirmation.
- Place a scheduled order when order-ahead is enabled.

**Restrictions:** *(amended in v2.1)*

- Customers cannot manually add points or record purchases.
- Customers **may** convert their own points into a voucher from within the customer app. They **cannot** consume a voucher, free drink, or any entitlement for product without staff action at the counter.
- Student-only promotions must remain hidden or unavailable to general customers.

> **Rationale for the amendment.** Earlier versions of this document treated "redeem" as a single act. It is two: *converting points into an entitlement*, and *consuming an entitlement for product*. The fraud this PRD guards against — a customer granting themselves free product — lives entirely in the second. Permitting the first is standard in comparable Malaysian loyalty apps (§20) and materially improves the customer experience without weakening the control. See §10.1.

### 6.2 Staff / Barista / Cashier

**Goals:**

- Start a staff session with counter or shift context.
- Identify a customer quickly by scanning or entering an accepted member identifier.
- Build an order using an image-supported product grid and category navigation.
- Apply only valid discounts, offers, vouchers, and free-drink rewards.
- Record payment details, issue a receipt, and complete the sale accurately.
- Review held orders, sales history, and the current-day summary.

**Experience needs:**

- Tablet landscape support.
- Large touch targets.
- Clear subtotal, discount, reward, payment, and change information.
- Mistake-resistant confirmation and validation.

### 6.3 Admin / Owner / Manager

**Goals:**

- Monitor revenue, transactions, average order value, members, points, redemptions, promotions, and system status.
- Manage customers, student verification, products, menu images, offers, vouchers, and item availability.
- Filter and review transactions.
- Export reports and create backups.
- Use operational guides, SOPs, settings, and merchant demonstration support.

**Experience needs:**

- Professional desktop dashboard.
- Clear period comparisons and business trends.
- Reliable exports and operational transparency.

---

## 7. Product Scope

### 7.1 In Scope — Unified Aida Café Product

| Capability Group | Included Scope |
|---|---|
| **Customer Experience** | Registration, login, member profile, QR/barcode membership, points, stamps, rewards, history, menu, promotions, tiers, and scheduled ordering |
| **Staff POS** | Member lookup, product selection, cart, discounts, payments, cash change, order hold/resume, receipts, redemptions, history, and daily summary |
| **Admin Dashboard** | KPIs, charts, transaction review, member management, student verification, menu CRUD, image management, offer management, exports, backup, SOP, and settings |
| **Loyalty Core** | Points, stamp cards, free drinks, vouchers, tiers, birthday rewards, campaign multipliers, and staff-controlled redemption |
| **Member Segmentation** | Student and general customer types with eligibility controls |
| **Platform Core** | Shared database, API, authentication, role-based permissions, analytics, status monitoring, and offline demonstration fallback |
| **Design Modernization** | Warm premium design system across mobile, tablet, and desktop experiences |

### 7.2 Current Soft-POS Boundary

The system currently records the order and selected payment method, while payment is completed outside the application through cash, a card terminal, an e-wallet merchant flow, or a student wallet. The system does not currently process or settle funds.

### 7.3 Future Platform Scope

The future café digitalization platform may include:

- Real payment-gateway integration.
- DuitNow, FPX, card, Touch 'n Go, GrabPay, and supported merchant-payment integrations.
- Real QR or barcode camera scanning.
- University SSO or student database verification.
- Push, email, or SMS notifications.
- Inventory and ingredient tracking.
- Kitchen display and order-status workflows.
- Accounting and external POS integration.
- Native iOS and Android applications.
- Multi-branch and franchise management.
- White-label branding and tenant configuration.
- Loyalty rule builders and campaign automation.
- AI-assisted sales, demand, and customer insights.

### 7.4 Out of Scope for the Current Production Release

- Direct payment processing or storage of payment-card data.
- Live university SSO or direct student-database access.
- Inventory, recipe, and ingredient depletion.
- Kitchen display system.
- Multi-branch operations.
- Public app-store release.
- Automated accounting settlement.
- Production AI recommendations.

---

## 8. End-to-End Product Experience

### 8.1 Standard Purchase Flow

1. The customer registers or logs in.
2. At the counter, the customer displays a QR code, barcode, member code, student ID, or another supported identifier.
3. Staff scans or manually enters the identifier.
4. The POS displays the member name, customer type, student status, tier, points, stamps, and available rewards.
5. Staff selects products and quantities.
6. The platform evaluates active offers and eligibility.
7. Staff applies an eligible offer or reward where required.
8. The POS displays subtotal, discount, total, points to be earned, stamp impact, payment method, cash received, and change where applicable.
9. Staff confirms the sale after external payment is completed.
10. The system records the order, updates points and stamps, unlocks a free drink when the threshold is reached, and makes the transaction visible to the customer and admin.

### 8.2 Reward Redemption Flow

1. The customer views available vouchers or free drinks.
2. The customer presents the reward at the counter or requests redemption in the customer interface.
3. Staff verifies the member and confirms the reward is valid.
4. The system prevents insufficient-balance, ineligible, duplicate, or expired redemption.
5. Staff completes the redemption.
6. The platform records points used or the free-drink entitlement consumed.

### 8.3 Scheduled Order-Ahead Flow

1. The customer browses the menu and selects products.
2. The customer selects an available collection date and time.
3. The system validates product availability and applicable offers.
4. The order is submitted for café preparation.
5. Staff views the scheduled order in the operational queue.
6. Payment handling follows the configured order-ahead payment model when this feature is implemented.

---

## 9. Functional Requirements

Requirement status uses the following definitions:

- **Live:** Available in the production baseline.
- **Modernization:** Existing capability to be retained and redesigned in the new interface.
- **Planned:** Approved product capability not yet fully available in production.
- **Future:** Longer-term platform capability.

### 9.1 Customer Mobile App / PWA

| ID | Requirement | Priority | Status |
|---|---|---:|---|
| CUS-01 | Customer self-registration for Student Member or General Customer accounts | P0 | Live / Modernization |
| CUS-02 | Secure login using username, email, student ID, member code, barcode, QR value, or phone where linked | P0 | Live / Modernization |
| CUS-03 | Personal profile with member type and account information | P0 | Live / Modernization |
| CUS-04 | Digital membership card with QR code, barcode, member code, and supported identifiers | P0 | Live / Modernization |
| CUS-05 | Home screen showing greeting, points balance, stamp progress, free-drink balance, and eligible offer highlights | P0 | Live / Modernization |
| CUS-06 | Rewards area showing vouchers, points requirements, stamp rewards, and redemption status | P0 | Live / Modernization |
| CUS-07 | Customer-initiated points-to-voucher redemption in the app; the resulting voucher requires staff to apply it at checkout | P0 | Amended v2.1 |
| CUS-08 | Transaction and redemption history | P0 | Live / Modernization |
| CUS-09 | Menu browsing with product name, image, description, category, availability, and RM price | P0 | Modernization |
| CUS-10 | Featured items, best sellers, promotional banners, and campaign content | P1 | Modernization |
| CUS-11 | Student-only offers visible only to verified eligible members | P0 | Live / Modernization |
| CUS-12 | Membership tier and tier-progress display | P1 | Planned |
| CUS-13 | Points-to-reward equivalence indicator | P1 | Planned |
| CUS-14 | Scheduled order-ahead and collection-time selection | P1 | Planned |
| CUS-15 | Birthday reward visibility and notification | P1 | Planned |
| CUS-16 | Mobile bottom navigation for Home, Rewards, QR, Menu, and Profile | P0 | Live / Modernization |
| CUS-17 | Elevated one-tap QR access from primary navigation | P0 | Modernization |
| CUS-18 | Password reset by email for a locked-out customer | P0 | New v2.1 |
| CUS-19 | In-app password change for an authenticated customer | P1 | New v2.1 |
| CUS-20 | Account deletion with a defined data-retention outcome (§18 privacy, Malaysia PDPA) | P0 | New v2.1 |
| CUS-21 | Edit own profile: name, phone, and birthday | P1 | New v2.1 |
| CUS-22 | Membership QR renders with no network connection | P0 | New v2.1 |
| CUS-23 | Cached balances are displayed with the time they were last refreshed | P1 | New v2.1 |

> **CUS-18 through CUS-21 were absent from v2.0.** A customer who forgets a password currently has no route back to their points balance, and §18 mandates a deletion process that no requirement implemented. CUS-18 introduces a new platform dependency: the backend must be able to send email.
>
> **CUS-22 and CUS-23** make explicit the offline guarantees the customer app relies on. The membership card is the one screen a customer opens with a barista waiting, and it must never depend on campus wifi.

#### 9.1.1 Flutter Customer App — Screen Build Status (as of 17 Jul 2026)

Against the 23-screen list in `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md` §3, plus real ordering added afterward at client request (cart, checkout, order tracking, order history — outside the original 23, see the v2.4 change log entry):

**Built:** Login, Sign Up (registration), Forgot Password (CUS-01, CUS-02), Home (CUS-05), Rewards catalogue + redeem + voucher wallet, combined into one screen rather than three (CUS-06, CUS-07), Membership QR card (CUS-04, CUS-17, CUS-22), Menu + category browsing (CUS-09), Menu item detail with size/add-ons/notes/favoriting, Profile (CUS-03) and Edit Profile (CUS-21), Transaction history list and receipt detail (CUS-08), plus the added cart/checkout/order-tracking flow.

**Not yet built:**
- Splash / session bootstrap — the app opens directly to Login; there is no cached-session check to bootstrap yet since Auth has no real backend (§24.4 #11).
- Student verification pending screen (§14.2) — a self-declared student currently has no screen explaining that their status is pending admin verification.
- Offer detail — promotional cards on Home are not tappable to any detail view (CUS-10, CUS-11 render the offer, but don't yet let a customer open it).
- Change password (CUS-19) and Delete account (CUS-20) — both have a requirement and a Settings row that says "coming soon"; neither has a screen.
- Points ledger — no dedicated view of individual point-earning/spending events (CUS-08 covers transactions, not a ledger).
- Settings — a real screen (notifications, language, etc.) as opposed to the placeholder row.
- Voucher detail with an expiry countdown as its own page (§10.1) — expiry is shown inline on each voucher card, not as a separate detail screen.

Two rows on Profile — "My Stats" and "Invite a Friend" — were added during UI iteration and are not in the original 23-screen list or any CUS requirement. They are placeholders; keep or drop is an open product call, not an engineering one.

### 9.2 Staff POS Tablet

| ID | Requirement | Priority | Status |
|---|---|---:|---|
| POS-01 | Authenticated staff session with cashier identity and optional counter or shift context | P0 | Live / Modernization |
| POS-02 | Scan or manually enter member QR, barcode, member code, student ID, username, or phone | P0 | Live / Modernization |
| POS-03 | Display member name, type, verification status, tier, points, stamps, and available rewards | P0 | Live / Modernization |
| POS-04 | Product category navigation with active-item filtering | P0 | Live / Modernization |
| POS-05 | Product grid showing image, name, price, and availability | P0 | Live / Modernization |
| POS-06 | Cart management with add, remove, quantity changes, line totals, subtotal, discount, and final total | P0 | Live / Modernization |
| POS-07 | Automatic validation of student offers and other eligibility rules | P0 | Live / Modernization |
| POS-08 | Support percentage, fixed-amount, double-points, and special-price offers | P0 | Live / Modernization |
| POS-09 | Display expected points earned, stamp change, and free-drink unlock before confirmation | P0 | Live / Modernization |
| POS-10 | Select Cash, Card, E-wallet, or Student Wallet as the recorded payment method | P0 | Live / Modernization |
| POS-11 | Cash received and automatic change calculation | P0 | Live / Modernization |
| POS-12 | Checkout confirmation before recording the sale | P0 | Live / Modernization |
| POS-13 | Generate and display a transaction receipt | P0 | Live / Modernization |
| POS-14 | Hold and resume an incomplete order | P1 | Live / Modernization |
| POS-15 | Redeem vouchers and free drinks with validation | P0 | Live / Modernization |
| POS-16 | Sales history and transaction detail access | P0 | Live / Modernization |
| POS-17 | Today summary for revenue, orders, and operational totals | P0 | Live / Modernization |
| POS-18 | In-app Demo Help and operating guidance | P1 | Live / Modernization |
| POS-19 | Touch-optimized tablet landscape design with large targets and clear hierarchy | P0 | Modernization |
| POS-20 | Real camera-based QR or barcode scanning | P1 | Future |
| POS-21 | Scheduled-order preparation queue and collection status | P1 | Planned |

### 9.3 Admin and Owner Dashboard

| ID | Requirement | Priority | Status |
|---|---|---:|---|
| ADM-01 | Sidebar navigation for Overview, Reports, Transactions, Menu, Promotions, Members, Settings, Guides, and Export | P0 | Live / Modernization |
| ADM-02 | KPI overview for revenue, orders, average order value, active members, student members, points issued, rewards redeemed, and system status | P0 | Live / Modernization |
| ADM-03 | Daily, weekly, and selected-period sales trends | P0 | Live / Modernization |
| ADM-04 | Top-product and category performance reporting | P0 | Live / Modernization |
| ADM-05 | Recent transactions with payment and reward status | P0 | Live / Modernization |
| ADM-06 | Filterable transaction history | P0 | Live / Modernization |
| ADM-07 | Period-over-period KPI comparisons | P1 | Planned |
| ADM-08 | Member management for student and general customer accounts | P0 | Live / Modernization |
| ADM-09 | Student verification status management | P0 | Live / Modernization |
| ADM-10 | Menu item create, read, update, activate, and deactivate functions | P0 | Live / Modernization |
| ADM-11 | Product image upload and management | P0 | Live / Modernization |
| ADM-12 | Best-seller and student-offer eligibility flags for products | P0 | Live / Modernization |
| ADM-13 | Offer, promotion, voucher, date-range, eligibility, and rule management | P0 | Live / Modernization |
| ADM-14 | Active-promotion overview panel | P0 | Modernization |
| ADM-15 | CSV exports for sales, members, redemptions, and daily summary | P0 | Live / Modernization |
| ADM-16 | Full JSON backup and restore | P1 | Live / Modernization |
| ADM-17 | Demo Guide, SOP, system settings, and merchant handover information | P1 | Live / Modernization |
| ADM-18 | Scheduled-order management and operational status | P1 | Planned |
| ADM-19 | Multi-branch and tenant-level administration | P2 | Future |
| ADM-20 | AI-generated sales and customer insights | P2 | Future |

### 9.4 Shared Platform Core

| ID | Requirement | Priority | Status |
|---|---|---:|---|
| CORE-01 | One shared source of truth for users, members, products, offers, orders, loyalty, and reporting | P0 | Live |
| CORE-02 | Role-based access for admin, staff, and customer accounts | P0 | Live |
| CORE-03 | Consistent data updates across customer, staff, and admin interfaces | P0 | Live |
| CORE-04 | Health and version endpoint for operational monitoring | P1 | Live |
| CORE-05 | Offline localStorage demonstration fallback when the API is unavailable | P1 | Live |
| CORE-06 | Live/offline connection status indicator | P1 | Live |
| CORE-07 | Refresh shared menu data when relevant screens regain focus or are reopened | P1 | Live |
| CORE-08 | Modular architecture supporting future mobile, PWA, POS, and dashboard clients | P0 | Modernization |

---

## 10. Loyalty, Rewards, and Membership Rules

### 10.1 Current Default Rules

| Rule | Default Definition |
|---|---|
| **Points accrual** | RM 1 spent = 1 Aida Point |
| **Stamp accrual** | 1 stamp per completed qualifying purchase |
| **Free drink** | Every 10 stamps unlocks 1 free drink and resets the active stamp counter |
| **RM 5 voucher** | 100 points |
| **RM 10 voucher** | 180 points |
| **Free pastry voucher** | 150 points |
| **Points → voucher** | *(v2.1)* The customer may perform this in the app, or staff may perform it at the POS. Points are deducted at the moment of conversion. |
| **Voucher → product** | *(v2.1)* Staff only. A voucher has no value until a cashier applies it at checkout. |
| **Voucher expiry** | *(v2.1)* A voucher expires after a business-configurable period. **Points are not refunded on expiry.** |
| **Redemption idempotency** | *(v2.1)* Every redemption carries a client-generated request ID. A repeated request must not deduct points twice. |
| **Member types** | Student Member and General Customer |
| **Student benefits** | Available only to verified eligible members |

The business owner must be able to revise point rates, stamp thresholds, voucher costs, expiry periods, and qualifying products without requiring a source-code change in the mature product.

### 10.2 Membership Tiers

The target product supports configurable tiers such as **Espresso**, **Gold**, or future branded levels. Tier rules may use lifetime spend, points earned, visit frequency, or another approved metric.

A tier may control:

- Display status and progress.
- Bonus-point multipliers.
- Exclusive vouchers.
- Birthday or anniversary rewards.
- Early access to campaigns.

### 10.3 Birthday Rewards

Birthday reward automation is a planned capability. It must support configurable validity periods, reward types, eligibility checks, and one-time redemption controls.

---

## 11. Offers and Promotions Engine

Offers are created by an admin and validated by the POS or ordering channel before use.

### 11.1 Eligibility Dimensions

- Member type: `city_student`, `general_customer`, or `all`.
- Verification status.
- Active start and end date.
- Product or category eligibility.
- Minimum spend.
- Usage limit per member or campaign.
- Location or branch in future multi-branch mode.

### 11.2 Supported Offer Types

| Offer Type | Behaviour |
|---|---|
| **Percentage** | Applies a percentage discount to an order, category, or eligible products |
| **Fixed amount** | Applies a flat RM discount capped at the eligible subtotal |
| **Double or bonus points** | Increases points earned without reducing the selling price |
| **Special price** | Applies a bundle or combo price to a defined product set |
| **Voucher** | Deducts points or consumes a granted entitlement for a defined reward |
| **Birthday reward** | Grants a time-limited birthday benefit |
| **Stamp reward** | Consumes a free-drink entitlement earned from stamp completion |

### 11.3 Validation Requirements

- General customers must not see or apply student-only offers.
- Expired, inactive, duplicate, ineligible, or exhausted offers must be rejected.
- Discounts must never reduce the payable total below zero.
- A reward or voucher must be consumed once unless explicitly configured otherwise.
- The recorded transaction must identify the applied offer and financial effect.

---

## 12. Menu and Product Management

### 12.1 Product Data

Each menu item supports:

- Product name.
- Category.
- Description.
- RM price.
- Product image and image alternative text.
- Active or inactive status.
- Best-seller flag.
- Student-offer eligibility flag.
- Future branch availability.
- Future option or modifier groups.

### 12.2 Initial Menu Reference

| Category | Example Products |
|---|---|
| **Coffee** | Latte, Americano, Cappuccino, Mocha |
| **Iced Drinks** | Iced Coffee, Iced Latte, Matcha Latte, Chocolate Ice |
| **Food** | Sandwich, Croissant, Muffin, Chicken Wrap |
| **Add-ons** | Extra Shot, Oat Milk, Whipped Cream |

Prices and menu content are business-controlled data and must not be hard-coded as permanent requirements.

### 12.3 Menu Image Requirements

| Requirement | Definition |
|---|---|
| Supported formats | PNG, JPG, JPEG, and WEBP |
| Current maximum size | 500 KB, validated on client and server |
| Storage | Base64 image data or external image URL in the current implementation |
| Shared availability | An admin upload must become available to all connected interfaces |
| Fallback | A category placeholder appears where no product image is available |

The production modernization stage should evaluate object storage for improved performance and maintainability instead of long-term base64 database storage.

---

## 13. Transactions, Checkout, and Payments

### 13.1 Sale Record

Each sale must record, at minimum:

```text
order_number
transaction_type
created_at
member_id
staff_user_id
cashier_name
items[]: item, category, quantity, unit_price, line_total
subtotal
discount
discount_type
applied_offer_or_reward
total
payment_method
cash_received
change_amount
points_earned
stamp_before
stamp_after
free_drink_unlocked
status
note
```

### 13.2 Redemption Record

Each redemption must record:

```text
transaction_type: Reward | Voucher | Free Drink
member_id
points_used
reward_name
created_at
cashier_name
source_entitlement
status
```

### 13.3 Current Payment Model

The product operates as a soft POS. Staff selects the payment method after payment occurs through an external mechanism.

Supported recorded methods:

- Cash.
- Card.
- E-wallet.
- Student Wallet.

### 13.4 Future Payment Strategy

| Payment Method | Potential Integration Direction |
|---|---|
| Cash | Manual record only |
| Debit or credit card | Bank terminal or approved merchant service |
| Touch 'n Go or GrabPay | Merchant QR or gateway with webhook confirmation |
| FPX | Approved gateway such as iPay88, Billplz, or Senangpay |
| External hardware POS | API, export, or supported integration with providers such as StoreHub, Qashier, or Soft Space |

The product must not implement custom card processing. Any production payment integration must use an approved payment provider and comply with its security and settlement requirements.

---

## 14. Authentication, Authorization, and Access Control

| Area | Requirement |
|---|---|
| Authentication | JWT bearer-token authentication in the current production backend |
| Session duration | Current default token expiry of seven days; configurable for production policy |
| Password protection | bcrypt hashing using `bcryptjs` in the current implementation |
| Roles | `admin`, `staff`, and `customer` |
| Member types | Student Member and General Customer |
| Login identifiers | Username, email, student ID, member code, barcode, QR value, or phone where linked |
| Customer registration | Self-service registration with controlled member-type selection and verification workflow |
| API protection | All protected API routes require a valid token |
| Authorization | Sensitive actions are limited by role; analytics and management functions require admin access |
| Redemption control | Customers may request rewards, but only staff or authorized users may complete deductions |
| Secrets | Database credentials and JWT secrets must remain in environment variables and never be committed |

### 14.1 Multi-Identifier Login Logic

1. Attempt direct account lookup by username or email.
2. When no direct account is found, resolve the submitted identifier against member scan fields.
3. Resolve the member record to its linked authentication account.
4. Verify the password hash and issue the role-appropriate session.

### 14.2 Student Verification

The product must support a verification status separate from customer self-declaration. Future verification options include:

- Manual admin verification.
- City U email-domain verification.
- Campus ID review.
- University SSO.
- Approved student-database integration.

---

## 15. Analytics, Reporting, Export, and Backup

### 15.1 Dashboard Metrics

The admin dashboard must support:

- Today revenue.
- Number of transactions or orders.
- Average order value.
- Active registered members.
- Student and general-member counts.
- Points issued.
- Rewards and vouchers redeemed.
- Sales trends.
- Top products and categories.
- Recent transactions.
- Active promotions.
- System and database connection status.
- Period-over-period comparisons in the modernized product.

### 15.2 Reporting and Filters

Reports should be filterable by relevant combinations of:

- Date and time range.
- Member or member type.
- Staff user.
- Product or category.
- Payment method.
- Offer or reward.
- Transaction type and status.
- Future branch or location.

### 15.3 Export and Backup

| Export | Status |
|---|---|
| Sales transactions CSV | Live |
| Members CSV | Live |
| Redemptions CSV | Live |
| Daily summary CSV | Live |
| Full JSON backup | Live |
| JSON restore | Live |
| Scheduled automated backup | Future |
| Accounting-system export | Future |

Backup and restore actions must be restricted to authorized users and must include confirmation to prevent accidental overwrite.

---

## 16. System Architecture

### 16.1 Product Ecosystem

```text
Customer Mobile App / PWA ─┐
                            │
Staff POS Tablet ───────────┼──► Shared Platform Core
                            │      Members · Auth · Menu
Admin / Owner Dashboard ────┘      Offers · Orders · Loyalty
                                   Analytics · Reporting
```

### 16.2 Current Deployed Architecture

```text
Browser SPA
(index.html + js/city-cafe-v2.js)
        │
        │ HTTPS + JWT bearer token
        ▼
Node.js + Express API on Render
        │
        ▼
Neon PostgreSQL
(ap-southeast-1)
```

### 16.3 UI Direction Preview Architecture

```text
Next.js 16 + React 19 + TypeScript
Static export hosted on GitHub Pages
Mock data only
No production API connection
```

### 16.4 Target Architecture

```text
Customer PWA / Mobile App ──┐
Staff POS Web App ───────────┼──► Backend API ──► PostgreSQL
Admin Dashboard ─────────────┘         │
                                      ├──► Payment Gateway (future)
                                      ├──► Notification Service (future)
                                      ├──► University Verification (future)
                                      └──► External POS / Accounting (future)
```

### 16.5 Architecture Principle

The target frontend may use separate role-oriented applications or route groups, but all interfaces must rely on a shared domain model, consistent API contracts, and centralized business rules. Points, stamps, discounts, and eligibility must not be independently recalculated using conflicting client-side logic.

---

## 17. Data Model and API Scope

### 17.1 Current Core Data Structures

The current production database includes or represents:

- `users`
- `students` / members
- `menu_items`
- `vouchers`
- `offers`
- `orders`
- `order_items`
- `loyalty_transactions` view

The unified domain model should progressively use neutral member naming rather than assuming every customer is a student.

### 17.2 Shared Entities

| Entity | Purpose |
|---|---|
| User | Authentication identity and role |
| Member | Customer profile, member type, identifiers, verification, tier, and loyalty balances |
| Menu Item | Product content, price, image, category, flags, and availability |
| Offer | Promotion rules, eligibility, dates, and financial or points effect |
| Voucher / Reward | Redeemable entitlement and points requirement |
| Order | Sale, scheduled order, totals, payment record, member, and cashier |
| Order Item | Product-level quantity and pricing details |
| Loyalty Transaction | Points, stamps, vouchers, or free-drink movement |
| Report / Export | Generated operational or management output |

### 17.3 Current API Areas

| API Area | High-Level Functions |
|---|---|
| System | Application UI, health, version, and connection status |
| Authentication | Login, registration, and current-user identity |
| Menu | List, create, update, and change item status, including images |
| Members | List, retrieve, identify, and view history |
| Scan | Resolve supported member identifiers for authorized staff |
| Offers | Retrieve and validate active promotions |
| Orders | Record sales, redemptions, and transaction history |
| Analytics | Admin overview and performance summaries |

All API contracts must return clear validation messages and must prevent unauthorized role access.

---

## 18. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | Core POS interactions must feel immediate; repeated product and member lookups should be optimized for counter use. |
| **Availability** | The production service should be suitable for café operating hours; free-tier cold starts must not be treated as an acceptable long-term production standard. |
| **Usability** | Customer experience must be simple and reward-focused; POS must be fast and mistake-resistant; admin must be owner-ready and data-driven. |
| **Responsiveness** | Customer interface is mobile-first, POS is optimized for tablet landscape, and admin is optimized for desktop while remaining usable on smaller screens. |
| **Accessibility** | Legible typography, sufficient contrast, keyboard support where relevant, meaningful alternative text, and appropriately sized touch targets. |
| **Security** | Protect member data, hash passwords, restrict roles, validate uploads, secure secrets, and avoid direct payment-card handling. |
| **Data Integrity** | A completed transaction must update order, loyalty, offer, and reporting data consistently. Partial updates must not create incorrect balances. |
| **Reliability** | Errors must not fail silently. Checkout, redemption, backup, and restore require clear confirmation and result feedback. |
| **Consistency** | Shared business rules and one design system must be used across all interfaces. |
| **Localization** | Malaysian Ringgit (RM), Malaysia date and time conventions, and English UI at launch; Bahasa Malaysia may be added later. |
| **Scalability** | The architecture must support future branches, white-label tenants, higher transaction volume, and separate client applications. |
| **Maintainability** | Domain logic, API services, UI components, and configuration must be modular and documented. |
| **Observability** | Health, application version, database connectivity, and meaningful server errors must be available to authorized operators. |
| **Privacy** | Collect only required personal data and define retention, consent, access, and deletion processes before broader deployment. |

---

## 19. Design System and Brand Direction

### 19.1 Brand Positioning

The target visual direction is a **warm premium café experience**: cozy, elegant, friendly, trustworthy, and modern. The application should look like a commercial café product rather than a poster, brochure, or generic admin template.

### 19.2 Brand Transition

> **Amended in v2.2.** The previous paragraph read: *"The current production frontend uses a strong pink-and-black Aida theme... The modernization should retain pink as a recognizable Aida accent."*

The client has since issued a **Core Palette** (below) that replaces pink with **City Red** as the sole accent used for student and City U identity. Pink is not part of the application UI in any surface — button, card, nav, banner, or otherwise.

> **Re-amended in v2.3.** The paragraph above is retained for history but no longer holds: on 16 Jul 2026 the client redirected the app theme to **red / pink / white**, bringing pink back as the secondary-surface colour. City Red remains reserved for student and City U identity. See the v2.3 table below.

Pink and gold-sparkle floral detailing do still appear on the **Aida Café logo mark** itself. This is a deliberate split, not an oversight: the logo is treated as a fixed brand asset, not a source of UI color. See §19.3.1.

### 19.3 Target Palette — Rose Palette (v2.3)

> **Superseded in v2.3.** The v2.2 Core Palette used warm coffee tones (Cream `#FCF8F5`, Latte `#E0D5C3`, Coffee `#7A5B44`, Espresso `#1C120E`). On 16 Jul 2026 the client redirected the theme to **red / pink / white**. Token *names* are retained from v2.2 — they are identifiers in code, and every screen references the role, not the hue — but their values and colour descriptions below are new. City Red, Reward Gold, Card White, Error, and Success carry over unchanged.

| Token | Value | Intended Use |
|---|---|---|
| City Red | `#AF2626` *(provisional)* | City U / student identity **only** — student offers, student badges, campus affiliation. Deliberately a deeper brick red than the Coffee action colour so the student signal survives in a red-accented UI. Not used for errors; see the Error row below. |
| Cream | `#FDF6F7` *(provisional)* | Primary background — blush-tinted white |
| Latte | `#F2CFD6` *(provisional)* | Secondary surfaces, dividers, muted fills — soft pink |
| Coffee | `#C13A52` *(provisional)* | Primary actions and brand text — raspberry red, brighter than City Red so buttons never read as a student badge |
| Espresso | `#27121A` *(provisional)* | High-contrast headers, controls, the membership card, and dark surfaces — near-black with a plum undertone |
| Reward Gold | `#C9A24E` *(provisional)* | Points, stamps, rewards, and loyalty emphasis **only** — a functional signal, not a theme colour; carried over unchanged |
| Card White | `#FFFFFF` | Cards and elevated surfaces |
| Error | `#8C3A2E` *(provisional, derived)* | Errors and destructive actions. Deliberately distinct from both City Red and Coffee — burnt sienna rather than a third red — so a failure never reads as a promotion or a button |

**Provisional flag.** The v2.3 values were chosen by the development team to demonstrate the client's red/pink/white direction; they are not sampled from any client asset. They are correct enough to build against but **not yet confirmed exact**. When the client supplies final hex codes, only `apps/customer/lib/core/theme/aida_colors.dart` needs to change — no screen references a colour directly.

#### 19.3.1 Palette vs. Logo — Decision

**The Core Palette governs every UI surface. The logo mark is not a UI colour source.**

The approved logo carries pink/rose florals and gold sparkle that do not appear in the Core Palette. The client has confirmed this split is intentional: those tones stay inside the logo asset itself and are never pulled into buttons, cards, offer banners, or navigation. A screen that needs the Aida mark uses a placeholder pending the final logo file (see §19.3.2); it does not approximate the mark's colours in surrounding UI.

#### 19.3.2 Logo Asset Status

The final logo file is **not yet supplied**. Every screen that needs it renders a neutral bordered "LOGO" placeholder rather than a guess at the mark — an incorrect logo shown to the client is worse than an obviously empty slot. The placeholder lives in one component (`apps/customer/lib/core/theme/aida_logo.dart`); dropping in the final asset is a one-file change.

### 19.4 Typography

| Role | Typeface Direction |
|---|---|
| Brand Script | Dancing Script |
| Display | Playfair Display |
| Body and UI | Plus Jakarta Sans |

### 19.5 UI Standards

- Clean rounded cards with subtle warm shadows.
- Clear spacing and modern information hierarchy.
- High-visibility loyalty and reward states.
- Product imagery that supports, rather than overwhelms, the transaction flow.
- Consistent components across customer, POS, and admin interfaces.
- Large POS tap targets and clear destructive-action confirmation.
- The café banner may guide the mood but must not be repeated as a page background.

---

## 20. Competitive Context and Product Differentiation

Aida System should learn from established Malaysian café and ordering experiences without copying their visual designs.

| Reference | Relevant Learning |
|---|---|
| ZUS Coffee | Keep points and rewards highly visible |
| Coffee Bean / MyCBTL | Premium membership and order-ahead experience |
| Starbucks Malaysia | High visual polish and recognizable loyalty status |
| Tealive | Promotions, recurring campaigns, and birthday benefits |
| Gigi Coffee | Fast scan and pickup workflows |
| Bask Bear Coffee | Warm, distinctive brand personality |
| Kenangan Coffee | Voucher and campaign clarity |
| GrabFood / Foodpanda | Familiar product, cart, and checkout hierarchy |

### Aida Differentiation

Aida is not only a customer ordering app. Its differentiator is the connected relationship between:

- Customer loyalty and ordering.
- Staff POS execution and reward validation.
- Owner analytics and configuration.
- Campus-specific student eligibility.
- A future reusable café digitalization platform.

---

## 21. Technology and Deployment Context

### 21.1 Current Production Stack

| Layer | Technology |
|---|---|
| Frontend | Single-page `index.html` and `js/city-cafe-v2.js` |
| Backend | Node.js and Express using ES modules |
| Database | PostgreSQL on Neon, Singapore region |
| Authentication | JWT and bcrypt |
| Hosting | Render |
| Development URL | `http://localhost:3001` |
| Production version surface | `/health` returns application version information |

### 21.2 UI Direction Stack

| Layer | Technology |
|---|---|
| Framework | Next.js 16 App Router |
| UI Runtime | React 19 and TypeScript |
| Styling | Scoped CSS under the Aida UI namespace |
| Output | Static export |
| Hosting | GitHub Pages |
| Data | Mock data only in the preview |

### 21.3 Target Technology Direction

The preferred modernization path is to connect a React / Next.js production frontend or PWA to the existing API, while gradually improving API structure, shared types, testing, observability, and storage. A native or cross-platform customer app may be considered after the responsive PWA experience is validated.

Technology choices must be confirmed during architecture planning and should not require rewriting proven backend functionality without a measurable benefit.

### 21.4 Customer App Stack *(added v2.1)*

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State management | Riverpod |
| Architecture | Domain / Data / Application / Presentation, dependencies pointing downward only |
| Secure storage | `flutter_secure_storage` — Keychain on iOS, EncryptedSharedPreferences on Android |
| Currency | Integer sen. Never floating point. |
| Backend coupling | None. All data access sits behind domain repository interfaces. |
| Repository location | `apps/customer/` |

The backend is swapped in by writing one class in the data layer and rebinding one provider. No screen changes.

**Toolchain note (10 Jul 2026):** the installed Flutter is 3.29.0, released February 2025. It should be upgraded deliberately before feature work begins. Android licences are unaccepted and the Xcode simulator runtimes are unavailable; neither blocks development on the web target, but both block shipping to a customer device.

---

## 22. Release History and Roadmap

| Phase | Status | Scope |
|---|---|---|
| **Phase 0 — Interactive Prototype** | Complete | Initial multi-role concept and merchant approval |
| **Phase 1 — Production Data Layer** | Complete | Neon PostgreSQL, Node.js API, and frontend connection |
| **Phase 2 — Authentication and Member Types** | Complete | JWT, multi-identifier login, student and general members |
| **Phase 3 — Offers and POS Discounts** | Complete | Percentage, fixed, double-points, and special-price rules |
| **Phase 4 — Menu Image Management** | Complete | Upload validation, shared image storage, and display |
| **Phase 5 — Merchant Demo Readiness** | Complete | Guides, KPIs, system status, versioning, and deployment hardening |
| **Phase 6 — UI Direction and Design System** | In review | Premium interface direction for customer, POS, and admin experiences |
| **Phase 7 — Full UI and Production Frontend Modernization** | Planned | Screen-by-screen design, production API connection, responsive interfaces, and shared components |
| **Phase 8 — Clickable Prototype and User Testing** | Planned | Stakeholder walkthroughs, staff testing, owner testing, and flow refinement |
| **Phase 9 — Aida Café Operational Launch Upgrade** | Planned | Stabilized production release using redesigned interfaces and formal handover |
| **Phase 10 — Ordering and Engagement Expansion** | Planned | Scheduled ordering, tiers, birthday rewards, richer campaigns, and notifications |
| **Phase 11 — External Integrations** | Future | Camera scan, payment gateway, university verification, external POS, and accounting |
| **Phase 12 — Operations Expansion** | Future | Inventory, kitchen display, multi-branch, and franchise controls |
| **Phase 13 — Café Digitalization Platform** | Future | White-label tenants, configurable loyalty, business onboarding, and AI insights |

### 22.1 Customer App (Flutter) Delivery Track

Added in v2.1. This track runs inside Phase 7 and delivers the customer interface as a native Flutter application rather than a web frontend. It resolves open decision §24.4 #2 in favour of a cross-platform mobile app.

| Stage | Status | Scope |
|---|---|---|
| **C0 — Discovery and Design** | **Complete** (10 Jul 2026) | Scope agreed, architecture chosen, 23 screens enumerated, four PRD amendments raised and accepted. Output: `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md` |
| **C1 — Foundation** | **In progress** | Flutter project scaffold, four-layer structure, typed failure taxonomy, `Money` value type in sen, design-system palette, test harness |
| **C2 — Auth and Membership Card** | Planned | Register, login, password reset, session bootstrap, offline QR card |
| **C3 — Loyalty Core** | Planned | Points, stamps, free drinks, rewards catalogue, redemption, voucher wallet and expiry |
| **C4 — Menu and Offers** | Planned | Menu browsing, item detail, eligible offers, student-offer visibility gating |
| **C5 — History and Account** | Planned | Transaction history, receipts, points ledger, edit profile, change password, delete account |
| **C6 — Backend Integration** | Blocked | Swap the mock repository for the real one. Blocked on the backend stack decision. |
| **C7 — Hardening and Release** | Planned | Native build targets, accessibility pass, cold-start handling, store submission |

The app is developed against a **mock repository implementation** through stages C1–C5. The backend choice blocks only C6; it does not block any screen.

### Phase Gates

| Gate | Required Approval |
|---|---|
| UI direction approval | Business Owner and University Owner |
| Full UI sign-off | Business Owner, Product, and Operations |
| User-testing approval | Owner, selected staff, and project team |
| Production modernization kickoff | Product and Engineering |
| Payment integration | Business registration, bank account, gateway merchant approval, and security review |
| Platform expansion | Separate commercial and technical approval |

---

## 23. Acceptance Criteria

The unified Aida Café release is accepted when the following criteria are met:

### 23.1 Customer

- Customer registration, login, and profile access work correctly.
- Student and general accounts receive the correct offer visibility.
- The membership identifier can be presented and resolved by staff.
- Points, stamps, free drinks, rewards, and transaction history are accurate.
- Customers cannot directly add points, and cannot obtain product without a staff action. *(Amended v2.1: converting one's own points into a voucher is permitted in-app; consuming that voucher is not.)*
- A repeated redemption request with the same request ID deducts points exactly once.
- The membership QR renders correctly with the device offline.
- Menu and promotional content are clearly presented.
- Scheduled ordering is accepted only when that module enters the release scope.

### 23.2 Staff POS

- Staff can identify a member through supported identifiers.
- Active menu items and images are available at the POS.
- Cart quantities, discounts, totals, payments, change, and receipts are correct.
- Offer and reward eligibility is validated before checkout.
- A completed sale updates loyalty balances and reporting exactly once.
- Voucher and free-drink redemption is validated and recorded.
- Sales history, held orders, and today summary operate correctly.
- The tablet interface is usable with large touch targets and clear feedback.

### 23.3 Admin

- KPIs and transaction data reflect the live shared database.
- Members, menu items, images, offers, and active statuses can be managed by authorized users.
- Student verification status is visible and manageable.
- Reports can be filtered and exported.
- JSON backup and restore require authorization and confirmation.
- Guides, SOP, system status, and settings are accessible to the correct role.

### 23.4 Platform and Security

- JWT authentication and role restrictions protect all sensitive API routes.
- Passwords are hashed and secrets are not committed.
- Production and offline-demo states are clearly distinguished.
- The health endpoint exposes operational version and status information.
- No payment-card data is collected or stored by Aida System.
- The application records errors clearly and does not silently fail during checkout or redemption.

### 23.5 Design

- Customer, POS, and admin experiences use one coherent Aida design system.
- The redesigned product reflects the warm premium direction using the Core Palette (§19.3). *(Amended v2.2: pink is no longer a UI colour; City U / student identity uses City Red. Pink remains solely on the logo mark per §19.3.1.)*
- Layouts are optimized for mobile, tablet landscape, and desktop respectively.
- Text, controls, contrast, images, and navigation meet the agreed usability standard.

---

## 24. Assumptions, Dependencies, Risks, and Open Decisions

### 24.1 Assumptions

1. Aida Café @ City U is the sole initial production venue.
2. Prices are displayed in Malaysian Ringgit.
3. Staff have access to a suitable tablet or browser-enabled POS device.
4. Members have access to a smartphone or another supported identifier.
5. Student-specific offers require a verified status.
6. The current backend and data model remain the foundation unless architecture review identifies a necessary change.

### 24.2 Dependencies

- Business and university stakeholder approval of the UI direction.
- Final menu, pricing, product-image, and availability data.
- Approved loyalty rates, voucher values, tier thresholds, and expiry rules.
- Confirmed student verification method.
- Promotion calendar and business rules.
- Production hosting, database, monitoring, and backup decisions.
- Merchant registration and gateway approval before real payments.

### 24.3 Risks and Constraints

| Risk or Constraint | Impact | Required Response |
|---|---|---|
| Render free-tier cold starts | Slow first request after idle | Upgrade hosting before relying on the system for uninterrupted counter operations |
| Offline localStorage mode | Data is browser-specific and not shared | Clearly label it as demonstration fallback, not production continuity |
| Base64 image storage | Database growth and slower transfer | Evaluate object storage during modernization |
| Manual student verification | Administrative effort and possible errors | Define verification workflow and audit status changes |
| Manual payment confirmation | Recorded sale may not match external settlement | Add staff confirmation and reconciliation process |
| Duplicate frontend logic | Loyalty or discount inconsistencies | Centralize calculations in backend services |
| Legacy naming such as `students` for all members | Confusing domain model | Migrate toward neutral member terminology safely |
| Free-tier production services | Reliability limitations | Establish paid production service levels before full launch |
| Backup restore misuse | Potential data overwrite | Restrict access, require confirmation, and maintain recovery copies |
| Personal-data handling | Privacy and compliance exposure | Define consent, retention, access, and deletion policy |

### 24.4 Open Decisions

1. ~~Should the production frontend be one responsive Next.js application or three separately deployed role applications?~~ **Resolved (v2.1):** three separate role applications. The customer app is Flutter; POS and Admin remain to be specified.
2. ~~Should the customer product launch first as a PWA or a native/cross-platform mobile application?~~ **Resolved (v2.1):** cross-platform native via Flutter.
3. Which student verification method will be used for launch?
4. What are the final points, stamps, tier, birthday, and voucher rules?
5. Will scheduled orders be paid at pickup or prepaid through a future gateway?
6. Which payment and external POS providers are commercially preferred?
7. What hosting service level is required for daily café operations?
8. Should product images move to managed object storage during the next release?
9. What privacy policy and data-retention periods will be adopted?
10. Which capabilities belong to Aida Café specifically and which should become configurable for the future white-label platform?

**Raised in v2.1:**

11. **Which stack for the rebuilt backend?** Blocks stage C6 and nothing else. Candidates: Supabase (managed Postgres, auth, storage, row-level security) or Node + Express + Postgres (mirrors the proven data model).
12. **What is the voucher expiry window?** Owner decision. §10.1 has never specified one. Required before C3 ships.
13. **Which email provider sends password resets?** New platform dependency introduced by CUS-18.
14. **Does account deletion anonymise loyalty history or hard-delete it?** Hard deletion corrupts historical sales reporting; anonymisation may not satisfy a PDPA erasure request. Legal input needed.
15. **Does the POS scan the membership QR with a camera, or does staff key in the member code?** POS-20 marks camera scanning as *Future*, which implies manual entry at launch. The customer app generates the same payload either way, so this does not block C2.

**Raised in v2.2:**

16. **Exact Core Palette hex values.** The table in §19.3 is built from a screenshot estimate. The client has agreed to supply final codes; low risk, single-file change once received.
17. **Final logo asset.** No logo file has been supplied. The app currently renders a placeholder everywhere the mark would appear (§19.3.2).

**Raised in v2.4:**

18. **Does Offer Detail need its own screen, or is a bottom sheet enough?** CUS-10/CUS-11 only require an offer to be *visible*; tapping one currently does nothing (§9.1.1). Rewards already consolidated three designed screens into one via bottom sheets — the same pattern may be the right call here too, rather than building a fourth full screen.
19. **What does the Student Verification Pending screen need to say?** §14.2 defines the verification *process* but not what a pending customer sees while waiting — copy and whether it names an expected turnaround time are both undecided.
20. **Is a Splash screen worth building before real Auth exists?** It has nothing to bootstrap (no cached token, no version gate) until Auth (§24.4 #11) is real — building it now risks a screen with a spinner and nothing to spin for.

---

## 25. Operational and Developer Notes

### 25.1 Local Production Baseline

```powershell
cd production/api
npm install
npm run dev
```

Open:

```text
http://localhost:3001
```

### 25.2 Database Setup and Migrations

```powershell
cd production/api
npm run setup-db
npm run migrate-v2
npm run migrate-v3
npm run migrate-v4
npm run migrate-v5
npm run hash-passwords
```

After a database reset or re-seed, the password-hashing and member-linking script must be run before demo authentication is tested.

### 25.3 Production Deployment

The current Render deployment uses Git-based deployment from the main branch. Required environment configuration includes:

- `DATABASE_URL`
- `JWT_SECRET`
- `NODE_ENV=production`

Secrets must never be stored in the repository or this PRD.

### 25.4 Current Project Structure Reference

```text
CityCafePrototype/
├── PRD.md
├── City_Cafe_Rewards_PRD.md
├── index.html
├── js/city-cafe-v2.js
├── DEMO_SCRIPT.md
├── MERCHANT_HANDOVER.md
├── PRODUCTION_CHECKLIST.md
└── production/
    ├── README.md
    ├── DEPLOY.md
    ├── database/
    │   ├── schema.sql
    │   ├── seed.sql
    │   ├── 002_members_upgrade.sql
    │   ├── 003_phase3_offers.sql
    │   ├── 004_link_demo_users.sql
    │   └── 005_menu_images.sql
    └── api/
        ├── src/index.js
        ├── src/version.js
        ├── src/middleware/auth.js
        ├── src/services/
        ├── src/routes/
        └── scripts/
```

The UI Direction Preview is maintained separately as a Next.js project. The modernization plan must define whether it becomes the replacement frontend inside the production repository or remains a separate client repository.

---

## 26. References

| Reference | Location |
|---|---|
| Production application | `https://city-cafe-rewards.onrender.com` |
| UI Direction Preview | `https://momenkhairalla-bit.github.io/aida-system/` |
| UI Direction source repository | `https://github.com/momenkhairalla-BIT/aida-system` |
| Current production frontend | `index.html` and `js/city-cafe-v2.js` |
| Current production backend | `production/api` |
| Current database assets | `production/database` |
| Merchant demonstration guide | `DEMO_SCRIPT.md` and in-app Demo Guide |
| Merchant handover | `MERCHANT_HANDOVER.md` |
| Production checklist | `PRODUCTION_CHECKLIST.md` |
| Customer App design spec | `docs/superpowers/specs/2026-07-10-aida-customer-app-design.md` |
| Customer App source | `apps/customer/` |

---

## 27. Change Log

### v2.1 — 10 July 2026 — Customer App amendment

Four decisions taken during Customer App design supersede v2.0. Each is recorded at the section it changes; they are collected here for review.

| # | Change | Sections affected | Reason |
|---|---|---|---|
| 1 | **The backend is rebuilt, not retained.** | §3.3, §24.4 #11 | The `production/api` source is unavailable to the project team. An unmodifiable backend cannot gain CUS-07, cannot have its cold start fixed, and cannot undergo the `students` → `members` migration. Retention was never actually available. |
| 2 | **Customers may convert their own points into a voucher in-app.** | §6.1, §9.1 CUS-07, §10.1, §23.1 | v2.0 treated "redeem" as one act. It is two. The fraud risk lives only in consuming an entitlement for product, which still requires staff. Matches the Malaysian loyalty apps in §20. |
| 3 | **The membership QR is static, generated once at registration.** | §9.1 CUS-22 | Renders offline, which the counter demands. **Accepted risk:** a screenshot can be shared. Mitigation deferred to the POS, which will display the member's name on scan. |
| 4 | **Four omitted screens added, plus two offline guarantees.** | §9.1 CUS-18 → CUS-23 | Password reset, password change, account deletion, and profile editing were absent. §18 mandates a deletion process that no requirement implemented. CUS-18 introduces an email-sending dependency the platform did not previously have. |

**Decisions resolved:** §24.4 #1 (three role applications) and #2 (Flutter, not PWA).

**Decisions raised:** §24.4 #11 → #15 (backend stack, voucher expiry window, email provider, deletion semantics, QR scan method).

**Unchanged and reaffirmed:** §16.5 — points, stamps, discounts, and eligibility are computed server-side and never recalculated on a client. The Customer App's data layer is forbidden from performing arithmetic on money, points, or stamps.

### v2.2 — 12 July 2026 — Core Palette amendment

The client issued a smaller **Core Palette** (City Red, Cream, Latte, Coffee, Espresso, Reward Gold, Card White) that replaces the v2.1 design-system table.

| # | Change | Sections affected | Reason |
|---|---|---|---|
| 1 | **Pink is retired as a UI colour.** City Red replaces it for City U / student identity. | §19.2, §19.3, §23.5 | Client-issued Core Palette contains no pink. City Red is deliberately kept out of error and destructive-action styling so a promotion never reads as a failure. |
| 2 | **Caramel and both legacy-reference tokens are retired.** | §19.3 | Not part of the Core Palette; nothing in the current build references them. |
| 3 | **The logo mark is not a UI colour source.** | §19.3.1 | The approved logo carries pink/rose florals and gold sparkle absent from the Core Palette. Confirmed intentional: those tones stay inside the mark and are never pulled into surrounding UI. |
| 4 | **Logo asset is pending; the app renders a placeholder.** | §19.3.2, §24.4 #17 | No final logo file has been supplied. A wrong logo shown to the client is worse than an empty, clearly-marked slot. |

**Decisions raised:** §24.4 #16 (exact hex confirmation) and #17 (final logo asset).

**Provisional data notice:** every hex value in the amended §19.3 table except Card White was estimated from a screenshot, not sampled from a source file. Treat them as build-accurate, not final, until the client supplies exact codes.

### v2.3 — 16 July 2026 — Rose Palette amendment

The client redirected the app theme to **red / pink / white**, superseding the v2.2 coffee-toned Core Palette.

| # | Change | Sections affected | Reason |
|---|---|---|---|
| 1 | **Pink returns as the secondary-surface colour.** Background becomes blush white, muted fills become soft pink, primary actions become raspberry red. | §19.2, §19.3 | Client direction, 16 Jul 2026. Reverses the v2.2 "pink is retired" decision for surfaces; City Red remains reserved for student / City U identity and is kept visually distinct from the new action red. |
| 2 | **Token names are unchanged; only values changed.** Cream, Latte, Coffee, Espresso keep their identifiers in code. | §19.3 | Every screen references the role, not the hue; renaming identifiers across the codebase adds churn with no product value. |
| 3 | **Reward Gold, Card White, Error, and Success carry over unchanged.** | §19.3 | These are functional signals (loyalty, surface, failure, success), not theme colours. |

**Provisional data notice:** the v2.3 values were chosen by the development team to demonstrate the direction, not sampled from a client asset. §24.4 #16 (exact hex confirmation) remains open.

### v2.4 — 17 July 2026 — Customer App build-status tracking

An audit of the Flutter Customer App against the 23-screen design spec (§9.1.1, new) found most core screens built, several still outstanding, and real ordering added beyond the original scope at client request.

| # | Change | Sections affected | Reason |
|---|---|---|---|
| 1 | **Real in-app ordering was added: cart, checkout, and order tracking.** | §9.1.1, §24.4 | Requested three separate times across different screens during Customer App review. Not the deferred CUS-14 (scheduled order-ahead) — this is immediate, session-based ordering with a demo checkout, no payment gateway, no backend order queue. |
| 2 | **§9.1.1 added: a per-screen build-status record against the original 23-screen list.** | §9.1 | The PRD tracked *requirements*; nothing recorded which designed *screens* actually exist yet, and an audit found real gaps (Offer detail is not tappable at all) that had gone unnoticed. |
| 3 | **Three new open decisions raised (§24.4 #18–20).** | §24.4 | Offer Detail's screen-vs-sheet question, Student Verification Pending's copy, and whether Splash is worth building before Auth is real — none blocked prior work, all block the screens they touch. |

**Decisions raised:** §24.4 #18 → #20 (Offer Detail pattern, verification-pending copy, Splash timing).

**Not a decision, but worth a reader's attention:** two Profile rows (My Stats, Invite a Friend) exist in the build with no corresponding requirement anywhere in this PRD. §9.1.1 flags them; whether to formalize or remove them is unresolved.

---

## Document Governance

This unified PRD is the product-scope source of truth. Technical deployment procedures, credentials, test data, detailed API schemas, database migrations, design files, and merchant SOPs should remain in their dedicated controlled documents.

Any future product change should update:

1. The relevant requirement and status in this PRD.
2. The roadmap phase and acceptance criteria.
3. The design and technical specifications affected by the change.
4. The production handover and operating procedures where applicable.

---

*End of Aida System Unified Product Requirements Document — Version 2.2*
