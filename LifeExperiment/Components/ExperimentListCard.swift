import SwiftUI

enum ExperimentListCardSurfaceStyle {
    case activePrimary
    case activeSecondary
    case continueReturn
    case completed
    case browse

    var cornerRadius: CGFloat {
        switch self {
        case .browse:
            return 14
        case .continueReturn:
            return 16
        case .activePrimary, .activeSecondary:
            return 14
        case .completed:
            return 12
        }
    }

    var fillColor: Color {
        switch self {
        case .activePrimary:
            return Color(.systemBackground)
        case .continueReturn:
            return Color(.secondarySystemBackground)
        case .activeSecondary:
            return Color(.systemGray6)
        case .completed:
            return Color(.secondarySystemBackground)
        case .browse:
            return Color(.secondarySystemBackground)
        }
    }

    var fillOpacity: Double {
        switch self {
        case .activePrimary, .browse:
            return 1.0
        case .continueReturn:
            return 1.0
        case .activeSecondary:
            return 0.7
        case .completed:
            return 1.0
        }
    }

    var borderOpacity: Double {
        switch self {
        case .activePrimary:
            return 0.03
        case .continueReturn:
            return 0.05
        case .activeSecondary:
            return 0.03
        case .browse:
            return 0.04
        case .completed:
            return 0.02
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .activePrimary:
            return 0.04
        case .continueReturn:
            return 0.04
        case .activeSecondary:
            return 0.04
        case .completed:
            return 0.015
        case .browse:
            return 0.03
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .browse, .completed:
            return 6
        case .continueReturn:
            return 10
        case .activePrimary, .activeSecondary:
            return 10
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .browse, .completed:
            return 2
        case .continueReturn:
            return 3
        case .activePrimary, .activeSecondary:
            return 4
        }
    }

    var titleSubtitleSpacing: CGFloat {
        switch self {
        case .continueReturn:
            return DSSpacing.xs
        default:
            return DSSpacing.xxs
        }
    }
}

struct ExperimentListCard<TrailingAccessory: View>: View {
    let title: String
    let subtitle: String?
    let titleWeight: Font.Weight
    let contentPadding: CGFloat
    let surfaceStyle: ExperimentListCardSurfaceStyle
    let trailingAccessory: TrailingAccessory

    private let action: (() -> Void)?
    private let destination: AnyView?

    init(
        title: String,
        subtitle: String? = nil,
        titleWeight: Font.Weight = .semibold,
        surfaceStyle: ExperimentListCardSurfaceStyle = .browse,
        contentPadding: CGFloat = DSSpacing.md,
        action: @escaping () -> Void,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleWeight = titleWeight
        self.surfaceStyle = surfaceStyle
        self.contentPadding = contentPadding
        self.action = action
        self.destination = nil
        self.trailingAccessory = trailingAccessory()
    }

    init<Destination: View>(
        title: String,
        subtitle: String? = nil,
        titleWeight: Font.Weight = .semibold,
        surfaceStyle: ExperimentListCardSurfaceStyle = .browse,
        contentPadding: CGFloat = DSSpacing.md,
        destination: Destination,
        @ViewBuilder trailingAccessory: () -> TrailingAccessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleWeight = titleWeight
        self.surfaceStyle = surfaceStyle
        self.contentPadding = contentPadding
        self.action = nil
        self.destination = AnyView(destination)
        self.trailingAccessory = trailingAccessory()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(PressableCardStyle())
            } else if let destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
                .buttonStyle(PressableCardStyle())
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        HStack(spacing: DSSpacing.sm) {
            VStack(alignment: .leading, spacing: surfaceStyle.titleSubtitleSpacing) {
                Text(title)
                    .font(DSText.rowTitle)
                    .fontWeight(titleWeight)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            trailingAccessory
        }
        .lightCardStyle(
            cornerRadius: surfaceStyle.cornerRadius,
            fillColor: surfaceStyle.fillColor,
            fillOpacity: surfaceStyle.fillOpacity,
            borderOpacity: surfaceStyle.borderOpacity,
            shadowOpacity: surfaceStyle.shadowOpacity,
            shadowRadius: surfaceStyle.shadowRadius,
            shadowYOffset: surfaceStyle.shadowYOffset,
            contentPadding: contentPadding
        )
        .contentShape(Rectangle())
    }
}
