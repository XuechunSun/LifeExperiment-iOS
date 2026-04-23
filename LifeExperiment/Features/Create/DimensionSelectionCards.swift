import SwiftUI

// MARK: - Dimension UI Components

struct DimensionChip: View {
    let dimension: Dimension
    let isPrimary: Bool
    let lang: AppLanguage

    var body: some View {
        HStack(spacing: 4) {
            if isPrimary {
                Image(systemName: "star.fill")
                    .font(DSText.caption2)
                    .foregroundColor(.yellow)
            }
            Text(L.dimensionDisplayTitle(lang, dimension: dimension))
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(isPrimary ? Color.blue.opacity(0.14) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isPrimary ? Color.blue.opacity(0.12) : Color.black.opacity(0.035), lineWidth: 1)
        )
        .foregroundColor(isPrimary ? .blue : .primary)
        .cornerRadius(16)
    }
}

private struct ImpactChipGroupView: View {
    let impact: ExperimentImpact
    let lang: AppLanguage

    private var chips: [(dimension: Dimension, isPrimary: Bool)] {
        var values: [(Dimension, Bool)] = [(impact.primary, true)]
        if let secondary = impact.secondary {
            values.append((secondary, false))
        }
        if let tertiary = impact.tertiary {
            values.append((tertiary, false))
        }
        return values
    }

    var body: some View {
        if chips.count <= 2 {
            HStack(spacing: 8) {
                ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                    DimensionChip(
                        dimension: chip.dimension,
                        isPrimary: chip.isPrimary,
                        lang: lang
                    )
                }
            }
        } else {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], alignment: .leading, spacing: 8) {
                ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                    DimensionChip(
                        dimension: chip.dimension,
                        isPrimary: chip.isPrimary,
                        lang: lang
                    )
                }
            }
        }
    }
}

struct DefaultDimensionsCard: View {
    let impact: ExperimentImpact
    let lang: AppLanguage
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L.createDefaultDimensionsHeadline(lang))
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: onEdit) {
                        Text(L.createDimensionEditAction(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Text(L.createDefaultDimensionsSub(lang))
                    .font(DSText.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ImpactChipGroupView(impact: impact, lang: lang)
        }
        .createSupportSurface(contentPadding: 16)
    }
}

struct CustomDimensionSelectionCard: View {
    let selectedImpact: ExperimentImpact?
    let lang: AppLanguage
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            if let impact = selectedImpact {
                // Show selected dimensions with Edit button
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(L.createCustomDimensionsHeadline(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: onChoose) {
                            Text(L.createDimensionEditAction(lang))
                                .font(DSText.subheadline)
                                .foregroundColor(.blue)
                        }
                    }

                    Text(L.createCustomDimensionsSubWhenSelected(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ImpactChipGroupView(impact: impact, lang: lang)
            } else {
                // Show "Choose dimensions" prompt
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(L.createCustomDimensionsHeadlineUnselected(lang))
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L.createCustomDimensionsSubUnselected(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onChoose) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(L.createDimensionChooseCTA(lang))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text(L.createCustomDimensionsReassure(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .createSupportSurface(contentPadding: 16)
    }
}

