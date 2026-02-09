//
//  ContentView.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI
import UIKit
import Foundation

// MARK: - Dimension & Impact Models

enum Dimension: String, Codable, CaseIterable, Identifiable {
    case emotion_awareness
    case body_energy
    case execution
    case focus_flow
    case expression_creativity
    case connection
    case self_understanding
    
    var id: String { rawValue }
    
    // MARK: - English (V1 Display)
    
    var title: String {
        switch self {
        case .emotion_awareness:
            return "Emotional Awareness"
        case .body_energy:
            return "Body & Energy"
        case .execution:
            return "Execution"
        case .focus_flow:
            return "Focus & Flow"
        case .expression_creativity:
            return "Expression & Creativity"
        case .connection:
            return "Connection"
        case .self_understanding:
            return "Self-Understanding"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .emotion_awareness:
            return "Notice and understand emotions"
        case .body_energy:
            return "Stabilize physical energy"
        case .execution:
            return "Start and complete actions"
        case .focus_flow:
            return "Stay focused and enter flow"
        case .expression_creativity:
            return "Create and express yourself"
        case .connection:
            return "Strengthen relationships"
        case .self_understanding:
            return "Learn what suits you"
        }
    }
    
    // MARK: - Chinese (Future Localization)
    
    var titleCN: String {
        switch self {
        case .emotion_awareness:
            return "情绪觉察"
        case .body_energy:
            return "身体能量"
        case .execution:
            return "执行力"
        case .focus_flow:
            return "专注与心流"
        case .expression_creativity:
            return "表达与创造"
        case .connection:
            return "连接"
        case .self_understanding:
            return "自我理解"
        }
    }
    
    var subtitleCN: String? {
        switch self {
        case .emotion_awareness:
            return "觉察并理解情绪"
        case .body_energy:
            return "身体状态与能量管理"
        case .execution:
            return "行动与完成"
        case .focus_flow:
            return "专注力与沉浸体验"
        case .expression_creativity:
            return "创作与表达能力"
        case .connection:
            return "人际连接与关系"
        case .self_understanding:
            return "自我认知与成长"
        }
    }
}

struct ExperimentImpact: Codable, Hashable {
    var primary: Dimension
    var secondary: [Dimension] // max 2
}

// MARK: - Seed Catalog Models

struct SeedCatalog: Codable {
    let version: String
    let categories: [SeedCategory]
}

struct SeedCategory: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String?
    let subcategories: [SeedSubcategory]
}

struct SeedSubcategory: Identifiable, Codable {
    let id: String
    let title: String
    let default_dimensions: [Dimension]?
    let prompts: [String]
}

struct SeedCatalogLoader {
    static func load() -> SeedCatalog? {
        guard let url = Bundle.main.url(forResource: "experiment_seed", withExtension: "json") else {
            print("⚠️ SeedCatalogLoader: experiment_seed.json not found in bundle")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let catalog = try JSONDecoder().decode(SeedCatalog.self, from: data)
            print("✅ SeedCatalogLoader: Loaded catalog v\(catalog.version) with \(catalog.categories.count) categories")
            return catalog
        } catch {
            print("⚠️ SeedCatalogLoader: Failed to decode experiment_seed.json - \(error)")
            return nil
        }
    }
}

// MARK: - Impact Helper

/// Convert default_dimensions array to ExperimentImpact
/// - Parameter arr: Array of dimensions from seed data
/// - Returns: ExperimentImpact with primary and secondary dimensions, or nil if empty
/// Order matters: first = primary (1.0), second = secondary (0.5), third = tertiary (0.2)

func impactFromDefaultDimensions(_ arr: [Dimension]?) -> ExperimentImpact? {
    guard let arr = arr, !arr.isEmpty else { return nil }
    
    let primary = arr[0]
    let secondary = Array(arr.dropFirst().prefix(2))
    
    return ExperimentImpact(primary: primary, secondary: secondary)
}



struct CTAQuoteStore: Decodable {
    let version: String
    let language: String
    let items: [String]
}

enum CTALoader {
    static func loadQuotes() -> [String] {
        guard let url = Bundle.main.url(forResource: "cta_quotes", withExtension: "json") else {
            return []
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(CTAQuoteStore.self, from: data)
            return decoded.items
        } catch {
            return []
        }
    }

    /// Deterministic daily pick so it doesn't change on every render.
    static func pickDailyQuote(from quotes: [String], date: Date = Date()) -> String? {
        guard !quotes.isEmpty else { return nil }
        let dayIndex = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let idx = (dayIndex - 1) % quotes.count
        return quotes[idx]
    }
}


