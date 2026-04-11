import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy

    var body: some View {
        HighlightCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(copy.headline)
                        .font(DSFont.accent(size: 24, relativeTo: .title3))
                        .foregroundColor(.white)

                    Text(copy.subheadline)
                        .font(DSText.secondary)
                        .foregroundColor(.white.opacity(0.88))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        }
    }
}

struct GuideSuggestionsSection: View {
    let suggestions: [ExperimentSuggestion]
    let onStartSuggestion: (ExperimentSuggestion) -> Void
    let onExploreMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Try something new today")
                .font(DSText.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.82))

            VStack(spacing: DSSpacing.sm) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onStartSuggestion(suggestion)
                    } label: {
                        SuggestionCard(
                            title: suggestion.title,
                            subtitle: suggestion.impactDisplayText,
                            icon: suggestionEmoji(for: suggestion),
                            style: .homeSuggestion
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Explore more") {
                onExploreMore()
            }
            .font(DSText.subheadline)
            .foregroundColor(.blue)
            .buttonStyle(.plain)
            .padding(.top, DSSpacing.xxs)
        }
    }

    private func suggestionEmoji(for suggestion: ExperimentSuggestion) -> String {
        if suggestion.category.contains("Expression") {
            return "🎨"
        }
        if suggestion.category.contains("Self") || suggestion.mode == .reflective {
            return "🌿"
        }
        if suggestion.category.contains("Body") || suggestion.mode == .reset {
            return "✨"
        }
        if suggestion.category.contains("Connection") {
            return "💫"
        }
        return "✨"
    }
}
