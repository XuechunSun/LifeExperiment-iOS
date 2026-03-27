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

    @State private var searchText: String = ""
    @State private var sortOption: SortOption = .lastUpdated
    @State private var isNotUpdatedExpanded: Bool = false

    private enum SortOption: String, CaseIterable, Identifiable {
        case lastUpdated = "Last Updated"
        case createdDate = "Created Date"

        var id: String { rawValue }
    }

    private var updatedToday: [Experiment] {
        sortedExperiments(
            filteredExperiments(activeExperiments.filter { isUpdatedToday($0) })
        )
    }

    private var notUpdatedToday: [Experiment] {
        sortedExperiments(
            filteredExperiments(activeExperiments.filter { !isUpdatedToday($0) })
        )
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var visibleNotUpdatedToday: [Experiment] {
        if isSearching || isNotUpdatedExpanded || notUpdatedToday.count <= 12 {
            return notUpdatedToday
        }
        return Array(notUpdatedToday.prefix(12))
    }

    private var shouldShowNotUpdatedToggle: Bool {
        !isSearching && notUpdatedToday.count > 12
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                HStack {
                    Spacer()

                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                sortOption = option
                            } label: {
                                if option == sortOption {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Text(S.sectionUpdatedToday)
                    .lifeSectionTitle()
                sectionCard(experiments: updatedToday, emptyText: S.emptyNoUpdatesToday)

                Text("Not Updated Today (\(notUpdatedToday.count))")
                    .lifeSectionTitle()
                sectionCard(experiments: visibleNotUpdatedToday, emptyText: S.emptyAllUpdated)

                if shouldShowNotUpdatedToggle {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isNotUpdatedExpanded.toggle()
                        }
                    } label: {
                        Text(isNotUpdatedExpanded ? "Show less" : "See more")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(DSSpacing.md)
        }
        .navigationTitle(S.sectionActiveExperiments)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search experiments")
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

    private func filteredExperiments(_ experiments: [Experiment]) -> [Experiment] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return experiments }

        return experiments.filter { experiment in
            experiment.title.localizedCaseInsensitiveContains(query)
        }
    }

    private func sortedExperiments(_ experiments: [Experiment]) -> [Experiment] {
        experiments.sorted { lhs, rhs in
            switch sortOption {
            case .lastUpdated:
                return lhs.updatedAt > rhs.updatedAt
            case .createdDate:
                return lhs.createdAt > rhs.createdAt
            }
        }
    }
}

