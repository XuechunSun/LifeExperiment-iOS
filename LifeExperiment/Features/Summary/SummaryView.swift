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
        let experimentId: UUID
        let title: String
        let delta: Double
        let message: String

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

        return experiments.compactMap { experiment in
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

            let message: String
            if delta >= 0.5 {
                message = "Often linked to better mood"
            } else if delta >= 0.2 {
                message = "Sometimes linked to better mood"
            } else if delta > -0.2 {
                message = "Mood feels fairly similar on these days"
            } else {
                message = "These days may feel more mixed"
            }

            return HelpfulExperimentInsight(
                experimentId: experiment.id,
                title: experiment.title,
                delta: delta,
                message: message
            )
        }
        .sorted { lhs, rhs in
            if lhs.delta != rhs.delta {
                return lhs.delta > rhs.delta
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        .prefix(2)
        .map { $0 }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What Seems to Help")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Experiments that may be supporting your mood.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if helpfulInsights.isEmpty {
                        Text("Patterns will appear as you log more experiments.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(helpfulInsights) { insight in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Experiment · \(insight.title)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(insight.message)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Divider()

                // Module 1: Dimension Insights (v1) - Now at top
                DimensionInsightsView(experiments: experiments)

                Divider()

                // Module 2: Storage Boxes by Category
                StorageBoxesView(experiments: experiments, seedCatalog: seedCatalog, onUpdate: onUpdate)

                // Module 3: Calendar Footprint (hidden for v1, can be restored later)
                if showCalendarFootprint {
                    Divider()

                    CalendarFootprintView(experiments: experiments, onUpdate: onUpdate, onSelectDay: { day in
                        selectedDay = day
                    })
                }
            }
            .padding()
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

