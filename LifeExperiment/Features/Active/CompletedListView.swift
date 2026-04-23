import SwiftUI

// MARK: - Completed List View

struct CompletedListView: View {
    let completedExperiments: [Experiment]
    let onSelectExperiment: (Experiment) -> Void
    let onDuplicate: (Experiment) -> Void
    let onDelete: (Experiment) -> Void

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

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

                    Text(L.noCompletedExperiments(lang))
                        .font(DSText.title2)
                        .fontWeight(.semibold)

                    Text(L.noCompletedExperimentsSubtitle(lang))
                        .lifeSecondaryText()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(L.completedListEncouragement(lang))
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
                            Text(L.sectionThisWeekList(lang))
                                .lifeSectionTitle()
                            sectionCard(experiments: thisWeek)
                        }

                        if !earlier.isEmpty {
                            Text(L.sectionEarlierList(lang))
                                .lifeSectionTitle()
                            sectionCard(experiments: earlier)
                        }
                    }
                    .padding(DSSpacing.md)
                }
            }
        }
        .navigationTitle(L.completedExperiments(lang))
        .navigationBarTitleDisplayMode(.large)
    }

    private func sectionCard(experiments: [Experiment]) -> some View {
        VStack(spacing: DSSpacing.md) {
            ForEach(experiments) { experiment in
                ExperimentListCard(
                    title: experiment.title,
                    subtitle: experiment.completedAt.map { date in
                        L.completedOnDate(
                            lang,
                            dateString: date.formatted(date: .abbreviated, time: .omitted)
                        )
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

