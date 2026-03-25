import SwiftUI

struct ExperimentEditorView: View {
    let seedCatalog: SeedCatalog?
    let mode: ExperimentEditorMode
    let createPrefill: ExperimentEditorPrefill?

    /// called when user taps primary button
    let onCommit: (Experiment) -> Void

    @Environment(\.dismiss) private var dismiss

    // Draft state
    @State private var title: String = ""

    @State private var selectedSeedCategoryId: String?
    @State private var selectedSeedSubcategoryId: String?

    @State private var isOtherCategory: Bool = false
    @State private var useCustomSubcategory: Bool = false
    @State private var pickedSavedSubcategory: Bool = false
    @State private var isProgrammaticSubcategorySet: Bool = false

    @State private var customSubcategoryText: String = ""
    @State private var saveCustomSubcategoryToList: Bool = false
    @StateObject private var savedStore = SubcategorySavedStore()
    @StateObject private var customImpactStore = CustomImpactMappingStore()
    @State private var showManageSheet: Bool = false
    @State private var pendingDeleteSavedName: String? = nil
    @State private var showDeleteSavedConfirm: Bool = false
    @State private var allowsImageLogging: Bool = true

    // Prompt revert state
    @State private var baselineTitleForRevert: String = ""
    @State private var hasBaselineTitle: Bool = false
    @State private var showRevertTitle: Bool = false
    @State private var isProgrammaticTitleChange: Bool = false
    @FocusState private var focusedField: ExperimentEditorFocusField?

    // Dimension state
    @State private var selectedImpact: ExperimentImpact?
    @State private var hasManuallyEditedImpact: Bool = false
    @State private var showDimensionPicker: Bool = false

    // For rename "no changes -> disable"
    private let originalExperiment: Experiment?
    private var preferences = AppPreferences()

