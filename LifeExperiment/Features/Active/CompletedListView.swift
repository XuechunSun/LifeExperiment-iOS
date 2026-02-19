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
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 60)

                    Text(S.emptyNoCompletedExperiments)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(S.emptyNoCompletedSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("Try something tiny—one day is still an experiment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    // This week section
                    if !thisWeek.isEmpty {
                        Section {
                            ForEach(thisWeek) { experiment in
                                Button(action: {
                                    onSelectExperiment(experiment)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(experiment.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)

                                            if let completedAt = experiment.completedAt {
                                                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        ExperimentRowMenu(
                                            kind: .completed,
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
                                }
                            }
                        } header: {
                            Text(S.sectionThisWeek)
                        }
                    }

                    // Earlier section
                    if !earlier.isEmpty {
                        Section {
                            ForEach(earlier) { experiment in
                                Button(action: {
                                    onSelectExperiment(experiment)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(experiment.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)

                                            if let completedAt = experiment.completedAt {
                                                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        ExperimentRowMenu(
                                            kind: .completed,
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
                                }
                            }
                        } header: {
                            Text(S.sectionEarlier)
                        }
                    }
                }
            }
        }
        .navigationTitle("Completed Experiments")
        .navigationBarTitleDisplayMode(.large)
    }
}

