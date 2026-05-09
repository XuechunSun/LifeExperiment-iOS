import Foundation

enum EnergyLevel: String, Codable, Hashable, CaseIterable {
    case normal, low, veryLow

    var emoji: String {
        switch self {
        case .normal: return "🙂"
        case .low: return "🌙"
        case .veryLow: return "🛌"
        }
    }

    /// Display label, language-aware. Persisted raw value (`rawValue`) is the source of truth.
    func localizedLabel(_ lang: AppLanguage) -> String {
        switch (lang, self) {
        case (.english, .normal): return "Doing okay"
        case (.english, .low): return "Low energy"
        case (.english, .veryLow): return "Very low"
        case (.chinese, .normal): return "状态还好"
        case (.chinese, .low): return "能量偏低"
        case (.chinese, .veryLow): return "非常低落"
        }
    }
}

enum MinimalAction: String, Codable, Hashable, CaseIterable {
    case tinyTask, learn, oneLine

    var emoji: String {
        switch self {
        case .tinyTask: return "✅"
        case .learn: return "📖"
        case .oneLine: return "✏️"
        }
    }

    /// Display label, language-aware. Persisted raw value (`rawValue`) is the source of truth.
    func localizedLabel(_ lang: AppLanguage) -> String {
        switch (lang, self) {
        case (.english, .tinyTask): return "Tiny task"
        case (.english, .learn): return "Learn something"
        case (.english, .oneLine): return "Write one line"
        case (.chinese, .tinyTask): return "做件小事"
        case (.chinese, .learn): return "学一点东西"
        case (.chinese, .oneLine): return "写一行字"
        }
    }
}

enum RecoveryType: String, Codable, Hashable, CaseIterable {
    case walk, watch, eat, rest

    var emoji: String {
        switch self {
        case .walk: return "🚶"
        case .watch: return "📺"
        case .eat: return "🍽️"
        case .rest: return "😴"
        }
    }

    /// Display label, language-aware. Persisted raw value (`rawValue`) is the source of truth.
    func localizedLabel(_ lang: AppLanguage) -> String {
        switch (lang, self) {
        case (.english, .walk): return "Walk"
        case (.english, .watch): return "Watch"
        case (.english, .eat): return "Eat"
        case (.english, .rest): return "Rest"
        case (.chinese, .walk): return "散步"
        case (.chinese, .watch): return "看点东西"
        case (.chinese, .eat): return "吃点东西"
        case (.chinese, .rest): return "休息"
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

    /// Display string for Day Detail inline block, language-aware (CL#3).
    /// Built-in labels are localized at display time; user-entered `note` is shown verbatim elsewhere.
    func localizedDetailLine(lang: AppLanguage) -> String {
        if let recoveryType {
            return "\(actionType.localizedLabel(lang)) · \(recoveryType.localizedLabel(lang))"
        }
        return actionType.localizedLabel(lang)
    }
}
