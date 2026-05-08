import Foundation

struct ExperimentSuggestion: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let prefillCategoryTitle: String
    let prefillSubcategoryTitle: String
    let impact: ExperimentImpact?
    let effort: SuggestionEffort
    let mode: SuggestionMode
    let tags: [String]

    /// Lang-aware subtitle for suggestion cards. Uses `L.dimensionDisplayTitle` for
    /// dimension labels; falls back to the (English-only) `category` field unchanged.
    func impactDisplayText(lang: AppLanguage) -> String {
        guard let impact else { return category }

        var labels = [L.dimensionDisplayTitle(lang, dimension: impact.primary)]
        if let secondary = impact.secondary, secondary != impact.primary {
            labels.append(L.dimensionDisplayTitle(lang, dimension: secondary))
        }
        return labels.joined(separator: " · ")
    }
}

enum SuggestionEffort: String, Codable {
    case low
    case medium
    case high
}

enum SuggestionMode: String, Codable {
    case starter
    case reflective
    case social
    case reset
}