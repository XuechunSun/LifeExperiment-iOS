import SwiftUI

struct ExperimentEditorView: View {
    let seedCatalog: SeedCatalog?
    let mode: ExperimentEditorMode

    /// called when user taps primary button
    let onCommit: (Experiment) -> Void

    @Environment(\.dismiss) private var dismiss

    // Draft state
    @State private var title: String = ""

    @State private var selectedSeedCategoryId: String?
    @State private var selectedSeedSubcategoryId: String?

    @State private var useCustomCategory: Bool = false
    @State private var useCustomSubcategory: Bool = false

    @State private var customCategoryText: String = ""
    @State private var customSubcategoryText: String = ""

    // Prompt revert state
    @State private var baselineTitleForRevert: String = ""
    @State private var hasBaselineTitle: Bool = false
    @State private var showRevertTitle: Bool = false
    @State private var isProgrammaticTitleChange: Bool = false
    @FocusState private var focusedField: Field?

    // Dimension state
    @State private var selectedImpact: ExperimentImpact?
    @State private var hasManuallyEditedImpact: Bool = false
    @State private var showDimensionPicker: Bool = false

    // For rename "no changes -> disable"
    private let originalExperiment: Experiment?

    init(seedCatalog: SeedCatalog?, mode: ExperimentEditorMode, onCommit: @escaping (Experiment) -> Void) {
        self.seedCatalog = seedCatalog
        self.mode = mode
        self.onCommit = onCommit

        switch mode {
        case .rename(let existing):
            self.originalExperiment = existing
        case .duplicate(let from):
            self.originalExperiment = from
        case .create:
            self.originalExperiment = nil
        }
    }

    private enum Field: Hashable {
        case title
        case customCategory
        case customSubcategory
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func trimmedOrNil(_ s: String) -> String? {
        let t = trimmed(s)
        return t.isEmpty ? nil : t
    }

    private var selectedSeedCategory: SeedCategory? {
        guard let catalog = seedCatalog, let id = selectedSeedCategoryId else { return nil }
        return catalog.categories.first { $0.id == id }
    }

    private var draftCategory: String? {
        if useCustomCategory {
            return trimmedOrNil(customCategoryText)
        } else if let c = selectedSeedCategory {
            return c.title
        }
        return nil
    }

    private var draftSubcategory: String? {
        // If category is custom, we only allow custom subcategory
        if useCustomCategory {
            return trimmedOrNil(customSubcategoryText)
        }

        if useCustomSubcategory {
            return trimmedOrNil(customSubcategoryText)
        }

        if let category = selectedSeedCategory,
           let subId = selectedSeedSubcategoryId,
           let sub = category.subcategories.first(where: { $0.id == subId }) {
            return sub.title
        }

        return nil
    }

    private var categoryDisplayText: String {
        if useCustomCategory {
            return "Custom"
        }
        if let c = selectedSeedCategory { return c.title }
        return "Optional"
    }

    private var subcategoryDisplayText: String {
        if useCustomSubcategory || useCustomCategory {
            return "Custom"
        }

        if let category = selectedSeedCategory,
           let subId = selectedSeedSubcategoryId,
           let sub = category.subcategories.first(where: { $0.id == subId }) {
            return sub.title
        }
        return "Optional"
    }

    private var canPickSubcategoryFromSeed: Bool {
        // only when a seed category is selected and we are not in custom category
        return !useCustomCategory && selectedSeedCategoryId != nil
    }

    private var hasCategorySelected: Bool {
        return useCustomCategory || selectedSeedCategoryId != nil
    }

    private var selectedSeedSubcategory: SeedSubcategory? {
        guard !useCustomCategory,
              !useCustomSubcategory,
              let category = selectedSeedCategory,
              let subId = selectedSeedSubcategoryId else {
            return nil
        }
        return category.subcategories.first(where: { $0.id == subId })
    }

    private var defaultImpact: ExperimentImpact? {
        guard let subcategory = selectedSeedSubcategory else { return nil }
        return impactFromDefaultDimensions(subcategory.default_dimensions)
    }

