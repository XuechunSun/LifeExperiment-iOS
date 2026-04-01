import SwiftUI

// MARK: - Summary View (Week 4 Structure)

struct SummaryView: View {
    let loadExperiments: () -> [Experiment]
    let onUpdate: (Experiment) -> Void
    let seedCatalog: SeedCatalog?

    @State private var showFullCalendar: Bool = false
    @State private var selectedDay: Date?

    // Toggle to show/hide Calendar Footprint (currently hidden for v1)
    private let showCalendarFootprint: Bool = false

    var experiments: [Experiment] {
        loadExperiments()
    }

    private var loggedDates: Set<Date> {
        let calendar = Calendar.current
        var dates = Set<Date>()

        for experiment in experiments {
            dates.insert(calendar.startOfDay(for: experiment.createdAt))
            dates.insert(calendar.startOfDay(for: experiment.updatedAt))
            for log in experiment.logs {
                dates.insert(calendar.startOfDay(for: log.date))
            }
            if let completedAt = experiment.completedAt {
                dates.insert(calendar.startOfDay(for: completedAt))
            }
        }

        return dates
    }

    private struct HelpfulExperimentInsight: Identifiable {
        enum Confidence: Int {
            case low = 0
            case medium = 1
            case high = 2
        }

        let experimentId: UUID
        let title: String
        let delta: Double
        let message: String
        let experimentDayCount: Int
        let confidence: Confidence

        var id: UUID { experimentId }
    }

    private var helpfulInsights: [HelpfulExperimentInsight] {
        let calendar = Calendar.current

        struct MoodEntry {
            let experimentId: UUID
            let day: Date
            let score: Double
        }

        let moodEntries: [MoodEntry] = experiments.flatMap { experiment in
            experiment.logs.compactMap { log in
                guard let score = moodScore(for: log.mood) else { return nil }
                return MoodEntry(
                    experimentId: experiment.id,
                    day: calendar.startOfDay(for: log.date),
                    score: score
                )
            }
        }

        return experiments.compactMap { (experiment: Experiment) -> HelpfulExperimentInsight? in
            let experimentEntries = moodEntries.filter { $0.experimentId == experiment.id }
            guard experimentEntries.count >= 3 else { return nil }

            let experimentDays = Set(experimentEntries.map(\.day))
            let comparisonEntries = moodEntries.filter { entry in
                !experimentDays.contains(entry.day)
            }
            guard comparisonEntries.count >= 3 else { return nil }

            let experimentAvg = experimentEntries.map(\.score).reduce(0, +) / Double(experimentEntries.count)
            let comparisonAvg = comparisonEntries.map(\.score).reduce(0, +) / Double(comparisonEntries.count)
            let delta = experimentAvg - comparisonAvg

            let confidence: HelpfulExperimentInsight.Confidence
            if experimentEntries.count >= 14 && delta >= 0.5 {
                confidence = .high
            } else if experimentEntries.count >= 7 && delta >= 0.3 {
                confidence = .medium
            } else {
                confidence = .low
            }

            let signalTypeText: String = {
                let categoryText = (experiment.category ?? "").lowercased()
                let titleText = experiment.title.lowercased()
                let combined = "\(categoryText) \(titleText)"

                if combined.contains("emotional") { return "emotional state" }
                if combined.contains("body") || combined.contains("health") || combined.contains("fitness") { return "energy" }
                if combined.contains("focus") || combined.contains("work") || combined.contains("productivity") { return "focus" }
                if combined.contains("creative") || combined.contains("expression") { return "creativity" }
                if combined.contains("social") || combined.contains("connection") { return "connection" }
                return "mood"
            }()

            let message: String
            if delta <= -0.2 {
                message = "These days may feel more mixed"
            } else if delta < 0.2 {
                message = "Feels fairly similar on these days"
            } else if confidence == .high {
                message = "Often linked to better \(signalTypeText)"
            } else if confidence == .medium {
                message = "Sometimes linked to better \(signalTypeText)"
            } else {
                message = "This might be helping your \(signalTypeText)"
            }

            return HelpfulExperimentInsight(
                experimentId: experiment.id,
                title: experiment.title,
                delta: delta,
                message: message,
                experimentDayCount: experimentEntries.count,
                confidence: confidence
            )
        }
        .sorted { (lhs: HelpfulExperimentInsight, rhs: HelpfulExperimentInsight) in
            if lhs.confidence.rawValue != rhs.confidence.rawValue {
                return lhs.confidence.rawValue > rhs.confidence.rawValue
            }
            if lhs.delta != rhs.delta {
                return lhs.delta > rhs.delta
            }
            if lhs.experimentDayCount != rhs.experimentDayCount {
                return lhs.experimentDayCount > rhs.experimentDayCount
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        .prefix(2)
        .enumerated()
        .map { index, insight in
            guard index == 1,
                  insight.message.hasPrefix("This might be helping your ") else {
                return insight
            }

            return HelpfulExperimentInsight(
                experimentId: insight.experimentId,
                title: insight.title,
                delta: insight.delta,
                message: insight.message.replacingOccurrences(
                    of: "This might be helping your ",
                    with: "A lighter version of this may be helping your "
                ),
                experimentDayCount: insight.experimentDayCount,
                confidence: insight.confidence
            )
        }
    }

    private func moodScore(for mood: Mood?) -> Double? {
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

    private var primaryHelpfulInsight: HelpfulExperimentInsight? {
        helpfulInsights.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                HighlightCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white.opacity(0.9))
                            Text("A small pattern I'm noticing")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        if let insight = primaryHelpfulInsight {
                            Text("You felt better on days you did \(insight.title)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("You've shown up for this on \(insight.experimentDayCount) days.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Patterns can start to show up as you keep showing up")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, DSInset.pageHorizontal)

                // Module 1: Dimension Insights (v1) - Now at top
                DimensionInsightsView(experiments: experiments)
                    .padding(.horizontal, DSInset.pageHorizontal)

                // Module 2: Storage boxes / context
                SectionBlock(
                    title: "Where you’ve been exploring",
                    subtitle: "The life areas your experiments have touched so far.",
                    style: .storage
                ) {
                    StorageBoxesView(experiments: experiments, seedCatalog: seedCatalog, onUpdate: onUpdate)
                }
                .padding(.horizontal, DSInset.pageHorizontal)

                // Module 3: Calendar Footprint (hidden for v1, can be restored later)
                if showCalendarFootprint {
                    CalendarFootprintView(experiments: experiments, onUpdate: onUpdate, onSelectDay: { day in
                        selectedDay = day
                    })
                    .padding(.horizontal, DSInset.pageHorizontal)
                }
            }
            .padding(.vertical, DSSpacing.md)
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showFullCalendar) {
            FullCalendarView(loggedDates: loggedDates, experiments: experiments, onUpdate: onUpdate)
        }
        .navigationDestination(item: $selectedDay) { day in
            DayDetailView(day: day, experiments: experiments, onUpdate: onUpdate)
        }
    }
}

