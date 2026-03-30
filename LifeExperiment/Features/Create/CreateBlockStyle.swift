import SwiftUI

extension View {
    func createSectionLabelStyle() -> some View {
        self
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.secondary.opacity(0.88))
            .kerning(0.3)
            .textCase(.uppercase)
    }

    func createInputSurface(padding: CGFloat = DSSpacing.md) -> some View {
        self
            .padding(padding)
            .background(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
            .cornerRadius(14)
    }

    func createSupportSurface(
        cornerRadius: CGFloat = 12,
        contentPadding: CGFloat = DSSpacing.md
    ) -> some View {
        self.lightCardStyle(
            cornerRadius: cornerRadius,
            fillColor: Color(.systemBackground),
            fillOpacity: 0.98,
            borderOpacity: 0.045,
            shadowOpacity: 0.035,
            shadowRadius: 6,
            shadowYOffset: 2,
            contentPadding: contentPadding
        )
    }
}
