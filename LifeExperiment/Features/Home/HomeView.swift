import SwiftUI

// MARK: - Home View (Main Landing Page)

struct HomeView: View {
    let loadExperiments: () -> [Experiment]
    let seedCatalog: SeedCatalog?
    let onCreateExperiment: () -> Void
    let onTrySuggestion: (ExperimentSuggestion) -> Void
    let onSelectExperiment: (Experiment) -> Void
    let onUpdate: (Experiment) -> Void
    let onShowActiveMore: () -> Void
    let onShowCompletedMore: () -> Void
    let onShowSummary: () -> Void
    let onSelectDay: (Date) -> Void
    let onRenameExperiment: (Experiment) -> Void
    let onDuplicateExperiment: (Experiment) -> Void
    let onDeleteExperiment: (Experiment) -> Void

    private static let cachedSuggestions: [ExperimentSuggestion] = ExperimentSuggestionsLoader.load()

    // MARK: - State Determination

    private var experiments: [Experiment] {
        loadExperiments()
    }

    private var activeExperiments: [Experiment] {
        experiments.filter { $0.status == .active }
    }

    private var allSuggestions: [ExperimentSuggestion] {
        Self.cachedSuggestions
    }

    // Helper: Check if experiment was updated on a specific day (created, logged, or completed)
    private func isUpdated(on day: Date, experiment: Experiment) -> Bool {
        let calendar = Calendar.current

        // Check if created on this day
        if calendar.isDate(experiment.createdAt, inSameDayAs: day) {
            return true
        }

        // Check if has log on this day
        if experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            return true
        }

        // Check if completed on this day
        if let completedAt = experiment.completedAt, calendar.isDate(completedAt, inSameDayAs: day) {
            return true
        }

