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

    private var categoryBoxes: [CategoryBox] {
        var boxes: [CategoryBox] = []

        if let catalog = seedCatalog {
            for cat in catalog.categories {
                let exps = experiments.filter { exp in
                    exp.category?.trimmingCharacters(in: .whitespacesAndNewlines) == cat.title
                }
                let updatedAt = exps.isEmpty ? Date.distantPast : (exps.map { $0.updatedAt }.max() ?? Date.distantPast)
                boxes.append(
                    CategoryBox(
                        category: cat.title,
                        seedCategoryId: cat.id,
                        experiments: exps,
                        updatedAt: updatedAt
                    )
                )
            }
        }

        let otherExps = otherExperiments
        let otherUpdated = otherExps.isEmpty
            ? Date.distantPast
            : (otherExps.map { $0.updatedAt }.max() ?? Date.distantPast)
        boxes.append(
            CategoryBox(
                category: "Other",
                seedCategoryId: nil,
                experiments: otherExps,
                updatedAt: otherUpdated
            )
        )

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
    /// Stable key for the grid: seed category id, or `"other"` for the Other bucket.
    var id: String { seedCategoryId ?? "other" }
    let category: String
    let seedCategoryId: String?
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

    init(
        category: String,
        seedCategoryId: String?,
        experiments: [Experiment],
        updatedAt: Date,
        customCategoryNames: [String] = []
    ) {
        self.category = category
        self.seedCategoryId = seedCategoryId
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
    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    private var displayCategoryName: String {
        if let seedId = box.seedCategoryId {
            return L.summarySeedCategoryTitle(lang, categoryId: seedId)
        }
        if box.category == "Other" {
            return L.createCategoryOther(lang)
        }
        return box.category
    }

    private func subtitleText() -> String? {
        if box.isEmpty {
            return L.storageBoxEmpty(lang)
        } else if !box.subcategories.isEmpty {
            return box.subcategories
                .prefix(2)
                .map { SeedTaxonomyDisplay.displaySubcategory(stored: $0, lang: lang) }
                .joined(separator: ", ")
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
                Text(displayCategoryName)
                    .font(DSText.rowTitle)
                    .foregroundColor(box.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Subtitle: custom categories, subcategories, or Empty label
                if let subtitle = subtitleText() {
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

                        Text(L.storageBoxEmptyStateTitle(lang))
                            .font(DSText.title2)
                            .fontWeight(.semibold)

                        Text(L.storageBoxNoExperiments(lang, categoryName: displayCategoryName))
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .navigationTitle(displayCategoryName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L.actionClose(lang)) {
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
                                    subtitle: L.lastUpdated(
                                        lang,
                                        dateString: experiment.updatedAt.formatted(date: .abbreviated, time: .omitted)
                                    ),
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
                    .navigationTitle(displayCategoryName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L.actionClose(lang)) {
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

