import SwiftUI

struct SectionBlock<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
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
                .lifeCard()
        }
    }
}
