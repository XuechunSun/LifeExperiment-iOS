import Foundation

struct PersonalizedSuggestionSignal {
    let topDimension: Dimension
    let weakestDimension: Dimension
}

enum PersonalizedSuggestionEngine {
    static func personalizedSignal(from experiments: [Experiment]) -> PersonalizedSuggestionSignal? {
        let dimensionDays = dimensionDays(from: experiments)
        guard let topDimension = topDimension(from: dimensionDays) else { return nil }

        let weakestDimension = Dimension.allCases.min { lhs, rhs in
            let lhsDays = dimensionDays[lhs] ?? 0
            let rhsDays = dimensionDays[rhs] ?? 0
            if lhsDays != rhsDays {
                return lhsDays < rhsDays
            }
            let lhsIndex = Dimension.allCases.firstIndex(of: lhs) ?? 0
            let rhsIndex = Dimension.allCases.firstIndex(of: rhs) ?? 0
            return lhsIndex < rhsIndex
        }

        guard let weakestDimension else { return nil }
        guard (dimensionDays[topDimension] ?? 0) > (dimensionDays[weakestDimension] ?? 0) else { return nil }

        return PersonalizedSuggestionSignal(topDimension: topDimension, weakestDimension: weakestDimension)
    }

    static func personalizedSuggestion(from signal: PersonalizedSuggestionSignal) -> ExperimentSuggestion? {
        switch signal.weakestDimension {
        case .connection:
            return ExperimentSuggestion(
                id: "personal_connection_reach_out",
                title: "Reach out to someone you trust today",
                category: "Connection",
                prefillCategoryTitle: "Life List",
                prefillSubcategoryTitle: "New Experiences",
                effort: .low,
                mode: .social,
                tags: ["personalized", "connection"]
            )
        case .self_understanding:
            return ExperimentSuggestion(
                id: "personal_self_honest_thought",
                title: "Write down one honest thought today",
                category: "Self-Understanding",
                prefillCategoryTitle: "Life Reset",
                prefillSubcategoryTitle: "Self Reflection",
                effort: .low,
                mode: .reflective,
                tags: ["personalized", "self"]
            )
        case .emotion_awareness:
            return ExperimentSuggestion(
                id: "personal_emotion_notice_feeling",
                title: "Pause and notice how you feel right now",
                category: "Emotional Awareness",
                prefillCategoryTitle: "Emotional Care",
                prefillSubcategoryTitle: "Emotional Awareness",
                effort: .low,
                mode: .reflective,
                tags: ["personalized", "emotional"]
            )
        case .expression_creativity:
            return ExperimentSuggestion(
                id: "personal_expression_write_three_minutes",
                title: "Write for 3 minutes without editing",
                category: "Expression & Creativity",
                prefillCategoryTitle: "Life List",
                prefillSubcategoryTitle: "Creative Expression",
                effort: .low,
                mode: .reflective,
                tags: ["personalized", "expression"]
            )
        case .body_energy:
            return ExperimentSuggestion(
                id: "personal_body_take_walk",
                title: "Take a 10-minute walk without your phone",
                category: "Body & Energy",
                prefillCategoryTitle: "Well-being Habits",
                prefillSubcategoryTitle: "Movement",
                effort: .low,
                mode: .starter,
                tags: ["personalized", "body"]
            )
        case .execution:
            return ExperimentSuggestion(
                id: "personal_execution_small_task",
                title: "Start one small task you've been postponing",
                category: "Execution",
                prefillCategoryTitle: "30-Day Challenge",
                prefillSubcategoryTitle: "Daily Discipline",
                effort: .low,
                mode: .starter,
                tags: ["personalized", "execution"]
            )
        case .focus_flow:
            return ExperimentSuggestion(
                id: "personal_focus_ten_quiet_minutes",
                title: "Give one task 10 quiet minutes today",
                category: "Focus & Flow",
                prefillCategoryTitle: "30-Day Challenge",
                prefillSubcategoryTitle: "Skill Sprint",
                effort: .low,
                mode: .reset,
                tags: ["personalized", "focus"]
            )
        }
    }

    private static func dimensionDays(from experiments: [Experiment]) -> [Dimension: Int] {
        var dayCounts: [Dimension: Set<Date>] = [:]
        let calendar = Calendar.current

        for dimension in Dimension.allCases {
            dayCounts[dimension] = Set<Date>()
        }

        let eligibleExperiments = experiments.filter { experiment in
            (experiment.status == .active || experiment.status == .completed) &&
            experiment.impact != nil &&
            !validLogDays(for: experiment, calendar: calendar).isEmpty
        }

        for experiment in eligibleExperiments {
            guard let impact = experiment.impact else { continue }
            let validDays = validLogDays(for: experiment, calendar: calendar)

            dayCounts[impact.primary]?.formUnion(validDays)
            if let secondary = impact.secondary {
                dayCounts[secondary]?.formUnion(validDays)
            }
            if let tertiary = impact.tertiary {
                dayCounts[tertiary]?.formUnion(validDays)
            }
        }

        return dayCounts.mapValues { $0.count }
    }

    private static func topDimension(from dimensionDays: [Dimension: Int]) -> Dimension? {
        dimensionDays
            .filter { $0.value > 0 }
            .sorted { lhs, rhs in
                if lhs.value != rhs.value {
                    return lhs.value > rhs.value
                }
                let lhsIndex = Dimension.allCases.firstIndex(of: lhs.key) ?? 0
                let rhsIndex = Dimension.allCases.firstIndex(of: rhs.key) ?? 0
                return lhsIndex < rhsIndex
            }
            .first?
            .key
    }

    private static func validLogDays(for experiment: Experiment, calendar: Calendar) -> Set<Date> {
        Set(experiment.logs.compactMap { log -> Date? in
            let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedNote.isEmpty || log.mood != nil else { return nil }
            return calendar.startOfDay(for: log.date)
        })
    }
}
