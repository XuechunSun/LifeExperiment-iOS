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

    // MARK: - Launch evaluation

    /// One-shot launch evaluation. Idempotent — safe to call every time the
    /// root view appears.
    ///
    /// Behavior:
    ///   1. If `stage == .notStarted` AND any existing-user signal is present,
    ///      silently mark stage `.completed` so v1.0 upgraders are never forced
    ///      into onboarding.
    ///   2. If `stage == .experimentCreated` but the referenced experiment no
    ///      longer exists (e.g. user deleted it before logging), reset stage to
    ///      `.completed` and clear `guidedExperimentId` so the first-log
    ///      callout cannot get stuck.
    ///   3. Otherwise: no-op.
    static func evaluateOnLaunch(loadExperiments: () -> [Experiment]) {
        switch stage {
        case .notStarted:
            if hasAnyExistingUserSignal(loadExperiments: loadExperiments) {
                stage = .completed
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

    // MARK: - Existing-user signal detection

    /// Returns `true` when any sign of prior app usage is detected. Generous on
    /// purpose: we'd rather skip onboarding for an edge-case existing user than
    /// show it twice.
    ///
    /// The eight signals match the Phase 0 verification:
    ///   1. `experimentsData` decodes to at least one experiment
    ///   2. `lowEnergyLogsData` decodes to a non-empty array
    ///   3. `historyData` decodes to a non-empty array (legacy day-counter)
    ///   4. `customSubcategoriesByCategoryData` decodes to a non-empty dict
    ///   5. `customImpactByCategorySubcategoryData` decodes to a non-empty dict
    ///   6. `app_language` is written to a non-empty string
    ///   7. `profile_developer_tools_unlocked == true`
    ///   8. `pref.imageLoggingEnabled` key has been written (any value)
    private static func hasAnyExistingUserSignal(
        loadExperiments: () -> [Experiment]
    ) -> Bool {
        let defaults = UserDefaults.standard

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

        if let language = defaults.string(forKey: "app_language"), !language.isEmpty {
            return true
        }

        if defaults.bool(forKey: "profile_developer_tools_unlocked") {
            return true
        }

        if defaults.object(forKey: "pref.imageLoggingEnabled") != nil {
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
