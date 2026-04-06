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

    var impactDisplayText: String {
        guard let impact else { return category }

        var labels = [impact.primary.title]
        if let secondary = impact.secondary, secondary != impact.primary {
            labels.append(secondary.title)
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