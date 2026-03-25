import SwiftUI

// MARK: - Reusable Card Component

struct ExperimentCardRow: View {
    let title: String
    let subtitle: String
    let leadingIcon: String?
    let showsChevron: Bool
    let usesCardBackground: Bool

    init(
        title: String,
        subtitle: String,
        leadingIcon: String? = nil,
        showsChevron: Bool = true,
        usesCardBackground: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.showsChevron = showsChevron
        self.usesCardBackground = usesCardBackground
    }

    // Convenience initializer for Experiment
    init(experiment: Experiment, showsChevron: Bool = true, usesCardBackground: Bool = true) {
        self.title = experiment.title

        // Format subtitle based on experiment status
        if experiment.status == .completed, let completedAt = experiment.completedAt {
            self.subtitle = "Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))"
        } else {
            self.subtitle = "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))"
        }

        self.leadingIcon = nil
        self.showsChevron = showsChevron
        self.usesCardBackground = usesCardBackground
    }

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text(title)
                    .font(DSText.rowTitle)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(DSText.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(DSText.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(usesCardBackground ? 0 : DSSpacing.md)
        .background(usesCardBackground ? Color.clear : Color.clear)
        .modifier(ConditionalLifeCardModifier(enabled: usesCardBackground))
        .contentShape(Rectangle())
    }
}

private struct ConditionalLifeCardModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.lifeCard()
        } else {
            content
        }
    }
}

