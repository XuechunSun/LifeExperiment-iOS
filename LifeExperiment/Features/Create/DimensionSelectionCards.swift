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
        .padding(.vertical, 6)
        .background(isPrimary ? Color.blue.opacity(0.15) : Color(.systemGray5))
        .foregroundColor(isPrimary ? .blue : .primary)
        .cornerRadius(16)
    }
}

struct DefaultDimensionsCard: View {
    let impact: ExperimentImpact
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This experiment usually helps with:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
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
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CustomDimensionSelectionCard: View {
    let selectedImpact: ExperimentImpact?
    let onChoose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let impact = selectedImpact {
                // Show selected dimensions with Edit button
                HStack {
                    Text("This experiment helps with:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: onChoose) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
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
                VStack(alignment: .leading, spacing: 8) {
                    Text("What does this experiment help with most? (required)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button(action: onChoose) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Choose dimensions")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                    }

                    Text("Don't overthink it — you can adjust later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

