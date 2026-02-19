import SwiftUI

// MARK: - Day Detail View

struct DayDetailView: View {
    let day: Date
    let experiments: [Experiment]
    let onUpdate: (Experiment) -> Void

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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active Updates Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                        Text("Active Updates")
                            .font(.headline)
                    }

                    if activeUpdateExperiments.isEmpty {
                        Text("No active updates on this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(activeUpdateExperiments) { experiment in
                            NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                ExperimentCardRow(experiment: experiment)
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
                            .font(.headline)
                    }

                    if completedExperiments.isEmpty {
                        Text("No experiments completed on this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(completedExperiments) { experiment in
                            NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                ExperimentCardRow(experiment: experiment)
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

