import SwiftUI

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
    @State private var showFullHistory = false
    @State private var showAddPhotoComingSoon = false
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

    private let pageHorizontalPadding: CGFloat = 20
    private var preferences = AppPreferences()

    private var insightLines: [InsightLine] {
        InsightCalculator.compute(logs: localExperiment.logs, now: Date())
    }

    private var canShowImages: Bool {
        preferences.imageLoggingEnabled && localExperiment.allowsImageLogging
    }

    var body: some View {
        detailContent
            .overlay(alignment: .top) { toastOverlay }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
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
            .alert("Coming soon", isPresented: $showAddPhotoComingSoon) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Add photo will be available in a future update.")
            }
            .alert(S.experimentCompleteConfirm, isPresented: $showCompleteConfirm) {
                Button(S.actionCancel, role: .cancel) { }
                Button(S.actionComplete, role: .destructive) { completeExperiment() }
            } message: {
                Text(S.experimentCompleteMessage)
            }
            .alert(S.experimentReopenConfirm, isPresented: $showReopenConfirm) {
                Button(S.actionCancel, role: .cancel) { }
                Button(S.actionReopen) { reopenExperiment() }
            } message: {
                Text("You'll be able to add new logs again.")
            }
    }

    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                todaySection
                reviewSection
                historySection
            }
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.vertical, 16)
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .center, spacing: 0) {
                Text(localExperiment.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            if isCompleted {
                VStack(alignment: .leading, spacing: 4) {
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

            Text("Created \(localExperiment.createdAt, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var todaySection: some View {
        if !isCompleted {
            if !insightLines.isEmpty {
                ExperimentInsightSnapshotSection(lines: insightLines)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How did you feel today?")
                        .font(.headline)
                    MoodSelectorView(selectedMood: $draftMood)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Notes:")
                            .font(.headline)

                        Spacer()

                        if canShowImages {
                            Button {
                                showAddPhotoComingSoon = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera")
                                    Text("Add photo")
                                        .underline()
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Add photo")
                        }
                    }
                    .frame(minHeight: 24)

                    TextEditor(text: $draftNote)
                        .frame(minHeight: 80, maxHeight: 96)
                        .padding(6)
                        .background(Color(.systemGray6))
                        .cornerRadius(preferences.uiStyle.cardCornerRadius)
                        .focused($noteFocused)
                }

                HStack {
                    Button("Complete Experiment") {
                        showCompleteConfirm = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)

                    Spacer()

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
            }

            Divider()
        }
    }

    @ViewBuilder
    private var reviewSection: some View {
        if isCompleted {
            VStack(alignment: .leading, spacing: 12) {
                Text("Review")
                    .font(.title2)
                    .fontWeight(.bold)

                if let review = localExperiment.review, review.locked {
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

                        Button("Save Review") { saveReview() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }

            Divider()
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let visibleLogs = showFullHistory ? sortedLogs : Array(sortedLogs.prefix(6))

        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.title2)
                .fontWeight(.bold)

            if sortedLogs.isEmpty {
                Text("No logs yet. Start logging today!")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(visibleLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(log.mood?.emoji ?? " ")
                                .frame(width: 24, alignment: .leading)

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

                if sortedLogs.count > 10 {
                    Button(showFullHistory ? "Show less" : "See earlier entries") {
                        showFullHistory.toggle()
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
        }
    }

    @ViewBuilder
    private var toastOverlay: some View {
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isCompleted {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reopen") { showReopenConfirm = true }
            }
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

fileprivate struct ExperimentInsightSnapshotSection: View {
    let lines: [InsightLine]
    fileprivate var preferences = AppPreferences()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insight Snapshot")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(emoji(for: line.kind))
                            .font(.caption)

                        Text(line.text)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(preferences.uiStyle.cardPadding)
        .background(Color(.systemGray6))
        .cornerRadius(preferences.uiStyle.cardCornerRadius)
    }

    private func emoji(for kind: InsightKind) -> String {
        switch kind {
        case .mood:
            return "🧭"
        case .stability:
            return "🌊"
        case .rhythm:
            return "🗓️"
        }
    }
}



