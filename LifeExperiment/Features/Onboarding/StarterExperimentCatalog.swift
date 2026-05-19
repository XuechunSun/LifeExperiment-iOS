//
//  StarterExperimentCatalog.swift
//  LifeExperiment
//
//  Phase 2 of MiniLab v1.1 onboarding — defines the three low-pressure starter
//  experiments offered during first-run onboarding, with explicit seed taxonomy
//  mapping and an explicit `ExperimentImpact` primary dimension.
//
//  Why English source-of-truth titles
//  ----------------------------------
//  `englishTitle` is also a key in `BuiltInTitleDisplay.englishToChinese`. When
//  the user does not edit the prefilled title inside the editor,
//  ExperimentEditorView persists the English source on disk (see
//  `prefillSourceTitle` handling) so future displays still localize correctly
//  through `BuiltInTitleDisplay.localizedTitle(stored:lang:)`.
//

import Foundation

/// One of three starter experiments offered during first-run onboarding.
enum StarterExperiment: String, CaseIterable, Identifiable {
    case pause
    case name
    case clearOne

    var id: String { rawValue }

    /// English source-of-truth title. Must stay in lockstep with the matching
    /// key in `BuiltInTitleDisplay.englishToChinese`.
    var englishTitle: String {
        switch self {
        case .pause: return "Take a 5-minute pause"
        case .name: return "Name what I'm feeling today"
        case .clearOne: return "Clear one small task"
        }
    }

    /// SF Symbol used for the starter card icon.
    var iconSystemName: String {
        switch self {
        case .pause: return "leaf"
        case .name: return "heart"
        case .clearOne: return "checkmark.circle"
        }
    }

    /// Seed catalog category id (matches `experiment_seed.json`).
    var seedCategoryId: String {
        switch self {
        case .pause: return "well_being"
        case .name: return "emotional_care"
        case .clearOne: return "life_reset"
        }
    }

    /// Seed catalog subcategory id (matches `experiment_seed.json`).
    var seedSubcategoryId: String {
        switch self {
        case .pause: return "sleep_rest"
        case .name: return "emotional_awareness"
        case .clearOne: return "daily_structure"
        }
    }

    /// Primary dimension passed explicitly via `ExperimentImpact` so dimensions
    /// are deterministically prefilled — we do NOT rely on
    /// `ExperimentEditorView` inferring dimensions from seed `default_dimensions`.
    var primaryDimension: Dimension {
        switch self {
        case .pause: return .body_energy
        case .name: return .emotion_awareness
        case .clearOne: return .execution
        }
    }

    func localizedTitle(_ lang: AppLanguage) -> String {
        switch self {
        case .pause: return L.onboardingStarterPauseTitle(lang)
        case .name: return L.onboardingStarterNameTitle(lang)
        case .clearOne: return L.onboardingStarterClearTitle(lang)
        }
    }

    func localizedSubtitle(_ lang: AppLanguage) -> String {
        switch self {
        case .pause: return L.onboardingStarterPauseSubtitle(lang)
        case .name: return L.onboardingStarterNameSubtitle(lang)
        case .clearOne: return L.onboardingStarterClearSubtitle(lang)
        }
    }
}

/// Builds the `ExperimentEditorPrefill` payload that opens the existing Create
/// sheet pre-filled for a chosen starter.
enum StarterExperimentCatalog {
    /// Resolves the chosen starter into an `ExperimentEditorPrefill`. Category
    /// and subcategory *titles* are looked up from the loaded seed catalog so
    /// `ExperimentEditorView.applyCreatePrefillIfNeeded()` can match them by
    /// title (its existing behavior). When the catalog cannot be loaded — e.g.
    /// the JSON is missing in a degraded build — we still return a usable
    /// title + explicit impact prefill rather than crashing.
    static func prefill(for starter: StarterExperiment, lang: AppLanguage) -> ExperimentEditorPrefill {
        let catalog = SeedCatalogLoader.load()
        let category = catalog?.categories.first(where: { $0.id == starter.seedCategoryId })
        let subcategory = category?.subcategories.first(where: { $0.id == starter.seedSubcategoryId })

        return ExperimentEditorPrefill(
            title: starter.englishTitle,
            categoryTitle: category?.title,
            subcategoryTitle: subcategory?.title,
            impact: ExperimentImpact(primary: starter.primaryDimension)
        )
    }
}
