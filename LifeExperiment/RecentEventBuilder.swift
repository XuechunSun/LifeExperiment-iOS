import Foundation

struct RecentEventBuilder {

    static func build(experiments: [Experiment], today: Date) -> [RecentEvent] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)

        // Home state (roughly)
        let activeExperiments = experiments.filter { $0.status == .active }
        let hasUpdatedToday = experiments.contains { isUpdated(on: todayStart, experiment: $0) }
        let noActive = activeExperiments.isEmpty

        var events: [RecentEvent] = []

        // A) streak
        let streak = calculateStreak(experiments: experiments, today: todayStart)
        if streak >= 2 {
            events.append(
                RecentEvent(
                    iconSystemName: RecentEventTemplate.Icon.streak,
                    title: "\(streak) days in a row",
                    subtitle: "You’ve shown up consistently"
                )
            )
        } else if streak == 1 && hasUpdatedToday && events.isEmpty {
            events.append(
                RecentEvent(
                    iconSystemName: RecentEventTemplate.Icon.updated,
                    title: "You made progress today",
                    subtitle: nil
                )
            )
        }

        // B) completed yesterday
        if events.count < 2 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            let completedYesterday = experiments.filter { exp in
                guard let completedAt = exp.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: yesterday)
            }

            if !completedYesterday.isEmpty {
                let count = completedYesterday.count
                events.append(
                    RecentEvent(
                        iconSystemName: RecentEventTemplate.Icon.completion,
                        title: "Completed yesterday",
                        subtitle: count > 1 ? "\(count) experiments finished" : "A real milestone"
                    )
                )
            }
        }

        // C) first time category
        if events.count < 2 && hasUpdatedToday {
            if let category = firstTimeCategory(experiments: experiments, today: todayStart) {
                events.append(
                    RecentEvent(
                        iconSystemName: RecentEventTemplate.Icon.firstTime,
                        title: "First time: \(category)",
                        subtitle: "Love this direction"
                    )
                )
            }
        }

        // D) empty state encouragement
        if noActive && events.isEmpty {
            events.append(
                RecentEvent(
                    iconSystemName: RecentEventTemplate.Icon.empty,
                    title: "You’re here",
                    subtitle: "That’s the first step"
                )
            )
        }

        return Array(events.prefix(2))
    }

    // MARK: - Helpers

    private static func isUpdated(on day: Date, experiment: Experiment) -> Bool {
        let calendar = Calendar.current

        if calendar.isDate(experiment.createdAt, inSameDayAs: day) { return true }
        if experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: day) }) { return true }
        if let completedAt = experiment.completedAt, calendar.isDate(completedAt, inSameDayAs: day) { return true }

        return false
    }

    private static func calculateStreak(experiments: [Experiment], today: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: today)

        for _ in 0..<365 {
            let hasUpdate = experiments.contains { isUpdated(on: checkDate, experiment: $0) }
            if hasUpdate {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    private static func firstTimeCategory(experiments: [Experiment], today: Date) -> String? {
        // experiments updated today
        let updatedToday = experiments.filter { isUpdated(on: today, experiment: $0) }

        guard let todayExp = updatedToday.first(where: { exp in
            let c = (exp.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !c.isEmpty
        }) else { return nil }

        let category = todayExp.category!.trimmingCharacters(in: .whitespacesAndNewlines)

        let others = experiments.filter { exp in
            exp.id != todayExp.id &&
            (exp.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == category
        }

        return others.isEmpty ? category : nil
    }
}

