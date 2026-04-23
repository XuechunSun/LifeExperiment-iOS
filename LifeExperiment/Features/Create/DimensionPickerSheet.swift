import SwiftUI

struct DimensionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPrimary: Dimension
    @State private var selectedAdditional: [Dimension]  // Ordered array instead of Set

    let initialImpact: ExperimentImpact?
    let lang: AppLanguage
    let onSave: (ExperimentImpact) -> Void

    init(
        initialImpact: ExperimentImpact?,
        lang: AppLanguage,
        onSave: @escaping (ExperimentImpact) -> Void
    ) {
        self.initialImpact = initialImpact
        self.lang = lang
        self.onSave = onSave

        // Initialize state
        if let impact = initialImpact {
            _selectedPrimary = State(initialValue: impact.primary)
            // Use additionalDimensions helper
            _selectedAdditional = State(initialValue: impact.additionalDimensions)
        } else {
            _selectedPrimary = State(initialValue: .self_understanding)
            _selectedAdditional = State(initialValue: [])
        }
    }

    private var availableAdditional: [Dimension] {
        Dimension.allCases.filter { $0 != selectedPrimary }
    }

    private var canSave: Bool {
        selectedAdditional.count <= 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L.createPrimaryDimensionIntro(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)

                    ForEach(Dimension.allCases) { dimension in
                        Button(action: {
                            selectedPrimary = dimension
                            // Remove from additional if it was there
                            selectedAdditional.removeAll { $0 == dimension }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L.dimensionDisplayTitle(lang, dimension: dimension))
                                        .font(DSText.body)
                                        .foregroundColor(.primary)
                                    Text(L.dimensionPickerSubtitle(lang, dimension: dimension))
                                        .font(DSText.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedPrimary == dimension {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(L.createPrimaryDimensionSection(lang))
                }

                Section {
                    Text(L.createAdditionalDimensionsIntro(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)

                    ForEach(availableAdditional) { dimension in
                        Button(action: {
                            if let index = selectedAdditional.firstIndex(of: dimension) {
                                // Remove if already selected
                                selectedAdditional.remove(at: index)
                            } else if selectedAdditional.count < 2 {
                                // Append to maintain selection order
                                selectedAdditional.append(dimension)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L.dimensionDisplayTitle(lang, dimension: dimension))
                                        .font(DSText.body)
                                        .foregroundColor(.primary)
                                    Text(L.dimensionPickerSubtitle(lang, dimension: dimension))
                                        .font(DSText.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()

                                // Show selection order badge if selected
                                if let index = selectedAdditional.firstIndex(of: dimension) {
                                    HStack(spacing: 4) {
                                        Text("\(index + 1)")
                                            .font(DSText.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(width: 16, height: 16)
                                            .background(Color.blue)
                                            .clipShape(Circle())

                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedAdditional.count >= 2 && !selectedAdditional.contains(dimension))
                        .opacity((selectedAdditional.count >= 2 && !selectedAdditional.contains(dimension)) ? 0.5 : 1.0)
                    }
                } header: {
                    Text(L.createAdditionalDimensionsSection(lang))
                } footer: {
                    if selectedAdditional.count >= 2 {
                        Text(L.createAdditionalDimensionsMaxFooter(lang))
                            .font(DSText.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle(L.createEditDimensions(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.actionCancel(lang)) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L.save(lang)) {
                        let impact = ExperimentImpact(
                            primary: selectedPrimary,
                            secondary: selectedAdditional.count > 0 ? selectedAdditional[0] : nil,
                            tertiary: selectedAdditional.count > 1 ? selectedAdditional[1] : nil
                        )
                        onSave(impact)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

