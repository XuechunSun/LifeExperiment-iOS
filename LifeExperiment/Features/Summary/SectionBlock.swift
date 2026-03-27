import SwiftUI

let cardBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
let highlightCard = Color.blue.opacity(0.06)
let secondaryCard = Color(.systemGray6)

struct SectionBlock<Content: View>: View {
    let title: String
    let subtitle: String?
    let backgroundColor: Color
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        backgroundColor: Color = secondaryCard,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(title)
                    .font(DSText.section)
                    .foregroundColor(.primary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .lifeSecondaryText()
                }
            }

            content
                .padding(DSSpacing.md)
                .background(backgroundColor)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }
}
