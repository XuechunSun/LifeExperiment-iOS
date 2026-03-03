import Foundation

struct InsightSnapshot: Equatable {
    let lines: [InsightLine]
}

enum InsightKind: String, Hashable {
    case mood
    case stability
    case rhythm
}

struct InsightLine: Identifiable, Hashable, Equatable {
    let id: String
    let text: String
    let kind: InsightKind
}

enum InsightCalculator {
    private static let moodDeltaThreshold: Double = 0.3
    private static let participationThreshold: Int = 2
    private static let stabilityEpsilon: Double = 0.05
    private static let maxLines: Int = 2

    static func compute(logs: [DailyLog], now: Date, calendar: Calendar = .current) -> [InsightLine] {
        // 1) Mood windows: log-based (last 7 mood logs vs previous 7 mood logs)
        let moodLogs: [(date: Date, score: Double)] = logs.compactMap { log in
            guard let score = moodScore(for: log.mood) else { return nil }
            return (log.date, score)
        }
        .sorted { $0.date < $1.date }

        let recentMoodLogs = Array(moodLogs.suffix(7))
        let recentMoodScores = recentMoodLogs.map { $0.score }

        // Eligibility: recent mood >= 2
        guard recentMoodScores.count >= 2 else { return [] }

        let previousMoodLogs = Array(moodLogs.dropLast(recentMoodLogs.count).suffix(7))
        let previousMoodScores = previousMoodLogs.map { $0.score }

        // 2) Always include Mood Direction (fallback to steady if no previous window)
        let directionText: String = {
            guard let recentAvg = average(recentMoodScores) else {
                return "Mood has been fairly steady recently."
            }
            guard let prevAvg = average(previousMoodScores) else {
                // No baseline -> avoid pretending trend; show steady fallback
                return "Mood has been fairly steady recently."
            }
            let delta = recentAvg - prevAvg
            if delta > moodDeltaThreshold { return "Mood has been slightly trending up recently." }
            if delta < -moodDeltaThreshold { return "Mood has been slightly trending down recently." }
            return "Mood has been fairly steady recently."
        }()

        var lines: [InsightLine] = [
            InsightLine(id: "\(InsightKind.mood.rawValue)|\(directionText)|0", text: directionText, kind: .mood)
        ]

        // If only 2 mood logs, show ONLY 1 line (per option 2)
        if recentMoodScores.count == 2 {
            return lines
        }

        // 3) Optional second line (priority: Stability, else Participation)
        // 3a) Stability: requires recent >= 3 AND previous >= 2
        if let stability = moodStabilityLine(recent: recentMoodScores, previous: previousMoodScores) {
            lines.append(InsightLine(id: "\(InsightKind.stability.rawValue)|\(stability)|1", text: stability, kind: .stability))
            return Array(lines.prefix(maxLines))
        }

        // 3b) Participation: calendar-based (keep frequency meaning)
        let counts = participationCountsCalendar(logs: logs, now: now, calendar: calendar)
        if let participation = participationLine(recentCount: counts.recent, previousCount: counts.previous) {
            lines.append(InsightLine(id: "\(InsightKind.rhythm.rawValue)|\(participation)|1", text: participation, kind: .rhythm))
        }

        return Array(lines.prefix(maxLines))
    }

    private static func participationCountsCalendar(logs: [DailyLog], now: Date, calendar: Calendar) -> (recent: Int, previous: Int) {
        let anchorDay = calendar.startOfDay(for: now)
        var recent = 0
        var previous = 0

        for log in logs {
            let day = calendar.startOfDay(for: log.date)
            guard let dayDiff = calendar.dateComponents([.day], from: day, to: anchorDay).day else { continue }
            if (0...6).contains(dayDiff) { recent += 1 }
            else if (7...13).contains(dayDiff) { previous += 1 }
        }
        return (recent, previous)
    }

    private static func participationLine(recentCount: Int, previousCount: Int) -> String? {
        let delta = recentCount - previousCount
        if delta >= participationThreshold { return "You've been checking in more often recently." }
        if delta <= -participationThreshold { return "You've been checking in less often recently." }
        return "Your check-in rhythm has been consistent."
    }

    private static func moodStabilityLine(recent: [Double], previous: [Double]) -> String? {
        guard recent.count >= 3, previous.count >= 2 else { return nil }
        let recentStd = standardDeviation(recent)
        let previousStd = standardDeviation(previous)
        if recentStd < previousStd - stabilityEpsilon { return "Mood swings have been smoothing out." }
        if recentStd > previousStd + stabilityEpsilon { return "Mood swings have been slightly more variable." }
        return "Mood variability has been fairly consistent."
    }

    private static func moodScore(for mood: Mood?) -> Double? {
        guard let mood else { return nil }
        switch mood {
        case .veryBad:
            return 1
        case .bad:
            return 2
        case .neutral:
            return 3
        case .good:
            return 4
        case .veryGood:
            return 5
        }
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func standardDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { partial, value in
            let diff = value - mean
            return partial + diff * diff
        } / Double(values.count)
        return sqrt(variance)
    }
}
