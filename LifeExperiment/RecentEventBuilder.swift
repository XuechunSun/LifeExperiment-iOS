import Foundation

struct RecentEventBuilder {

    static func build(experiments: [Experiment], today: Date, lang: AppLanguage) -> [RecentEvent] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)

        var events: [RecentEvent] = []

        // 1. Milestones
        if let milestoneEvent = milestoneEvent(experiments: experiments, today: todayStart, lang: lang) {
            events.append(milestoneEvent)
        }

        // 2. Consistency
        let streak = calculateLogStreak(experiments: experiments, today: todayStart)
        if streak >= 2 {
            events.append(
                RecentEvent(
                    iconSystemName: RecentEventTemplate.Icon.streak,
                    title: L.homeRecentStreakTitle(lang, streakDays: streak),
                    subtitle: L.homeRecentStreakSubtitle(lang)
                )
            )
        }

        // 3. Exploration
        if events.count < 2 {
            if let rawCategory = firstTimeCategoryLoggedToday(experiments: experiments, today: todayStart) {
                let displayCategory = SeedTaxonomyDisplay.displayCategory(stored: rawCategory, lang: lang)
                if !displayCategory.isEmpty {
                    events.append(
                        RecentEvent(
                            iconSystemName: RecentEventTemplate.Icon.firstTime,
                            title: L.homeRecentFirstTimeTitle(lang, categoryName: displayCategory),
                            subtitle: L.homeRecentFirstTimeSubtitle(lang)
                        )
                    )
                }
            }
        }

        // 4. Growth
        if events.count < 2 {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: todayStart)!
            if hasLog(on: todayStart, experiments: experiments) && !hasLog(on: yesterday, experiments: experiments) {
                events.append(
                    RecentEvent(
                        iconSystemName: "leaf.fill",
                        title: L.homeRecentShowedUpTitle(lang),
                        subtitle: L.homeRecentShowedUpSubtitle(lang)
                    )
                )
            }
        }

        // 5. Awareness
        if events.count < 2 {
            let moodLogCount = moodLogCountThisWeek(experiments: experiments, today: todayStart)
            if moodLogCount >= 3 {
                events.append(
                    RecentEvent(
                        iconSystemName: "brain.head.profile",
                        title: L.homeRecentReflectionTitle(lang),
                        subtitle: L.homeRecentReflectionSubtitle(lang)
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

    private static func milestoneEvent(experiments: [Experiment], today: Date, lang: AppLanguage) -> RecentEvent? {
        let calendar = Calendar.current

        guard let anchorDate = milestoneAnchorDate(experiments: experiments, calendar: calendar) else {
            return nil
        }

        let daysSinceAnchor = calendar.dateComponents([.day], from: anchorDate, to: today).day ?? -1

        switch daysSinceAnchor {
        case 0:
            return RecentEvent(
                iconSystemName: "heart.fill",
                title: L.homeRecentMilestoneFirstDayTitle(lang),
                subtitle: L.homeRecentMilestoneFirstDaySubtitle(lang)
            )
        case 6:
            return RecentEvent(
                iconSystemName: "sparkles",
                title: L.homeRecentMilestone7DaysTitle(lang),
                subtitle: L.homeRecentMilestone7DaysSubtitle(lang)
            )
        case 29:
            return RecentEvent(
                iconSystemName: "sparkles",
                title: L.homeRecentMilestone30DaysTitle(lang),
                subtitle: L.homeRecentMilestone30DaysSubtitle(lang)
            )
        default:
            return nil
        }
    }

    private static func milestoneAnchorDate(experiments: [Experiment], calendar: Calendar) -> Date? {
        let earliestValidLogDate = experiments
            .flatMap(\.logs)
            .compactMap { log -> Date? in
                guard isValidMilestoneLog(log) else { return nil }
                return calendar.startOfDay(for: log.date)
            }
            .min()

        if let earliestValidLogDate {
            return earliestValidLogDate
        }

        return experiments
            .map { calendar.startOfDay(for: $0.createdAt) }
            .min()
    }

    private static func isValidMilestoneLog(_ log: DailyLog) -> Bool {
        let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedNote.isEmpty || log.mood != nil
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

