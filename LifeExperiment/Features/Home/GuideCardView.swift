import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy

    var body: some View {
        HighlightCard {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(copy.headline)
                    .font(DSFont.accent(size: 24, relativeTo: .title3))
                    .foregroundColor(.white)

                Text(copy.subheadline)
                    .font(DSText.secondary)
                    .foregroundColor(.white.opacity(0.88))
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        }
    }
}

struct GuideSuggestionsSection: View {
    let suggestions: [ExperimentSuggestion]
    let onStartSuggestion: (ExperimentSuggestion) -> Void
    let onExploreMore: () -> Void
    var onTakeItEasy: (() -> Void)?
    var hasLoggedLowEnergyToday: Bool = false

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(L.exploreSomethingNew(lang))
                    .font(DSText.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary.opacity(0.82))

                Spacer()

                if let onTakeItEasy {
                    Button(action: onTakeItEasy) {
                        Text(hasLoggedLowEnergyToday
                            ? L.exploreTakeItEasyAgain(lang)
                            : L.exploreTakeItEasyToday(lang))
                            .font(DSText.subheadline)
                            .italic()
                            .underline()
                            .foregroundColor(.primary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }

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

            Button(L.exploreMore(lang)) {
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
