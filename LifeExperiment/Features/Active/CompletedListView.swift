import SwiftUI

// MARK: - Completed List View

struct CompletedListView: View {
    let completedExperiments: [Experiment]
    let onSelectExperiment: (Experiment) -> Void
    let onDuplicate: (Experiment) -> Void
    let onDelete: (Experiment) -> Void

    private var thisWeek: [Experiment] {
        let calendar = Calendar.current
        return completedExperiments.filter { exp in
            guard let completedAt = exp.completedAt else { return false }
            return calendar.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    private var earlier: [Experiment] {
        let calendar = Calendar.current
        return completedExperiments.filter { exp in
            guard let completedAt = exp.completedAt else { return true }
            return !calendar.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    var body: some View {
        Group {
            if completedExperiments.isEmpty {
                // Empty state
                VStack(spacing: DSSpacing.md) {
                    Spacer()
                        .frame(height: 60)

                    Text(S.emptyNoCompletedExperiments)
                        .font(DSText.title2)
                        .fontWeight(.semibold)

                    Text(S.emptyNoCompletedSubtitle)
                        .lifeSecondaryText()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("Try something tiny—one day is still an experiment.")
                        .lifeCaption()
                        .italic()
                        .padding(.top, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        if !thisWeek.isEmpty {
                            Text(S.sectionThisWeek)
                                .lifeSectionTitle()
                            sectionCard(experiments: thisWeek)
                        }

                        if !earlier.isEmpty {
                            Text(S.sectionEarlier)
                                .lifeSectionTitle()
                            sectionCard(experiments: earlier)
                        }
                    }
                    .padding(DSSpacing.md)
                }
            }
        }
        .navigationTitle("Completed Experiments")
        .navigationBarTitleDisplayMode(.large)
    }

    private func sectionCard(experiments: [Experiment]) -> some View {
        VStack(spacing: DSSpacing.md) {
            ForEach(experiments) { experiment in
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
                        onDuplicate: { onDuplicate(experiment) },
                        onDelete: { onDelete(experiment) }
                    )
                }
            }
        }
    }
}

