//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI

enum Mood: String, CaseIterable, Identifiable, Codable, Hashable {
    case veryBad, bad, neutral, good, veryGood
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .veryBad: return "😞"
        case .bad: return "🙁"
        case .neutral: return "😐"
        case .good: return "🙂"
        case .veryGood: return "😄"
        }
    }
    
    var labelCN: String {
        switch self {
        case .veryBad: return "很差"
        case .bad: return "不太好"
        case .neutral: return "一般"
        case .good: return "不错"
        case .veryGood: return "很好"
        }
    }
}

struct DayRecord: Identifiable, Codable, Hashable {
    let id: Int
    let day: Int
    var note: String
    var mood: Mood?
    
    init(day: Int, note: String = "", mood: Mood? = nil) {
        self.id = day
        self.day = day
        self.note = note
        self.mood = mood
    }
}

enum ExperimentStatus: String, Codable {
    case active
    case completed
}

struct DailyLog: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var note: String
    var mood: Mood?
    
    init(id: UUID = UUID(), date: Date = Date(), note: String = "", mood: Mood? = nil) {
        self.id = id
        self.date = date
        self.note = note
        self.mood = mood
    }
}

struct ExperimentReview: Codable, Hashable {
    var whatDidITry: String
    var whatHappened: String
    var whatWillIDoDifferently: String
    var locked: Bool
}

