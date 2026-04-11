# LifeExperiment MVP App Store Shipping Plan

This plan covers everything standing between the current codebase and a publishable v1.0 on the iOS App Store. Items are grouped into three tiers: **P0 (App Store blockers)**, **P1 (data safety and core UX)**, and **P2 (polish and nice-to-have)**.

All todos are held for now — the owner still needs to make additional changes (language selection, app name, etc.) before starting on this list.

---

## P0 — App Store Submission Blockers

These must be resolved or the app will be rejected by App Review.

### 1. App Icon

The asset catalog at `LifeExperiment/Assets.xcassets/AppIcon.appiconset/` has a `Contents.json` scaffold but **no actual image files**. App Store Connect requires a 1024x1024 icon.

- [ ] Design and add a 1024x1024 PNG to the AppIcon set
- [ ] Verify it renders correctly at small sizes (29pt, 40pt, 60pt)
- [ ] Fill in dark and tinted appearance variants (optional but recommended)

### 2. Deployment Target

The project currently targets **iOS 26.2** (Xcode 26 beta). This is unreleased and no real users can install the app.

- [ ] Lower `IPHONEOS_DEPLOYMENT_TARGET` to a shipping OS (e.g. **iOS 17.0** or **iOS 18.0**)
- [ ] Audit any iOS 26-only API usage and add `@available` guards or fallbacks
- [ ] This change lives in both Debug and Release configs inside `project.pbxproj`

### 3. Bundle Identifier

Currently set to `com.yourname-com.XSun.LifeExperiment` — this looks like a template placeholder.

- [ ] Register a proper bundle ID in Apple Developer portal (e.g. `com.xuechunsun.LifeExperiment`)
- [ ] Update `PRODUCT_BUNDLE_IDENTIFIER` in both Debug and Release build configs

### 4. Privacy Manifest (PrivacyInfo.xcprivacy)

Apple requires a privacy manifest since Spring 2024. The app has **none**.

- [ ] Create `PrivacyInfo.xcprivacy` declaring:
  - **NSPrivacyAccessedAPITypes**: `UserDefaults` (reason: app functionality)
  - **NSPrivacyCollectedDataTypes**: empty (no data collection)
  - **NSPrivacyTracking**: false
- [ ] Place it in the `LifeExperiment/` folder (auto-synced by the filesystem group)

### 5. Photo Library Usage Description

`ExperimentDetailView` imports **PhotosUI** and uses `PhotosPicker`, but no usage description is declared in build settings.

- [ ] Add `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` to both Debug and Release configs in `project.pbxproj`
- [ ] Suggested copy: *"LifeExperiment uses your photos to attach images to daily logs."*

### 6. Privacy Policy

App Store Connect requires a privacy policy URL for all apps.

- [ ] Write a simple privacy policy (the app is local-only, no data collection)
- [ ] Host it on a public URL (GitHub Pages, Notion, or a simple website)
- [ ] Enter the URL in App Store Connect metadata

### 7. App Store Connect Metadata

- [ ] App name, subtitle, description, keywords
- [ ] At least 3 screenshots per device class (6.7" iPhone required, 6.5" optional, iPad optional)
- [ ] Category selection (likely "Lifestyle" or "Health & Fitness")
- [ ] Age rating questionnaire
- [ ] Support URL and marketing URL

---

## P1 — Data Safety and Core UX

These are not App Store blockers but represent **real user-facing risks** that should be addressed before shipping.

### 8. Migrate Persistence Off UserDefaults

All experiment data (`[Experiment]` with nested `[DailyLog]`) is stored as a single JSON blob in `@AppStorage`. UserDefaults is not designed for large structured data and can cause:

- Performance degradation as data grows
- Silent data loss if the blob exceeds practical limits (~1-4 MB)
- No transactional safety

**Recommended approach:**

- [ ] Move `experimentsData` and `historyData` to **file-based JSON** in the app's Documents directory (simplest migration)
- [ ] Or adopt **SwiftData** if targeting iOS 17+
- [ ] Keep `@AppStorage` only for small preferences (UI style, toggles)
- [ ] The persistence helpers are in `ContentView.swift` lines 72-90 (`getExperiments`, `setExperiments`, `getHistory`, `setHistory`)

### 9. Data Model Versioning

Currently, if the `Experiment` or `DailyLog` model changes incompatibly, `JSONDecoder` fails silently and the app returns empty arrays — **all user data disappears**.

- [ ] Add a `schemaVersion` integer to UserDefaults/file header
- [ ] On decode failure, attempt recovery: keep the raw Data, log the error, show user-facing alert
- [ ] The custom `init(from:)` decoders in `ExperimentModels.swift` help with additive changes but not removals or type changes

### 10. Data Export / Backup

The app explicitly tells users *"Your data is currently stored on this device"* (`ProfileView.swift`) but provides **no way to back up or export**.

- [ ] Add an "Export My Data" action in Profile that produces a shareable JSON file via `UIActivityViewController`
- [ ] This is a trust signal for users and an App Review positive

### 11. Onboarding Flow

There is no onboarding. New users land on the Home tab with a seeded "My First Experiment" and guide cards but no explanation of the app's purpose or how to use it.

