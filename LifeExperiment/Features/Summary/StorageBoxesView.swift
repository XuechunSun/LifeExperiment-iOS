import SwiftUI

// MARK: - Storage Boxes Module

struct StorageBoxesView: View {
    let experiments: [Experiment]
    let seedCatalog: SeedCatalog?
    let onUpdate: (Experiment) -> Void
    @Binding var showCreateStorageBox: Bool

    private var seedCategorySet: Set<String> {
        Set(seedCatalog?.categories.map { $0.title } ?? [])
    }

    private var uncategorizedExperiments: [Experiment] {
        experiments.filter { exp in
            let category = exp.category?.trimmingCharacters(in: .whitespacesAndNewlines)
            return category == nil || category?.isEmpty == true
        }
    }

    private var customExperiments: [Experiment] {
        experiments.filter { exp in
            guard let category = exp.category?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !category.isEmpty else {
                return false
            }
            return !seedCategorySet.contains(category)
        }
    }

    private var customCategoryNames: [String] {
        let names = customExperiments.compactMap { exp in
            exp.category?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        return Array(Set(names)).sorted()
    }

    private var allCategories: [String] {
        var categories: [String] = []

        // Add seed categories first
        if let catalog = seedCatalog {
            categories.append(contentsOf: catalog.categories.map { $0.title })
        }

        // Add "Custom"
        categories.append("Custom")

        // Add "Uncategorized"
        categories.append("Uncategorized")

        return categories
    }

    private var categoryBoxes: [CategoryBox] {
        var boxes: [CategoryBox] = []

        for category in allCategories {
            let exps: [Experiment]
            let customNames: [String]

            if category == "Custom" {
                exps = customExperiments
                customNames = customCategoryNames
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

        // Sort: non-empty boxes first (by updatedAt desc), then empty boxes (alphabetically)
        return boxes.sorted { box1, box2 in
            if box1.isEmpty && box2.isEmpty {
                return box1.category < box2.category
            } else if box1.isEmpty {
                return false
            } else if box2.isEmpty {
                return true
            } else {
                return box1.updatedAt > box2.updatedAt
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Boxes by Category")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(categoryBoxes) { box in
                    StorageBoxTile(box: box, onUpdate: onUpdate)
                }

                // Create new storage box tile
                Button(action: {
                    showCreateStorageBox = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Text("New Category")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            }
        }
    }
}

struct CategoryBox: Identifiable {
    let id = UUID()
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
        } else if box.category == "Custom" && !box.customCategoryNames.isEmpty {
            // Show up to 2 custom category names
            return box.customCategoryNames.prefix(2).joined(separator: ", ")
        } else if !box.subcategories.isEmpty {
            return box.subcategories.prefix(2).joined(separator: ", ")
        }
        return nil
    }

    var body: some View {
        Button(action: {
            showExperimentsList = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Box icon
                Image(systemName: box.isEmpty ? "shippingbox" : "shippingbox.fill")
                    .font(.title)
                    .foregroundColor(box.isEmpty ? Color.gray.opacity(0.3) : .blue)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Category name
                Text(box.category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(box.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Subtitle: custom categories, subcategories, or Empty label
                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic(box.isEmpty)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
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
                    List {
                        ForEach(box.experiments.sorted { $0.updatedAt > $1.updatedAt }) { experiment in
                            NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                ExperimentCardRow(experiment: experiment)
                            }
                        }
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

struct CreateStorageBoxView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text("Create Storage Box")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("New Category")
        .navigationBarTitleDisplayMode(.inline)
    }
}

