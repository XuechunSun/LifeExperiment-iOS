//
//  OnboardingState.swift
//  LifeExperiment
//
//  Phase 1 of MiniLab v1.1 onboarding — persisted launch-time state only.
//  No UI is added in this phase.
//
//  Persistence model
//  -----------------
//  Two UserDefaults keys back this state:
//    - "onboarding.stage"             — raw value of `OnboardingStage`
//    - "onboarding.guidedExperimentId" — UUID string of the experiment the user
//      creates during the first-run guided flow, used by the first-log callout
//      to anchor itself to that specific experiment.
//
//  Writers
//  -------
//  The first-run flow (added in later phases) is the ONLY writer of these keys.
//  The Profile replay flow MUST NOT mutate either key.
//

import Foundation

/// Onboarding lifecycle stages for the v1.1 first-run flow.
enum OnboardingStage: String, Codable {
    /// Never opened intro. Default for fresh installs.
    case notStarted
    /// User dismissed intro pages but has not yet committed a guided starter.
    case introSeen
    /// User created their first guided experiment, awaiting the first log.
    case experimentCreated
    /// Onboarding is finished (skipped, migrated existing user, or first log saved).
    case completed
}

/// Static accessors and one-shot launch evaluation for onboarding state.
///
/// All access goes through `UserDefaults.standard` so the state can be read or
/// written outside SwiftUI (`@AppStorage` would only work inside views).
enum OnboardingState {

    // MARK: - Persisted keys

    static let stageKey = "onboarding.stage"
    static let guidedExperimentIdKey = "onboarding.guidedExperimentId"
    // Phase 8.1 Part A: queue for the one-time read-only v1.1 guide shown to
    // users we silently migrated from v1.0 (i.e. `stage == .notStarted` AND
    // existing-user signals detected on launch). True ⇒ "show the guide once
    // on next root onAppear." The host clears it to false when the sheet is
    // dismissed. Independent from `stage` so the read-only guide never has to
    // mutate onboarding state.
    static let migratedUserGuidePendingKey = "onboarding.migratedUserGuidePending"

    // MARK: - Accessors

