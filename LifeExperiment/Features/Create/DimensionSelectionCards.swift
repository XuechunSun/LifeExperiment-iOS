import SwiftUI

// MARK: - Dimension UI Components

struct DimensionChip: View {
    let dimension: Dimension
    let isPrimary: Bool

    var body: some View {
        HStack(spacing: 4) {
            if isPrimary {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
            Text(dimension.title)
                .font(.subheadline)
                .fontWeight(isPrimary ? .semibold : .regular)
        }
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

struct DefaultDimensionsCard: View {
    let impact: ExperimentImpact
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("This experiment usually helps with")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: onEdit) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Text("Your primary dimension appears first, with supporting dimensions after it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], alignment: .leading, spacing: 8) {
                DimensionChip(dimension: impact.primary, isPrimary: true)

                if let secondary = impact.secondary {
                    DimensionChip(dimension: secondary, isPrimary: false)
                }

                if let tertiary = impact.tertiary {
                    DimensionChip(dimension: tertiary, isPrimary: false)
                }
            }
        }
        .createSupportSurface(contentPadding: 16)
    }
}

struct CustomDimensionSelectionCard: View {
    let selectedImpact: ExperimentImpact?
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            if let impact = selectedImpact {
                // Show selected dimensions with Edit button
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("This experiment helps with")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: onChoose) {
                            Text("Edit")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }

                    Text("Choose the dimensions that feel most true right now. You can adjust them later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], alignment: .leading, spacing: 8) {
                    DimensionChip(dimension: impact.primary, isPrimary: true)

                    if let secondary = impact.secondary {
                        DimensionChip(dimension: secondary, isPrimary: false)
                    }

                    if let tertiary = impact.tertiary {
                        DimensionChip(dimension: tertiary, isPrimary: false)
                    }
                }
            } else {
                // Show "Choose dimensions" prompt
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("What does this experiment help with most? (required)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start with the most relevant area first, then add any supporting ones.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onChoose) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Choose dimensions")
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

                    Text("Don't overthink it — you can adjust later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .createSupportSurface(contentPadding: 16)
    }
}

