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

struct Experiment: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var status: ExperimentStatus
    var createdAt: Date
    
    init(id: UUID = UUID(), title: String, status: ExperimentStatus, createdAt: Date) {
        self.id = id
        self.title = title
        self.status = status
        self.createdAt = createdAt
    }
}

struct ContentView: View {
    enum LoggingStatus: String {
        case idle
        case logging
        case logged
    }

    // Persistent storage
    @AppStorage("dayCount") private var dayCount: Int = 1
    @AppStorage("statusRaw") private var statusRaw: String = LoggingStatus.idle.rawValue
    @AppStorage("historyData") private var historyData: Data = .init()
    @AppStorage("experimentsData") private var experimentsData: Data = .init()
    
    // Navigation state
    @State private var selectedDay: DayRecord?
    @State private var selectedExperiment: Experiment?

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
            let defaultExperiment = Experiment(
                title: "My First Experiment",
                status: .active,
                createdAt: Date()
            )
            setExperiments([defaultExperiment])
        }
    }
    
    private func sortedExperiments() -> [Experiment] {
        let experiments = getExperiments()
        return experiments.sorted { exp1, exp2 in
            if exp1.status != exp2.status {
                return exp1.status == .active
            }
            return exp1.createdAt > exp2.createdAt
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
                                
                                HStack {
                                    Text(experiment.status.rawValue.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    
                                    Text(experiment.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Experiments")
            .navigationDestination(item: $selectedExperiment) { experiment in
                ExperimentDetailView(experiment: experiment)
            }
            .onAppear {
                seedExperimentsIfNeeded()
            }
        }
    }
    
    func dayDetailView(for record: DayRecord) -> some View {
        DayDetailContent(record: record, updateRecord: updateRecord)
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
    let experiment: Experiment
    
    var body: some View {
        VStack(spacing: 20) {
            Text(experiment.title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Status:")
                        .fontWeight(.semibold)
                    Text(experiment.status.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Created:")
                        .fontWeight(.semibold)
                    Text(experiment.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            .font(.body)
            
            Text("Experiment details coming soon")
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 20)
            
            Spacer()
        }
        .padding()
        .navigationTitle(experiment.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
