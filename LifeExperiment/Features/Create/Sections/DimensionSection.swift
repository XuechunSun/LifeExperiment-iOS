import SwiftUI

struct DimensionSection: View {
    let isSeedBased: Bool
    let isCustomSubcategoryMode: Bool
    let displayedImpact: ExperimentImpact?

    @Binding var showDimensionPicker: Bool
    let lang: AppLanguage

    var body: some View {
        if let impact = displayedImpact, isSeedBased {
            DefaultDimensionsCard(impact: impact, lang: lang) {
                showDimensionPicker = true
            }
        }

        if isCustomSubcategoryMode {
            CustomDimensionSelectionCard(selectedImpact: displayedImpact, lang: lang) {
                showDimensionPicker = true
            }
        }
    }
}
