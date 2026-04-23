import Foundation

/// Display-time resolution of app seed category/subcategory titles to `L` strings. Does not alter persistence.
enum SeedTaxonomyDisplay {
    private static let catalog: SeedCatalog? = {
        guard let loaded = SeedCatalogLoader.load(), !loaded.categories.isEmpty else {
            return nil
        }
        return loaded
    }()

    static func displayCategory(stored: String, lang: AppLanguage) -> String {
        let normalized = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return normalized }
        if normalized == "Other" {
            return L.createCategoryOther(lang)
        }
        if let c = catalog, let cat = c.categories.first(where: { $0.title == normalized }) {
            return L.summarySeedCategoryTitle(lang, categoryId: cat.id)
        }
        return normalized
    }

    static func displaySubcategory(stored: String, lang: AppLanguage) -> String {
        let normalized = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.isEmpty { return normalized }
        guard let c = catalog else { return normalized }
        for cat in c.categories {
            if let sub = cat.subcategories.first(where: { $0.title == normalized }) {
                return L.seedSubcategoryLabel(lang, subcategoryId: sub.id)
            }
        }
        return normalized
    }
}
