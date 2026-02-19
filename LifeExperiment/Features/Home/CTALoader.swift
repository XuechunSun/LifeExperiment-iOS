import Foundation

struct CTAQuoteStore: Decodable {
    let version: String
    let language: String
    let items: [String]
}

enum CTALoader {
    static func loadQuotes() -> [String] {
        guard let url = Bundle.main.url(forResource: "cta_quotes", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CTAQuoteStore.self, from: data)
            return decoded.items
        } catch {
            return []
        }
    }

    /// Deterministic daily pick so it doesn't change on every render.
    static func pickDailyQuote(from quotes: [String], date: Date = Date()) -> String? {
        guard !quotes.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let idx = (dayIndex - 1) % quotes.count
        return quotes[idx]
    }
}

