import SwiftUI

struct HomePersonalizedSuggestionSection: View {
    let signal: PersonalizedSuggestionSignal
    let suggestion: ExperimentSuggestion
    let onTapSuggestion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Worth noticing")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.82))

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("You’ve been leaning toward \(PersonalizedSuggestionFormatter.dimensionSummaryLabel(for: signal.topDimension)) lately.")
                    .lifeSecondaryText()
                    .fixedSize(horizontal: false, vertical: true)

                Text("Here’s something different you could explore.")
                    .lifeCaption()
            }

            Button {
                onTapSuggestion()
            } label: {
                SuggestionCard(
                    title: suggestion.title,
                    subtitle: suggestion.category,
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
    static func dimensionSummaryLabel(for dimension: Dimension) -> String {
        switch dimension {
        case .emotion_awareness:
            return "emotional awareness"
        case .body_energy:
            return "body and energy"
        case .execution:
            return "action"
        case .focus_flow:
            return "focus"
        case .expression_creativity:
            return "expression"
        case .connection:
            return "connection"
        case .self_understanding:
            return "self-understanding"
        }
    }

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
