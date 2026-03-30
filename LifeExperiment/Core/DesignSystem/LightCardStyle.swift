import SwiftUI

struct LightCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    var fillColor: Color = Color(.secondarySystemBackground)
    var fillOpacity: Double = 1.0
    var borderOpacity: Double = 0.04
    var shadowOpacity: Double = 0.03
    var shadowRadius: CGFloat = 6
    var shadowYOffset: CGFloat = 2
    var contentPadding: CGFloat = DSSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(contentPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(borderOpacity), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: shadowYOffset
            )
    }
}

extension View {
    func lightCardStyle(
        cornerRadius: CGFloat = 16,
        fillColor: Color = Color(.secondarySystemBackground),
        fillOpacity: Double = 1.0,
        borderOpacity: Double = 0.04,
        shadowOpacity: Double = 0.03,
        shadowRadius: CGFloat = 6,
        shadowYOffset: CGFloat = 2,
        contentPadding: CGFloat = DSSpacing.md
    ) -> some View {
        modifier(
            LightCardStyle(
                cornerRadius: cornerRadius,
                fillColor: fillColor,
                fillOpacity: fillOpacity,
                borderOpacity: borderOpacity,
                shadowOpacity: shadowOpacity,
                shadowRadius: shadowRadius,
                shadowYOffset: shadowYOffset,
                contentPadding: contentPadding
            )
        )
    }
}