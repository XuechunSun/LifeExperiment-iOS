import SwiftUI

let cardBackground = Color(red: 0.96, green: 0.97, blue: 0.98)
let highlightCard = Color.blue.opacity(0.06)
let secondaryCard = Color(.systemGray6)

enum DSInset {
    static let pageHorizontal: CGFloat = 16
}

enum SummaryCardStyle {
    case neutral
    case strength
    case growth
    case storage
}

struct HighlightCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.65, green: 0.72, blue: 0.95),
                        Color(red: 0.72, green: 0.65, blue: 0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
    }
}

struct SummaryCard<Content: View>: View {
    let style: SummaryCardStyle
    let content: Content

    init(style: SummaryCardStyle = .neutral, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(DSSpacing.md)
            .background(backgroundView)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .neutral:
            cardBackground
        case .strength:
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.blue.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .growth:
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.035)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .storage:
            Color(.systemGray6)
        }
    }

    private var strokeOpacity: Double {
        switch style {
        case .neutral:
            return 0.4
        case .strength, .growth:
            return 0.55
        case .storage:
            return 0.24
        }
    }
}

struct SectionBlock<Content: View>: View {
    let title: String
    let subtitle: String?
    let style: SummaryCardStyle
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        style: SummaryCardStyle = .neutral,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
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

            SummaryCard(style: style) {
                content
            }
        }
    }
}
