import SwiftUI

// MARK: - Day Detail View

struct DayDetailView: View {
    let day: Date
    let experiments: [Experiment]
    var lowEnergyLogs: [LowEnergyLog] = []
    let onUpdate: (Experiment) -> Void

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    private let rowSpacing: CGFloat = DSSpacing.md
    private var isNewUser: Bool {
        ExperimentDetailView.shouldShowFirstLogGuidance(for: experiments)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        if lang == .chinese {
            formatter.locale = Locale(identifier: "zh_Hans_CN")
            formatter.dateFormat = "EEEE，M月d日"
        } else {
            formatter.locale = Locale(identifier: "en_US")
            formatter.dateFormat = "EEEE, MMM d"
        }
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
        L.lastUpdated(
            lang,
            dateString: experiment.updatedAt.formatted(date: .abbreviated, time: .omitted)
        )
    }

    private func completedSubtitle(for experiment: Experiment) -> String {
        if let completedAt = experiment.completedAt {
            return L.completedOnDate(
                lang,
                dateString: completedAt.formatted(date: .abbreviated, time: .omitted)
            )
        }
        return L.sectionCompleted(lang)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active Updates Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                        Text(L.dayDetailActiveUpdates(lang))
                            .font(DSText.headline)
                    }

                    if activeUpdateExperiments.isEmpty {
                        Text(L.dayDetailNoActiveUpdates(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(activeUpdateExperiments) { experiment in
                                ExperimentListCard(
                                    title: BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang),
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
                        Text(L.sectionCompleted(lang))
                            .font(DSText.headline)
                    }

                    if completedExperiments.isEmpty {
                        Text(L.dayDetailNoExperimentsCompleted(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        VStack(spacing: rowSpacing) {
                            ForEach(completedExperiments) { experiment in
                                ExperimentListCard(
                                    title: BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang),
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
                            Text(L.dayDetailTookItEasy(lang))
                                .font(DSText.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Text(leLog.localizedDetailLine(lang: lang))
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
