//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI
import UIKit
import Foundation

// MARK: - Content View

struct ContentView: View {
    enum LoggingStatus: String {
        case idle
        case logging
        case logged
    }
    
    enum ActiveSheet: Identifiable {
        case rename(Experiment)
        case duplicate(Experiment)
        
        var id: String {
            switch self {
            case .rename(let exp):
                return "rename-\(exp.id.uuidString)"
            case .duplicate(let exp):
                return "duplicate-\(exp.id.uuidString)"
            }
        }
    }

    @AppStorage("app_language") private var appLanguageRaw: String = ""

    // Persistent storage
    @AppStorage("dayCount") private var dayCount: Int = 1
    @AppStorage("statusRaw") private var statusRaw: String = LoggingStatus.idle.rawValue
    @AppStorage("historyData") private var historyData: Data = .init()
    @AppStorage("experimentsData") private var experimentsData: Data = .init()
    @AppStorage("lowEnergyLogsData") private var lowEnergyLogsData: Data = .init()
    
    // Tab state
    @State private var selectedTab: Tab = .home
    
    // Navigation state (separate paths for each tab)
    @State private var homePath: [Route] = []
    @State private var activePath: [Route] = []
    @State private var summaryPath: [Route] = []
    @State private var profilePath: [Route] = []
    @State private var rootRefreshID = UUID()
    
    @State private var selectedDay: DayRecord?
    @State private var showCreateExperimentSheet: Bool = false
    @State private var showLowEnergyFlow: Bool = false
    @State private var experimentToDelete: Experiment?
    @State private var activeSheet: ActiveSheet?
    @State private var createPrefill: ExperimentEditorPrefill?
    @State private var actionToastMessage: String?
    @State private var isHandlingActiveSheetCommit = false

    // Phase 2 onboarding (v1.1). The cover is shown when `OnboardingState.stage`
    // is `.notStarted` or `.introSeen` on first appear of the root TabView.
    // `pendingOnboardingPrefill` carries the starter prefill across the cover's
    // dismiss → Create sheet present hand-off so the two presentations sequence
    // cleanly (we hand `createPrefill` only inside `onDismiss`).
    @State private var isShowingOnboarding: Bool = false
    @State private var pendingOnboardingPrefill: ExperimentEditorPrefill?
    @State private var hasEvaluatedOnboardingForLaunch: Bool = false

    // Phase 3 marker: distinguishes a Create sheet that was opened from the
    // onboarding starter pick from every other create path (Create tab, Home
    // suggestion prefill, rename, duplicate). Set in the cover's
    // `onStarterChosen` callback, consumed exactly once in either
    // `handleCreateCommit` (commit branch) or the item-driven sheet's
    // `onDismiss` (cancel branch). Cleared on every consumption so it can
    // never leak across unrelated subsequent creates.
    @State private var isOnboardingCreateInProgress: Bool = false
    
    // Seed catalog
    @State private var seedCatalog: SeedCatalog?

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    // MARK: - Persistence helpers

    private func getStatus() -> LoggingStatus {
        LoggingStatus(rawValue: statusRaw) ?? .idle
    }

    private func setStatus(_ newStatus: LoggingStatus) {
        statusRaw = newStatus.rawValue
    }

    private func getHistory() -> [DayRecord] {
        (try? JSONDecoder().decode([DayRecord].self, from: historyData)) ?? []
    }

    private func setHistory(_ newHistory: [DayRecord]) {
        if let encoded = try? JSONEncoder().encode(newHistory) {
            historyData = encoded
        }
    }
    
    private func getExperiments() -> [Experiment] {
        (try? JSONDecoder().decode([Experiment].self, from: experimentsData)) ?? []
    }
    
    private func setExperiments(_ experiments: [Experiment]) {
        if let encoded = try? JSONEncoder().encode(experiments) {
            experimentsData = encoded
        }
    }
    
    // MARK: - Low Energy Log persistence (CL#1: one per day, CL#5: decode safety)

    private func getLowEnergyLogs() -> [LowEnergyLog] {
        (try? JSONDecoder().decode([LowEnergyLog].self, from: lowEnergyLogsData)) ?? []
    }

