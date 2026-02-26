import Foundation

enum DefaultDimensionMapping {
    static func suggestedImpact(from subcategory: SeedSubcategory?) -> ExperimentImpact? {
        guard let subcategory else { return nil }
        return impactFromDefaultDimensions(subcategory.default_dimensions)
    }
}