    private var displayedImpact: ExperimentImpact? {
        if hasManuallyEditedImpact {
            return selectedImpact
        }
        return defaultImpact
    }

    private var isSeedBased: Bool {
        return !useCustomCategory && selectedSeedCategoryId != nil && selectedSeedSubcategoryId != nil
    }

    private var isCustom: Bool {
        return useCustomCategory
    }

    private var hasSeedCategory: Bool {
        return !useCustomCategory && selectedSeedCategoryId != nil
    }

    private var hasSeedSubcategory: Bool {
        return !useCustomCategory && selectedSeedSubcategoryId != nil
    }

    private var availablePrompts: [String] {
        // Only show prompts in create or duplicate mode
        switch mode {
        case .rename:
            return []
        case .create, .duplicate:
            break
        }

        // Only show prompts for seed subcategories (not custom)
        guard let subcategory = selectedSeedSubcategory, !subcategory.prompts.isEmpty else {
            return []
        }

        // Return at most 3 prompts
        return Array(subcategory.prompts.prefix(3))
    }

    private var isCreateActionDisabled: Bool {
        let t = trimmed(title)
        if t.isEmpty { return true }

        let isCreateOrDuplicate: Bool = {
            if case .create = mode { return true }
            if case .duplicate = mode { return true }
            return false
        }()

        // If a seed category is selected, require a subcategory
        if hasSeedCategory && !hasSeedSubcategory {
            return true
        }

        // For custom category experiments in create/duplicate mode, require primary dimension selection
        if isCustom && isCreateOrDuplicate && selectedImpact == nil {
            return true
        }

        // rename mode: disable if no changes
        if case .rename = mode, let original = originalExperiment {
            let sameTitle = trimmed(original.title) == t
            let sameCategory = (original.category ?? "") == (draftCategory ?? "")
            let sameSub = (original.subcategory ?? "") == (draftSubcategory ?? "")
            return sameTitle && sameCategory && sameSub
        }

        return false
    }

    // MARK: - UI building blocks (Card style)