    private func setLowEnergyLogs(_ logs: [LowEnergyLog]) {
        let sorted = logs.sorted { $0.date > $1.date }
        if let encoded = try? JSONEncoder().encode(sorted) {
            lowEnergyLogsData = encoded
        }
    }

    func addLowEnergyLog(_ log: LowEnergyLog) {
        var logs = getLowEnergyLogs()
        let calendar = Calendar.current
        if let existingIndex = logs.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: log.date) }) {
            logs[existingIndex] = log
        } else {
            logs.append(log)
        }
        setLowEnergyLogs(logs)
    }

    /// Deprecated as of v1.1 — onboarding owns first-experiment creation.
    /// Retained for one release so that any in-flight code paths or rollback
    /// branches can find the symbol; remove in a later cleanup pass.
    private func seedExperimentsIfNeeded() {
        if getExperiments().isEmpty {
            let now = Date()
            let defaultExperiment = Experiment(
                title: L.seedStarterExperimentTitle(lang),
                status: .active,
                createdAt: now,
                updatedAt: now
            )
            setExperiments([defaultExperiment])
        }
    }

    /// Startup checks: migrate legacy starter title when eligible.
    /// (v1.1: auto-seed removed — `seedExperimentsIfNeeded()` is no longer called.
    /// First-experiment creation now goes through the onboarding flow.)
    private func runStarterPersistenceChecks() {
        migrateLegacyStarterExperimentTitleIfNeeded()
        // seedExperimentsIfNeeded() — removed in v1.1; see comment above.
    }

    /// One-time-style migration: legacy seeded title → localized starter title when clearly untouched.
    private func migrateLegacyStarterExperimentTitleIfNeeded() {
        let legacyTitle = "My First Experiment"
        var experiments = getExperiments()
        guard experiments.count == 1,
              var only = experiments.first,
              only.title == legacyTitle,
              only.logs.isEmpty,
              only.review == nil,
              only.status == .active,
              only.completedAt == nil
        else { return }

        only.title = L.seedStarterExperimentTitle(lang)
        only.updatedAt = Date()
        experiments[0] = only
        setExperiments(experiments)
    }

    private func sortedExperiments() -> [Experiment] {
        let experiments = getExperiments()
        return experiments.filter { $0.status == .active }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func resetAllLocalData() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }
        // Note: removes all UserDefaults keys, including profile_developer_tools_unlocked → developer tools hidden after reset.

        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logPhotosURL = documentsURL.appendingPathComponent("LogPhotos", isDirectory: true)
            if fileManager.fileExists(atPath: logPhotosURL.path) {
                try? fileManager.removeItem(at: logPhotosURL)
            }
        }

        dayCount = 1
        statusRaw = LoggingStatus.idle.rawValue
        historyData = .init()
        experimentsData = .init()
        lowEnergyLogsData = .init()

        selectedTab = .home
        homePath = []
        activePath = []
        summaryPath = []
        profilePath = []
        selectedDay = nil
        showCreateExperimentSheet = false
        showLowEnergyFlow = false
        experimentToDelete = nil
        activeSheet = nil
        createPrefill = nil
        rootRefreshID = UUID()
    }
    
    func updateExperiment(_ updated: Experiment) {
        var experiments = getExperiments()
        if let index = experiments.firstIndex(where: { $0.id == updated.id }) {
            experiments[index] = updated
            setExperiments(experiments)
        }
    }
    
    func addExperiment(_ experiment: Experiment) {
        var experiments = getExperiments()
        experiments.append(experiment)
        setExperiments(experiments)
    }
    
    func deleteExperiment(id: UUID) {
        var experiments = getExperiments()
        experiments.removeAll { $0.id == id }
        setExperiments(experiments)
    }

    private func handleCreateCommit(_ experiment: Experiment, dismissStandardCreateSheet: Bool) {
        // Onboarding hand-off (v1.1 Phase 3): when the create sheet was opened
        // from the onboarding starter pick, anchor the guided experiment id
        // and advance the onboarding stage. We require BOTH the marker AND
        // `stage == .introSeen` so any unrelated commit (Create tab, Home
        // suggestion, rename, duplicate) is ignored. The marker is cleared
        // unconditionally BEFORE we nil `createPrefill`, otherwise the sheet's
        // own `onDismiss` would observe a stale `true` and reopen the cover
        // after a successful save.
        if isOnboardingCreateInProgress && OnboardingState.stage == .introSeen {
            OnboardingState.guidedExperimentId = experiment.id.uuidString
            OnboardingState.stage = .experimentCreated
        }
        isOnboardingCreateInProgress = false

        addExperiment(experiment)
        createPrefill = nil

        if dismissStandardCreateSheet {
            showCreateExperimentSheet = false
        }

        selectedTab = .active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activePath.append(.experiment(experiment.id))
        }
    }

    private func showActionToast(_ message: String) {
        Haptics.success()
        actionToastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if actionToastMessage == message {
                actionToastMessage = nil
            }
        }
    }

    private func handleRenameCommit(_ updated: Experiment) {
        guard !isHandlingActiveSheetCommit else { return }
        isHandlingActiveSheetCommit = true
        updateExperiment(updated)
        activeSheet = nil
        showActionToast("Renamed")
        DispatchQueue.main.async {
            isHandlingActiveSheetCommit = false
        }
    }

    private func handleDuplicateCommit(_ created: Experiment) {
        guard !isHandlingActiveSheetCommit else { return }
        isHandlingActiveSheetCommit = true
        addExperiment(created)
        activeSheet = nil
        showActionToast("Duplicated")
        selectedTab = .active
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            activePath = [.experiment(created.id)]
            isHandlingActiveSheetCommit = false
        }
    }

    var message: String {
        switch getStatus() {
        case .idle:
            return "Life Experiment 🌱"
        case .logging:
            return "Life Experiment 🌱"
        case .logged:
            return "Experiment Logged 🌿"
        }
    }

    func moveToNextDay() {
        // Only record day if not already in history (prevents duplicates)
        var h = getHistory()
        if !h.contains(where: { $0.day == dayCount }) {
            h.append(DayRecord(day: dayCount))
            setHistory(h)
        }
        dayCount += 1
        setStatus(.idle)
    }
    
    func updateRecord(_ updated: DayRecord) {
        var h = getHistory()
        if let index = h.firstIndex(where: { $0.id == updated.id }) {
            h[index] = updated
            setHistory(h)
        }
    }
    
    func historyLabel(for record: DayRecord) -> String {
        var label = "Day \(record.day)"
        if let mood = record.mood {
            label += " \(mood.emoji)"
        }
        if !record.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            label += " 📝"
        }
        return label
    }

    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Day \(dayCount)")
                .font(DSText.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(DSText.title)
        }
    }

    var historySection: some View {
        let h = getHistory()
        return Group {
            if !h.isEmpty {
                VStack(spacing: 8) {
                    Text("Completed Days:")
                        .font(DSText.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        ForEach(h) { record in
                            Button(historyLabel(for: record)) {
                                selectedDay = record
                            }
                            .font(DSText.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    var idleSection: some View {
            Button("Log Today") {
            setStatus(.logging)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                setStatus(.logged)
            }
        }
    }

    var loggingSection: some View {
        Text("Saving...")
            .foregroundColor(.secondary)
            .italic()
    }

    var loggedSection: some View {
        VStack(spacing: 12) {
            Text("Logged ✓")
                .foregroundColor(.green)

            HStack(spacing: 12) {
                Button("Next Day") {
                    moveToNextDay()
                }
                .buttonStyle(.bordered)

                Button("Log out") {
                    setStatus(.idle)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            NavigationStack(path: $homePath) {
                HomeView(
                    loadExperiments: getExperiments,
                    lowEnergyLogs: getLowEnergyLogs(),
                    seedCatalog: seedCatalog,
                    onCreateExperiment: {
                        createPrefill = nil
                        showCreateExperimentSheet = true
                    },
                    onStartLowEnergy: {
                        showLowEnergyFlow = true
                    },
                    onTrySuggestion: { suggestion in
                        createPrefill = ExperimentEditorPrefill(
                            title: suggestion.title,
                            categoryTitle: suggestion.prefillCategoryTitle,
                            subcategoryTitle: suggestion.prefillSubcategoryTitle,
                            impact: suggestion.impact
                        )
                    },
                    onSelectExperiment: { experiment in
                        homePath.append(.experiment(experiment.id))
                    },
                    onUpdate: updateExperiment,
                    onShowActiveMore: {
                        homePath.append(.activeMore)
                    },
                    onShowCompletedMore: {
                        homePath.append(.completedMore)
                    },
                    onShowSummary: {
                        // Navigate to Summary tab instead
                        selectedTab = .summary
                    },
                    onSelectDay: { day in
                        homePath.append(.day(day))
                    },
                    onRenameExperiment: { experiment in
                        activeSheet = .rename(experiment)
                    },
                    onDuplicateExperiment: { experiment in
                        activeSheet = .duplicate(experiment)
                    },
                    onDeleteExperiment: { experiment in
                        experimentToDelete = experiment
                    }
                )
                .navigationTitle("MiniLab")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    routeDestination(route: route, path: $homePath)
                }
            }
            .tabItem {
                Label(L.tabHome(lang), systemImage: "house.fill")
            }
            .tag(Tab.home)
            
            // Tab 2: Active Experiments
            NavigationStack(path: $activePath) {
                activeExperimentsView
                    .navigationTitle(L.active(lang))
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route: route, path: $activePath)
                    }
            }
            .tabItem {
                Label(L.tabActive(lang), systemImage: "list.bullet")
            }
            .tag(Tab.active)
            
            // Tab 3: Create (placeholder - sheet is presented via onChange)
            Color.clear
                .tabItem {
                    Label(L.tabCreate(lang), systemImage: "plus.circle.fill")
                }
                .tag(Tab.create)
            
            // Tab 4: Summary
            NavigationStack(path: $summaryPath) {
                SummaryView(loadExperiments: getExperiments, lowEnergyLogs: getLowEnergyLogs(), onUpdate: updateExperiment, seedCatalog: seedCatalog)
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route: route, path: $summaryPath)
                    }
            }
            .tabItem {
                Label(L.tabSummary(lang), systemImage: "chart.bar.fill")
            }
            .tag(Tab.summary)
            
            // Tab 5: Profile
            NavigationStack(path: $profilePath) {
                ProfileView(
                    loadExperiments: getExperiments,
                    lowEnergyLogs: getLowEnergyLogs(),
                    onResetAllData: resetAllLocalData
                )
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route: route, path: $profilePath)
                    }
            }
            .tabItem {
                Label(L.tabProfile(lang), systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
        .id(rootRefreshID)
        .onChange(of: selectedTab) { oldValue, newValue in
            // When user switches to Create tab, present the create sheet
            if newValue == .create {
                createPrefill = nil
                showCreateExperimentSheet = true
            }
        }
        // TODO: Keep these as two presentation paths for now:
        // - Bool-driven sheet handles the normal Create tab / empty create flow
        // - Item-driven sheet handles suggestion-prefilled create reliably on first tap
        // If create entry points expand further, consolidate behind a single presentation coordinator.
        .sheet(isPresented: $showCreateExperimentSheet, onDismiss: {
            // When create sheet is dismissed, return to Home if still on Create tab
            createPrefill = nil
            if selectedTab == .create {
                selectedTab = .home
            }
        }) {
            ExperimentEditorView(seedCatalog: seedCatalog, mode: .create, createPrefill: createPrefill) { experiment in
                handleCreateCommit(experiment, dismissStandardCreateSheet: true)
            }
        }
        .sheet(item: $createPrefill, onDismiss: {
            // Capture marker before any state changes so we can reliably tell
            // whether this dismissal came from the onboarding-prefilled path.
            // `handleCreateCommit` clears the marker AND advances stage to
            // `.experimentCreated` on a successful save, so a committed save
            // cannot match the reopen condition below.
            let wasOnboardingCreate = isOnboardingCreateInProgress
            createPrefill = nil

            if wasOnboardingCreate && OnboardingState.stage == .introSeen {
                isOnboardingCreateInProgress = false
                // Defer the cover re-presentation by one runloop tick so the
                // dismissing sheet's hosting view has fully torn down before
                // the fullScreenCover tries to claim the screen.
                DispatchQueue.main.async {
                    isShowingOnboarding = true
                }
            }
        }) { prefill in
            ExperimentEditorView(seedCatalog: seedCatalog, mode: .create, createPrefill: prefill) { experiment in
                handleCreateCommit(experiment, dismissStandardCreateSheet: false)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .rename(let experiment):
                ExperimentEditorView(seedCatalog: seedCatalog, mode: .rename(existing: experiment)) { updated in
                    handleRenameCommit(updated)
                }
            case .duplicate(let experiment):
                ExperimentEditorView(seedCatalog: seedCatalog, mode: .duplicate(from: experiment)) { created in
                    handleDuplicateCommit(created)
                }
            }
        }
        .sheet(isPresented: $showLowEnergyFlow) {
            LowEnergyFlowView { log in
                addLowEnergyLog(log)
                showLowEnergyFlow = false
            } onDismiss: {
                showLowEnergyFlow = false
            }
        }
        .fullScreenCover(isPresented: $isShowingOnboarding, onDismiss: {
            // After the cover finishes dismissing, hand any pending starter
            // prefill to the existing `.sheet(item: $createPrefill)` so the two
            // presentations don't fight for the screen.
            if let prefill = pendingOnboardingPrefill {
                pendingOnboardingPrefill = nil
                createPrefill = prefill
            } else {
                // No prefill in flight (Skip path or an unexpected dismiss).
                // Make sure the onboarding-create marker is clean so any later
                // Create commit cannot accidentally write onboarding state.
                isOnboardingCreateInProgress = false
            }
        }) {
            // Resume at starter pick for users who quit after intro 2.
            let initialStep: OnboardingStep = (OnboardingState.stage == .introSeen)
                ? .starterPick
                : .intro1
            OnboardingFlowView(
                initialStep: initialStep,
                onStarterChosen: { prefill in
                    // Mark this specific Create open as the onboarding one.
                    // The marker is consumed in `handleCreateCommit` (save) or
                    // `.sheet(item: $createPrefill).onDismiss` (cancel).
                    pendingOnboardingPrefill = prefill
                    isOnboardingCreateInProgress = true
                    isShowingOnboarding = false
                },
                onSkipConfirmed: {
                    isShowingOnboarding = false
                }
            )
        }
        .onAppear {
            OnboardingState.evaluateOnLaunch(loadExperiments: { getExperiments() })
            runStarterPersistenceChecks()
            if seedCatalog == nil {
                seedCatalog = SeedCatalogLoader.load()
            }
            // First-run onboarding presentation: evaluate exactly once per
            // cold launch so navigating around the app doesn't re-trigger the
            // cover after the user has dismissed it in this session.
            if !hasEvaluatedOnboardingForLaunch {
                hasEvaluatedOnboardingForLaunch = true
                let stage = OnboardingState.stage
                if stage == .notStarted || stage == .introSeen {
                    isShowingOnboarding = true
                }
            }
        }
        .alert(L.experimentDeleteConfirm(lang), isPresented: Binding(
            get: { experimentToDelete != nil },
            set: { if !$0 { experimentToDelete = nil } }
        ), presenting: experimentToDelete) { experiment in
            Button(L.actionCancel(lang), role: .cancel) {
                experimentToDelete = nil
            }
            Button(L.actionDelete(lang), role: .destructive) {
                deleteExperiment(id: experiment.id)
                experimentToDelete = nil
            }
        } message: { experiment in
            Text(L.experimentDeleteBody(
                lang,
                experimentTitle: BuiltInTitleDisplay.localizedTitle(stored: experiment.title, lang: lang)
            ))
        }
        .overlay(alignment: .top) {
            if let actionToastMessage {
                Text(actionToastMessage)
                    .font(DSText.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Active Experiments View
    
    private var activeExperimentsView: some View {
        let activeExperiments = getExperiments().filter { $0.status == .active }
            .sorted { $0.updatedAt > $1.updatedAt }
        
        return Group {
            if activeExperiments.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "tray")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text(L.noActiveExperiments(lang))
                        .font(DSText.title2)
                        .fontWeight(.semibold)
                    
                    Text(L.noActiveExperimentsSubtitle(lang))
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        selectedTab = .create
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(L.createExperimentButton(lang))
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(primaryLavenderButton)
                        .cornerRadius(10)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            } else {
                AllActiveListView(
                    activeExperiments: activeExperiments,
                    isUpdatedToday: { experiment in
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        
                        // Check if created, logged, or completed today
                        if calendar.isDate(experiment.createdAt, inSameDayAs: today) {
                            return true
                        }
                        if experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                            return true
                        }
                        if let completedAt = experiment.completedAt, calendar.isDate(completedAt, inSameDayAs: today) {
                            return true
                        }
                        return false
                    },
                    onSelectExperiment: { experiment in
                        activePath.append(.experiment(experiment.id))
                    },
                    onCreateExperiment: {
                        showCreateExperimentSheet = true
                    },
                    onRename: { experiment in
                        activeSheet = .rename(experiment)
                    },
                    onDuplicate: { experiment in
                        activeSheet = .duplicate(experiment)
                    },
                    onDelete: { experiment in
                        experimentToDelete = experiment
                    }
                )
            }
        }
    }
    
    // MARK: - Route Destination (Reusable navigation handler)
    
    @ViewBuilder
    private func routeDestination(route: Route, path: Binding<[Route]>) -> some View {
        switch route {
        case .experiment(let id):
            let experiments = getExperiments()
            if let experiment = experiments.first(where: { $0.id == id }) {
                ExperimentDetailView(
                    experiment: experiment,
                    isNewUser: ExperimentDetailView.shouldShowFirstLogGuidance(for: experiments),
                    onUpdate: updateExperiment
                )
                // Stable per experiment: id must NOT include updatedAt, or each save remounts the view
                // and clears @State (e.g. the post-save success toast).
                .id(experiment.id.uuidString)
            } else {
                Text(L.experimentNotFound(lang))
                    .foregroundColor(.secondary)
            }
            
        case .activeMore:
            let activeExperiments = getExperiments().filter { $0.status == .active }
                .sorted { $0.updatedAt > $1.updatedAt }
            AllActiveListView(
                activeExperiments: activeExperiments,
                isUpdatedToday: { experiment in
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    // Check if created, logged, or completed today
                    if calendar.isDate(experiment.createdAt, inSameDayAs: today) {
                        return true
                    }
                    if experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                        return true
                    }
                    if let completedAt = experiment.completedAt, calendar.isDate(completedAt, inSameDayAs: today) {
                        return true
                    }
                    return false
                },
                onSelectExperiment: { experiment in
                    path.wrappedValue.append(.experiment(experiment.id))
                },
                onCreateExperiment: {
                    showCreateExperimentSheet = true
                },
                onRename: { experiment in
                    activeSheet = .rename(experiment)
                },
                onDuplicate: { experiment in
                    activeSheet = .duplicate(experiment)
                },
                onDelete: { experiment in
                    experimentToDelete = experiment
                }
            )
            
        case .completedMore:
            let completedExperiments = getExperiments()
                .filter { $0.status == .completed }
                .sorted { exp1, exp2 in
                    let date1 = exp1.completedAt ?? exp1.updatedAt
                    let date2 = exp2.completedAt ?? exp2.updatedAt
                    return date1 > date2
                }
            CompletedListView(
                completedExperiments: completedExperiments,
                onSelectExperiment: { experiment in
                    path.wrappedValue.append(.experiment(experiment.id))
                },
                onDuplicate: { experiment in
                    activeSheet = .duplicate(experiment)
                },
                onDelete: { experiment in
                    experimentToDelete = experiment
                }
            )
            
        case .summary:
            SummaryView(loadExperiments: getExperiments, lowEnergyLogs: getLowEnergyLogs(), onUpdate: updateExperiment, seedCatalog: seedCatalog)
            
        case .day(let date):
            DayDetailView(day: date, experiments: getExperiments(), lowEnergyLogs: getLowEnergyLogs(), onUpdate: updateExperiment)
        }
    }
    
    func dayDetailView(for record: DayRecord) -> some View {
        DayDetailContent(record: record, updateRecord: updateRecord)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