- [ ] Add a lightweight 2-3 screen onboarding shown on first launch
- [ ] Track with a `hasSeenOnboarding` flag in `@AppStorage`
- [ ] Cover: what Life Experiment is, how experiments work, how to log

### 12. Loading and Error States

- [ ] **No `ProgressView`** anywhere in the app. Photo saving/loading in `ExperimentDetailView` should show a spinner.
- [ ] **JSON decode failures** in `ContentView`, `SubcategorySavedStore`, and `CustomImpactMappingStore` are silent. Add a fallback error banner or alert.
- [ ] **Bundle JSON loaders** (`ExperimentSuggestionsLoader`, `CTALoader`) `print` errors to console — fine for MVP but consider a debug log.

### 13. Accessibility Baseline

The app has almost zero accessibility coverage:

- Only 1 `accessibilityLabel` in the entire codebase (photo button in `ExperimentDetailView`)
- No `accessibilityHint` or `accessibilityValue` anywhere
- No Dynamic Type testing or tuning

**Minimum for MVP:**

- [ ] Add `accessibilityLabel` to all icon-only buttons and interactive controls
- [ ] Add `accessibilityLabel` to the mood selector emoji buttons
- [ ] Test with VoiceOver once and fix any unusable flows
- [ ] Ensure custom font sizes respect Dynamic Type (the `relativeTo:` parameter in `DSFont` helps, but verify)

---

## P2 — Polish and Nice-to-Have

These improve quality but are not blocking for a v1.0 ship.

### 14. Localization Cleanup

The app uses a custom `enum S` with inline English/Chinese ternaries (`Strings.swift`), but **many strings are hardcoded in views** (alerts, guide copy, section titles, empty states).

- [ ] Audit all hardcoded English strings and move them into `S`
- [ ] Consider migrating to a proper `.xcstrings` String Catalog for future localization
- [ ] Low priority for v1.0 if shipping English-only

### 15. Analytics and Crash Reporting

No analytics or crash reporting exists. For a shipped app:

- [ ] Add a lightweight crash reporter (e.g. Firebase Crashlytics, Sentry, or Apple's built-in crash logs via Xcode Organizer)
- [ ] Optional: add minimal anonymous analytics to understand feature usage
- [ ] Respect user privacy — the app's "no data collection" stance is a strength

### 16. Unit / UI Tests

There are **zero tests** in the project. For MVP:

- [ ] Add unit tests for critical logic: `RecentEventBuilder`, `PersonalizedSuggestionEngine`, persistence encode/decode round-trips
- [ ] Add at least one UI test that verifies the app launches and basic navigation works

### 17. iPad Adaptive Layout

The app targets iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) but has no adaptive layout (`NavigationSplitView`, size classes).

- [ ] **Option A:** Add a basic `NavigationSplitView` for iPad
- [ ] **Option B:** Restrict to iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) for v1.0 and add iPad later
- [ ] Option B is simpler and avoids a bad iPad experience at launch

### 18. Dark Mode Audit

Dark mode works implicitly via semantic system colors, but:

- [ ] The `HighlightCard` gradient (`highlightCardStart`, `highlightCardEnd` in `SectionBlock.swift`) uses hardcoded RGB that may look off in dark mode
- [ ] Custom colors like `primaryLavenderButton` should be verified in dark mode
- [ ] No dark-mode-specific color assets exist in the asset catalog

### 19. Keyboard UX

`@FocusState` is used in 3 views but there is no app-wide keyboard dismissal policy.

- [ ] Add `.scrollDismissesKeyboard(.interactively)` to scrollable views with text fields
- [ ] Consider a toolbar "Done" button on text editors

### 20. Remove DEBUG-Only Features Before Release

`ProfileView` has a `#if DEBUG` section with "Reset All Data" and "Simulate signed in/out" — verify these are properly gated and won't appear in Release builds.

- [ ] Confirm `#if DEBUG` gates are correct in `ProfileView.swift`

### 21. Remove Placeholder / "Coming Soon" Copy

Several UI elements reference unbuilt features:

- [ ] "Cloud sync — Coming soon" in Profile
- [ ] "Sign in with Apple — Coming soon" in AuthOptionsSheet
- [ ] Consider removing these entirely for v1.0 to avoid user confusion, or keep them clearly disabled

---

## Suggested Ship Order

```
P0 (App Store Blockers)         P1 (Data Safety)              P2 (Polish)
──────────────────────────      ──────────────────────────     ──────────────────────
1. App Icon                     8.  Migrate Persistence        14. Localization Cleanup
2. Deployment Target            9.  Model Versioning           15. Analytics
3. Bundle ID                    10. Data Export                 16. Tests
4. Privacy Manifest             11. Onboarding                 17. iPad Decision
5. Photo Usage Desc             12. Loading/Error States        18. Dark Mode Audit
6. Privacy Policy               13. Accessibility Baseline      19. Keyboard UX
7. ASC Metadata                                                20. Remove Debug Gates
                                                               21. Remove Coming Soon
```

**Estimated effort:**

- P0 (blockers): 2-3 days
- P1 (data safety + core UX): 4-6 days
- P2 (polish): 3-5 days spread over time

---

## Current Status

All items are **on hold**. Pending owner changes:

- Language selection feature
- App name finalization
- Other feature-level changes

Once those are done, start with P0 top-to-bottom, then P1, then P2.
