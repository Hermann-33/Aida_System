# Apple App Store Readiness Guardrails

**Applies to:** AIDA customer iOS application and backend behavior exposed by it.  
**Reviewed:** 2026-09-18  
**Current implementation verdict:** Phases 1–9 engineering `COMPLETE`; Phase 10 App Store release gate is `PARTIAL`.

## Current Apple requirements re-checked on 2026-09-18

Official Apple submission guidance was re-checked at Phase 10 start. For uploads in 2026, iOS/iPadOS apps must be built with the iOS/iPadOS 26 SDK or later. App Store Connect requires accurate app privacy disclosures and an iOS privacy-policy URL. Apps supporting account creation must provide an in-app whole-account deletion path. Submission requires the required metadata and a selected build; screenshots require at least one and permit up to ten per supported device presentation. Accessibility support can now be declared in App Store Connect.

AIDA sells physical café food/drink. These purchases remain outside StoreKit/IAP. Payment/refund state remains server-authoritative and no external payment processor is activated.

## Phase 10 implementation completed so far

- dedicated matching Phase 10 branches were created from the exact validated Phase 9 heads in both repositories;
- the customer release workflow now includes the Phase 10 branch and a macOS unsigned iOS release-build gate;
- the iOS release gate requires an application `PrivacyInfo.xcprivacy` file;
- an application privacy manifest was added declaring no application-level tracking and no application-declared required-reason API categories. Third-party SDK manifests remain part of the archive-level privacy report and must be verified before submission;
- existing `Info.plist` currently declares no camera, location, contacts, microphone, photo-library or tracking permission purpose strings, matching the current customer dependency/feature surface inspected at Phase 10 start.

## Privacy and account deletion

Whole-account deletion is caller-bound to `auth.uid()`, accepts no target user ID, removes customer-owned identity/state and anonymizes legitimately retained commercial history. Retained customer-authored free text and the original customer request digest are scrubbed. Marketing preference defaults off.

Before submission, App Store Connect privacy answers must be reconciled against the final archive privacy report and actual Supabase/customer data flows. Do not claim "Data Not Collected" merely because the application-level privacy manifest contains an empty collected-data array: App Store privacy disclosures cover server and third-party collection as well.

## Remaining release blockers / owner-controlled actions

Phase 10 cannot truthfully claim App Store submission readiness until all of the following have evidence:

- exact-head customer static/test/golden/Android release gates and the new unsigned iOS release build are green;
- final iOS archive is produced with the current required Apple SDK/Xcode toolchain and its aggregate privacy report is reviewed;
- signing team, production bundle identifier, distribution certificate/profile and App Store Connect app record are confirmed;
- production Privacy Policy URL and Support URL are live; Terms URL/content is verified where presented by the app;
- App Store Connect privacy answers match actual app/backend/SDK data handling;
- review credentials or a deterministic review/demo path and review notes are prepared;
- final screenshots and metadata match the submitted binary;
- accessibility declarations are made only for features actually tested;
- production backend configuration, account deletion and physical-goods payment behavior receive final release verification.

Provider-specific activation, merchant onboarding, credentials/webhook secrets, cost-bearing services and legal/business decisions remain explicit owner-approval boundaries.

The cumulative independent/Astra/Codex audit is deferred until Phase 10 implementation and normal validation are complete. It is not waived.

Phase completion does not authorize PR merge or App Store submission.
