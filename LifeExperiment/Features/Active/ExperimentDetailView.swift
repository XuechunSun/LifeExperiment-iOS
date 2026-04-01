import SwiftUI
import PhotosUI
import UIKit

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
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var draftPhotoLocalPath: String?
    @State private var photoMarkedForRemoval = false
    @State private var isSavingPhoto = false
    @State private var photoErrorMessage: String?
    @State private var showPhotoErrorAlert = false
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
            _draftPhotoLocalPath = State(initialValue: todayLog.photoLocalPath)
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

    private var persistedTodayPhotoLocalPath: String? {
        let today = Calendar.current.startOfDay(for: Date())
        return localExperiment.logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.photoLocalPath
    }

    private var photoDraftHelperText: String? {
        guard canShowImages else { return nil }
        let persisted = persistedTodayPhotoLocalPath
        if draftPhotoLocalPath == persisted { return nil }
        if draftPhotoLocalPath != nil {
            return "Photo will be saved when you tap Save."
        }
        if persisted != nil {
            return "Photo will be removed when you tap Save."
        }
        return nil
    }

    private var hasTodayLog: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return localExperiment.logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var todaySuggestion: (title: String, subtitle: String, icon: String)? {
        if draftMood == nil {
            return (
                "Start with a quick mood check-in",
                "One tap is enough to mark how today has felt so far.",
                "🌿"
            )
        }

        if draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (
                "Add one small note",
                "A sentence is enough to remember what stood out today.",
                "✍️"
            )
        }

        if canShowImages && draftPhotoLocalPath == nil {
            return (
                "A photo is optional",
                "If an image helps capture today more clearly, you can add one.",
                "📷"
            )
        }

        if hasTodayLog {
            return (
                "You already have a start",
                "Save again anytime if you want to refine today’s check-in.",
                "✨"
            )
        }

        return (
            "Keep today simple",
            "A quick check-in is enough to keep this experiment in motion.",
            "🌱"
        )
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
            .alert("Couldn't attach photo.", isPresented: $showPhotoErrorAlert, presenting: photoErrorMessage) { _ in
                Button("OK", role: .cancel) { }
            } message: { message in
                Text(message)
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
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    await handleSelectedPhoto(item: newItem)
                }
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
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(localExperiment.title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if localExperiment.category != nil || localExperiment.subcategory != nil {
                HStack(spacing: 8) {
                    if let category = localExperiment.category {
                        detailTag(category)
                    }
                    if let subcategory = localExperiment.subcategory {
                        detailTag(subcategory)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Created \(localExperiment.createdAt, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isCompleted {
                    Text("This experiment is completed. Logging is disabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()

                    if let completedAt = localExperiment.completedAt {
                        Text("Completed on \(completedAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lightCardStyle(
            cornerRadius: 16,
            fillColor: Color(.systemBackground),
            fillOpacity: 1.0,
            borderOpacity: 0.04,
            shadowOpacity: 0.03,
            shadowRadius: 8,
            shadowYOffset: 2,
            contentPadding: preferences.uiStyle.cardPadding
        )
    }

    @ViewBuilder
    private var todaySection: some View {
        if !isCompleted {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                if !insightLines.isEmpty {
                    ExperimentInsightSnapshotSection(lines: insightLines)
                }

                if let suggestion = todaySuggestion {
                    SuggestionCard(
                        title: suggestion.title,
                        subtitle: suggestion.subtitle,
                        icon: suggestion.icon,
                        style: .createSuggestion
                    )
                }
            }

            VStack(alignment: .leading, spacing: DSSpacing.md) {
                // VStack(alignment: .leading, spacing: DSSpacing.xs) {
                //     Text("Today’s check-in")
                //         .font(DSText.section)
                //         .foregroundColor(.primary)

                    // Text("A small reflection is enough to keep this experiment in motion.")
                    //     .lifeSecondaryText()
                //}

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        Text("How do you feel today?")
                            .font(.headline)
                        MoodSelectorView(selectedMood: $draftMood)
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Notes")
                                .font(.headline)

                            Spacer()

                            if canShowImages {
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
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
                                .disabled(isSavingPhoto)
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

                        if canShowImages,
                           let path = draftPhotoLocalPath,
                           !photoMarkedForRemoval,
                           let image = LocalPhotoStore.loadImage(fromRelativePath: path) {
                            HStack(spacing: 10) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text("Photo attached")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Button("Remove") {
                                    draftPhotoLocalPath = nil
                                    photoMarkedForRemoval = true
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)

                                Spacer()
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }

                        if let helperText = photoDraftHelperText {
                            Text(helperText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    HStack {
                        // Button("Complete Experiment") {
                        //     showCompleteConfirm = true
                        // }
                        // .buttonStyle(.bordered)
                        // .tint(.secondary)

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

                    Button {
                        showCompleteConfirm = true
                    } label: {
                        Text("Complete Experiment")
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .lightCardStyle(
                cornerRadius: 16,
                fillColor: Color(.systemBackground),
                fillOpacity: 0.98,
                borderOpacity: 0.04,
                shadowOpacity: 0.02,
                shadowRadius: 6,
                shadowYOffset: 2,
                contentPadding: preferences.uiStyle.cardPadding
            )
        }
    }

    @ViewBuilder
    private var reviewSection: some View {
        if isCompleted {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                Text("A small reflection")
                    .font(DSText.section)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    if let review = localExperiment.review, review.locked {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
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
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What did I try?")
                                        .font(.headline)
                                    Text("Optional")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }
                                TextEditor(text: $draftWhatDidITry)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading, spacing: DSSpacing.sm) {

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What happened?")
                                        .font(.headline)

                                    Text("Optional")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }

                                TextEditor(text: $draftWhatHappened)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading, spacing: DSSpacing.sm) {

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("What will I do differently next time?")
                                        .font(.headline)

                                    Text("Optional")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .italic()
                                }

                                TextEditor(text: $draftWhatWillIDoDifferently)
                                    .frame(minHeight: 80)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }

                            HStack {
                                Spacer()

                                Button("Save Review") { saveReview() }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
                .lightCardStyle(
                    cornerRadius: 16,
                    fillColor: Color(.systemBackground),
                    fillOpacity: 0.98,
                    borderOpacity: 0.04,
                    shadowOpacity: 0.02,
                    shadowRadius: 6,
                    shadowYOffset: 2,
                    contentPadding: preferences.uiStyle.cardPadding
                )
            }
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let visibleLogs = showFullHistory ? sortedLogs : Array(sortedLogs.prefix(6))

        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("History")
                .font(DSText.section)
                .foregroundColor(.primary)

            if sortedLogs.isEmpty {
                Text("No logs yet. Start logging today!")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(visibleLogs) { log in
                    HistoryLogRow(log: log)
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

    private func detailTag(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
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
            localExperiment.logs[index].photoLocalPath = draftPhotoLocalPath
        } else {
            let newLog = DailyLog(
                date: today,
                note: draftNote,
                mood: draftMood,
                photoLocalPath: draftPhotoLocalPath
            )
            localExperiment.logs.append(newLog)
        }

        localExperiment.updatedAt = Date()
        onUpdate(localExperiment)

        // Success haptic feedback
        Haptics.success()

        noteFocused = false
        photoMarkedForRemoval = false
        showSavedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSavedToast = false
        }
    }

    @MainActor
    private func handleSelectedPhoto(item: PhotosPickerItem) async {
        isSavingPhoto = true
        defer {
            isSavingPhoto = false
            selectedPhotoItem = nil
        }

        guard let data = try? await item.loadTransferable(type: Data.self) else {
            photoErrorMessage = "Please try selecting another photo."
            showPhotoErrorAlert = true
            return
        }
        guard let relativePath = LocalPhotoStore.saveImageData(data) else {
            photoErrorMessage = "Unable to save this photo locally."
            showPhotoErrorAlert = true
            return
        }
        photoErrorMessage = nil
        photoMarkedForRemoval = false
        draftPhotoLocalPath = relativePath
    }
}

private enum LocalPhotoStore {
    private static let folderName = "LogPhotos"

    private static func photosDirectoryURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = documentsURL.appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func saveImageData(_ data: Data) -> String? {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.85),
              let directory = photosDirectoryURL() else {
            return nil
        }

        let fileName = "logphoto_\(UUID().uuidString).jpg"
        let fileURL = directory.appendingPathComponent(fileName)
        do {
            try jpegData.write(to: fileURL, options: .atomic)
            return "\(folderName)/\(fileName)"
        } catch {
            return nil
        }
    }

    static func loadImage(fromRelativePath relativePath: String) -> UIImage? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileURL = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}

fileprivate struct ExperimentInsightSnapshotSection: View {
    let lines: [InsightLine]
    fileprivate var preferences = AppPreferences()

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text("Insight Snapshot")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(emoji(for: line.kind))
                            .font(.caption)

                        Text(line.text)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(preferences.uiStyle.cardPadding)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.07),
                    Color.blue.opacity(0.045)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: preferences.uiStyle.cardCornerRadius)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: preferences.uiStyle.cardCornerRadius))
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

private struct HistoryLogRow: View {
    let log: DailyLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(log.mood?.emoji ?? " ")
                    .frame(width: 24, alignment: .leading)

                if log.photoLocalPath != nil {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .lightCardStyle(
            cornerRadius: 12,
            fillColor: Color(.secondarySystemBackground),
            fillOpacity: 1.0,
            borderOpacity: 0.025,
            shadowOpacity: 0.015,
            shadowRadius: 4,
            shadowYOffset: 1,
            contentPadding: 12
        )
    }
}