struct Experiment: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var status: ExperimentStatus
    var createdAt: Date
    var updatedAt: Date
    var logs: [DailyLog] = []
    var review: ExperimentReview?
    var completedAt: Date?
    
    init(id: UUID = UUID(), title: String, status: ExperimentStatus, createdAt: Date, updatedAt: Date? = nil, logs: [DailyLog] = [], review: ExperimentReview? = nil, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.logs = logs
        self.review = review
        self.completedAt = completedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        status = try container.decode(ExperimentStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? createdAt
        logs = (try? container.decode([DailyLog].self, forKey: .logs)) ?? []
        review = try? container.decode(ExperimentReview.self, forKey: .review)
        completedAt = try? container.decode(Date.self, forKey: .completedAt)
    }
}

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
    
    // Navigation state
    @State private var selectedDay: DayRecord?
    @State private var selectedExperiment: Experiment?
    @State private var showCreateExperimentSheet: Bool = false
    @State private var showSummary: Bool = false
    @State private var experimentToDelete: Experiment?
    @State private var activeSheet: ActiveSheet?

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
    
    func renameExperiment(id: UUID, newTitle: String) {
        var experiments = getExperiments()
        if let index = experiments.firstIndex(where: { $0.id == id }) {
            experiments[index].title = newTitle
            experiments[index].updatedAt = Date()
            setExperiments(experiments)
        }
    }
    
    func duplicateExperiment(_ experiment: Experiment) {
        let now = Date()
        let duplicate = Experiment(
            id: UUID(),
            title: "\(experiment.title) (Copy)",
            status: .active,
            createdAt: now,
            updatedAt: now,
            logs: experiment.logs,
            review: nil,
            completedAt: nil
        )
        activeSheet = .duplicate(duplicate)
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
                .font(.headline)
                .foregroundColor(.secondary)

            Text(message)
                .font(.title)
        }
    }

    var historySection: some View {
        let h = getHistory()
        return Group {
            if !h.isEmpty {
                VStack(spacing: 8) {
                    Text("Completed Days:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        ForEach(h) { record in
                            Button(historyLabel(for: record)) {
                                selectedDay = record
                            }
                            .font(.caption)
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
        NavigationStack {
            List {
                let experiments = sortedExperiments()
                if experiments.isEmpty {
                    Text("No active experiments yet. Create one to get started.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(experiments) { experiment in
                        Button(action: {
                            selectedExperiment = experiment
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(experiment.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Updated \(experiment.updatedAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                experimentToDelete = experiment
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                activeSheet = .rename(experiment)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.orange)
                            
                            Button {
                                duplicateExperiment(experiment)
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Active Experiments")
            .navigationDestination(item: $selectedExperiment) { experiment in
                ExperimentDetailView(experiment: experiment, onUpdate: updateExperiment)
            }
            .navigationDestination(isPresented: $showSummary) {
                SummaryView(loadExperiments: getExperiments, onUpdate: updateExperiment)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showSummary = true
                    }) {
                        Image(systemName: "chart.bar")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showCreateExperimentSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateExperimentSheet) {
                CreateExperimentView(onCreate: { experiment in
                    addExperiment(experiment)
                    showCreateExperimentSheet = false
                })
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .rename(let experiment):
                    RenameExperimentView(currentTitle: experiment.title, onRename: { newTitle in
                        renameExperiment(id: experiment.id, newTitle: newTitle)
                        activeSheet = nil
                    })
                case .duplicate(let duplicate):
                    RenameExperimentView(currentTitle: duplicate.title, onRename: { newTitle in
                        var finalDuplicate = duplicate
                        finalDuplicate.title = newTitle
                        addExperiment(finalDuplicate)
                        activeSheet = nil
                    })
                }
            }
            .onAppear {
                seedExperimentsIfNeeded()
            }
            .alert("Delete this experiment?", isPresented: .constant(experimentToDelete != nil), presenting: experimentToDelete) { experiment in
                Button("Cancel", role: .cancel) {
                    experimentToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteExperiment(id: experiment.id)
                    experimentToDelete = nil
                }
            } message: { experiment in
                Text("All logs and data for \"\(experiment.title)\" will be deleted. This cannot be undone.")
            }
        }
    }
    
    func dayDetailView(for record: DayRecord) -> some View {
        DayDetailContent(record: record, updateRecord: updateRecord)
    }
}

struct CreateExperimentView: View {
    let onCreate: (Experiment) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Experiment Title", text: $title)
                } header: {
                    Text("Title")
                }
            }
            .navigationTitle("New Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let now = Date()
                        let newExperiment = Experiment(
                            title: title,
                            status: .active,
                            createdAt: now,
                            updatedAt: now
                        )
                        onCreate(newExperiment)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct RenameExperimentView: View {
    let currentTitle: String
    let onRename: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    
    init(currentTitle: String, onRename: @escaping (String) -> Void) {
        self.currentTitle = currentTitle
        self.onRename = onRename
        _title = State(initialValue: currentTitle)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Experiment Title", text: $title)
                } header: {
                    Text("Title")
                }
            }
            .navigationTitle("Rename Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onRename(title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct MoodSelectorView: View {
    @Binding var selectedMood: Mood?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Mood.allCases) { mood in
                Button(action: {
                    if selectedMood == mood {
                        selectedMood = nil
                    } else {
                        selectedMood = mood
                    }
                }) {
                    Text(mood.emoji)
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedMood == mood ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                }
            }
        }
    }
}

struct DayDetailContent: View {
    let record: DayRecord
    let updateRecord: (DayRecord) -> Void
    
    @State private var draftNote: String
    @State private var draftMood: Mood?
    @State private var showSavedToast = false
    @FocusState private var noteFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(record: DayRecord, updateRecord: @escaping (DayRecord) -> Void) {
        self.record = record
        self.updateRecord = updateRecord
        _draftNote = State(initialValue: record.note)
        _draftMood = State(initialValue: record.mood)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Day \(record.day)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You completed your experiment on this day! 🎉")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How did you feel today? (Optional)")
                    .font(.headline)
                
                MoodSelectorView(selectedMood: $draftMood)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes:")
                    .font(.headline)
                
                TextEditor(text: $draftNote)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($noteFocused)
            }
            .padding(.horizontal)
            
            Button("Save") {
                var updated = record
                updated.note = draftNote
                updated.mood = draftMood
                updateRecord(updated)
                
                // Dismiss keyboard
                noteFocused = false
                
                // Show toast
                showSavedToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSavedToast = false
                }
            }
            .buttonStyle(.borderedProminent)
            
            if showSavedToast {
                Text("Saved ✓")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Day \(record.day)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExperimentDetailView: View {
    let onUpdate: (Experiment) -> Void
    
    @State private var localExperiment: Experiment
    @State private var draftNote: String = ""
    @State private var draftMood: Mood?
    @State private var showSavedToast = false
    @State private var showCompleteConfirm = false
    @State private var showReopenConfirm = false
    @State private var showEmptyNoteAlert = false
    @State private var showMoodRequiredAlert = false
    @State private var showBlankReviewToast = false
    @FocusState private var noteFocused: Bool
    
    // Review draft fields
    @State private var draftWhatDidITry: String = ""
    @State private var draftWhatHappened: String = ""
    @State private var draftWhatWillIDoDifferently: String = ""
    
    init(experiment: Experiment, onUpdate: @escaping (Experiment) -> Void) {
        self.onUpdate = onUpdate
        _localExperiment = State(initialValue: experiment)
        
        let today = Calendar.current.startOfDay(for: Date())
        if let todayLog = experiment.logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            _draftNote = State(initialValue: todayLog.note)
            _draftMood = State(initialValue: todayLog.mood)
        }
        
        // Initialize review draft fields if review exists
        if let review = experiment.review {
            _draftWhatDidITry = State(initialValue: review.whatDidITry)
            _draftWhatHappened = State(initialValue: review.whatHappened)
            _draftWhatWillIDoDifferently = State(initialValue: review.whatWillIDoDifferently)
        }
    }
    
    var isCompleted: Bool {
        localExperiment.status == .completed
    }
    
    var sortedLogs: [DailyLog] {
        localExperiment.logs.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Date Header
                VStack(spacing: 8) {
                    Text(Date(), style: .date)
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if isCompleted {
                        VStack(spacing: 4) {
                            Text("This experiment is completed. Logging is disabled.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                            
                            if let completedAt = localExperiment.completedAt {
                                Text("Completed on \(completedAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Completed ✓")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.bottom, 8)
                
                // Experiment Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created: \(localExperiment.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let completedAt = localExperiment.completedAt {
                        Text("Completed: \(completedAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Updated: \(localExperiment.updatedAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Today Section (only when active)
                if !isCompleted {
                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How did you feel today?")
                                .font(.headline)
                            
                            MoodSelectorView(selectedMood: $draftMood)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes:")
                                .font(.headline)
                            
                            TextEditor(text: $draftNote)
                                .frame(minHeight: 120)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .focused($noteFocused)
                        }
                        
                        Button("Save") {
                            if draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                showEmptyNoteAlert = true
                            } else if draftMood == nil {
                                showMoodRequiredAlert = true
                            } else {
                                saveTodayLog()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Complete Experiment") {
                        showCompleteConfirm = true
                    }
                    .buttonStyle(.bordered)

                    Divider()
                }
                
                // Review Section (only for completed experiments)
                if isCompleted {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let review = localExperiment.review, review.locked {
                            // Read-only review
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What did I try?")
                                        .font(.headline)
                                    Text(review.whatDidITry)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What happened?")
                                        .font(.headline)
                                    Text(review.whatHappened)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What will I do differently next time?")
                                        .font(.headline)
                                    Text(review.whatWillIDoDifferently)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            // Editable review
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What did I try? (Optional)")
                                        .font(.headline)
                                    TextEditor(text: $draftWhatDidITry)
                                        .frame(minHeight: 80)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What happened? (Optional)")
                                        .font(.headline)
                                    TextEditor(text: $draftWhatHappened)
                                        .frame(minHeight: 80)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What will I do differently next time? (Optional)")
                                        .font(.headline)
                                    TextEditor(text: $draftWhatWillIDoDifferently)
                                        .frame(minHeight: 80)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                Button("Save Review") {
                                    saveReview()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // History Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("History")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if sortedLogs.isEmpty {
                        Text("No logs yet. Start logging today!")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(sortedLogs) { log in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(log.date, style: .date)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    if let mood = log.mood {
                                        Text(mood.emoji)
                                    }
                                    
                                    Spacer()
                                }
                                
                                if !log.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(log.note)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding()
        }
        .overlay(alignment: .top) {
            if showSavedToast {
                Text("Saved ✓")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .padding(.top, 8)
            } else if showBlankReviewToast {
                Text("Saved. Review left blank.")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .padding(.top, 8)
            }
        }
        .navigationTitle(localExperiment.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCompleted {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reopen") {
                        showReopenConfirm = true
                    }
                }
            }
        }
        .alert("Add a quick note?", isPresented: $showEmptyNoteAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A short note helps you remember what happened today.")
        }
        .alert("Pick a mood?", isPresented: $showMoodRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("It takes one tap and helps you see patterns over time.")
        }
        .alert("Complete this experiment?", isPresented: $showCompleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Complete", role: .destructive) {
                completeExperiment()
            }
        } message: {
            Text("You won't be able to add new logs after completion.")
        }
        .alert("Reopen this experiment?", isPresented: $showReopenConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reopen") {
                reopenExperiment()
            }
        } message: {
            Text("You'll be able to add new logs again.")
        }
    }
    
    func completeExperiment() {
        let now = Date()
        localExperiment.status = .completed
        localExperiment.completedAt = now
        localExperiment.updatedAt = now
        onUpdate(localExperiment)
        noteFocused = false
    }
    
    func reopenExperiment() {
        localExperiment.status = .active
        localExperiment.completedAt = nil
        localExperiment.updatedAt = Date()
        
        // Unlock review if it exists and prefill draft fields
        if let review = localExperiment.review {
            localExperiment.review?.locked = false
            draftWhatDidITry = review.whatDidITry
            draftWhatHappened = review.whatHappened
            draftWhatWillIDoDifferently = review.whatWillIDoDifferently
        }
        
        onUpdate(localExperiment)
    }
    
    func saveReview() {
        let review = ExperimentReview(
            whatDidITry: draftWhatDidITry,
            whatHappened: draftWhatHappened,
            whatWillIDoDifferently: draftWhatWillIDoDifferently,
            locked: true
        )
        localExperiment.review = review
        localExperiment.updatedAt = Date()
        onUpdate(localExperiment)
        
        // Check if all fields are blank
        let allBlank = draftWhatDidITry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       draftWhatHappened.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                       draftWhatWillIDoDifferently.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if allBlank {
            showBlankReviewToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showBlankReviewToast = false
            }
        }
    }
    
    func saveTodayLog() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let index = localExperiment.logs.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            localExperiment.logs[index].note = draftNote
            localExperiment.logs[index].mood = draftMood
        } else {
            let newLog = DailyLog(date: today, note: draftNote, mood: draftMood)
            localExperiment.logs.append(newLog)
        }
        
        localExperiment.updatedAt = Date()
        onUpdate(localExperiment)
        
        noteFocused = false
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedToast = false
        }
    }
}

struct SummaryView: View {
    let loadExperiments: () -> [Experiment]
    let onUpdate: (Experiment) -> Void
    
    @State private var selectedExperiment: Experiment?
    
    var experiments: [Experiment] {
        loadExperiments()
    }
    
    var completedExperiments: [Experiment] {
        experiments.filter { $0.status == .completed }.sorted { exp1, exp2 in
            let date1 = exp1.completedAt ?? exp1.updatedAt
            let date2 = exp2.completedAt ?? exp2.updatedAt
            return date1 > date2
        }
    }
    
    var recentCompleted: [Experiment] {
        Array(completedExperiments.prefix(3))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Stats Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Overview")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(completedExperiments.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(experiments.filter { $0.status == .active }.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                // Recent Completed
                if !recentCompleted.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Completed")
                            .font(.headline)
                        
                        ForEach(recentCompleted) { experiment in
                            Button(action: {
                                selectedExperiment = experiment
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(experiment.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        if let completedAt = experiment.completedAt {
                                            Text("Completed \(completedAt, style: .date)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Completed")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // All Completed
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Completed")
                        .font(.headline)
                    
                    if completedExperiments.isEmpty {
                        Text("No completed experiments yet.")
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    } else {
                        ForEach(completedExperiments) { experiment in
                            Button(action: {
                                selectedExperiment = experiment
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(experiment.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        HStack {
                                            if let completedAt = experiment.completedAt {
                                                Text("Completed \(completedAt, style: .date)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            } else {
                                                Text("Completed")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let review = experiment.review, review.locked {
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text("Reviewed")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedExperiment) { experiment in
            ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)
        }
    }
}

#Preview {
    ContentView()
}
