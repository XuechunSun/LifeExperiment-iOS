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
    
    // Seed catalog
    @State private var seedCatalog: SeedCatalog?

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

    private func seedExperimentsIfNeeded() {
        if getExperiments().isEmpty {
            let now = Date()
            let defaultExperiment = Experiment(
                title: "My First Experiment",
                status: .active,
                createdAt: now,
                updatedAt: now
            )
            setExperiments([defaultExperiment])
        }
    }
    
    private func sortedExperiments() -> [Experiment] {
        let experiments = getExperiments()
        return experiments.filter { $0.status == .active }.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func resetAllLocalData() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }

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
                Label(S.tabHome, systemImage: "house.fill")
            }
            .tag(Tab.home)
            
            // Tab 2: Active Experiments
            NavigationStack(path: $activePath) {
                activeExperimentsView
                    .navigationTitle(S.tabActive)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route: route, path: $activePath)
                    }
            }
            .tabItem {
                Label(S.tabActive, systemImage: "list.bullet")
            }
            .tag(Tab.active)
            
            // Tab 3: Create (placeholder - sheet is presented via onChange)
            Color.clear
                .tabItem {
                    Label(S.tabCreate, systemImage: "plus.circle.fill")
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
                Label(S.tabSummary, systemImage: "chart.bar.fill")
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
                Label(S.tabProfile, systemImage: "person.fill")
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
            createPrefill = nil
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
        .onAppear {
            seedExperimentsIfNeeded()
            if seedCatalog == nil {
                seedCatalog = SeedCatalogLoader.load()
            }
        }
        .alert(S.experimentDeleteConfirm, isPresented: Binding(
            get: { experimentToDelete != nil },
            set: { if !$0 { experimentToDelete = nil } }
        ), presenting: experimentToDelete) { experiment in
            Button(S.actionCancel, role: .cancel) {
                experimentToDelete = nil
            }
            Button(S.actionDelete, role: .destructive) {
                deleteExperiment(id: experiment.id)
                experimentToDelete = nil
            }
        } message: { experiment in
            Text("All logs and data for \"\(experiment.title)\" " + S.experimentDeleteMessage)
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
                    
                    Text(S.emptyNoActiveExperiments)
                        .font(DSText.title2)
                        .fontWeight(.semibold)
                    
                    Text(S.emptyNoActiveSubtitle)
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        selectedTab = .create
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(S.actionCreate + " Experiment")
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
                .id("\(experiment.id.uuidString)-\(experiment.updatedAt.timeIntervalSinceReferenceDate)")
            } else {
                Text("Experiment not found")
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
