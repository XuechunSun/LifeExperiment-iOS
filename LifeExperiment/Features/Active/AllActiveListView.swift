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
        List {
            // Updated Today section
            Section {
                if updatedToday.isEmpty {
                    Text(S.emptyNoUpdatesToday)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(updatedToday) { experiment in
                        Button(action: {
                            onSelectExperiment(experiment)
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(experiment.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                ExperimentRowMenu(
                                    kind: .active,
                                    onRename: { onRename(experiment) },
                                    onDuplicate: { onDuplicate(experiment) },
                                    onDelete: { onDelete(experiment) }
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: { onDelete(experiment) }) {
                                Label("Delete", systemImage: "trash")
                            }
                            Button(action: { onDuplicate(experiment) }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.orange)
                            Button(action: { onRename(experiment) }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text(S.sectionUpdatedToday)
            }

            // Not Updated Today section
            Section {
                if notUpdatedToday.isEmpty {
                    Text(S.emptyAllUpdated)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notUpdatedToday) { experiment in
                        Button(action: {
                            onSelectExperiment(experiment)
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(experiment.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)

                                    Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                ExperimentRowMenu(
                                    kind: .active,
                                    onRename: { onRename(experiment) },
                                    onDuplicate: { onDuplicate(experiment) },
                                    onDelete: { onDelete(experiment) }
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: { onDelete(experiment) }) {
                                Label("Delete", systemImage: "trash")
                            }
                            Button(action: { onDuplicate(experiment) }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.orange)
                            Button(action: { onRename(experiment) }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text(S.sectionNotUpdatedToday)
            }

            // Start New Experiment button
            Section {
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
                .listRowBackground(Color.blue.opacity(0.1))
            }
        }
        .navigationTitle(S.sectionActiveExperiments)
        .navigationBarTitleDisplayMode(.large)
    }
}

