import Foundation

enum ExperimentSuggestionsLoader {
    static func load() -> [ExperimentSuggestion] {
        guard let url = Bundle.main.url(forResource: "ExperimentSuggestions", withExtension: "json") else {
            #if DEBUG
            print("Failed to find ExperimentSuggestions.json in bundle.")
            #endif
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ExperimentSuggestion].self, from: data)
            #if DEBUG
            BuiltInTitleDisplay.debugAssertCoverage(
                decoded.map(\.title),
                context: "ExperimentSuggestions.json"
            )
            #endif
            return decoded
        } catch {
            #if DEBUG
            print("Failed to decode ExperimentSuggestions.json: \(error)")
            #endif
            return []
        }
    }
}