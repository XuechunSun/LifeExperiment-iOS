import SwiftUI

enum SuggestionCardStyle {
    case subtle
    case emphasized
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
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(2)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(backgroundView)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .subtle:
            Color(.systemGray6)

        case .emphasized:
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