// MARK: - App Models

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
    
    var label: String {
        S.moodLabel(self)
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
    var category: String?
    var subcategory: String?
    var impact: ExperimentImpact?
    var status: ExperimentStatus
    var createdAt: Date
    var updatedAt: Date
    var logs: [DailyLog] = []
    var review: ExperimentReview?
    var completedAt: Date?
    
    init(id: UUID = UUID(), title: String, category: String? = nil, subcategory: String? = nil, impact: ExperimentImpact? = nil, status: ExperimentStatus, createdAt: Date, updatedAt: Date? = nil, logs: [DailyLog] = [], review: ExperimentReview? = nil, completedAt: Date? = nil) {
        self.id = id
        self.title = title
        self.category = category
        self.subcategory = subcategory
        self.impact = impact
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
        category = try? container.decode(String.self, forKey: .category)
        subcategory = try? container.decode(String.self, forKey: .subcategory)
        impact = try? container.decode(ExperimentImpact.self, forKey: .impact)
        status = try container.decode(ExperimentStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? createdAt
        logs = (try? container.decode([DailyLog].self, forKey: .logs)) ?? []
        review = try? container.decode(ExperimentReview.self, forKey: .review)
        completedAt = try? container.decode(Date.self, forKey: .completedAt)
    }
}

// MARK: - Home View (Main Landing Page)

struct HomeView: View {
    let loadExperiments: () -> [Experiment]
    let seedCatalog: SeedCatalog?
    let onCreateExperiment: () -> Void
    let onSelectExperiment: (Experiment) -> Void
    let onUpdate: (Experiment) -> Void
    let onShowActiveMore: () -> Void
    let onShowCompletedMore: () -> Void
    let onShowSummary: () -> Void
    let onSelectDay: (Date) -> Void
    let onRenameExperiment: (Experiment) -> Void
    let onDuplicateExperiment: (Experiment) -> Void
    let onDeleteExperiment: (Experiment) -> Void
    
    // MARK: - State Determination
    
    private var experiments: [Experiment] {
        loadExperiments()
    }
    
    private var activeExperiments: [Experiment] {
        experiments.filter { $0.status == .active }
    }
    
    // Helper: Check if experiment was updated on a specific day (created, logged, or completed)
    private func isUpdated(on day: Date, experiment: Experiment) -> Bool {
        let calendar = Calendar.current
        
        // Check if created on this day
        if calendar.isDate(experiment.createdAt, inSameDayAs: day) {
            return true
        }
        
        // Check if has log on this day
        if experiment.logs.contains(where: { calendar.isDate($0.date, inSameDayAs: day) }) {
            return true
        }
        
        // Check if completed on this day
        if let completedAt = experiment.completedAt, calendar.isDate(completedAt, inSameDayAs: day) {
            return true
        }
        
        return false
    }
    
    // Check if user has updated today (log added, experiment created, or experiment completed today)
    private var hasUpdatedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return experiments.contains { isUpdated(on: today, experiment: $0) }
    }
    
    // Determine which state we're in
    private enum HomeState {
        case noActiveExperiments      // State C
        case activeButNoUpdatesToday  // State A
        case updatedToday             // State B
    }
    
    private var currentState: HomeState {
        if activeExperiments.isEmpty {
            return .noActiveExperiments
        } else if hasUpdatedToday {
            return .updatedToday
        } else {
            return .activeButNoUpdatesToday
        }
    }
    
    // MARK: - Continue Recording Logic
    
    // Candidates: active experiments NOT updated today
    private var continueCandidates: [Experiment] {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Filter out experiments updated today (using same definition as hasUpdatedToday)
        return activeExperiments.filter { experiment in
            !isUpdated(on: today, experiment: experiment)
        }.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // Preview: at most 2 for Home display
    private var continuePreview: [Experiment] {
        Array(continueCandidates.prefix(2))
    }
    
    // Show Continue section in State A & B (not C)
    private var shouldShowContinueRecording: Bool {
        currentState != .noActiveExperiments && !continuePreview.isEmpty
    }
    
    // Title varies by state
    private var continueRecordingTitle: String {
        if currentState == .updatedToday {
            // State B: Weakened, optional tone
            return "Keep going (optional)"
        } else {
            // State A: Primary CTA
            return "Continue Recording"
        }
    }
    
    // MARK: - Completed Logic
    
    private var completedExperiments: [Experiment] {
        experiments.filter { $0.status == .completed }.sorted { exp1, exp2 in
            let date1 = exp1.completedAt ?? exp1.updatedAt
            let date2 = exp2.completedAt ?? exp2.updatedAt
            return date1 > date2
        }
    }
    
    private var completedPreview: [Experiment] {
        Array(completedExperiments.prefix(2))
    }
    
    private var shouldShowCompleted: Bool {
        !completedExperiments.isEmpty
    }
    
    // MARK: - Recent Events Logic (using RecentEventBuilder)
    // MARK: - Recent Events (Milestone-based, system-generated)
    
    private var recentEvents: [RecentEvent] {
        RecentEventBuilder.build(experiments: experiments, today: Date())
    }
    
    // MARK: - UI
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. Calendar Footprint - Always visible
                CalendarFootprintView(experiments: experiments, onSelectDay: onSelectDay)
                
                Divider()
                
                // 2. CTA (Emotional Trigger) - Always visible
                VStack(alignment: .leading, spacing: 8) {
                    Text(ctaText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let ctaSubtext = ctaSubtext {
                        Text(ctaSubtext)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 3. Recent Events - Card style
                if !recentEvents.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(S.sectionRecentEvents)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        let eventsToShow = Array(recentEvents.prefix(2))
                        
                        if eventsToShow.count == 2 {
                            // Two-column grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(eventsToShow) { event in
                                    RecentEventCard(event: event)
                                }
                            }
                        } else {
                            // Single card
                            ForEach(eventsToShow) { event in
                                RecentEventCard(event: event)
                            }
                        }
                    }
                }

                // 4. Continue Recording - State A (primary) & State B (weakened/optional)
                if shouldShowContinueRecording {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        let isWeakened = (currentState == .updatedToday)
                        
                        HStack {
                            Text(continueRecordingTitle)
                                .font(isWeakened ? .subheadline : .headline)
                                .foregroundColor(isWeakened ? .secondary : .primary)
                            
                            Spacer()
                            
                            if activeExperiments.count > 2 {
                                Button(action: {
                                    onShowActiveMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        ForEach(continuePreview) { experiment in
                            Button(action: {
                                onSelectExperiment(experiment)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(experiment.title)
                                            .font(.subheadline)
                                            .fontWeight(isWeakened ? .regular : .semibold)
                                            .foregroundColor(isWeakened ? .secondary : .primary)
                                        
                                        Text("Last updated \(experiment.updatedAt, style: .date)")
                                            .font(isWeakened ? .caption2 : .caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    ExperimentRowMenu(
                                        kind: .active,
                                        onRename: { onRenameExperiment(experiment) },
                                        onDuplicate: { onDuplicateExperiment(experiment) },
                                        onDelete: { onDeleteExperiment(experiment) }
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(isWeakened ? 0.5 : 1.0))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // 5. Start New Experiment - Always visible
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(currentState == .noActiveExperiments ? "Start Your First Experiment" : "Start New Experiment")
                        .font(.headline)
                    
                    Button(action: {
                        onCreateExperiment()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("Create Experiment")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // 6. Completed - Lightweight section
                if shouldShowCompleted {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(S.sectionCompleted)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if completedExperiments.count > 2 {
                                Button(action: {
                                    onShowCompletedMore()
                                }) {
                                    Text(S.actionMore)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        ForEach(completedPreview) { experiment in
                            Button(action: {
                                onSelectExperiment(experiment)
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
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    ExperimentRowMenu(
                                        kind: .completed,
                                        onDuplicate: { onDuplicateExperiment(experiment) },
                                        onDelete: { onDeleteExperiment(experiment) }
                                    )
                                }
                                .padding()
                                .background(Color(.systemGray6).opacity(0.7))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Recent Event Card Component
    
    struct RecentEventCard: View {
        let event: RecentEvent
        
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: event.iconSystemName)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let subtitle = event.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    // MARK: - CTA Text Logic (Quote-based)
    
    private var ctaText: String {
        let quotes = CTALoader.loadQuotes()
        return CTALoader.pickDailyQuote(from: quotes) ?? "Begin anywhere."  
    }

    private var ctaSubtext: String? {
        return nil
    }

}

// MARK: - Reusable Card Component

struct ExperimentCardRow: View {
    let title: String
    let subtitle: String
    let leadingIcon: String?
    
    init(title: String, subtitle: String, leadingIcon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
    }
    
    // Convenience initializer for Experiment
    init(experiment: Experiment) {
        self.title = experiment.title
        
        // Format subtitle based on experiment status
        if experiment.status == .completed, let completedAt = experiment.completedAt {
            self.subtitle = "Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))"
        } else {
            self.subtitle = "Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        
        self.leadingIcon = nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
    }
}

// MARK: - Experiment Row Menu (Stable trailing menu)

struct ExperimentRowMenu: View {
    enum Kind {
        case active
        case completed
    }
    
    let kind: Kind
    let onRename: (() -> Void)?
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    init(kind: Kind, onRename: (() -> Void)? = nil, onDuplicate: @escaping () -> Void, onDelete: @escaping () -> Void) {
        self.kind = kind
        self.onRename = onRename
        self.onDuplicate = onDuplicate
        self.onDelete = onDelete
    }
    
    var body: some View {
        Menu {
            if kind == .active, let onRename {
                Button(action: onRename) {
                    Label("Rename", systemImage: "pencil")
                }
            }
            
            Button(action: onDuplicate) {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            
            Divider()
            
            Button("Delete", role: .destructive, action: onDelete)
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
                .padding(.leading, 8)
        }
    }
}

// MARK: - All Active List View (Grouped by Update Status)

struct AllActiveListView: View {
    let activeExperiments: [Experiment]
    let isUpdatedToday: (Experiment) -> Bool
    let onSelectExperiment: (Experiment) -> Void
    let onCreateExperiment: () -> Void
    let onRename: (Experiment) -> Void
    let onDuplicate: (Experiment) -> Void
    let onDelete: (Experiment) -> Void
    
    private var updatedToday: [Experiment] {
        activeExperiments.filter { isUpdatedToday($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    private var notUpdatedToday: [Experiment] {
        activeExperiments.filter { !isUpdatedToday($0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var body: some View {
        List {
            // Updated Today section
            Section {
                if updatedToday.isEmpty {
                    Text(S.emptyNoUpdatesToday)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(updatedToday) { experiment in
                        Button(action: {
                            onSelectExperiment(experiment)
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(experiment.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                ExperimentRowMenu(
                                    kind: .active,
                                    onRename: { onRename(experiment) },
                                    onDuplicate: { onDuplicate(experiment) },
                                    onDelete: { onDelete(experiment) }
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: { onDelete(experiment) }) {
                                Label("Delete", systemImage: "trash")
                            }
                            Button(action: { onDuplicate(experiment) }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.orange)
                            Button(action: { onRename(experiment) }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text(S.sectionUpdatedToday)
            }
            
            // Not Updated Today section
            Section {
                if notUpdatedToday.isEmpty {
                    Text(S.emptyAllUpdated)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notUpdatedToday) { experiment in
                        Button(action: {
                            onSelectExperiment(experiment)
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(experiment.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Last updated \(experiment.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                ExperimentRowMenu(
                                    kind: .active,
                                    onRename: { onRename(experiment) },
                                    onDuplicate: { onDuplicate(experiment) },
                                    onDelete: { onDelete(experiment) }
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive, action: { onDelete(experiment) }) {
                                Label("Delete", systemImage: "trash")
                            }
                            Button(action: { onDuplicate(experiment) }) {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .tint(.orange)
                            Button(action: { onRename(experiment) }) {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                Text(S.sectionNotUpdatedToday)
            }
            
            // Start New Experiment button
            Section {
                Button(action: {
                    onCreateExperiment()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(S.sectionStartNewExperiment)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.blue.opacity(0.1))
            }
        }
        .navigationTitle(S.sectionActiveExperiments)
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Completed List View

struct CompletedListView: View {
    let completedExperiments: [Experiment]
    let onSelectExperiment: (Experiment) -> Void
    let onDuplicate: (Experiment) -> Void
    let onDelete: (Experiment) -> Void
    
    private var thisWeek: [Experiment] {
        let calendar = Calendar.current
        return completedExperiments.filter { exp in
            guard let completedAt = exp.completedAt else { return false }
            return calendar.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }
    
    private var earlier: [Experiment] {
        let calendar = Calendar.current
        return completedExperiments.filter { exp in
            guard let completedAt = exp.completedAt else { return true }
            return !calendar.isDate(completedAt, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }
    
    var body: some View {
        Group {
            if completedExperiments.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 60)
                    
                    Text(S.emptyNoCompletedExperiments)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(S.emptyNoCompletedSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Try something tiny—one day is still an experiment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    // This week section
                    if !thisWeek.isEmpty {
                        Section {
                            ForEach(thisWeek) { experiment in
                                Button(action: {
                                    onSelectExperiment(experiment)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(experiment.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let completedAt = experiment.completedAt {
                                                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        ExperimentRowMenu(
                                            kind: .completed,
                                            onDuplicate: { onDuplicate(experiment) },
                                            onDelete: { onDelete(experiment) }
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive, action: { onDelete(experiment) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button(action: { onDuplicate(experiment) }) {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.orange)
                                }
                            }
                        } header: {
                            Text(S.sectionThisWeek)
                        }
                    }
                    
                    // Earlier section
                    if !earlier.isEmpty {
                        Section {
                            ForEach(earlier) { experiment in
                                Button(action: {
                                    onSelectExperiment(experiment)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.title3)
                                            .foregroundColor(.green)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(experiment.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            
                                            if let completedAt = experiment.completedAt {
                                                Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        ExperimentRowMenu(
                                            kind: .completed,
                                            onDuplicate: { onDuplicate(experiment) },
                                            onDelete: { onDelete(experiment) }
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive, action: { onDelete(experiment) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    Button(action: { onDuplicate(experiment) }) {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.orange)
                                }
                            }
                        } header: {
                            Text(S.sectionEarlier)
                        }
                    }
                }
            }
        }
        .navigationTitle("Completed Experiments")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Navigation Route

enum Route: Hashable {
    case experiment(UUID)
    case activeMore
    case completedMore
    case summary
    case day(Date)
}

// MARK: - Tab enum

enum Tab: Int {
    case home = 0
    case active = 1
    case create = 2
    case summary = 3
    case profile = 4
}

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
    
    // Tab state
    @State private var selectedTab: Tab = .home
    
    // Navigation state (separate paths for each tab)
    @State private var homePath: [Route] = []
    @State private var activePath: [Route] = []
    @State private var summaryPath: [Route] = []
    @State private var profilePath: [Route] = []
    
    @State private var selectedDay: DayRecord?
    @State private var showCreateExperimentSheet: Bool = false
    @State private var experimentToDelete: Experiment?
    @State private var activeSheet: ActiveSheet?
    
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
        TabView(selection: $selectedTab) {
            // Tab 1: Home
            NavigationStack(path: $homePath) {
                HomeView(
                    loadExperiments: getExperiments,
                    seedCatalog: seedCatalog,
                    onCreateExperiment: {
                        showCreateExperimentSheet = true
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
                .navigationTitle("Life Experiment")
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
                    .navigationTitle(S.sectionActiveExperiments)
                    .navigationBarTitleDisplayMode(.large)
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
                SummaryView(loadExperiments: getExperiments, onUpdate: updateExperiment, seedCatalog: seedCatalog)
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
                ProfileView()
                    .navigationDestination(for: Route.self) { route in
                        routeDestination(route: route, path: $profilePath)
                    }
            }
            .tabItem {
                Label(S.tabProfile, systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // When user switches to Create tab, present the create sheet
            if newValue == .create {
                showCreateExperimentSheet = true
            }
        }
        .sheet(isPresented: $showCreateExperimentSheet, onDismiss: {
            // When create sheet is dismissed, return to Home if still on Create tab
            if selectedTab == .create {
                selectedTab = .home
            }
        }) {
            ExperimentEditorView(seedCatalog: seedCatalog, mode: .create) { experiment in
                addExperiment(experiment)
                showCreateExperimentSheet = false
                // Switch to Active tab after creation
                selectedTab = .active
                // Optionally push to the new experiment detail
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    activePath.append(.experiment(experiment.id))
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .rename(let experiment):
                ExperimentEditorView(seedCatalog: seedCatalog, mode: .rename(existing: experiment)) { updated in
                    updateExperiment(updated)
                    activeSheet = nil
                }
            case .duplicate(let experiment):
                ExperimentEditorView(seedCatalog: seedCatalog, mode: .duplicate(from: experiment)) { created in
                    addExperiment(created)
                    activeSheet = nil
                }
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
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(S.emptyNoActiveSubtitle)
                        .font(.subheadline)
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
                        .background(Color.blue)
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
            if let experiment = getExperiments().first(where: { $0.id == id }) {
                ExperimentDetailView(experiment: experiment, onUpdate: updateExperiment)
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
            SummaryView(loadExperiments: getExperiments, onUpdate: updateExperiment, seedCatalog: seedCatalog)
            
        case .day(let date):
            DayDetailView(day: date, experiments: getExperiments(), onUpdate: updateExperiment)
        }
    }
    
    func dayDetailView(for record: DayRecord) -> some View {
        DayDetailContent(record: record, updateRecord: updateRecord)
    }
}

// MARK: - Experiment Editor (Unified for Rename / Duplicate / Create)

enum ExperimentEditorMode {
    case create
    case rename(existing: Experiment)
    case duplicate(from: Experiment)

    var navTitle: String {
        switch self {
        case .create: return "New Experiment"
        case .rename: return "Edit Experiment"
        case .duplicate: return "Duplicate Experiment"
        }
    }

    var primaryButtonTitle: String {
        switch self {
        case .create: return "Create"
        case .rename: return "Save"
        case .duplicate: return "Create"
        }
    }
}

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


struct MoodSelectorView: View {
    @Binding var selectedMood: Mood?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Mood.allCases) { mood in
                Button(action: {
                    // Haptic feedback on mood selection
                    Haptics.selection()
                    
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
            
            Button(S.actionSave) {
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
                // Header
                VStack(alignment: .center, spacing: 12) {
                    // Title
                    Text(localExperiment.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Completed banner
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
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Category tags
                    if localExperiment.category != nil || localExperiment.subcategory != nil {
                        HStack(spacing: 8) {
                            if let category = localExperiment.category {
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            
                            if let subcategory = localExperiment.subcategory {
                                Text(subcategory)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Created date
                    Text("Created \(localExperiment.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
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
                        
                        Button(S.actionSave) {
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
                    
                    Button(S.experimentCompleteButton) {
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
        .alert(S.experimentCompleteConfirm, isPresented: $showCompleteConfirm) {
            Button(S.actionCancel, role: .cancel) { }
            Button(S.actionComplete, role: .destructive) {
                completeExperiment()
            }
        } message: {
            Text(S.experimentCompleteMessage)
        }
        .alert(S.experimentReopenConfirm, isPresented: $showReopenConfirm) {
            Button(S.actionCancel, role: .cancel) { }
            Button(S.actionReopen) {
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
        
        // Success haptic feedback for completion
        Haptics.success()
        
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
        
        // Success haptic feedback
        Haptics.success()
        
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
        
        // Success haptic feedback
        Haptics.success()
        
        noteFocused = false
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedToast = false
        }
    }
}

// MARK: - Dimension UI Components

struct DimensionChip: View {
    let dimension: Dimension
    let isPrimary: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if isPrimary {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
            Text(dimension.title)
                .font(.subheadline)
                .fontWeight(isPrimary ? .semibold : .regular)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isPrimary ? Color.blue.opacity(0.15) : Color(.systemGray5))
        .foregroundColor(isPrimary ? .blue : .primary)
        .cornerRadius(16)
    }
}

struct DefaultDimensionsCard: View {
    let impact: ExperimentImpact
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This experiment usually helps with:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onEdit) {
                    Text("Edit")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], alignment: .leading, spacing: 8) {
                DimensionChip(dimension: impact.primary, isPrimary: true)
                
                ForEach(impact.secondary, id: \.self) { dimension in
                    DimensionChip(dimension: dimension, isPrimary: false)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct CustomDimensionSelectionCard: View {
    let selectedImpact: ExperimentImpact?
    let onChoose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let impact = selectedImpact {
                // Show selected dimensions with Edit button
                HStack {
                    Text("This experiment helps with:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: onChoose) {
                        Text("Edit")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], alignment: .leading, spacing: 8) {
                    DimensionChip(dimension: impact.primary, isPrimary: true)
                    
                    ForEach(impact.secondary, id: \.self) { dimension in
                        DimensionChip(dimension: dimension, isPrimary: false)
                    }
                }
            } else {
                // Show "Choose dimensions" prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("What does this experiment help with most? (required)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: onChoose) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Choose dimensions")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                    }
                    
                    Text("Don't overthink it — you can adjust later.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DimensionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPrimary: Dimension
    @State private var selectedAdditional: Set<Dimension>
    
    let initialImpact: ExperimentImpact?
    let onSave: (ExperimentImpact) -> Void
    
    init(initialImpact: ExperimentImpact?, onSave: @escaping (ExperimentImpact) -> Void) {
        self.initialImpact = initialImpact
        self.onSave = onSave
        
        // Initialize state
        if let impact = initialImpact {
            _selectedPrimary = State(initialValue: impact.primary)
            _selectedAdditional = State(initialValue: Set(impact.secondary))
        } else {
            _selectedPrimary = State(initialValue: .self_understanding)
            _selectedAdditional = State(initialValue: [])
        }
    }
    
    private var availableAdditional: [Dimension] {
        Dimension.allCases.filter { $0 != selectedPrimary }
    }
    
    private var canSave: Bool {
        selectedAdditional.count <= 2
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Select the primary dimension this experiment focuses on.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(Dimension.allCases) { dimension in
                        Button(action: {
                            selectedPrimary = dimension
                            // Remove from additional if it was there
                            selectedAdditional.remove(dimension)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dimension.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    if let subtitle = dimension.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedPrimary == dimension {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Primary Dimension (Required)")
                }
                
                Section {
                    Text("Optionally select up to 2 additional dimensions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(availableAdditional) { dimension in
                        Button(action: {
                            if selectedAdditional.contains(dimension) {
                                selectedAdditional.remove(dimension)
                            } else if selectedAdditional.count < 2 {
                                selectedAdditional.insert(dimension)
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dimension.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    if let subtitle = dimension.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedAdditional.contains(dimension) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedAdditional.count >= 2 && !selectedAdditional.contains(dimension))
                        .opacity((selectedAdditional.count >= 2 && !selectedAdditional.contains(dimension)) ? 0.5 : 1.0)
                    }
                } header: {
                    Text("Additional Dimensions (Optional, max 2)")
                } footer: {
                    if selectedAdditional.count >= 2 {
                        Text("Maximum of 2 additional dimensions reached")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .navigationTitle("Edit Dimensions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.actionCancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(S.actionSave) {
                        let impact = ExperimentImpact(
                            primary: selectedPrimary,
                            secondary: Array(selectedAdditional).sorted(by: { $0.title < $1.title })
                        )
                        onSave(impact)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}

// MARK: - Summary View (Week 4 Structure)

struct SummaryView: View {
    let loadExperiments: () -> [Experiment]
    let onUpdate: (Experiment) -> Void
    let seedCatalog: SeedCatalog?
    
    @State private var showFullCalendar: Bool = false
    @State private var selectedDay: Date?
    @State private var showCreateStorageBox: Bool = false
    
    var experiments: [Experiment] {
        loadExperiments()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Module 1: Calendar Footprint
                CalendarFootprintView(experiments: experiments, onSelectDay: { day in
                    selectedDay = day
                })
                
                Divider()
                
                // Module 2: Storage Boxes by Category
                StorageBoxesView(experiments: experiments, seedCatalog: seedCatalog, onUpdate: onUpdate, showCreateStorageBox: $showCreateStorageBox)
            }
            .padding()
        }
        .navigationTitle("Summary")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showFullCalendar) {
            FullCalendarView()
        }
        .navigationDestination(item: $selectedDay) { day in
            DayDetailView(day: day, experiments: experiments, onUpdate: onUpdate)
        }
        .navigationDestination(isPresented: $showCreateStorageBox) {
            CreateStorageBoxView()
        }
    }
}

// MARK: - Calendar Footprint Module

struct CalendarFootprintView: View {
    let experiments: [Experiment]
    let onSelectDay: (Date) -> Void
    @State private var weekOffset: Int = 0
    
    // Find the earliest and latest activity dates across all experiments
    private var activityDateRange: (earliest: Date, latest: Date) {
        var minDate: Date?
        var maxDate: Date?
        
        for experiment in experiments {
            // Check createdAt
            if minDate == nil || experiment.createdAt < minDate! {
                minDate = experiment.createdAt
            }
            if maxDate == nil || experiment.createdAt > maxDate! {
                maxDate = experiment.createdAt
            }
            
            // Check log dates
            for log in experiment.logs {
                if minDate == nil || log.date < minDate! {
                    minDate = log.date
                }
                if maxDate == nil || log.date > maxDate! {
                    maxDate = log.date
                }
            }
            
            // Check completedAt
            if let completedAt = experiment.completedAt {
                if minDate == nil || completedAt < minDate! {
                    minDate = completedAt
                }
                if maxDate == nil || completedAt > maxDate! {
                    maxDate = completedAt
                }
            }
            
            // Check updatedAt
            if minDate == nil || experiment.updatedAt < minDate! {
                minDate = experiment.updatedAt
            }
            if maxDate == nil || experiment.updatedAt > maxDate! {
                maxDate = experiment.updatedAt
            }
        }
        
        let today = Date()
        return (earliest: minDate ?? today, latest: maxDate ?? today)
    }
    
    // Find the most recent activity date across all experiments (for reference)
    private var referenceDate: Date {
        activityDateRange.latest
    }
    
    // Calculate the Monday of the week for a given date
    private func monday(for date: Date) -> Date {
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: dateStart)  // 1=Sun, 2=Mon, ..., 7=Sat
        let offsetToMonday = (weekday + 5) % 7  // Mon->0, Tue->1, ..., Sun->6
        return calendar.date(byAdding: .day, value: -offsetToMonday, to: dateStart)!
    }
    
    // Calculate weeks between two Mondays
    private func weeksBetween(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 0
    }
    
    // Week bounds
    private var weekBounds: (min: Int, max: Int) {
        //let calendar = Calendar.current
        let referenceMonday = monday(for: referenceDate)
        let earliestMonday = monday(for: activityDateRange.earliest)
        let today = Date()
        let latestActivityMonday = monday(for: activityDateRange.latest)
        let todayMonday = monday(for: today)
        
        // Do not allow beyond today's week
        let latestMonday = latestActivityMonday < todayMonday ? latestActivityMonday : todayMonday
        
        let minWeekOffset = weeksBetween(from: referenceMonday, to: earliestMonday)
        let maxWeekOffset = weeksBetween(from: referenceMonday, to: latestMonday)
        
        return (min: minWeekOffset, max: maxWeekOffset)
    }
    
    // Get the displayed week based on reference date and offset
    private var displayedWeekStart: Date {
        let calendar = Calendar.current
        let baseMonday = monday(for: referenceDate)
        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseMonday)!
    }
    
    private var currentWeekDays: [Date] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            calendar.date(byAdding: .day, value: offset, to: displayedWeekStart)!
        }
    }
    
    private var weekHeaderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: displayedWeekStart))"
    }
    
    private func jumpToToday() {
        let calendar = Calendar.current
        let todayMonday = monday(for: Date())
        let referenceMonday = monday(for: referenceDate)
        
        // Calculate weeks difference
        if let weeks = calendar.dateComponents([.weekOfYear], from: referenceMonday, to: todayMonday).weekOfYear {
            let bounds = weekBounds
            weekOffset = min(max(weeks, bounds.min), bounds.max)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar Footprint")
                .font(.headline)
            
            // Week navigation header
            HStack {
                // Previous week button
                Button(action: {
                    let bounds = weekBounds
                    weekOffset = max(weekOffset - 1, bounds.min)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                        .foregroundColor(weekOffset <= weekBounds.min ? .gray : .blue)
                        .frame(width: 30, height: 30)
                }
                .disabled(weekOffset <= weekBounds.min)
                
                Spacer()
                
                // Week label
                Text(weekHeaderText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Today button
                Button("Today") {
                    jumpToToday()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                // Next week button
                Button(action: {
                    let bounds = weekBounds
                    weekOffset = min(weekOffset + 1, bounds.max)
                }) {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(weekOffset >= weekBounds.max ? .gray : .blue)
                        .frame(width: 30, height: 30)
                }
                .disabled(weekOffset >= weekBounds.max)
            }
            
            // Weekly row (Mon-Sun)
            HStack(spacing: 4) {
                ForEach(currentWeekDays, id: \.self) { day in
                    CalendarDayCell(day: day, experiments: experiments)
                        .onTapGesture {
                            onSelectDay(day)
                        }
                }
            }
            
            // See full calendar link
            NavigationLink(destination: FullCalendarView()) {
                HStack {
                    Text("See full calendar")
                        .font(.subheadline)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.blue)
            }
        }
    }
}

struct CalendarDayCell: View {
    let day: Date
    let experiments: [Experiment]
    
    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day)
    }
    
    private var dateNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day)
    }
    
    private var activeUpdateExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            guard exp.status == .active else { return false }
            
            // Check if has log on this day
            let hasLog = exp.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }
            
            // Check if created on this day
            let createdOnDay = calendar.isDate(exp.createdAt, inSameDayAs: day)
            
            return hasLog || createdOnDay
        }
    }
    
    private var activeCount: Int {
        activeUpdateExperiments.count
    }
    
    private var completedExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            if let completedAt = exp.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            return false
        }
    }
    
    private var completedCount: Int {
        completedExperiments.count
    }
    
    private var totalIntensity: Int {
        // Count distinct experiments that are either active updates OR completed on this day
        let activeIDs = Set(activeUpdateExperiments.map(\.id))
        let completedIDs = Set(completedExperiments.map(\.id))
        return activeIDs.union(completedIDs).count
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Weekday
            Text(weekdayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Date number
            Text(dateNumber)
                .font(.caption)
                .fontWeight(.medium)
            
            // Status icons row
            HStack(spacing: 2) {
                if activeCount > 0 {
                    Image(systemName: "pencil.circle")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                if completedCount > 0 {
                    Image(systemName: "checkmark.seal")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .frame(height: 12)
            
            // Intensity dots row
            HStack(spacing: 1) {
                if totalIntensity > 0 {
                    let displayCount = min(totalIntensity, 5)
                    ForEach(0..<displayCount, id: \.self) { _ in
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                    }
                    if totalIntensity > 5 {
                        Image(systemName: "plus")
                            .font(.system(size: 6))
                            .foregroundColor(.orange)
                    }
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Day Detail View

struct DayDetailView: View {
    let day: Date
    let experiments: [Experiment]
    let onUpdate: (Experiment) -> Void
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day)
    }
    
    private var completedExperiments: [Experiment] {
        let calendar = Calendar.current
        return experiments.filter { exp in
            if let completedAt = exp.completedAt {
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            return false
        }
    }
    
    private var activeUpdateExperiments: [Experiment] {
        let calendar = Calendar.current
        
        // Get IDs of experiments completed on this day
        let completedIDs = Set(completedExperiments.map(\.id))
        
        return experiments.filter { exp in
            // Must be active status
            guard exp.status == .active else { return false }
            
            // Exclude experiments completed on this day (they go to Completed section only)
            guard !completedIDs.contains(exp.id) else { return false }
            
            // Check if has log on this day
            let hasLog = exp.logs.contains { log in
                calendar.isDate(log.date, inSameDayAs: day)
            }
            
            // Check if created on this day
            let createdOnDay = calendar.isDate(exp.createdAt, inSameDayAs: day)
            
            return hasLog || createdOnDay
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Active Updates Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                        Text("Active Updates")
                            .font(.headline)
                    }
                    
                    if activeUpdateExperiments.isEmpty {
                        Text("No active updates on this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(activeUpdateExperiments) { experiment in
                            NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                ExperimentCardRow(experiment: experiment)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Completed Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal")
                            .foregroundColor(.green)
                        Text("Completed")
                            .font(.headline)
                    }
                    
                    if completedExperiments.isEmpty {
                        Text("No experiments completed on this day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(completedExperiments) { experiment in
                            NavigationLink(destination: ExperimentDetailView(experiment: experiment, onUpdate: onUpdate)) {
                                ExperimentCardRow(experiment: experiment)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(dayLabel)
        .navigationBarTitleDisplayMode(.large)
    }
}

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

// MARK: - Stub Views

struct FullCalendarView: View {
    var body: some View {
        VStack {
            Text("Full Calendar View")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Full Calendar")
        .navigationBarTitleDisplayMode(.large)
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

#Preview {
    ContentView()
}