    /// Current onboarding stage. Defaults to `.notStarted` when unset or unknown.
    static var stage: OnboardingStage {
        get {
            let raw = UserDefaults.standard.string(forKey: stageKey)
                ?? OnboardingStage.notStarted.rawValue
            return OnboardingStage(rawValue: raw) ?? .notStarted
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: stageKey)
        }
    }

    /// UUID string of the experiment created during onboarding. Empty when none.
    static var guidedExperimentId: String {
        get {
            UserDefaults.standard.string(forKey: guidedExperimentIdKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: guidedExperimentIdKey)
        }
    }

    /// True when `evaluateOnLaunch` has classified this user as a migrated v1.0
    /// user AND the read-only v1.1 guide has not yet been shown / dismissed.
    /// Default `false` ⇒ fresh installs never show the migrated-user guide.
    /// Only the host (ContentView) flips this to `false` after the sheet is
    /// dismissed. Only `evaluateOnLaunch` ever sets this to `true`.
    static var migratedUserGuidePending: Bool {
        get { UserDefaults.standard.bool(forKey: migratedUserGuidePendingKey) }
        set { UserDefaults.standard.set(newValue, forKey: migratedUserGuidePendingKey) }
    }

    // MARK: - Launch evaluation

    /// One-shot launch evaluation. Idempotent — safe to call every time the
    /// root view appears.
    ///
    /// Behavior:
    ///   1. If `stage == .notStarted` AND a *data-bearing* migrated-user
    ///      signal is present, silently mark stage `.completed` so v1.0
    ///      upgraders are never forced into onboarding, and queue the
    ///      one-time read-only guide. Preference-only signals (language,
    ///      photo-logging toggle, dev-tools unlock) do NOT qualify — see
    ///      `hasMigratedUsageSignal` below.
    ///   2. If `stage == .experimentCreated` but the referenced experiment no
    ///      longer exists (e.g. user deleted it before logging), reset stage to
    ///      `.completed` and clear `guidedExperimentId` so the first-log
    ///      callout cannot get stuck.
    ///   3. Otherwise: no-op.
    static func evaluateOnLaunch(loadExperiments: () -> [Experiment]) {
        switch stage {
        case .notStarted:
            if hasMigratedUsageSignal(loadExperiments: loadExperiments) {
                stage = .completed
                // Phase 8.1 Part A: this is the only code path that classifies
                // a user as migrated. We queue the read-only guide here and
                // nowhere else, so fresh installs (no usage data) can never
                // accidentally trigger it — including users who only switched
                // language before completing onboarding (Phase 8.1.1 fix).
                // The flag is fire-and-forget — the host (ContentView) clears
                // it when the sheet is dismissed.
                migratedUserGuidePending = true
            }
        case .experimentCreated:
            let id = guidedExperimentId
            if !id.isEmpty,
               !loadExperiments().contains(where: { $0.id.uuidString == id }) {
                stage = .completed
                guidedExperimentId = ""
            }
        case .introSeen, .completed:
            break
        }
    }

    // MARK: - Migrated-user signal detection

    /// Returns `true` only when this user has *data-bearing* evidence of prior
    /// app usage — i.e. something a v1.0 user would have created intentionally,
    /// not a side effect of toggling a preference.
    ///
    /// Phase 8.1.1 tightening
    /// ----------------------
    /// Earlier Phase 0/8.1 logic also treated preference-only keys (`app_language`,
    /// `profile_developer_tools_unlocked`, `pref.imageLoggingEnabled`) as
    /// existing-user signals. That misclassified fresh v1.1 users who simply
    /// switched language before completing onboarding — they would be silently
    /// promoted to `.completed` AND see the migrated-user guide on relaunch.
    /// We now require an actual usage artifact. A v1.0 user with zero usage
    /// data who only flipped a preference will fall through and see first-run
    /// onboarding — an acceptable, contained regression.
    ///
    /// Strong signals (any one is sufficient):
    ///   1. `experimentsData` decodes to at least one experiment
    ///   2. `lowEnergyLogsData` decodes to a non-empty array
    ///   3. `historyData` decodes to a non-empty array (legacy day-counter)
    ///   4. `customSubcategoriesByCategoryData` decodes to a non-empty dict
    ///   5. `customImpactByCategorySubcategoryData` decodes to a non-empty dict
    ///
    /// Intentionally NOT signals anymore:
    ///   • `app_language`                       (preference-only)
    ///   • `profile_developer_tools_unlocked`   (preference-only)
    ///   • `pref.imageLoggingEnabled`           (preference-only)
    private static func hasMigratedUsageSignal(
        loadExperiments: () -> [Experiment]
    ) -> Bool {
        if !loadExperiments().isEmpty {
            return true
        }

        if hasNonEmptyEncodedArray(forKey: "lowEnergyLogsData", as: [LowEnergyLog].self) {
            return true
        }

        if hasNonEmptyEncodedArray(forKey: "historyData", as: [DayRecord].self) {
            return true
        }

        if hasNonEmptyEncodedDictionary(forKey: "customSubcategoriesByCategoryData", as: [String: [String]].self) {
            return true
        }

        if hasNonEmptyEncodedDictionary(forKey: "customImpactByCategorySubcategoryData", as: [String: ExperimentImpact].self) {
            return true
        }

        return false
    }

    // MARK: - Decode helpers

    private static func hasNonEmptyEncodedArray<Element: Decodable>(
        forKey key: String,
        as type: [Element].Type
    ) -> Bool {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            !data.isEmpty,
            let decoded = try? JSONDecoder().decode([Element].self, from: data)
        else { return false }
        return !decoded.isEmpty
    }

    private static func hasNonEmptyEncodedDictionary<Value: Decodable>(
        forKey key: String,
        as type: [String: Value].Type
    ) -> Bool {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            !data.isEmpty,
            let decoded = try? JSONDecoder().decode([String: Value].self, from: data)
        else { return false }
        return !decoded.isEmpty
    }
}
