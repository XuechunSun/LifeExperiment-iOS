
import SwiftUI


enum DSText {
    static let display = Font.system(size: 28, weight: .semibold)
    static let section = Font.system(size: 20, weight: .semibold)
    static let rowTitle = Font.system(size: 15, weight: .semibold)
    static let body = Font.system(size: 17)
    static let secondary = Font.system(size: 15)
    static let caption = Font.system(size: 12)
}

enum DSSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}

struct LifeCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DSSpacing.md)
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

extension View {
    func lifeCard() -> some View {
        self.modifier(LifeCard())
    }
}

extension View {
    func lifeSectionTitle() -> some View {
        self
            .font(DSText.section)
            .foregroundColor(.primary)
    }

    func lifeSecondaryText() -> some View {
        self
            .font(DSText.secondary)
            .foregroundColor(.secondary)
    }

    func lifeCaption() -> some View {
        self
            .font(DSText.caption)
            .foregroundColor(.secondary)
    }
}

struct LifeRow<Content: View>: View {
    let content: Content
    let showsChevron: Bool

    init(showsChevron: Bool = false,
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.showsChevron = showsChevron
    }

    var body: some View {
        HStack {
            content
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, DSSpacing.sm)
        .contentShape(Rectangle())
    }
}