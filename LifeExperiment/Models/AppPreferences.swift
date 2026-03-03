import SwiftUI

enum UIStyle: String, CaseIterable, Identifiable {
    case minimal
    case cozy
    case playful

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .cozy:
            return "Cozy"
        case .playful:
            return "Playful"
        }
    }

    var cardCornerRadius: CGFloat {
        switch self {
        case .minimal:
            return 12
        case .cozy:
            return 16
        case .playful:
            return 20
        }
    }

    var cardPadding: CGFloat {
        switch self {
        case .minimal:
            return 14
        case .cozy:
            return 18
        case .playful:
            return 20
        }
    }
}

struct AppPreferences: DynamicProperty {
    @AppStorage("pref.uiStyle") var uiStyleRaw: String = UIStyle.minimal.rawValue
    @AppStorage("pref.imageLoggingEnabled") var imageLoggingEnabled: Bool = true

    var uiStyle: UIStyle {
        get { UIStyle(rawValue: uiStyleRaw) ?? .minimal }
        nonmutating set { uiStyleRaw = newValue.rawValue }
    }

    var uiStyleBinding: Binding<UIStyle> {
        Binding(
            get: { uiStyle },
            set: { uiStyle = $0 }
        )
    }

    var imageLoggingEnabledBinding: Binding<Bool> {
        Binding(
            get: { imageLoggingEnabled },
            set: { imageLoggingEnabled = $0 }
        )
    }
}

