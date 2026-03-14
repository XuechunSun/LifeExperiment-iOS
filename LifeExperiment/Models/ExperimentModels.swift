import Foundation

// MARK: - Core App Models

enum Mood: String, CaseIterable, Identifiable, Codable, Hashable {
    case veryBad, bad, neutral, good, veryGood

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .veryBad: return "😞"
        case .bad: return "🙁"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }

    var label: String {
        S.moodLabel(self)
    }

    var labelCN: String {
        switch self {
        case .veryBad: return "很差"
        case .bad: return "不太好"
        case .neutral: return "一般"
        case .good: return "不错"
        case .veryGood: return "很好"
        }
    }
}

struct DayRecord: Identifiable, Codable, Hashable {
    let id: Int
    let day: Int
    var note: String
    var mood: Mood?

    init(day: Int, note: String = "", mood: Mood? = nil) {
        self.id = day
        self.day = day
        self.note = note
        self.mood = mood
    }
}

enum ExperimentStatus: String, Codable {
    case active
    case completed
}

struct DailyLog: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var note: String
    var mood: Mood?
    var photoLocalPath: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        note: String = "",
        mood: Mood? = nil,
        photoLocalPath: String? = nil
    ) {
        self.id = id
        self.date = date
        self.note = note
        self.mood = mood
        self.photoLocalPath = photoLocalPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        note = (try? container.decode(String.self, forKey: .note)) ?? ""
        mood = try? container.decode(Mood.self, forKey: .mood)
        photoLocalPath = try? container.decode(String.self, forKey: .photoLocalPath)
    }
}

struct ExperimentReview: Codable, Hashable {
    var whatDidITry: String
    var whatHappened: String
    var whatWillIDoDifferently: String
    var locked: Bool
}

struct Experiment: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: String?
    var subcategory: String?
    var impact: ExperimentImpact?
    var status: ExperimentStatus
    var createdAt: Date
    var updatedAt: Date
    var logs: [DailyLog] = []
    var review: ExperimentReview?
    var completedAt: Date?
    var allowsImageLogging: Bool = true

    init(
        id: UUID = UUID(),
        title: String,
        category: String? = nil,
        subcategory: String? = nil,
        impact: ExperimentImpact? = nil,
        status: ExperimentStatus,
        createdAt: Date,
        updatedAt: Date? = nil,
        logs: [DailyLog] = [],
        review: ExperimentReview? = nil,
        completedAt: Date? = nil,
        allowsImageLogging: Bool = true
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory
        self.impact = impact
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.logs = logs
        self.review = review
        self.completedAt = completedAt
        self.allowsImageLogging = allowsImageLogging
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try? container.decode(String.self, forKey: .category)
        subcategory = try? container.decode(String.self, forKey: .subcategory)
        impact = try? container.decode(ExperimentImpact.self, forKey: .impact)
        status = try container.decode(ExperimentStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? createdAt
        logs = (try? container.decode([DailyLog].self, forKey: .logs)) ?? []
        review = try? container.decode(ExperimentReview.self, forKey: .review)
        completedAt = try? container.decode(Date.self, forKey: .completedAt)
        allowsImageLogging = (try? container.decode(Bool.self, forKey: .allowsImageLogging)) ?? true
    }
}

