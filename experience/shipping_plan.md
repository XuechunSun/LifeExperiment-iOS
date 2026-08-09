# MiniLab App Store Shipping Plan

## Current Status

**v1.1 is live on the App Store** (build 3). Local codebase is on build 4, preparing for the next release.

All P0 App Store blockers have been resolved. The app ships as **MiniLab** (`com.xuechunsun.minilab`), targets iOS 17.0, and is iPhone-only.

---

## What Was Shipped in v1.1

- Full onboarding flow (intro pages, starter experiment selection, guided first-log banner)
- Home view hierarchy polish and onboarding entry flow
- MiniLab Guide integrated into Profile
- Final bilingual (EN/ZH) copy and localization pass
- Logging experience polish (mood, notes, history UI)
- Completed experiment empty state + refreshable create prompts
- Low energy flow ("Gentle Day" mode)

---

## Resolved (P0 — App Store Blockers)

| Item | Status |
|------|--------|
| App Icon | ✅ `MiniLab Icon.png` in AppIcon asset set |
| Deployment Target | ✅ iOS 17.0 |
| Bundle Identifier | ✅ `com.xuechunsun.minilab` |
| Privacy Manifest | ✅ `PrivacyInfo.xcprivacy` (UserDefaults declared, no tracking) |
| Photo Library Usage Description | ✅ Set in both Debug and Release build configs |
| iPad restriction | ✅ `TARGETED_DEVICE_FAMILY = 1` (iPhone only) |
| Privacy Policy | ✅ (hosted externally) |
| App Store Connect Metadata | ✅ Submitted with v1.1 |

---

## Remaining Work

### P1 — Data Safety (not blocking, but important before scale)

#### 1. Migrate Persistence Off UserDefaults

All experiment data (`[Experiment]` with nested `[DailyLog]`) is stored as a single JSON blob in `@AppStorage`. UserDefaults is not designed for large structured data.

- [ ] Move `experimentsData` and `historyData` to file-based JSON in the app's Documents directory, or adopt **SwiftData** (iOS 17+)
- [ ] Keep `@AppStorage` only for small preferences (language, toggles)
- [ ] Persistence helpers live in `ContentView.swift` lines 72–90

#### 2. Data Model Versioning

If `Experiment` or `DailyLog` models change incompatibly, `JSONDecoder` fails silently and returns empty arrays — user data disappears.

- [ ] Add a `schemaVersion` integer to the storage header
- [ ] On decode failure: keep raw Data, log error, show user-facing alert

#### 3. Data Export / Backup

The app tells users data is on-device but provides no way to back it up.

- [ ] Add "Export My Data" action in Profile via `UIActivityViewController` (shareable JSON)

#### 4. Accessibility Baseline

Almost no accessibility coverage currently.

- [ ] Add `accessibilityLabel` to all icon-only buttons and interactive controls
- [ ] Add `accessibilityLabel` to mood selector emoji buttons
- [ ] Test once with VoiceOver and fix any unusable flows

#### 5. Loading and Error States

- [ ] Photo saving/loading in `ExperimentDetailView` has no spinner
- [ ] JSON decode failures in `ContentView`, `SubcategorySavedStore`, and `CustomImpactMappingStore` are silent

---

### P2 — Polish (post-v1.x)

#### 6. Localization Cleanup

Many strings are still hardcoded in views (alerts, guide copy, section titles).

- [ ] Audit all hardcoded EN/ZH strings and move into `Strings.swift` (`enum S`)
- [ ] Consider migrating to `.xcstrings` String Catalog for a future full localization pass

#### 7. Analytics and Crash Reporting

- [ ] Add lightweight crash reporter (Firebase Crashlytics, Sentry, or Xcode Organizer logs)
- [ ] Optional: minimal anonymous analytics — respect the "no data collection" positioning

#### 8. Unit Tests

Zero tests exist currently.

- [ ] Unit tests for: `RecentEventBuilder`, `PersonalizedSuggestionEngine`, persistence encode/decode round-trips

#### 9. Dark Mode Audit

- [ ] `HighlightCard` gradient in `SectionBlock.swift` uses hardcoded RGB — verify in dark mode
- [ ] Verify `primaryLavenderButton` and custom colors in dark mode

---

## Next Up

UI redesign pass using Figma MCP — updating page layouts to match new designs.

---

*Last updated: 2026-08-09*
