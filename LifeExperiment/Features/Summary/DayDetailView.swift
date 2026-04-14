import SwiftUI

// MARK: - Day Detail View

struct DayDetailView: View {
    let day: Date
    let experiments: [Experiment]
    var lowEnergyLogs: [LowEnergyLog] = []
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

        let completedIDs = Set(completedExperiments.map(\.id))

        return experiments.filter { exp in
            guard exp.status == .active else { return false }
            guard !completedIDs.contains(exp.id) else { return false }

            let hasLog = exp.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }
            let createdOnDay = calendar.isDate(exp.createdAt, inSameDayAs: day)

            return hasLog || createdOnDay
        }
    }

    private var lowEnergyLogForDay: LowEnergyLog? {
        let calendar = Calendar.current
        return lowEnergyLogs.first { calendar.isDate($0.date, inSameDayAs: day) }
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

                // RF#4: Lightweight inline block for low energy log (CL#3 display rules)
                if let leLog = lowEnergyLogForDay {
                    Divider()

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(DSText.subheadline)
                            .foregroundColor(.green.opacity(0.7))
                            .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Took it easy today")
                                .font(DSText.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(leLog.detailLine)
                                .font(DSText.caption)
                                .foregroundColor(.secondary)

                            if let note = leLog.note,
                               !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(note)
                                    .font(DSText.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(dayLabel)
        .navigationBarTitleDisplayMode(.large)
    }
}
