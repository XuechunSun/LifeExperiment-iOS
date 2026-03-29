import Foundation

struct RecentEventBuilder {

    static func build(experiments: [Experiment], today: Date) -> [RecentEvent] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)

        var events: [RecentEvent] = []

        // 1. Consistency
        let streak = calculateLogStreak(experiments: experiments, today: todayStart)
        if streak >= 2 {
            events.append(
                RecentEvent(
                    iconSystemName: RecentEventTemplate.Icon.streak,
                    title: "🔥 \(streak) days in a row",
                    subtitle: "You’re building a rhythm"
                )
            )
        }

        // 2. Exploration
        if events.count < 2 {
            if let category = firstTimeCategoryLoggedToday(experiments: experiments, today: todayStart) {
                events.append(
                    RecentEvent(
                        iconSystemName: RecentEventTemplate.Icon.firstTime,
                        title: "✨ First time in \(category)",
                        subtitle: "A new area to explore"
                    )
                )
            }
        }

        // 3. Growth
        if events.count < 2 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            if hasLog(on: todayStart, experiments: experiments) && !hasLog(on: yesterday, experiments: experiments) {
                events.append(
                    RecentEvent(
                        iconSystemName: "leaf.fill",
                        title: "🌱 You showed up today",
                        subtitle: "A small return still counts"
                    )
                )
            }
        }

        // 4. Awareness
        if events.count < 2 {
            let moodLogCount = moodLogCountThisWeek(experiments: experiments, today: todayStart)
            if moodLogCount >= 3 {
                events.append(
                    RecentEvent(
                        iconSystemName: "brain.head.profile",
                        title: "🧠 You’ve been reflecting consistently",
                        subtitle: "You’re noticing your inner patterns"
                    )
                )
            }
        }

        return Array(events.prefix(2))
    }

    // MARK: - Helpers

    private static func hasLog(on day: Date, experiments: [Experiment]) -> Bool {
        let calendar = Calendar.current
        return experiments.contains { experiment in
            experiment.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }
        }
    }

    private static func calculateLogStreak(experiments: [Experiment], today: Date) -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: today)

        for _ in 0..<365 {
            if hasLog(on: checkDate, experiments: experiments) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }

    private static func firstTimeCategoryLoggedToday(experiments: [Experiment], today: Date) -> String? {
        let calendar = Calendar.current
        let todaysCategories = experiments.compactMap { experiment -> String? in
            guard experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) else {
                return nil
            }
            let category = (experiment.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return category.isEmpty ? nil : category
        }

        for category in todaysCategories {
            let existedBeforeToday = experiments.contains { experiment in
                guard (experiment.category ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == category else {
                    return false
                }
                return calendar.startOfDay(for: experiment.createdAt) < today
            }

            if !existedBeforeToday {
                return category
            }
        }

        return nil
    }

    private static func moodLogCountThisWeek(experiments: [Experiment], today: Date) -> Int {
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today)
        return experiments.reduce(0) { total, experiment in
            total + experiment.logs.filter { log in
                guard log.mood != nil else { return false }
                guard let weekInterval else { return false }
                return weekInterval.contains(log.date)
            }.count
        }
    }
}

