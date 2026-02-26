import SwiftUI

struct DimensionSection: View {
    let isSeedBased: Bool
    let isCustomSubcategoryMode: Bool
    let displayedImpact: ExperimentImpact?

    @Binding var showDimensionPicker: Bool

    var body: some View {
        if let impact = displayedImpact, isSeedBased {
            DefaultDimensionsCard(impact: impact) {
                showDimensionPicker = true
            }
        }

        if isCustomSubcategoryMode {
            CustomDimensionSelectionCard(selectedImpact: displayedImpact) {
                showDimensionPicker = true
            }
        }
    }
}
