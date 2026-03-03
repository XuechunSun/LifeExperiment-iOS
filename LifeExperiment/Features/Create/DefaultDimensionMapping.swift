import Foundation

enum DefaultDimensionMapping {
    static func suggestedImpact(from subcategory: SeedSubcategory?) -> ExperimentImpact? {
        guard let subcategory else { return nil }
        return impactFromDefaultDimensions(subcategory.default_dimensions)
    }
    
    // Conservative fallback for seed-category + custom-subcategory only.
    // Other category intentionally has no fallback.
    // Seed custom-subcategory fallback:
        // life_reset → self_understanding
        // life_list → expression_creativity
        // challenge_30 → execution
        // well_being → body_energy
        // emotional_care → emotion_awareness
        // (Other has no fallback)
    static func fallbackImpactForSeedCustomSubcategory(seedCategoryId: String) -> ExperimentImpact? {
        let primary: Dimension?
        switch seedCategoryId {
        case "life_reset":
            primary = .self_understanding
        case "life_list":
            primary = .expression_creativity
        case "challenge_30":
            primary = .execution
        case "well_being":
            primary = .body_energy
        case "emotional_care":
            primary = .emotion_awareness
        default:
            primary = nil
        }

        guard let primary else { return nil }
        return ExperimentImpact(primary: primary, secondary: nil, tertiary: nil)
    }
}
