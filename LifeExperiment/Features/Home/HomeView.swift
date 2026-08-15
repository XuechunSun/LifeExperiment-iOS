import SwiftUI

// MARK: - Home View (Main Landing Page)

struct HomeView: View {
    let loadExperiments: () -> [Experiment]
    let lowEnergyLogs: [LowEnergyLog]
    let seedCatalog: SeedCatalog?
    let onCreateExperiment: () -> Void
    let onStartLowEnergy: () -> Void
    let onTrySuggestion: (ExperimentSuggestion) -> Void
    let onSelectExperiment: (Experiment) -> Void
    /// Opens an experiment scrolled to its History section.
    let onSelectExperimentHistory: (Experiment) -> Void
    let onUpdate: (Experiment) -> Void
    let onShowActiveMore: () -> Void
    let onShowCompletedMore: () -> Void
    let onShowSummary: () -> Void
    let onSelectDay: (Date) -> Void
    let onRenameExperiment: (Experiment) -> Void
    let onDuplicateExperiment: (Experiment) -> Void
    let onDeleteExperiment: (Experiment) -> Void

    @AppStorage("app_language") private var appLanguageRaw: String = ""

    private static let cachedSuggestions: [ExperimentSuggestion] = ExperimentSuggestionsLoader.load()

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

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
        GuideCopyProvider.stableCopy(for: homeGuideState, lang: lang)
    }

    private var hasLoggedLowEnergyToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        return lowEnergyLogs.contains { calendar.isDate($0.date, inSameDayAs: today) }
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

    // Phase 5.1: Continue Recording uses a *log-only* "updated today" check
    // instead of the broader `isUpdated(on:experiment:)` helper. Creating an
    // experiment (or completing it) does not count as "recorded today" for
    // this section — only an actual daily log does. This ensures a newly
    // created experiment with no log yet (including the onboarding starter)
    // shows up in Continue Recording.
    //
    // Other Home consumers (`hasUpdatedToday`, RecentEventBuilder, Calendar)
    // intentionally still treat creation as activity and are unchanged.
    private func hasLog(on day: Date, experiment: Experiment) -> Bool {
        let calendar = Calendar.current
        return experiment.logs.contains { calendar.isDate($0.date, inSameDayAs: day) }
    }

    // Candidates: active experiments with no log for today.
    private var continueCandidates: [Experiment] {
        let today = Calendar.current.startOfDay(for: Date())

        return activeExperiments.filter { experiment in
            !hasLog(on: today, experiment: experiment)
        }.sorted { $0.updatedAt > $1.updatedAt }
    }

    // Preview: at most 2 for Home display
    private var continuePreview: [Experiment] {
        Array(continueCandidates.prefix(2))
    }

    // The Today hero card mirrors the top-ranked Continue candidate, so both
    // sections always agree on which experiment is "next up".
    private var heroExperiment: Experiment? {
        continueCandidates.first
    }

    // Show Continue section in State A & B (not C)
    private var shouldShowContinueRecording: Bool {
        currentState != .noActiveExperiments && !continuePreview.isEmpty
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
        RecentEventBuilder.build(experiments: experiments, today: Date(), lang: lang)
    }

    // MARK: - UI

    // Final Home section ordering (v1.1 Phase 5):
    //   1. Today hero card                       — when heroExperiment exists
    //   2. CalendarFootprintView                 — always
    //   3. GuideCardView (Purple Guide CTA)      — always, atmosphere / orientation
    //   4. Continue Recording                    — when shouldShowContinueRecording
    //   5. Worth Noticing (Personalized)         — when personalizedSuggestion exists
    //   6. Try Something New (GuideSuggestions)  — always
    //   7. Recent Moments                        — when recentEvents is non-empty
    //   8. Completed                             — when shouldShowCompleted
    //
    // Steps 4–6 share a tight 12pt action cluster (matching the old inner
    // Guide cluster rhythm). The three states (no-active / active no-update /
    // updated-today) drop out of this single ordering automatically via the
    // existing `shouldShowContinueRecording` and `personalizedSuggestion`
    // predicates — no per-state branching needed.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                if let heroExperiment {
                    todaySection(experiment: heroExperiment)
                }

                CalendarFootprintView(experiments: experiments, lowEnergyLogs: lowEnergyLogs, onUpdate: onUpdate, onSelectDay: onSelectDay)

                // Purple Guide CTA — always directly under Calendar so the
                // brand-orientation atmosphere stays in place regardless of
                // user state.
                GuideCardView(copy: guideCopy)

                VStack(alignment: .leading, spacing: 12) {
                    if shouldShowContinueRecording {
                        continueSection
                            .padding(.bottom, DSSpacing.md)
                    }

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
                        },
                        onTakeItEasy: { onStartLowEnergy() },
                        hasLoggedLowEnergyToday: hasLoggedLowEnergyToday
                    )
                }

                if !recentEvents.isEmpty {
                    recentSection
                }

                if shouldShowCompleted {
                    completedSection
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.top, DSSpacing.sm)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Extracted action sections (Phase 5 reorder helpers)

    @ViewBuilder
    private func todaySection(experiment: Experiment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L.todaySection(lang))
                .font(DSText.section)
                .foregroundColor(.primary)

            TodayHeroCard(
                experiment: experiment,
                lang: lang,
                onOpen: { onSelectExperiment(experiment) },
                onReadMore: { onSelectExperimentHistory(experiment) }
            )
        }
    }

    @ViewBuilder
    private var continueSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L.continueText(lang))
                    .font(DSText.headline)
                    .foregroundColor(.primary)

                Spacer()

                if activeExperiments.count > 2 {
                    Button(action: {
                        onShowActiveMore()
                    }) {
                        Text(L.seeMore(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(primaryLavenderButton)
                    }
                }
            }

            ForEach(continuePreview) { experiment in
                ExperimentListCard(
                    title: BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang),
                    subtitle: L.homeContinueLastUpdated(
                        lang,
                        dateString: experiment.updatedAt.formatted(date: .abbreviated, time: .omitted)
                    ),
                    titleWeight: .semibold,
                    surfaceStyle: .continueReturn,
                    contentPadding: DSSpacing.lg,
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

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L.recentMoments(lang))
                .font(DSText.subheadline)
                .foregroundColor(.primary.opacity(0.65))

            let eventsToShow = Array(recentEvents.prefix(2))
            ForEach(eventsToShow) { event in
                RecentEventCard(event: event)
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L.sectionCompleted(lang))
                    .font(DSText.subheadline)
                    .foregroundColor(.primary.opacity(0.65))

                Spacer()

                if completedExperiments.count > 2 {
                    Button(action: {
                        onShowCompletedMore()
                    }) {
                        Text(L.seeMore(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(primaryLavenderButton)
                    }
                }
            }

            ForEach(completedPreview) { experiment in
                ExperimentListCard(
                    title: BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang),
                    subtitle: experiment.completedAt.map { completedAt in
                        L.homeCompletedOn(
                            lang,
                            dateString: completedAt.formatted(date: .abbreviated, time: .omitted)
                        )
                    },
                    titleWeight: .medium,
                    surfaceStyle: .completed,
                    contentPadding: DSSpacing.sm,
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

    // MARK: - Recent Event Card Component

    struct RecentEventCard: View {
        let event: RecentEvent

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: event.iconSystemName)
                    .font(DSText.subheadline)
                    .foregroundColor(Color.orange.opacity(0.65))
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(DSText.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary.opacity(0.88))

                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .font(DSText.caption)
                            .foregroundColor(.secondary.opacity(0.9))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(DSSpacing.sm)
            .background(
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.03),
                        Color.pink.opacity(0.018)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.035), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

