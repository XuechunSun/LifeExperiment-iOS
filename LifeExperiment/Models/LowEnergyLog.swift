import Foundation

enum EnergyLevel: String, Codable, Hashable, CaseIterable {
    case normal, low, veryLow

    var label: String {
        switch self {
        case .normal: return "Doing okay"
        case .low: return "Low energy"
        case .veryLow: return "Very low"
        }
    }

    var emoji: String {
        switch self {
        case .normal: return "🙂"
        case .low: return "🌙"
        case .veryLow: return "🛌"
        }
    }
}

enum MinimalAction: String, Codable, Hashable, CaseIterable {
    case tinyTask, learn, oneLine

    var label: String {
        switch self {
        case .tinyTask: return "Tiny task"
        case .learn: return "Learn something"
        case .oneLine: return "Write one line"
        }
    }

    var emoji: String {
        switch self {
        case .tinyTask: return "✅"
        case .learn: return "📖"
        case .oneLine: return "✏️"
        }
    }
}

enum RecoveryType: String, Codable, Hashable, CaseIterable {
    case walk, watch, eat, rest

    var label: String {
        switch self {
        case .walk: return "Walk"
        case .watch: return "Watch"
        case .eat: return "Eat"
        case .rest: return "Rest"
        }
    }

    var emoji: String {
        switch self {
        case .walk: return "🚶"
        case .watch: return "📺"
        case .eat: return "🍽️"
        case .rest: return "😴"
        }
    }
}

struct LowEnergyLog: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let energyLevel: EnergyLevel
    let actionType: MinimalAction
    let recoveryType: RecoveryType?
    let note: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        energyLevel: EnergyLevel,
        actionType: MinimalAction,
        recoveryType: RecoveryType? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.energyLevel = energyLevel
        self.actionType = actionType
        self.recoveryType = recoveryType
        self.note = note
    }

    /// Display string for Day Detail inline block (CL#3).
    var detailLine: String {
        if let recoveryType {
            return "\(actionType.label) · \(recoveryType.label)"
        }
        return actionType.label
    }
}
