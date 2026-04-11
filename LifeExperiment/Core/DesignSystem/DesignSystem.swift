
import SwiftUI
import UIKit

enum DSFont {

    private static let figtreeFontName: String? = {
        for family in UIFont.familyNames where family.lowercased().contains("figtree") {
            if let name = UIFont.fontNames(forFamilyName: family).first {
                return name
            }
        }
        return nil
    }()

    private static let caveatFontName: String? = {
        for family in UIFont.familyNames where family.lowercased().contains("caveat") {
            if let name = UIFont.fontNames(forFamilyName: family).first {
                return name
            }
        }
        return nil
    }()

    static func primary(size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle) -> Font {
        if let name = figtreeFontName {
            return Font.custom(name, size: size, relativeTo: textStyle).weight(weight)
        }
        return .system(size: size, weight: weight)
    }

    static func accent(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        if let name = caveatFontName {
            return Font.custom(name, size: size, relativeTo: textStyle)
        }
        return .system(size: size, weight: .semibold)
    }

    static func uiPrimary(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let name = figtreeFontName, let font = UIFont(name: name, size: size) {
            return font
        }
        return .systemFont(ofSize: size, weight: weight)
    }
}


enum DSText {
    static let display = DSFont.primary(size: 28, weight: .semibold, relativeTo: .largeTitle)
    static let section = DSFont.primary(size: 20, weight: .semibold, relativeTo: .title3)
    static let rowTitle = DSFont.primary(size: 15, weight: .semibold, relativeTo: .headline)
    static let body = DSFont.primary(size: 17, relativeTo: .body)
    static let secondary = DSFont.primary(size: 15, relativeTo: .subheadline)
    static let caption = DSFont.primary(size: 12, relativeTo: .caption)

    static let largeTitle = DSFont.primary(size: 34, weight: .bold, relativeTo: .largeTitle)
    static let title = DSFont.primary(size: 28, weight: .bold, relativeTo: .title)
    static let title2 = DSFont.primary(size: 22, weight: .bold, relativeTo: .title2)
    static let title3 = DSFont.primary(size: 20, relativeTo: .title3)
    static let headline = DSFont.primary(size: 17, weight: .semibold, relativeTo: .headline)
    static let subheadline = DSFont.primary(size: 15, relativeTo: .subheadline)
    static let caption2 = DSFont.primary(size: 11, relativeTo: .caption2)
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