        return false
    }

    // Check if user has updated today (log added, experiment created, or experiment completed today)
    private var hasUpdatedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return experiments.contains { isUpdated(on: today, experiment: $0) }
    }

    // Determine which state we're in
    private enum HomeState {
        case noActiveExperiments      // State C
        case activeButNoUpdatesToday  // State A
        case updatedToday             // State B
    }

    private var currentState: HomeState {
        if activeExperiments.isEmpty {
            return .noActiveExperiments
        } else if hasUpdatedToday {
            return .updatedToday
        } else {
            return .activeButNoUpdatesToday
        }
    }

    private var hasLoggedToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        return experiments.contains { experiment in
            experiment.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: today)
            }
        }
    }

    private var homeGuideState: HomeGuideState {
        if activeExperiments.isEmpty {
            return .noActive
        } else if hasLoggedToday {
            return .loggedToday
        } else {
            return .activeNoLogToday
        }
    }

    private var guideCopy: GuideCopy {
        GuideCopyProvider.copy(for: homeGuideState)
    }

    private var guideSuggestions: [ExperimentSuggestion] {
        suggestions(for: homeGuideState)
    }

    private var personalizedSignal: PersonalizedSuggestionSignal? {
        PersonalizedSuggestionEngine.personalizedSignal(from: experiments)
    }

    private var personalizedSuggestion: ExperimentSuggestion? {
        guard let personalizedSignal else { return nil }
        return PersonalizedSuggestionEngine.personalizedSuggestion(from: personalizedSignal)
    }

    // MARK: - Continue Recording Logic

    // Candidates: active experiments NOT updated today
    private var continueCandidates: [Experiment] {
        let today = Calendar.current.startOfDay(for: Date())

        // Filter out experiments updated today (using same definition as hasUpdatedToday)
        return activeExperiments.filter { experiment in
            !isUpdated(on: today, experiment: experiment)
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    // Preview: at most 2 for Home display
    private var continuePreview: [Experiment] {
        Array(continueCandidates.prefix(2))
    }

    // Show Continue section in State A & B (not C)
    private var shouldShowContinueRecording: Bool {
        currentState != .noActiveExperiments && !continuePreview.isEmpty
    }

    // Title varies by state
    private var continueRecordingTitle: String {
        "Continue"
    }

    // MARK: - Completed Logic

    private var completedExperiments: [Experiment] {
        experiments.filter { $0.status == .completed }.sorted { exp1, exp2 in
            let date1 = exp1.completedAt ?? exp1.updatedAt
            let date2 = exp2.completedAt ?? exp2.updatedAt
            return date1 > date2
        }
    }

    private var completedPreview: [Experiment] {
        Array(completedExperiments.prefix(2))
    }

    private var shouldShowCompleted: Bool {
        !completedExperiments.isEmpty
    }

    // MARK: - Recent Events Logic (using RecentEventBuilder)
    // MARK: - Recent Events (Milestone-based, system-generated)

    private var recentEvents: [RecentEvent] {
        RecentEventBuilder.build(experiments: experiments, today: Date())
    }

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // 1. Calendar Footprint - Always visible
                CalendarFootprintView(experiments: experiments, onUpdate: onUpdate, onSelectDay: onSelectDay)

                sectionDivider

                VStack(alignment: .leading, spacing: 12) {
                    GuideCardView(copy: guideCopy)

                    if let personalizedSuggestion,
                       let personalizedSignal {
                        HomePersonalizedSuggestionSection(
                            signal: personalizedSignal,
                            suggestion: personalizedSuggestion,
                            onTapSuggestion: {
                                onTrySuggestion(personalizedSuggestion)
                            }
                        )
                    }

                    GuideSuggestionsSection(
                        suggestions: guideSuggestions,
                        onStartSuggestion: { suggestion in
                            onTrySuggestion(suggestion)
                        },
                        onExploreMore: {
                            onCreateExperiment()
                        }
                    )
                }

                // 3. Continue Recording - State A (primary) & State B (weakened/optional)
                if shouldShowContinueRecording {
                    sectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        //let isWeakened = hasLoggedToday

                        HStack {
                            Text(continueRecordingTitle)
                                .font(DSText.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            if activeExperiments.count > 2 {
                                Button(action: {
                                    onShowActiveMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(DSText.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        ForEach(continuePreview) { experiment in
                            ExperimentListCard(
                                title: experiment.title,
                                subtitle: "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))",
                                titleWeight: .semibold,
                                surfaceStyle: .activePrimary,
                                contentPadding: DSSpacing.md,
                                action: {
                                    onSelectExperiment(experiment)
                                }
                            ) {
                                ExperimentRowMenu(
                                    kind: .active,
                                    onRename: { onRenameExperiment(experiment) },
                                    onDuplicate: { onDuplicateExperiment(experiment) },
                                    onDelete: { onDeleteExperiment(experiment) }
                                )
                            }
                        }
                    }
                }

                // 5. Recent Events - Card style
                if !recentEvents.isEmpty {
                    sectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        Text(S.sectionRecentEvents)
                            .font(DSText.headline)
                            .foregroundColor(.primary.opacity(0.72))

                        let eventsToShow = Array(recentEvents.prefix(2))
                        ForEach(eventsToShow) { event in
                            RecentEventCard(event: event)
                        }
                    }
                }

                // 6. Completed - Lightweight section
                if shouldShowCompleted {
                    sectionDivider

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(S.sectionCompleted)
                                .font(DSText.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            if completedExperiments.count > 2 {
                                Button(action: {
                                    onShowCompletedMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(DSText.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        ForEach(completedPreview) { experiment in
                            ExperimentListCard(
                                title: experiment.title,
                                subtitle: experiment.completedAt.map {
                                    "Completed \($0.formatted(date: .abbreviated, time: .omitted))"
                                },
                                titleWeight: .medium,
                                surfaceStyle: .completed,
                                contentPadding: DSSpacing.md,
                                action: {
                                    onSelectExperiment(experiment)
                                }
                            ) {
                                ExperimentRowMenu(
                                    kind: .completed,
                                    onDuplicate: { onDuplicateExperiment(experiment) },
                                    onDelete: { onDeleteExperiment(experiment) }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var sectionDivider: some View {
        Divider()
            .overlay(Color.primary.opacity(0.05))
    }

    // MARK: - Recent Event Card Component

    struct RecentEventCard: View {
        let event: RecentEvent

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: event.iconSystemName)
                    .font(DSText.subheadline)
                    .foregroundColor(.orange.opacity(0.8))
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(DSText.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .font(DSText.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.05),
                        Color.pink.opacity(0.035)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func suggestions(for state: HomeGuideState) -> [ExperimentSuggestion] {
        let unusedSuggestions = allSuggestions.filter { suggestion in
            !usedExperimentTitles.contains(normalizedTitle(suggestion.title))
        }
        let prioritized: [ExperimentSuggestion]

        switch state {
        case .noActive:
            prioritized = unusedSuggestions.filter { $0.mode == .starter || $0.effort == .low }
        case .activeNoLogToday:
            prioritized = unusedSuggestions.filter { $0.mode == .reset || $0.mode == .reflective }
        case .loggedToday:
            let primary = unusedSuggestions.filter { $0.mode == .social || $0.mode == .reflective }
            let fallback = unusedSuggestions.filter { $0.mode == .starter }
            prioritized = deduplicatedSuggestions(primary + fallback)
        }

        var selected = pickDiverseSuggestions(from: prioritized, limit: 3)

        if selected.count < 3 {
            let otherUnused = deduplicatedSuggestions(unusedSuggestions.filter { suggestion in
                !selected.contains(where: { $0.id == suggestion.id })
            })
            selected += pickDiverseSuggestions(from: otherUnused, limit: 3 - selected.count)
        }

        if selected.count < 3 {
            let anyRemaining = deduplicatedSuggestions(allSuggestions.filter { suggestion in
                !selected.contains(where: { $0.id == suggestion.id })
            })
            selected += pickDiverseSuggestions(from: anyRemaining, limit: 3 - selected.count)
        }

        return Array(selected.prefix(3))
    }

    private func deduplicatedSuggestions(_ suggestions: [ExperimentSuggestion]) -> [ExperimentSuggestion] {
        var seen = Set<String>()
        return suggestions.filter { suggestion in
            seen.insert(suggestion.id).inserted
        }
    }

    private var usedExperimentTitles: Set<String> {
        Set(experiments.map { normalizedTitle($0.title) })
    }

    private func normalizedTitle(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func pickDiverseSuggestions(from suggestions: [ExperimentSuggestion], limit: Int) -> [ExperimentSuggestion] {
        guard limit > 0 else { return [] }

        var picks: [ExperimentSuggestion] = []
        var usedCategories = Set<String>()

        for suggestion in suggestions where picks.count < limit {
            if !usedCategories.contains(suggestion.category) {
                picks.append(suggestion)
                usedCategories.insert(suggestion.category)
            }
        }

        if picks.count < limit {
            for suggestion in suggestions where picks.count < limit {
                if !picks.contains(where: { $0.id == suggestion.id }) {
                    picks.append(suggestion)
                }
            }
        }

        return picks
    }
}

