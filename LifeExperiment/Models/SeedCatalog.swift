import Foundation

// MARK: - Seed Catalog Models

struct SeedCatalog: Codable {
    let version: String
    let categories: [SeedCategory]
}

struct SeedCategory: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String?
    let subcategories: [SeedSubcategory]
}

struct SeedSubcategory: Identifiable, Codable {
    let id: String
    let title: String
    let default_dimensions: [Dimension]?
    let prompts: [String]
}

struct SeedCatalogLoader {
    static func load() -> SeedCatalog? {
        guard let url = Bundle.main.url(forResource: "experiment_seed", withExtension: "json") else {
            print("⚠️ SeedCatalogLoader: experiment_seed.json not found in bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(SeedCatalog.self, from: data)
            print("✅ SeedCatalogLoader: Loaded catalog v\(catalog.version) with \(catalog.categories.count) categories")
            return catalog
        } catch {
            print("⚠️ SeedCatalogLoader: Failed to decode experiment_seed.json - \(error)")
            return nil
        }
    }
}

// MARK: - Impact Helper

/// Convert default_dimensions array to ExperimentImpact
/// - Parameter arr: Array of dimensions from seed data
/// - Returns: ExperimentImpact with primary and secondary dimensions, or nil if empty
/// Order matters: first = primary (1.0), second = secondary (0.5), third = tertiary (0.2)
func impactFromDefaultDimensions(_ arr: [Dimension]?) -> ExperimentImpact? {
    guard let arr = arr, !arr.isEmpty else { return nil }

    let primary = arr[0]
    let secondary: Dimension? = arr.count > 1 ? arr[1] : nil
    let tertiary: Dimension? = arr.count > 2 ? arr[2] : nil

    return ExperimentImpact(primary: primary, secondary: secondary, tertiary: tertiary)
}

