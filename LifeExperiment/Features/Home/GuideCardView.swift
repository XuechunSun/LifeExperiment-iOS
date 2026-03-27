import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy
    let suggestions: [ExperimentSuggestion]
    let onStartSuggestion: (ExperimentSuggestion) -> Void
    let onExploreMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 6, height: 6)

                    Text(copy.headline)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

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
            .padding(.top, DSSpacing.xxs)
        }
        .padding(DSSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
    }
}
