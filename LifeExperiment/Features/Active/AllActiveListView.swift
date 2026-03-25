import SwiftUI

// MARK: - All Active List View (Grouped by Update Status)

struct AllActiveListView: View {
    let activeExperiments: [Experiment]
    let isUpdatedToday: (Experiment) -> Bool
    let onSelectExperiment: (Experiment) -> Void
    let onCreateExperiment: () -> Void
    let onRename: (Experiment) -> Void
    let onDuplicate: (Experiment) -> Void
    let onDelete: (Experiment) -> Void

    private var updatedToday: [Experiment] {
        activeExperiments.filter { isUpdatedToday($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private var notUpdatedToday: [Experiment] {
        activeExperiments.filter { !isUpdatedToday($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text(S.sectionUpdatedToday)
                    .lifeSectionTitle()
                sectionCard(experiments: updatedToday, emptyText: S.emptyNoUpdatesToday)

                Text(S.sectionNotUpdatedToday)
                    .lifeSectionTitle()
                sectionCard(experiments: notUpdatedToday, emptyText: S.emptyAllUpdated)

                Button(action: {
                    onCreateExperiment()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(S.sectionStartNewExperiment)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, DSSpacing.sm)
                .lifeCard()
            }
            .padding(DSSpacing.md)
        }
        .navigationTitle(S.sectionActiveExperiments)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func sectionCard(experiments: [Experiment], emptyText: String) -> some View {
        if experiments.isEmpty {
            Text(emptyText)
                .lifeSecondaryText()
                .padding(.vertical, DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lifeCard()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(experiments.enumerated()), id: \.element.id) { index, experiment in
                    Button(action: {
                        onSelectExperiment(experiment)
                    }) {
                        HStack(spacing: DSSpacing.sm) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(experiment.title)
                                    .font(DSText.rowTitle)
                                    .foregroundColor(.primary)

                                Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .lifeCaption()
                            }

                            Spacer()

                            ExperimentRowMenu(
                                kind: .active,
                                onRename: { onRename(experiment) },
                                onDuplicate: { onDuplicate(experiment) },
                                onDelete: { onDelete(experiment) }
                            )
                        }
                        .padding(.vertical, DSSpacing.sm)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < experiments.count - 1 {
                        Divider()
                    }
                }
            }
            .lifeCard()
        }
    }
}

