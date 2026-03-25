import Foundation

enum HomeGuideState {
    case noActive
    case activeNoLogToday
    case loggedToday
}

struct GuideCopy {
    let headline: String
    let subheadline: String
}

enum GuideCopyProvider {
    static func copy(for state: HomeGuideState) -> GuideCopy {
        switch state {
        case .noActive:
            return GuideCopy(
                headline: "You can begin with something small.",
                subheadline: "Pick one experiment for today, if you'd like."
            )

        case .activeNoLogToday:
            return GuideCopy(
                headline: "You already have something in motion.",
                subheadline: "You can continue a little today, if you want."
            )

        case .loggedToday:
            return GuideCopy(
                headline: "You’ve done a little today.",
                subheadline: "If you want, try something new."
            )
        }
    }
}
