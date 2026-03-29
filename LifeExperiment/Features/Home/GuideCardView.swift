import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy

    var body: some View {
        HighlightCard {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(copy.headline)
                        .font(.title3)
                        .fontWeight(.medium)
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
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.82))

            VStack(spacing: DSSpacing.sm) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onStartSuggestion(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text("\(suggestionEmoji(for: suggestion)) \(suggestion.title)")
                                .font(DSText.rowTitle)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(suggestionMetadata(for: suggestion))
                                .font(DSText.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DSSpacing.md)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.06),
                                    Color.blue.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
    }

    private func suggestionMetadata(for suggestion: ExperimentSuggestion) -> String {
        "\(suggestion.category) · \(modeLabel(for: suggestion.mode))"
    }

    private func modeLabel(for mode: SuggestionMode) -> String {
        switch mode {
        case .starter:
            return "Light"
        case .reflective:
            return "Reflective"
        case .social:
            return "Social"
        case .reset:
            return "Reset"
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
