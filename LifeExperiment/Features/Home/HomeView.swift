import SwiftUI

// MARK: - Home View (Main Landing Page)

struct HomeView: View {
    let loadExperiments: () -> [Experiment]
    let seedCatalog: SeedCatalog?
    let onCreateExperiment: () -> Void
    let onSelectExperiment: (Experiment) -> Void
    let onUpdate: (Experiment) -> Void
    let onShowActiveMore: () -> Void
    let onShowCompletedMore: () -> Void
    let onShowSummary: () -> Void
    let onSelectDay: (Date) -> Void
    let onRenameExperiment: (Experiment) -> Void
    let onDuplicateExperiment: (Experiment) -> Void
    let onDeleteExperiment: (Experiment) -> Void

    // MARK: - State Determination

    private var experiments: [Experiment] {
        loadExperiments()
    }

    private var activeExperiments: [Experiment] {
        experiments.filter { $0.status == .active }
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
        if currentState == .updatedToday {
            // State B: Weakened, optional tone
            return "Keep going (optional)"
        } else {
            // State A: Primary CTA
            return "Continue Recording"
        }
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
            VStack(alignment: .leading, spacing: 24) {
                // 1. Calendar Footprint - Always visible
                CalendarFootprintView(experiments: experiments, onUpdate: onUpdate, onSelectDay: onSelectDay)

                Divider()

                // 2. CTA (Emotional Trigger) - Always visible
                VStack(alignment: .leading, spacing: 8) {
                    Text(ctaText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    if let ctaSubtext = ctaSubtext {
                        Text(ctaSubtext)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                // 3. Recent Events - Card style
                if !recentEvents.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text(S.sectionRecentEvents)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        let eventsToShow = Array(recentEvents.prefix(2))

                        if eventsToShow.count == 2 {
                            // Two-column grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(eventsToShow) { event in
                                    RecentEventCard(event: event)
                                }
                            }
                        } else {
                            // Single card
                            ForEach(eventsToShow) { event in
                                RecentEventCard(event: event)
                            }
                        }
                    }
                }

                // 4. Continue Recording - State A (primary) & State B (weakened/optional)
                if shouldShowContinueRecording {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        let isWeakened = (currentState == .updatedToday)

                        HStack {
                            Text(continueRecordingTitle)
                                .font(isWeakened ? .subheadline : .headline)
                                .foregroundColor(isWeakened ? .secondary : .primary)

                            Spacer()

                            if activeExperiments.count > 2 {
                                Button(action: {
                                    onShowActiveMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        ForEach(continuePreview) { experiment in
                            Button(action: {
                                onSelectExperiment(experiment)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(experiment.title)
                                            .font(.subheadline)
                                            .fontWeight(isWeakened ? .regular : .semibold)
                                            .foregroundColor(isWeakened ? .secondary : .primary)

                                        Text("Last updated \(experiment.updatedAt, style: .date)")
                                            .font(isWeakened ? .caption2 : .caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    ExperimentRowMenu(
                                        kind: .active,
                                        onRename: { onRenameExperiment(experiment) },
                                        onDuplicate: { onDuplicateExperiment(experiment) },
                                        onDelete: { onDeleteExperiment(experiment) }
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(isWeakened ? 0.5 : 1.0))
                                .cornerRadius(8)
                            }
                        }
                    }
                }

                // 5. Start New Experiment - Always visible
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text(currentState == .noActiveExperiments ? "Start Your First Experiment" : "Start New Experiment")
                        .font(.headline)

                    Button(action: {
                        onCreateExperiment()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create Experiment")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // 6. Completed - Lightweight section
                if shouldShowCompleted {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(S.sectionCompleted)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            if completedExperiments.count > 2 {
                                Button(action: {
                                    onShowCompletedMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }

                        ForEach(completedPreview) { experiment in
                            Button(action: {
                                onSelectExperiment(experiment)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(experiment.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)

                                        if let completedAt = experiment.completedAt {
                                            Text("Completed \(completedAt, style: .date)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()

                                    ExperimentRowMenu(
                                        kind: .completed,
                                        onDuplicate: { onDuplicateExperiment(experiment) },
                                        onDelete: { onDeleteExperiment(experiment) }
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.7))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Recent Event Card Component

    struct RecentEventCard: View {
        let event: RecentEvent

        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: event.iconSystemName)
                    .font(.headline)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - CTA Text Logic (Quote-based)

    private var ctaText: String {
        let quotes = CTALoader.loadQuotes()
        return CTALoader.pickDailyQuote(from: quotes) ?? "Begin anywhere."
    }

    private var ctaSubtext: String? {
        return nil
    }
}

