import SwiftUI

// MARK: - Summary View (Week 4 Structure)

struct SummaryView: View {
    let loadExperiments: () -> [Experiment]
    var lowEnergyLogs: [LowEnergyLog] = []
    let onUpdate: (Experiment) -> Void
    let seedCatalog: SeedCatalog?

    @State private var showFullCalendar: Bool = false
    @State private var selectedDay: Date?

    @AppStorage("app_language") private var appLanguageRaw: String = ""

    // Toggle to show/hide Calendar Footprint (currently hidden for v1)
    private let showCalendarFootprint: Bool = false

    var experiments: [Experiment] {
        loadExperiments()
    }

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

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
        let limitedComparison: Bool
        let finalScore: Double

        var id: UUID { experimentId }
    }

    // MARK: - Insight Ranking V2

    // TODO: Future ranking improvements (do not implement now):
    // - Delta normalization: scale delta relative to user's personal mood variance
    //   to avoid penalizing users with naturally narrow mood ranges
    // - Multi-experiment interaction modeling: account for days where multiple
    //   experiments overlap, which may amplify or mask individual effects

    private var helpfulInsights: [HelpfulExperimentInsight] {
        let calendar = Calendar.current

        struct MoodEntry {
            let experimentId: UUID
            let day: Date
            let score: Double
        }

        struct DayMood {
            let day: Date
            let avgScore: Double
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

        let allMoodDays: [DayMood] = Dictionary(grouping: moodEntries, by: \.day)
            .map { DayMood(day: $0.key, avgScore: $0.value.map(\.score).reduce(0, +) / Double($0.value.count)) }

        #if DEBUG
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("[INSIGHT V2] total experiments: \(experiments.count)")
        print("[INSIGHT V2] total mood entries: \(moodEntries.count)  unique mood days: \(allMoodDays.count)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif

        let scored: [HelpfulExperimentInsight] = experiments.compactMap { (experiment: Experiment) -> HelpfulExperimentInsight? in

            // Step 1: experiment days with mood
            let experimentEntries = moodEntries.filter { $0.experimentId == experiment.id }
            let experimentDays = Set(experimentEntries.map(\.day))

            // Step 3: minimum inclusion — skip if fewer than 3 mood logs
            guard experimentEntries.count >= 3 else {
                #if DEBUG
                print("[FILTERED OUT] \"\(experiment.title)\" — only \(experimentEntries.count) mood log(s), need ≥3")
                #endif
                return nil
            }

            // Step 2: time-windowed comparison days
            // Only compare against days AFTER this experiment was created where
            // this experiment was NOT logged.
            //
            // NOTE: This comparison set may include days where other experiments
            // are active, making the baseline a "mixed state" rather than a clean
            // no-experiment control. This is acceptable for MVP.
            // TODO: Future improvement options:
            //   Option A: Compare only against "no-experiment days" for a cleaner baseline
            //   Option B: Down-weight multi-experiment days in comparison scoring
            let creationDay = calendar.startOfDay(for: experiment.createdAt)
            let comparisonDays = allMoodDays.filter { $0.day >= creationDay && !experimentDays.contains($0.day) }
            let comparisonDayCount = comparisonDays.count

            // Step 4: delta with zero-comparison safety
            let experimentAvg = experimentEntries.map(\.score).reduce(0, +) / Double(experimentEntries.count)
            let delta: Double
            if comparisonDays.isEmpty {
                delta = 0
            } else {
                let comparisonAvg = comparisonDays.map(\.avgScore).reduce(0, +) / Double(comparisonDayCount)
                delta = experimentAvg - comparisonAvg
            }

            // Step 5: base confidence
            let baseConfidence: HelpfulExperimentInsight.Confidence
            if experimentEntries.count >= 14 && delta >= 0.5 {
                baseConfidence = .high
            } else if experimentEntries.count >= 7 && abs(delta) >= 0.3 {
                baseConfidence = .medium
            } else {
                baseConfidence = .low
            }

            // Step 6: limited-comparison downgrade
            let limitedComparison = comparisonDayCount < 3
            let effectiveConfidence: HelpfulExperimentInsight.Confidence
            if limitedComparison {
                switch baseConfidence {
                case .high: effectiveConfidence = .medium
                case .medium, .low: effectiveConfidence = .low
                }
            } else {
                effectiveConfidence = baseConfidence
            }

            // Step 7: final score
            let confidenceWeight: Double
            switch effectiveConfidence {
            case .high: confidenceWeight = 1.0
            case .medium: confidenceWeight = 0.75
            case .low: confidenceWeight = 0.5
            }
            let comparisonPenalty: Double = limitedComparison ? 0.7 : 1.0
            let finalScore = delta * confidenceWeight * comparisonPenalty

            #if DEBUG
            let baseStr = baseConfidence == .high ? "HIGH" : baseConfidence == .medium ? "MEDIUM" : "LOW"
            let effStr = effectiveConfidence == .high ? "HIGH" : effectiveConfidence == .medium ? "MEDIUM" : "LOW"
            print("[INSIGHT V2] \"\(experiment.title)\"")
            print("  expDays=\(experimentEntries.count)  compDays=\(comparisonDayCount)  delta=\(String(format: "%.3f", delta))")
            print("  baseConf=\(baseStr)  limitedComp=\(limitedComparison)  effConf=\(effStr)")
            print("  finalScore=\(String(format: "%.3f", finalScore))")
            #endif

            // Step 9: message generation
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
                message = "These days feel a bit more mixed for you"
            } else if abs(delta) <= 0.2 {
                message = "Feels fairly similar on these days"
            } else if effectiveConfidence == .high {
                message = "Often linked to better \(signalTypeText)"
            } else if effectiveConfidence == .medium {
                message = "Sometimes linked to better \(signalTypeText)"
            } else {
                message = "A possible pattern with your \(signalTypeText)"
            }

            return HelpfulExperimentInsight(
                experimentId: experiment.id,
                title: experiment.title,
                delta: delta,
                message: message,
                experimentDayCount: experimentEntries.count,
                confidence: effectiveConfidence,
                limitedComparison: limitedComparison,
                finalScore: finalScore
            )
        }

        // Step 8: ranking with positive-delta preference
        func scoreSort(_ lhs: HelpfulExperimentInsight, _ rhs: HelpfulExperimentInsight) -> Bool {
            if lhs.finalScore != rhs.finalScore { return lhs.finalScore > rhs.finalScore }
            if lhs.delta != rhs.delta { return lhs.delta > rhs.delta }
            if lhs.experimentDayCount != rhs.experimentDayCount { return lhs.experimentDayCount > rhs.experimentDayCount }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        let positive = scored.filter { $0.delta > 0 }.sorted(by: scoreSort)
        let nonPositive = scored.filter { $0.delta <= 0 }.sorted(by: scoreSort)
        let ranked = positive + nonPositive

        #if DEBUG
        print("\n[RANKED ORDER — all \(ranked.count) candidates, positive-first]")
        for (i, insight) in ranked.enumerated() {
            let conf = insight.confidence == .high ? "HIGH" : insight.confidence == .medium ? "MEDIUM" : "LOW"
            let group = insight.delta > 0 ? "+" : "≤0"
            print("  #\(i + 1)  [\(group)] score=\(String(format: "%.3f", insight.finalScore))  conf=\(conf)  delta=\(String(format: "%.3f", insight.delta))  days=\(insight.experimentDayCount)  limited=\(insight.limitedComparison)  \"\(insight.title)\"")
        }
        let top2 = Array(ranked.prefix(2))
        print("\n[TOP 2 SELECTED]")
        for (i, insight) in top2.enumerated() {
            print("  #\(i + 1)  \"\(insight.title)\"  →  \"\(insight.message)\"")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        #endif

        // Step 9: top-2 selection with second-slot copy tweak
        return ranked
        .prefix(2)
        .enumerated()
        .map { index, insight in
            guard index == 1,
                  insight.message.hasPrefix("A possible pattern with your ") else {
                return insight
            }

            return HelpfulExperimentInsight(
                experimentId: insight.experimentId,
                title: insight.title,
                delta: insight.delta,
                message: insight.message.replacingOccurrences(
                    of: "A possible pattern with your ",
                    with: "A lighter signal around your "
                ),
                experimentDayCount: insight.experimentDayCount,
                confidence: insight.confidence,
                limitedComparison: insight.limitedComparison,
                finalScore: insight.finalScore
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

    // CL#4: Distinct calendar days with a LowEnergyLog
    private var gentleDayCount: Int {
        let calendar = Calendar.current
        let days = Set(lowEnergyLogs.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                HighlightCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white.opacity(0.9))
                            Text(L.smallPattern(lang))
                                .font(DSText.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        if let insight = primaryHelpfulInsight {
                            Text(L.highlightFeltBetterOnDaysDid(
                                lang,
                                experimentTitle: BuiltInTitleDisplay.localizedTitle(stored: insight.title, lang: lang)
                            ))
                                .font(DSFont.accent(size: 22, relativeTo: .title3))
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(insight.limitedComparison
                                ? L.basedOnLoggedDaysEarly(lang, days: insight.experimentDayCount)
                                : L.basedOnLoggedDays(lang, days: insight.experimentDayCount))
                                .font(DSText.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text(L.highlightEmptyEncouragement(lang))
                                .font(DSFont.accent(size: 22, relativeTo: .title3))
                                .foregroundColor(.white)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if gentleDayCount > 0 {
                            Text(L.highlightGentleDaysAlong(lang, count: gentleDayCount))
                                .font(DSText.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, DSInset.pageHorizontal)

                // Module 1: Dimension Insights (v1) - Now at top
                DimensionInsightsView(experiments: experiments)
                    .padding(.horizontal, DSInset.pageHorizontal)

                // Module 2: Storage boxes / context
                SectionBlock(
                    title: L.whereExploring(lang),
                    subtitle: L.whereExploringSubtitle(lang),
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
        .navigationTitle(L.summary(lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationDestination(isPresented: $showFullCalendar) {
            FullCalendarView(loggedDates: loggedDates, experiments: experiments, lowEnergyLogs: lowEnergyLogs, onUpdate: onUpdate)
        }
        .navigationDestination(item: $selectedDay) { day in
            DayDetailView(day: day, experiments: experiments, lowEnergyLogs: lowEnergyLogs, onUpdate: onUpdate)
        }
    }
}

