import SwiftUI

enum SuggestionCardStyle {
    case homeSuggestion
    case createSuggestion
}

struct SuggestionCard: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let style: SuggestionCardStyle

    private let cornerRadius: CGFloat = 14

    var body: some View {
        HStack(alignment: .top, spacing: 10) {

            if let icon {
                Text(icon)
                    .font(iconFont)
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(titleFontWeight)
                    .foregroundColor(titleColor)
                    .lineSpacing(2)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(subtitleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .allowsTightening(true)
                }
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary.opacity(0.72))
                    .padding(.top, 2)
            }
        }
        //.padding(14)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(backgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                //.stroke(Color.white.opacity(0.6), lineWidth: 1)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .createSuggestion:
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case .homeSuggestion:
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var titleFontWeight: Font.Weight {
        switch style {
        case .homeSuggestion:
            return .medium
        case .createSuggestion:
            return .regular
        }
    }

    private var titleColor: Color {
        switch style {
        case .homeSuggestion:
            return .primary.opacity(0.92)
        case .createSuggestion:
            return .primary.opacity(0.82)
        }
    }

    private var subtitleColor: Color {
        switch style {
        case .homeSuggestion:
            return .secondary
        case .createSuggestion:
            return .secondary.opacity(0.9)
        }
    }

    private var iconFont: Font {
        switch style {
        case .homeSuggestion:
            return .subheadline
        case .createSuggestion:
            return .caption
        }
    }

    private var iconColor: Color {
        switch style {
        case .homeSuggestion:
            return .primary.opacity(0.92)
        case .createSuggestion:
            return .primary.opacity(0.72)
        }
    }

    private var showsChevron: Bool {
        style == .homeSuggestion
    }
}
