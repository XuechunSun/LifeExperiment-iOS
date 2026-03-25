import Foundation

enum ExperimentSuggestionsLoader {
    static func load() -> [ExperimentSuggestion] {
        guard let url = Bundle.main.url(forResource: "ExperimentSuggestions", withExtension: "json") else {
            print("Failed to find ExperimentSuggestions.json in bundle.")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ExperimentSuggestion].self, from: data)
        } catch {
            print("Failed to decode ExperimentSuggestions.json: \(error)")
            return []
        }
    }
}