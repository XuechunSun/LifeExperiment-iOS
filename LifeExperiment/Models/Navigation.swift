import Foundation

// MARK: - Navigation Route

enum Route: Hashable {
    case experiment(UUID)
    /// Same destination as `experiment`, but opens scrolled to the History
    /// section. Used by Home's hero card "Read more" affordance.
    case experimentHistory(UUID)
    case activeMore
    case completedMore
    case summary
    case day(Date)
}

// MARK: - Tab enum

enum Tab: Int {
    case home = 0
    case active = 1
    case create = 2
    case summary = 3
    case profile = 4
}

