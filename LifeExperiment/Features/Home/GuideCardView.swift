import SwiftUI

struct GuideCardView: View {
    let copy: GuideCopy

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(copy.headline)
                .font(DSFont.accent(size: 24, relativeTo: .title3))
                .foregroundColor(.white)

            Text(copy.subheadline)
                .font(DSText.secondary)
                .foregroundColor(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    highlightCardStart,
                    highlightCardEnd,
                    primaryLavenderButton.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: primaryLavenderButton.opacity(0.16), radius: 18, x: 0, y: 6)
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
                            .foregroundColor(.secondary)
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
                        HomeExploreSuggestionRow(
                            title: BuiltInTitleDisplay.localizedTitle(stored: suggestion.title, lang: lang),
                            subtitle: suggestion.impactDisplayText(lang: lang),
                            icon: suggestionEmoji(for: suggestion)
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
            .foregroundColor(primaryLavenderButton)
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

private struct HomeExploreSuggestionRow: View {
    let title: String
    let subtitle: String?
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(icon)
                .font(DSText.subheadline)
                .foregroundColor(.primary.opacity(0.88))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSText.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.92))
                    .lineSpacing(2)

                if let subtitle {
                    Text(subtitle)
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(DSText.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary.opacity(0.55))
                .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.045),
                            Color.blue.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }
}