    private func cardField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            content()
        }
    }

    private func cardBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }

    private func customInputBlock(hint: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text(hint)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
        }
        .padding(.top, 8)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                // Title
                cardField(label: "Title") {
                    cardBackground {
                        TextField("Experiment Title", text: $title)
                            .focused($focusedField, equals: .title)
                            .textFieldStyle(.plain)
                    }
                }

                // Suggested Prompts
                if !availablePrompts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Suggested prompts for title")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            if showRevertTitle {
                                Button(action: {
                                    isProgrammaticTitleChange = true
                                    title = baselineTitleForRevert
                                    showRevertTitle = false
                                    hasBaselineTitle = false
                                    baselineTitleForRevert = ""
                                    DispatchQueue.main.async {
                                        isProgrammaticTitleChange = false
                                    }
                                }) {
                                    Label("Revert", systemImage: "arrow.uturn.backward")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        cardBackground {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                                ForEach(availablePrompts, id: \.self) { prompt in
                                    Button(action: {
                                        // Light haptic feedback
                                        Haptics.lightImpact()

                                        // Capture baseline only on first prompt tap
                                        if !hasBaselineTitle {
                                            baselineTitleForRevert = title
                                            hasBaselineTitle = true
                                        }

                                        isProgrammaticTitleChange = true
                                        title = prompt
                                        showRevertTitle = true
                                        DispatchQueue.main.async {
                                            isProgrammaticTitleChange = false
                                        }
                                    }) {
                                        Text(prompt)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }

                // Category
                cardField(label: "Category (Optional)") {
                    cardBackground {
                        VStack(alignment: .leading, spacing: 0) {
                            Menu {
                                Button("None") {
                                    useCustomCategory = false
                                    selectedSeedCategoryId = nil

                                    // reset subcategory too
                                    selectedSeedSubcategoryId = nil
                                    useCustomSubcategory = false
                                    customSubcategoryText = ""
                                    customCategoryText = ""
                                }

                                if let catalog = seedCatalog {
                                    ForEach(catalog.categories) { c in
                                        Button(c.title) {
                                            useCustomCategory = false
                                            selectedSeedCategoryId = c.id
                                            customCategoryText = ""

                                            // switching category clears subcategory
                                            selectedSeedSubcategoryId = nil
                                            useCustomSubcategory = false
                                            customSubcategoryText = ""
                                        }
                                    }
                                }

                                Button("Custom...") {
                                    useCustomCategory = true
                                    selectedSeedCategoryId = nil

                                    // custom category implies custom subcategory (optional)
                                    selectedSeedSubcategoryId = nil
                                    useCustomSubcategory = true
                                    customSubcategoryText = ""
                                }
                            } label: {
                                HStack {
                                    Text(categoryDisplayText)
                                        .foregroundColor(categoryDisplayText == "Optional" ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .simultaneousGesture(TapGesture().onEnded {
                                    focusedField = nil
                                })
                            }

                            if useCustomCategory {
                                customInputBlock(
                                    hint: "Please enter a custom category below",
                                    placeholder: "Custom Category",
                                    text: $customCategoryText
                                )
                            }
                        }
                    }
                }

                // Subcategory
                cardField(label: "Subcategory (Optional)") {
                    cardBackground {
                        if canPickSubcategoryFromSeed, let category = selectedSeedCategory {
                            VStack(alignment: .leading, spacing: 0) {
                                Menu {
                                    Button("None") {
                                        useCustomSubcategory = false
                                        selectedSeedSubcategoryId = nil
                                        customSubcategoryText = ""
                                    }

                                    ForEach(category.subcategories) { s in
                                        Button(s.title) {
                                            useCustomSubcategory = false
                                            selectedSeedSubcategoryId = s.id
                                            customSubcategoryText = ""
                                        }
                                    }

                                    Button("Custom...") {
                                        useCustomSubcategory = true
                                        selectedSeedSubcategoryId = nil
                                    }
                                } label: {
                                    HStack {
                                        Text(subcategoryDisplayText)
                                            .foregroundColor(subcategoryDisplayText == "Optional" ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                    .simultaneousGesture(TapGesture().onEnded {
                                        focusedField = nil
                                    })
                                }

                                if useCustomSubcategory {
                                    customInputBlock(
                                        hint: "Please enter a custom subcategory below",
                                        placeholder: "Custom Subcategory",
                                        text: $customSubcategoryText
                                    )
                                }
                            }
                        } else {
                            // No seed category selected OR category is custom
                            if hasCategorySelected {
                                // Custom category is selected - show menu-like row with hint + TextField
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text("Custom")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture { focusedField = nil }

                                    customInputBlock(
                                        hint: "Please enter a custom subcategory below",
                                        placeholder: "Custom Subcategory",
                                        text: $customSubcategoryText
                                    )
                                }
                            } else {
                                // No category selected at all - show disabled row with chevron
                                HStack {
                                    Text("Select a category first")
                                        .foregroundColor(.secondary)
                                        .italic()
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .opacity(0.0)
                                }
                            }
                        }
                    }
                }

                // Validation text for seed category without subcategory
                if hasSeedCategory && !hasSeedSubcategory {
                    Text("Please select a subcategory.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.top, -8)
                }

                // Default Dimensions Card (for seed-based experiments)
                if let impact = displayedImpact, isSeedBased {
                    DefaultDimensionsCard(impact: impact) {
                        showDimensionPicker = true
                    }
                }

                // Custom Dimension Selection Card (for custom category experiments)
                if isCustom {
                    CustomDimensionSelectionCard(selectedImpact: selectedImpact) {
                        showDimensionPicker = true
                    }
                }

                Spacer()
            }
            .padding()
            .onChange(of: title) { _, _ in
                if !isProgrammaticTitleChange {
                    showRevertTitle = false
                    hasBaselineTitle = false
                    baselineTitleForRevert = ""
                }
            }
            .onChange(of: selectedSeedSubcategoryId) { _, _ in
                // Reset manual editing when subcategory changes (only for seed-based)
                if !hasManuallyEditedImpact && isSeedBased {
                    selectedImpact = defaultImpact
                }
            }
            .onChange(of: useCustomCategory) { _, newValue in
                // Reset manual editing flag when switching between custom and seed
                // This ensures seed defaults are respected when switching to seed
                hasManuallyEditedImpact = false
                selectedImpact = newValue ? nil : defaultImpact
            }
            .sheet(isPresented: $showDimensionPicker) {
                DimensionPickerSheet(initialImpact: displayedImpact) { newImpact in
                    selectedImpact = newImpact
                    hasManuallyEditedImpact = true
                }
            }
            .navigationTitle(mode.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.actionCancel) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.primaryButtonTitle) {
                        let now = Date()
                        let finalTitle = trimmed(title)

                        switch mode {
                        case .create:
                            let exp = Experiment(
                                title: finalTitle,
                                category: draftCategory,
                                subcategory: draftSubcategory,
                                impact: displayedImpact,
                                status: .active,
                                createdAt: now,
                                updatedAt: now
                            )
                            onCommit(exp)

                        case .rename(let existing):
                            var updated = existing
                            updated.title = finalTitle
                            updated.category = draftCategory
                            updated.subcategory = draftSubcategory
                            updated.impact = displayedImpact
                            updated.updatedAt = now
                            onCommit(updated)

                        case .duplicate(let from):
                            // Create a NEW experiment with a new id + createdAt
                            let exp = Experiment(
                                id: UUID(),
                                title: finalTitle,
                                category: draftCategory,
                                subcategory: draftSubcategory,
                                impact: displayedImpact,
                                status: .active,
                                createdAt: now,
                                updatedAt: now,
                                logs: from.logs,
                                review: nil,
                                completedAt: nil
                            )
                            onCommit(exp)
                        }

                        dismiss()
                    }
                    .disabled(isCreateActionDisabled)
                }
            }
            .onAppear {
                // Prefill from mode
                switch mode {
                case .create:
                    // leave empty
                    break

                case .rename(let existing):
                    prefill(from: existing)

                case .duplicate(let from):
                    // Suggest a default title, but allow user to edit
                    // Prevent duplicate "(Copy)" suffix
                    if from.title.hasSuffix("(Copy)") {
                        title = from.title
                    } else {
                        title = "\(from.title) (Copy)"
                    }
                    prefillCategorySubcategory(from: from)

                    // Prefill impact if it exists
                    if let impact = from.impact {
                        selectedImpact = impact
                        hasManuallyEditedImpact = true
                    }
                }
            }
        }
    }

    // MARK: - Prefill helpers

    private func prefill(from exp: Experiment) {
        title = exp.title
        prefillCategorySubcategory(from: exp)

        // Prefill impact if it exists
        if let impact = exp.impact {
            selectedImpact = impact
            hasManuallyEditedImpact = true
        }
    }

    private func prefillCategorySubcategory(from exp: Experiment) {
        // Try match seed by title; if not found, fall back to custom
        let cat = exp.category
        let sub = exp.subcategory

        guard let catalog = seedCatalog, let cat, !cat.isEmpty else {
            // no category
            useCustomCategory = false
            selectedSeedCategoryId = nil
            useCustomSubcategory = false
            selectedSeedSubcategoryId = nil
            customCategoryText = ""
            customSubcategoryText = sub ?? ""
            return
        }

        if let seedCat = catalog.categories.first(where: { $0.title == cat }) {
            useCustomCategory = false
            selectedSeedCategoryId = seedCat.id
            customCategoryText = ""

            if let sub, !sub.isEmpty,
               let seedSub = seedCat.subcategories.first(where: { $0.title == sub }) {
                useCustomSubcategory = false
                selectedSeedSubcategoryId = seedSub.id
                customSubcategoryText = ""
            } else {
                // subcategory exists but not match -> treat as custom
                useCustomSubcategory = true
                selectedSeedSubcategoryId = nil
                customSubcategoryText = sub ?? ""
            }
        } else {
            // category not in seed -> custom category
            useCustomCategory = true
            selectedSeedCategoryId = nil
            customCategoryText = cat

            // when custom category, subcategory is custom (optional)
            useCustomSubcategory = true
            selectedSeedSubcategoryId = nil
            customSubcategoryText = sub ?? ""
        }
    }
}

