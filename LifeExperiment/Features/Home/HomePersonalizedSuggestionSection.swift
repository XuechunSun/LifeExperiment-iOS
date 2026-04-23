import SwiftUI

struct HomePersonalizedSuggestionSection: View {
    let signal: PersonalizedSuggestionSignal
    let suggestion: ExperimentSuggestion
    let onTapSuggestion: () -> Void

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    private var worthNoticingBodyVariant: Int {
        let cal = Calendar.current
        let now = Date()
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        let d = cal.component(.day, from: now)
        return abs(y &* 10_000 &+ m &* 100 &+ d) % 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(L.worthNoticing(lang))
                .font(DSText.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.82))

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(L.worthNoticingBodyPrimary(lang, variant: worthNoticingBodyVariant))
                    .lifeSecondaryText()
                    .fixedSize(horizontal: false, vertical: true)

                Text(L.worthNoticingBodySecondary(lang, variant: worthNoticingBodyVariant))
                    .lifeCaption()
            }

            Button {
                onTapSuggestion()
            } label: {
                SuggestionCard(
                    title: suggestion.title,
                    subtitle: suggestion.impactDisplayText,
                    icon: PersonalizedSuggestionFormatter.emoji(for: signal.weakestDimension),
                    style: .homeSuggestion
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, DSSpacing.xs)
    }
}

private enum PersonalizedSuggestionFormatter {
    static func emoji(for dimension: Dimension) -> String {
        switch dimension {
        case .connection:
            return "💫"
        case .self_understanding, .emotion_awareness:
            return "🌿"
        case .expression_creativity:
            return "🎨"
        case .body_energy:
            return "✨"
        case .execution:
            return "✓"
        case .focus_flow:
            return "◌"
        }
    }
}