    init(
        seedCatalog: SeedCatalog?,
        mode: ExperimentEditorMode,
        createPrefill: ExperimentEditorPrefill? = nil,
        onCommit: @escaping (Experiment) -> Void
    ) {
        self.seedCatalog = seedCatalog
        self.mode = mode
        self.createPrefill = createPrefill
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

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func trimmedOrNil(_ s: String) -> String? {
        let t = trimmed(s)
        return t.isEmpty ? nil : t
    }

    private var customSubcategoryCategoryKey: String? {
        if isOtherCategory { return "__other__" }
        guard let seedId = selectedSeedCategoryId else { return nil }
        return "seed:\(seedId)"
    }

    private var savedCustomSubcategoriesForCurrentCategory: [String] {
        guard let key = customSubcategoryCategoryKey else { return [] }
        return savedStore.saved(for: key)
    }

    private var shouldShowSaveCustomSubcategoryToggle: Bool {
        (isOtherCategory || useCustomSubcategory) &&
            !pickedSavedSubcategory &&
            trimmedOrNil(customSubcategoryText) != nil
    }

    private var willReplaceOldestSavedIfAdded: Bool {
        guard shouldShowSaveCustomSubcategoryToggle else { return false }
        guard let value = trimmedOrNil(customSubcategoryText) else { return false }
        return savedStore.willReplaceOldestIfAdding(value, for: customSubcategoryCategoryKey ?? "")
    }

    private func upsertCustomSubcategory(_ name: String, key: String) {
        savedStore.upsert(name, for: key)
    }

    private func removeCustomSubcategory(_ name: String, key: String) {
        savedStore.remove(name, for: key)

        let selected = trimmed(customSubcategoryText)
        if !selected.isEmpty && selected.caseInsensitiveCompare(name) == .orderedSame {
            customSubcategoryText = ""
            pickedSavedSubcategory = false
            saveCustomSubcategoryToList = false
            if !isOtherCategory {
                useCustomSubcategory = false
                selectedSeedSubcategoryId = nil
            }
        }
    }

    private func enterCustomSubcategoryMode() {
        useCustomSubcategory = true
        selectedSeedSubcategoryId = nil
        customSubcategoryText = ""
        pickedSavedSubcategory = false
        saveCustomSubcategoryToList = false
        focusedField = .customSubcategory
    }

    private func pickSavedSubcategory(_ name: String) {
        useCustomSubcategory = true
        selectedSeedSubcategoryId = nil
        isProgrammaticSubcategorySet = true
        customSubcategoryText = name
        pickedSavedSubcategory = true
        saveCustomSubcategoryToList = false
        DispatchQueue.main.async {
            isProgrammaticSubcategorySet = false
        }
    }

    private func selectSeedSubcategory(_ id: String) {
        useCustomSubcategory = false
        selectedSeedSubcategoryId = id
        customSubcategoryText = ""
        saveCustomSubcategoryToList = false
        pickedSavedSubcategory = false
    }

    private var selectedSeedCategory: SeedCategory? {
        guard let catalog = seedCatalog, let id = selectedSeedCategoryId else { return nil }
        return catalog.categories.first { $0.id == id }
    }

    private var draftCategory: String? {
        if isOtherCategory {
            return "Other"
        } else if let c = selectedSeedCategory {
            return c.title
        }
        return nil
    }

    private var draftSubcategory: String? {
        if isOtherCategory {
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
        if isOtherCategory {
            return "Other"
        }
        if let c = selectedSeedCategory { return c.title }
        return "Select..."
    }

    private var subcategoryDisplayText: String {
        if isOtherCategory {
            if let value = trimmedOrNil(customSubcategoryText) {
                return value
            }
            return "Enter..."
        }

        if useCustomSubcategory {
            if let value = trimmedOrNil(customSubcategoryText) {
                return value
            }
            return "Enter..."
        }

        if let category = selectedSeedCategory,
           let subId = selectedSeedSubcategoryId,
           let sub = category.subcategories.first(where: { $0.id == subId }) {
            return sub.title
        }
        return "Select..."
    }

    private var seedSubcategoryMenuItems: [SeedSubcategory] {
        guard let category = selectedSeedCategory else { return [] }
        return category.subcategories.filter {
            $0.title.caseInsensitiveCompare("None") != .orderedSame
        }
    }

    private var savedSubcategoriesForSeedMenu: [String] {
        let seedLowered = Set(seedSubcategoryMenuItems.map { $0.title.lowercased() })
        return savedCustomSubcategoriesForCurrentCategory.filter { !seedLowered.contains($0.lowercased()) }
    }

    private var canPickSubcategoryFromSeed: Bool {
        // only when a seed category is selected and we are not in Other category
        return !isOtherCategory && selectedSeedCategoryId != nil
    }

    private var hasCategorySelected: Bool {
        return isOtherCategory || selectedSeedCategoryId != nil
    }

    private var hasRequiredSubcategorySelection: Bool {
        if isOtherCategory {
            return trimmedOrNil(customSubcategoryText) != nil
        }
        guard hasSeedCategory else { return false }
        if useCustomSubcategory {
            return trimmedOrNil(customSubcategoryText) != nil
        }
        return selectedSeedSubcategoryId != nil
    }

    private var selectedSeedSubcategory: SeedSubcategory? {
        guard !isOtherCategory,
              !useCustomSubcategory,
              let category = selectedSeedCategory,
              let subId = selectedSeedSubcategoryId else {
            return nil
        }
        return category.subcategories.first(where: { $0.id == subId })
    }

    private var defaultImpact: ExperimentImpact? {
        DefaultDimensionMapping.suggestedImpact(from: selectedSeedSubcategory)
    }

    private var suggestedCustomImpact: ExperimentImpact? {
        guard isCustomSubcategoryMode else { return nil }
        guard let key = customSubcategoryCategoryKey else { return nil }
        guard let text = trimmedOrNil(customSubcategoryText) else { return nil }
        if let history = customImpactStore.suggestedImpact(categoryKey: key, subcategoryText: text) {
            return history
        }
        if isOtherCategory {
            return nil
        }
        if useCustomSubcategory, let seedCategoryId = selectedSeedCategoryId {
            return DefaultDimensionMapping.fallbackImpactForSeedCustomSubcategory(seedCategoryId: seedCategoryId)
        }
        return nil
    }

    private var displayedImpact: ExperimentImpact? {
        if hasManuallyEditedImpact {
            return selectedImpact
        }
        if isSeedBased {
            return defaultImpact
        }
        if isCustomSubcategoryMode {
            return suggestedCustomImpact
        }
        return nil
    }

    private var isSeedBased: Bool {
        return !isOtherCategory && selectedSeedCategoryId != nil && selectedSeedSubcategoryId != nil
    }

    private var isCustom: Bool {
        return isOtherCategory
    }

    private var isCustomSubcategoryMode: Bool {
        isOtherCategory || useCustomSubcategory
    }

    private var hasSeedCategory: Bool {
        return !isOtherCategory && selectedSeedCategoryId != nil
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

    private var shouldHideTitlePromptsForPrefill: Bool {
        guard case .create = mode else { return false }
        guard let createPrefill else { return false }
        return !trimmed(createPrefill.title).isEmpty &&
            !(createPrefill.categoryTitle ?? "").isEmpty &&
            !(createPrefill.subcategoryTitle ?? "").isEmpty
    }

    private var isCreateActionDisabled: Bool {
        let t = trimmed(title)
        if t.isEmpty { return true }

        if !hasCategorySelected {
            return true
        }

        let isCreateOrDuplicate: Bool = {
            if case .create = mode { return true }
            if case .duplicate = mode { return true }
            return false
        }()

        if !hasRequiredSubcategorySelection {
            return true
        }

        // For custom subcategory mode in create/duplicate, require an available impact
        if isCustomSubcategoryMode && isCreateOrDuplicate && displayedImpact == nil {
            return true
        }

        // rename mode: disable if no changes
        if case .rename = mode, let original = originalExperiment {
            let sameTitle = trimmed(original.title) == t
            let sameCategory = (original.category ?? "") == (draftCategory ?? "")
            let sameSub = (original.subcategory ?? "") == (draftSubcategory ?? "")
            let sameImpact = (original.impact == displayedImpact)
            let sameImageSetting = original.allowsImageLogging == allowsImageLogging
            return sameTitle && sameCategory && sameSub && sameImpact && sameImageSetting
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

    @ViewBuilder
    private var imageLoggingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Logging")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            cardBackground {
                Toggle("Allow images for this experiment", isOn: $allowsImageLogging)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {

                TitleSection(title: $title, focusedField: $focusedField)

                // Suggested Prompts
                if !availablePrompts.isEmpty && !shouldHideTitlePromptsForPrefill {
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

                CategorySection(
                    seedCatalog: seedCatalog,
                    isOtherCategory: $isOtherCategory,
                    selectedSeedCategoryId: $selectedSeedCategoryId,
                    selectedSeedSubcategoryId: $selectedSeedSubcategoryId,
                    useCustomSubcategory: $useCustomSubcategory,
                    customSubcategoryText: $customSubcategoryText,
                    saveCustomSubcategoryToList: $saveCustomSubcategoryToList,
                    pickedSavedSubcategory: $pickedSavedSubcategory,
                    categoryDisplayText: categoryDisplayText,
                    onDismissKeyboard: {
                        focusedField = nil
                    }
                )

                SubcategorySection(
                    isOtherCategory: isOtherCategory,
                    canPickSubcategoryFromSeed: canPickSubcategoryFromSeed,
                    hasCategorySelected: hasCategorySelected,
                    subcategoryDisplayText: subcategoryDisplayText,
                    savedCustomSubcategoriesForCurrentCategory: savedCustomSubcategoriesForCurrentCategory,
                    seedSubcategoryMenuItems: seedSubcategoryMenuItems,
                    savedSubcategoriesForSeedMenu: savedSubcategoriesForSeedMenu,
                    useCustomSubcategory: useCustomSubcategory,
                    pickedSavedSubcategory: pickedSavedSubcategory,
                    shouldShowSaveCustomSubcategoryToggle: shouldShowSaveCustomSubcategoryToggle,
                    willReplaceOldestSavedIfAdded: willReplaceOldestSavedIfAdded,
                    customSubcategoryText: $customSubcategoryText,
                    saveCustomSubcategoryToList: $saveCustomSubcategoryToList,
                    showManageSheet: $showManageSheet,
                    enterCustomSubcategoryMode: enterCustomSubcategoryMode,
                    pickSavedSubcategory: pickSavedSubcategory,
                    selectSeedSubcategoryId: selectSeedSubcategory,
                    onDismissKeyboard: {
                        focusedField = nil
                    }
                )

                if !hasCategorySelected {
                    Text("Please select a category.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.top, -8)
                } else if !hasRequiredSubcategorySelection {
                    Text(isOtherCategory ? "Please enter a subcategory." : "Please select a subcategory.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.top, -8)
                }

                DimensionSection(
                    isSeedBased: isSeedBased,
                    isCustomSubcategoryMode: isCustomSubcategoryMode,
                    displayedImpact: displayedImpact,
                    showDimensionPicker: $showDimensionPicker
                )

                if preferences.imageLoggingEnabled {
                    imageLoggingSection
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
            .onChange(of: customSubcategoryText) { _, newValue in
                if isProgrammaticSubcategorySet {
                    return
                }
                if pickedSavedSubcategory && trimmedOrNil(newValue) != nil {
                    pickedSavedSubcategory = false
                }
            }
            .onChange(of: isOtherCategory) { _, newValue in
                // Reset manual editing flag when switching between Other and seed
                hasManuallyEditedImpact = false
                selectedImpact = newValue ? nil : defaultImpact
            }
            .sheet(isPresented: $showManageSheet) {
                NavigationStack {
                    List {
                        ForEach(savedCustomSubcategoriesForCurrentCategory, id: \.self) { name in
                            HStack {
                                Text(name)
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    pendingDeleteSavedName = name
                                    showDeleteSavedConfirm = true
                                }
                                .buttonStyle(.borderless)
                                .font(.subheadline)
                            }
                        }

                        Section {
                            Text("Saved subcategories (max 5). Newest kept.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .navigationTitle("Manage Saved")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showManageSheet = false
                            }
                        }
                    }
                    .alert("Delete saved subcategory?", isPresented: $showDeleteSavedConfirm, presenting: pendingDeleteSavedName) { name in
                        Button("Cancel", role: .cancel) {
                            pendingDeleteSavedName = nil
                        }
                        Button("Delete", role: .destructive) {
                            if let key = customSubcategoryCategoryKey {
                                removeCustomSubcategory(name, key: key)
                            }
                            pendingDeleteSavedName = nil
                        }
                    } message: { name in
                        Text(name)
                    }
                }
            }
            .sheet(isPresented: $showDimensionPicker) {
                DimensionPickerSheet(initialImpact: displayedImpact) { newImpact in
                    selectedImpact = newImpact
                    hasManuallyEditedImpact = true
                    if isCustomSubcategoryMode,
                       let key = customSubcategoryCategoryKey,
                       let text = trimmedOrNil(customSubcategoryText) {
                        customImpactStore.saveImpact(newImpact, categoryKey: key, subcategoryText: text)
                    }
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
                        let finalCustomSubcategory = trimmedOrNil(customSubcategoryText)

                        if saveCustomSubcategoryToList,
                           shouldShowSaveCustomSubcategoryToggle,
                           let key = customSubcategoryCategoryKey,
                           let value = finalCustomSubcategory {
                            upsertCustomSubcategory(value, key: key)
                        }

                        switch mode {
                        case .create:
                            let exp = Experiment(
                                title: finalTitle,
                                category: draftCategory,
                                subcategory: draftSubcategory,
                                impact: displayedImpact,
                                status: .active,
                                createdAt: now,
                                updatedAt: now,
                                allowsImageLogging: allowsImageLogging
                            )
                            onCommit(exp)

                        case .rename(let existing):
                            var updated = existing
                            updated.title = finalTitle
                            updated.category = draftCategory
                            updated.subcategory = draftSubcategory
                            updated.impact = displayedImpact
                            updated.allowsImageLogging = allowsImageLogging
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
                                completedAt: nil,
                                allowsImageLogging: allowsImageLogging
                            )
                            onCommit(exp)
                        }

                        dismiss()
                    }
                    .disabled(isCreateActionDisabled)
                }
            }
            .onAppear {
                savedStore.loadIfNeeded(seedCatalog: seedCatalog)
                customImpactStore.loadIfNeeded()

                // Prefill from mode
                switch mode {
                case .create:
                    allowsImageLogging = preferences.imageLoggingEnabled
                    applyCreatePrefillIfNeeded()

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
                    allowsImageLogging = from.allowsImageLogging
                }
            }
        }
    }

    // MARK: - Prefill helpers

    private func prefill(from exp: Experiment) {
        title = exp.title
        prefillCategorySubcategory(from: exp)
        allowsImageLogging = exp.allowsImageLogging

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
            isOtherCategory = false
            selectedSeedCategoryId = nil
            useCustomSubcategory = false
            selectedSeedSubcategoryId = nil
            customSubcategoryText = sub ?? ""
            saveCustomSubcategoryToList = false
            pickedSavedSubcategory = false
            return
        }

        if let seedCat = catalog.categories.first(where: { $0.title == cat }) {
            isOtherCategory = false
            selectedSeedCategoryId = seedCat.id

            if let sub, !sub.isEmpty,
               let seedSub = seedCat.subcategories.first(where: { $0.title == sub }) {
                useCustomSubcategory = false
                selectedSeedSubcategoryId = seedSub.id
                customSubcategoryText = ""
                pickedSavedSubcategory = false
            } else {
                // subcategory exists but not match -> treat as custom
                useCustomSubcategory = true
                selectedSeedSubcategoryId = nil
                customSubcategoryText = sub ?? ""
                pickedSavedSubcategory = false
            }
            saveCustomSubcategoryToList = false
        } else {
            // category not in seed -> Other category
            isOtherCategory = true
            selectedSeedCategoryId = nil

            // when Other category, subcategory is custom (optional)
            useCustomSubcategory = false
            selectedSeedSubcategoryId = nil
            customSubcategoryText = sub ?? ""
            saveCustomSubcategoryToList = false
            pickedSavedSubcategory = false
        }
    }

    private func applyCreatePrefillIfNeeded() {
        guard let createPrefill else { return }

        title = createPrefill.title

        // If the prefill category matches an existing seed category title, reuse it.
        // Otherwise leave category unset for the user to choose safely.
        if let categoryTitle = createPrefill.categoryTitle,
           let catalog = seedCatalog,
           let seedCat = catalog.categories.first(where: { $0.title == categoryTitle }) {
            isOtherCategory = false
            selectedSeedCategoryId = seedCat.id

            if let subcategoryTitle = createPrefill.subcategoryTitle,
               let seedSub = seedCat.subcategories.first(where: { $0.title == subcategoryTitle }) {
                useCustomSubcategory = false
                selectedSeedSubcategoryId = seedSub.id
                customSubcategoryText = ""
            } else {
                useCustomSubcategory = false
                selectedSeedSubcategoryId = nil
                customSubcategoryText = ""
            }
        }
    }
}

