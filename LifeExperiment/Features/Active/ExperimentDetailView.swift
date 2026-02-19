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

