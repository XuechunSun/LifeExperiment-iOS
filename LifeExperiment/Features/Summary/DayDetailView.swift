import SwiftUI

// MARK: - Day Detail View

struct DayDetailView: View {
    let day: Date
    let experiments: [Experiment]
    let onUpdate: (Experiment) -> Void

    private let rowSpacing: CGFloat = DSSpacing.md
    private var isNewUser: Bool {
        ExperimentDetailView.shouldShowFirstLogGuidance(for: experiments)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }

    private var completedExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            if let completedAt = exp.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            return false
        }
    }

    private var activeUpdateExperiments: [Experiment] {
        let calendar = Calendar.current

        // Get IDs of experiments completed on this day
        let completedIDs = Set(completedExperiments.map(\.id))

        return experiments.filter { exp in
            // Must be active status
            guard exp.status == .active else { return false }

            // Exclude experiments completed on this day (they go to Completed section only)
            guard !completedIDs.contains(exp.id) else { return false }

            // Check if has log on this day
            let hasLog = exp.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }

            // Check if created on this day
            let createdOnDay = calendar.isDate(exp.createdAt, inSameDayAs: day)

            return hasLog || createdOnDay
        }
    }

    private func activeSubtitle(for experiment: Experiment) -> String {
        "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private func completedSubtitle(for experiment: Experiment) -> String {
        if let completedAt = experiment.completedAt {
            return "Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Completed"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active Updates Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                        Text("Active Updates")
                            .font(DSText.headline)
                    }

                    if activeUpdateExperiments.isEmpty {
                        Text("No active updates on this day")
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(activeUpdateExperiments) { experiment in
                                ExperimentListCard(
                                    title: experiment.title,
                                    subtitle: activeSubtitle(for: experiment),
                                    surfaceStyle: .activePrimary,
                                    contentPadding: DSSpacing.md,
                                    destination: ExperimentDetailView(
                                        experiment: experiment,
                                        isNewUser: isNewUser,
                                        onUpdate: onUpdate
                                    )
                                ) {
                                    Image(systemName: "chevron.right")
                                        .font(DSText.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Completed Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(DSText.headline)
                    }

                    if completedExperiments.isEmpty {
                        Text("No experiments completed on this day")
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(completedExperiments) { experiment in
                                ExperimentListCard(
                                    title: experiment.title,
                                    subtitle: completedSubtitle(for: experiment),
                                    surfaceStyle: .completed,
                                    contentPadding: DSSpacing.md,
                                    destination: ExperimentDetailView(
                                        experiment: experiment,
                                        isNewUser: isNewUser,
                                        onUpdate: onUpdate
                                    )
                                ) {
                                    Image(systemName: "chevron.right")
                                        .font(DSText.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(dayLabel)
        .navigationBarTitleDisplayMode(.large)
    }
}

