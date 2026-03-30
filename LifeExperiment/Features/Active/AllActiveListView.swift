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

    fileprivate enum SectionSurfaceStyle {
        case primary
        case secondary
    }

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
            VStack(alignment: .leading, spacing: 0) {
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
                            .padding(.horizontal, DSSpacing.sm)
                            .padding(.vertical, DSSpacing.xs)
                            .background(Color(.systemBackground))
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, DSSpacing.sm)

                sectionHeader(S.sectionUpdatedToday, style: .primary)
                    .padding(.bottom, DSSpacing.sm)
                sectionCard(
                    experiments: updatedToday,
                    emptyText: S.emptyNoUpdatesToday,
                    style: .primary
                )

                sectionHeader("Not Updated Today (\(notUpdatedToday.count))", style: .secondary)
                    .padding(.top, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.sm)
                sectionCard(
                    experiments: visibleNotUpdatedToday,
                    emptyText: S.emptyAllUpdated,
                    style: .secondary
                )

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
                    .padding(.top, DSSpacing.sm)
                }
            }
            .padding(DSSpacing.md)
        }
        .navigationTitle(S.sectionActiveExperiments)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search experiments")
    }

    @ViewBuilder
    private func sectionCard(
        experiments: [Experiment],
        emptyText: String,
        style: SectionSurfaceStyle
    ) -> some View {
        if experiments.isEmpty {
            Text(emptyText)
                .lifeSecondaryText()
                .padding(.vertical, DSSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modifier(ActiveSectionSurface(style: style))
        } else {
            VStack(spacing: DSSpacing.md) {
                ForEach(experiments) { experiment in
                    ExperimentListCard(
                        title: experiment.title,
                        subtitle: "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))",
                        surfaceStyle: cardSurfaceStyle(for: style),
                        contentPadding: DSSpacing.md,
                        action: {
                            onSelectExperiment(experiment)
                        }
                    ) {
                        ExperimentRowMenu(
                            kind: .active,
                            onRename: { onRename(experiment) },
                            onDuplicate: { onDuplicate(experiment) },
                            onDelete: { onDelete(experiment) }
                        )
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String, style: SectionSurfaceStyle) -> some View {
        Text(title)
            .font(style == .primary ? DSText.section : .headline)
            .foregroundStyle(style == .primary ? .primary : Color.primary.opacity(0.72))
    }

    private func cardSurfaceStyle(for style: SectionSurfaceStyle) -> ExperimentListCardSurfaceStyle {
        switch style {
        case .primary:
            return .activePrimary
        case .secondary:
            return .activeSecondary
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

private struct ActiveSectionSurface: ViewModifier {
    let style: AllActiveListView.SectionSurfaceStyle

    func body(content: Content) -> some View {
        content
            .padding(DSSpacing.md)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(12)
            .shadow(
                color: shadowColor,
                radius: style == .primary ? 10 : 0,
                x: 0,
                y: style == .primary ? 4 : 0
            )
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Color(.systemBackground)
        case .secondary:
            return Color(.systemGray6)
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.black.opacity(0.05)
        case .secondary:
            return Color.black.opacity(0.03)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return Color.black.opacity(0.06)
        case .secondary:
            return .clear
        }
    }
}

