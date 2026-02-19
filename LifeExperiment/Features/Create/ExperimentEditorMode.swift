import Foundation

// MARK: - Experiment Editor (Unified for Rename / Duplicate / Create)

enum ExperimentEditorMode {
    case create
    case rename(existing: Experiment)
    case duplicate(from: Experiment)

    var navTitle: String {
        switch self {
        case .create: return "New Experiment"
        case .rename: return "Edit Experiment"
        case .duplicate: return "Duplicate Experiment"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .create: return "Create"
        case .rename: return "Save"
        case .duplicate: return "Create"
        }
    }
}

