import SwiftUI

// MARK: - Storage Boxes Module

struct StorageBoxesView: View {
    let experiments: [Experiment]
    let seedCatalog: SeedCatalog?
    let onUpdate: (Experiment) -> Void

    private var isNewUser: Bool {
        ExperimentDetailView.shouldShowFirstLogGuidance(for: experiments)
    }

    private var otherExperiments: [Experiment] {
        experiments.filter { exp in
            let category = exp.category?.trimmingCharacters(in: .whitespacesAndNewlines)
            return category == nil || category?.isEmpty == true || category == "Other"
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
            .filter { $0.category != "Other" }
            .sorted {
                $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending
            }
        let otherBox = boxes.first { $0.category == "Other" }
        return coreBoxes + [otherBox].compactMap { $0 }
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: DSSpacing.md)], spacing: DSSpacing.md) {
            ForEach(categoryBoxes) { box in
                StorageBoxTile(box: box, isNewUser: isNewUser, onUpdate: onUpdate)
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
    let isNewUser: Bool
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
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                // Box icon
                Image(systemName: box.isEmpty ? "shippingbox" : "shippingbox.fill")
                    .font(DSText.title2)
                    .foregroundColor(box.isEmpty ? Color.gray.opacity(0.24) : primaryLavenderButton.opacity(0.7))
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
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.lg)
            .frame(height: 126)
            .background(tileBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .cornerRadius(14)
        }
        .buttonStyle(PressableCardStyle())
        .sheet(isPresented: $showExperimentsList) {
            NavigationStack {
                if box.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.3))

                        Text("Empty Category")
                            .font(DSText.title2)
                            .fontWeight(.semibold)

                        Text("No experiments in \"\(box.category)\" yet.")
                            .font(DSText.subheadline)
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
                        VStack(spacing: DSSpacing.md) {
                            ForEach(box.experiments.sorted { $0.updatedAt > $1.updatedAt }) { experiment in
                                ExperimentListCard(
                                    title: experiment.title,
                                    subtitle: "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))",
                                    surfaceStyle: .browse,
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

    private var tileBackground: some View {
        Group {
            if box.isEmpty {
                Color(.systemBackground).opacity(0.55)
            } else {
                Color(.systemBackground).opacity(0.6)
            }
        }
    }
}

