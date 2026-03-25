import SwiftUI

// MARK: - Storage Boxes Module

struct StorageBoxesView: View {
    let experiments: [Experiment]
    let seedCatalog: SeedCatalog?
    let onUpdate: (Experiment) -> Void

    private var uncategorizedExperiments: [Experiment] {
        experiments.filter { exp in
            let category = exp.category?.trimmingCharacters(in: .whitespacesAndNewlines)
            return category == nil || category?.isEmpty == true
        }
    }

    private var otherExperiments: [Experiment] {
        experiments.filter { exp in
            guard let category = exp.category?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !category.isEmpty else {
                return false
            }
            return category == "Other"
        }
    }

    private var allCategories: [String] {
        var categories: [String] = []

        // Add seed categories first
        if let catalog = seedCatalog {
            categories.append(contentsOf: catalog.categories.map { $0.title })
        }

        // Add "Other"
        categories.append("Other")

        // Add "Uncategorized"
        categories.append("Uncategorized")

        return categories
    }

    private var categoryBoxes: [CategoryBox] {
        var boxes: [CategoryBox] = []

        for category in allCategories {
            let exps: [Experiment]
            let customNames: [String]

            if category == "Other" {
                exps = otherExperiments
                customNames = []
            } else if category == "Uncategorized" {
                exps = uncategorizedExperiments
                customNames = []
            } else {
                // Seed category
                exps = experiments.filter { exp in
                    exp.category?.trimmingCharacters(in: .whitespacesAndNewlines) == category
                }
                customNames = []
            }

            let updatedAt = exps.isEmpty ? Date.distantPast : (exps.map { $0.updatedAt }.max() ?? Date.distantPast)
            boxes.append(CategoryBox(category: category, experiments: exps, updatedAt: updatedAt, customCategoryNames: customNames))
        }

        let coreBoxes = boxes
            .filter { $0.category != "Other" && $0.category != "Uncategorized" }
            .sorted {
                $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
            }
        let otherBox = boxes.first { $0.category == "Other" }
        let uncategorizedBox = boxes.first { $0.category == "Uncategorized" }
        return coreBoxes + [otherBox, uncategorizedBox].compactMap { $0 }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: DSSpacing.sm)], spacing: DSSpacing.sm) {
            ForEach(categoryBoxes) { box in
                StorageBoxTile(box: box, onUpdate: onUpdate)
            }
        }
    }
}

struct CategoryBox: Identifiable {
    var id: String { category }
    let category: String
    let experiments: [Experiment]
    let updatedAt: Date
    let customCategoryNames: [String]

    var isEmpty: Bool {
        experiments.isEmpty
    }

    var subcategories: [String] {
        let subs = experiments.compactMap { $0.subcategory?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return Array(Set(subs)).sorted()
    }

    init(category: String, experiments: [Experiment], updatedAt: Date, customCategoryNames: [String] = []) {
        self.category = category
        self.experiments = experiments
        self.updatedAt = updatedAt
        self.customCategoryNames = customCategoryNames
    }
}

struct StorageBoxTile: View {
    let box: CategoryBox
    let onUpdate: (Experiment) -> Void
    @State private var showExperimentsList: Bool = false

    private var subtitleText: String? {
        if box.isEmpty {
            return "Empty"
        } else if !box.subcategories.isEmpty {
            return box.subcategories.prefix(2).joined(separator: ", ")
        }
        return nil
    }

    var body: some View {
        Button(action: {
            showExperimentsList = true
        }) {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                // Box icon
                Image(systemName: box.isEmpty ? "shippingbox" : "shippingbox.fill")
                    .font(.title)
                    .foregroundColor(box.isEmpty ? Color.gray.opacity(0.3) : .blue)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Category name
                Text(box.category)
                    .font(DSText.rowTitle)
                    .foregroundColor(box.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Subtitle: custom categories, subcategories, or Empty label
                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .italic(box.isEmpty)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(DSSpacing.md)
            .frame(height: 120)
            .background(box.isEmpty ? Color(.systemGray6).opacity(0.5) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showExperimentsList) {
            NavigationStack {
                if box.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("Empty Category")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("No experiments in \"\(box.category)\" yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .navigationTitle(box.category)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showExperimentsList = false
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(box.experiments.sorted { $0.updatedAt > $1.updatedAt }.enumerated()), id: \.element.id) { index, experiment in
                                NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                    HStack(spacing: DSSpacing.sm) {
                                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                            Text(experiment.title)
                                                .font(DSText.rowTitle)
                                                .foregroundColor(.primary)

                                            Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                                .lifeCaption()
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(DSText.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, DSSpacing.sm)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if index < box.experiments.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .lifeCard()
                        .padding(DSSpacing.md)
                    }
                    .navigationTitle(box.category)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                showExperimentsList = false
                            }
                        }
                    }
                }
            }
        }
    }
}

