import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy
    let suggestions: [ExperimentSuggestion]
    let onStartSuggestion: (ExperimentSuggestion) -> Void
    let onExploreMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(copy.headline)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(copy.subheadline)
                    .lifeSecondaryText()
            }

            VStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(suggestion.title)
                            .font(DSText.rowTitle)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Spacer(minLength: DSSpacing.sm)

                            Button("Try") {
                                onStartSuggestion(suggestion)
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, DSSpacing.sm)

                    if index < suggestions.count - 1 {
                        Divider()
                    }
                }
            }

            Button("Explore more") {
                onExploreMore()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .buttonStyle(.plain)
            .padding(.top, DSSpacing.xs)
        }
        .padding(DSSpacing.md)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
