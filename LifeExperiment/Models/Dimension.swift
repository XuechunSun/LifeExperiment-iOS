import Foundation

// MARK: - Dimension

enum Dimension: String, Codable, CaseIterable, Identifiable {
    case emotion_awareness
    case body_energy
    case execution
    case focus_flow
    case expression_creativity
    case connection
    case self_understanding

    var id: String { rawValue }

    // MARK: - English (V1 Display)

    var title: String {
        switch self {
        case .emotion_awareness:
            return "Emotional Awareness"
        case .body_energy:
            return "Body & Energy"
        case .execution:
            return "Execution"
        case .focus_flow:
            return "Focus & Flow"
        case .expression_creativity:
            return "Expression & Creativity"
        case .connection:
            return "Connection"
        case .self_understanding:
            return "Self-Understanding"
        }
    }

    var subtitle: String? {
        switch self {
        case .emotion_awareness:
            return "Notice and understand emotions"
        case .body_energy:
            return "Stabilize physical energy"
        case .execution:
            return "Start and complete actions"
        case .focus_flow:
            return "Stay focused and enter flow"
        case .expression_creativity:
            return "Create and express yourself"
        case .connection:
            return "Strengthen relationships"
        case .self_understanding:
            return "Learn what suits you"
        }
    }

    var blurb: String {
        switch self {
        case .emotion_awareness:
            return "Noticing and understanding your emotional patterns helps you respond more intentionally."
        case .body_energy:
            return "Building body awareness and stable energy supports everything else you do."
        case .execution:
            return "The ability to start and complete meaningful actions is the foundation of growth."
        case .focus_flow:
            return "Deep focus and flow states unlock your most effective and fulfilling work."
        case .expression_creativity:
            return "Creating and expressing yourself authentically builds confidence and clarity."
        case .connection:
            return "Meaningful relationships and genuine connection enrich every dimension of life."
        case .self_understanding:
            return "Understanding what works for you—your needs, preferences, and patterns—guides better choices."
        }
    }

    // MARK: - Chinese (Future Localization)

    var titleCN: String {
        switch self {
        case .emotion_awareness:
            return "情绪觉察"
        case .body_energy:
            return "身体能量"
        case .execution:
            return "执行力"
        case .focus_flow:
            return "专注与心流"
        case .expression_creativity:
            return "表达与创造"
        case .connection:
            return "连接"
        case .self_understanding:
            return "自我理解"
        }
    }

    var subtitleCN: String? {
        switch self {
        case .emotion_awareness:
            return "觉察并理解情绪"
        case .body_energy:
            return "身体状态与能量管理"
        case .execution:
            return "行动与完成"
        case .focus_flow:
            return "专注力与沉浸体验"
        case .expression_creativity:
            return "创作与表达能力"
        case .connection:
            return "人际连接与关系"
        case .self_understanding:
            return "自我认知与成长"
        }
    }
}

