import Foundation

struct ExperimentSuggestion: Identifiable, Codable {
    let id: String
    let title: String
    let category: String
    let prefillCategoryTitle: String
    let prefillSubcategoryTitle: String
    let effort: SuggestionEffort
    let mode: SuggestionMode
    let tags: [String]
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