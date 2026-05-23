import SwiftUI
import PhotosUI
import UIKit

struct ExperimentDetailView: View {
    let isNewUser: Bool
    let onUpdate: (Experiment) -> Void

    @State private var localExperiment: Experiment
    @State private var draftNote: String = ""
    @State private var draftMood: Mood?
    @State private var showSavedToast = false
    // Phase 4 (v1.1 onboarding): shown instead of `showSavedToast` for the
    // first log on the guided onboarding experiment.
    @State private var showFirstLogToast = false
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
    @State private var didJustSaveEntry = false
    @FocusState private var noteFocused: Bool

    // Review draft fields
    @State private var draftWhatDidITry: String = ""
    @State private var draftWhatHappened: String = ""
    @State private var draftWhatWillIDoDifferently: String = ""

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    init(experiment: Experiment, isNewUser: Bool = false, onUpdate: @escaping (Experiment) -> Void) {
        self.isNewUser = isNewUser
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
        InsightCalculator.compute(logs: localExperiment.logs, now: Date(), lang: lang)
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
            return L.photoWillSaveWhenSave(lang)
        }
        if persisted != nil {
            return L.photoWillRemoveWhenSave(lang)
        }
        return nil
    }

    private var hasTodayLog: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return localExperiment.logs.contains { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var entryNumber: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedLogs = localExperiment.logs.sorted { $0.date < $1.date }
        if let idx = sortedLogs.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: today)
        }) {
            return idx + 1
        }
        return sortedLogs.count + 1
    }

    private var headerDateCaption: String {
        let createdDateString = localExperiment.createdAt.formatted(date: .abbreviated, time: .omitted)
        guard isCompleted, let completedAt = localExperiment.completedAt else {
            return L.detailCreatedOn(lang, dateString: createdDateString)
        }
        let completedDateString = completedAt.formatted(date: .abbreviated, time: .omitted)
        switch lang {
        case .english:
            return "Created \(createdDateString), completed \(completedDateString)"
        case .chinese:
            return "创建于 \(createdDateString)，完成于 \(completedDateString)"
        }
    }

    // MARK: - Onboarding first-log banner (Phase 4)

    /// True when the user has just created their guided onboarding experiment
    /// and has not yet saved a log for today on this same experiment. The
    /// guidedExperimentId match makes this strictly per-experiment, so other
    /// active experiments never show the banner. `!isCompleted` is a defensive
    /// duplicate of the outer `todaySection` guard.
    private var shouldShowOnboardingFirstLogBanner: Bool {
        OnboardingState.stage == .experimentCreated
            && OnboardingState.guidedExperimentId == localExperiment.id.uuidString
            && !hasTodayLog
            && !isCompleted
    }

    // Phase 8.1 Part C: typography softened to read as a gentle guide card
    // alongside the SuggestionCard below — title dropped from headline /
    // semibold-by-default to subheadline / medium with `.primary.opacity(0.92)`
    // (mirrors `SuggestionCard.homeSuggestion` titleColor), body dropped from
    // subheadline to caption, icon glyph scaled to match the SuggestionCard
    // icon font. Copy, visibility predicate, and lavender 10% surface are
    // unchanged. No CTA introduced; save/completion logic untouched.
    @ViewBuilder
    private var onboardingFirstLogBanner: some View {
        HStack(alignment: .top, spacing: DSSpacing.md) {
            Image(systemName: "sparkles")
                .font(DSText.subheadline)
                .foregroundColor(primaryLavenderButton)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(L.onboardingFirstLogBannerTitle(lang))
                    .font(DSText.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary.opacity(0.92))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L.onboardingFirstLogBannerBody(lang))
                    .font(DSText.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .lightCardStyle(
            cornerRadius: 14,
            fillColor: primaryLavenderButton.opacity(0.10),
            fillOpacity: 1.0,
            borderOpacity: 0,
            shadowOpacity: 0,
            shadowRadius: 0,
            shadowYOffset: 0,
            contentPadding: DSSpacing.md
        )
    }

    private var todaySuggestion: (title: String, subtitle: String, icon: String)? {
        if draftMood == nil {
            if isNewUser {
                return (
                    L.todaySuggestionStartWithFelt(lang),
                    L.todaySuggestionFirstNoteSimple(lang),
                    "🌿"
                )
            }
            return (
                L.todaySuggestionQuickCheckIn(lang),
                L.todaySuggestionMoodCheckSubtitle(lang),
                "🌿"
            )
        }

        if draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (
                L.todaySuggestionAddOneNote(lang),
                L.todaySuggestionNoteSentence(lang),
                "✍️"
            )
        }

        if canShowImages && draftPhotoLocalPath == nil {
            return (
                L.todaySuggestionPhotoOptional(lang),
                L.todaySuggestionPhotoClarify(lang),
                "📷"
            )
        }

        if hasTodayLog {
            return (
                L.todaySuggestionAlreadyStart(lang),
                L.todaySuggestionSaveAgain(lang),
                "✨"
            )
        }

        return (
            L.todaySuggestionKeepSimple(lang),
            L.todaySuggestionQuickEnough(lang),
            "🌱"
        )
    }

    static func shouldShowFirstLogGuidance(for experiments: [Experiment]) -> Bool {
        !experiments.contains { experiment in
            !experiment.logs.isEmpty || experiment.review != nil || experiment.completedAt != nil
        }
    }

    var body: some View {
        detailContent
            .overlay(alignment: .top) { toastOverlay }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(L.detailEmptyNoteAlertTitle(lang), isPresented: $showEmptyNoteAlert) {
                Button(L.actionOK(lang), role: .cancel) { }
            } message: {
                Text(L.detailEmptyNoteAlertMessage(lang))
            }
            .alert(L.detailPickMoodAlertTitle(lang), isPresented: $showMoodRequiredAlert) {
                Button(L.actionOK(lang), role: .cancel) { }
            } message: {
                Text(L.detailPickMoodAlertMessage(lang))
            }
            .alert(L.detailPhotoAttachFailedTitle(lang), isPresented: $showPhotoErrorAlert, presenting: photoErrorMessage) { _ in
                Button(L.actionOK(lang), role: .cancel) { }
            } message: { message in
                Text(message)
            }
            .alert(L.experimentCompleteConfirm(lang), isPresented: $showCompleteConfirm) {
                Button(L.actionCancel(lang), role: .cancel) { }
                Button(L.actionComplete(lang), role: .destructive) { completeExperiment() }
            } message: {
                Text(L.experimentCompleteMessage(lang))
            }
            .alert(L.experimentReopenConfirm(lang), isPresented: $showReopenConfirm) {
                Button(L.actionCancel(lang), role: .cancel) { }
                Button(L.actionReopen(lang)) { reopenExperiment() }
            } message: {
                Text(L.experimentReopenMessage(lang))
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
            // Phase V1.1 polish: page-level section rhythm bumped from a
            // hardcoded 20pt to `DSSpacing.xl` (24) so header → today →
            // review → history each read as their own beat.
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                headerSection
                todaySection
                reviewSection
                historySection
            }
            .padding(.horizontal, pageHorizontalPadding)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { hideKeyboard() }
    }

    @ViewBuilder
    private var headerSection: some View {
        // Phase V1.4 polish: gentle breathing-room bump between title /
        // tag chips / created-on caption (and the completed cluster when
        // applicable). Token-only change — header structure is unchanged.
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(BuiltInTitleDisplay.localizedTitle(stored: localExperiment.title, lang: lang))
                .font(DSText.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if localExperiment.category != nil || localExperiment.subcategory != nil {
                HStack(spacing: 8) {
                    if let category = localExperiment.category {
                        detailTag(SeedTaxonomyDisplay.displayCategory(stored: category, lang: lang))
                    }
                    if let subcategory = localExperiment.subcategory {
                        detailTag(SeedTaxonomyDisplay.displaySubcategory(stored: subcategory, lang: lang))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(headerDateCaption)
                    .font(DSText.caption)
                    .foregroundColor(.secondary)

                if isCompleted {
                    Label(L.sectionCompleted(lang), systemImage: "checkmark.seal.fill")
                        .font(DSText.caption)
                        .foregroundColor(primaryLavenderButton)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(primaryLavenderButton.opacity(0.12))
                        .clipShape(Capsule())

                    Text(L.detailExperimentCompletedNoLogging(lang))
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lightCardStyle(
            cornerRadius: 16,
            fillColor: Color(.systemBackground),
            fillOpacity: 1.0,
            borderOpacity: 0.02,
            shadowOpacity: 0.02,
            shadowRadius: 8,
            shadowYOffset: 2,
            contentPadding: preferences.uiStyle.cardPadding
        )
    }

    @ViewBuilder
    private var todaySection: some View {
        if !isCompleted {
            if shouldShowOnboardingFirstLogBanner {
                onboardingFirstLogBanner
            }

            VStack(alignment: .leading, spacing: DSSpacing.md) {
                if !insightLines.isEmpty {
                    ExperimentInsightSnapshotSection(lines: insightLines, lang: lang)
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

                // Phase V1.2 polish: inner today-card stack stepped up from
                // `DSSpacing.md` (16) to `DSSpacing.lg` (20) so the mood,
                // notes, and save groups read as three distinct beats.
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    Text(lang == .english ? "Entry \(entryNumber)" : "第 \(entryNumber) 次记录")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryLavenderButton)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(primaryLavenderButton.opacity(0.10))
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .center, spacing: DSSpacing.sm) {
                        Text(L.howDoYouFeelToday(lang))
                            .font(DSText.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        MoodSelectorView(selectedMood: $draftMood)
                    }

                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(L.notes(lang))
                                .font(DSText.headline)

                            Spacer()

                            if canShowImages {
                                // Phase V2.4 polish: brand-aligned trailing
                                // action — underline removed, accent moved
                                // from system blue to `primaryLavenderButton`.
                                // The camera SF Symbol, font scale, picker
                                // selection binding, `isSavingPhoto` disable
                                // guard, and accessibility label are all
                                // untouched.
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera")
                                        Text(L.addPhoto(lang))
                                    }
                                    .font(DSText.subheadline)
                                    .foregroundColor(primaryLavenderButton)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(isSavingPhoto)
                                .accessibilityLabel(L.addPhoto(lang))
                            }
                        }
                        .frame(minHeight: 24)

                        TextEditor(text: $draftNote)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 88, maxHeight: 120)
                            .padding(DSSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(primaryLavenderButton.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                                    )
                            )
                            .focused($noteFocused)
                            .overlay(alignment: .topLeading) {
                                if draftNote.isEmpty && didJustSaveEntry && !noteFocused {
                                    Text(L.detailLogSavedPlaceholder(lang))
                                        .font(DSText.secondary)
                                        .foregroundColor(.secondary.opacity(0.55))
                                        .padding(.horizontal, DSSpacing.md)
                                        .padding(.top, DSSpacing.md)
                                        .allowsHitTesting(false)
                                }
                            }

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

                                Text(L.photoAttached(lang))
                                    .font(DSText.caption)
                                    .foregroundColor(.secondary)

                                Button(L.remove(lang)) {
                                    draftPhotoLocalPath = nil
                                    photoMarkedForRemoval = true
                                }
                                .font(DSText.caption)
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
                                .font(DSText.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }

                    // Phase V2.1 polish: Save is now the page's clear
                    // primary action — full-width lavender pill that mirrors
                    // the visual recipe of `OnboardingFlowView.primaryButton`
                    // (50pt min height, semibold headline, 12pt corner).
                    // The action closure is byte-identical to the prior
                    // bordered-prominent button: empty-note alert → mood-
                    // required alert → `saveTodayLog()`. We deliberately do
                    // NOT add a `.disabled` binding here — the existing two
                    // validation alerts continue to gate the save path.
                    Button {
                        if draftNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showEmptyNoteAlert = true
                        } else if draftMood == nil {
                            showMoodRequiredAlert = true
                        } else {
                            saveTodayLog()
                        }
                    } label: {
                        Text(L.save(lang))
                            .font(DSText.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(primaryLavenderButton)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Phase V2.5 polish: Complete Experiment sits under Save
                    // as a calm secondary action — no underline (looks dated
                    // in iOS), no uppercase / tracking (avoids heavy ZH
                    // typography), centered with light caption styling. The
                    // confirm-alert path (`showCompleteConfirm = true`) is
                    // unchanged.
                    Button {
                        showCompleteConfirm = true
                    } label: {
                        Text(L.completeExperiment(lang))
                            .font(DSText.caption)
                            .foregroundColor(.secondary.opacity(0.78))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DSSpacing.xxs)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, DSSpacing.xxs)
                }
            }
            // Phase V1.3 polish: today card reads as the primary module.
            //   - fillOpacity 0.98 → 1.0  : solid surface (no translucent
            //     blend with the page background) so the card feels
            //     intentional rather than layered.
            //   - cornerRadius 16  → 18   : slightly softer silhouette so
            //     the today card visually leads against the header (16)
            //     and review (16) cards underneath.
            .lightCardStyle(
                cornerRadius: 18,
                fillColor: Color(.systemBackground),
                fillOpacity: 1.0,
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
                Text(L.completedReflectionTitle(lang))
                    .font(DSText.section)
                    .foregroundColor(.primary)

                if localExperiment.review?.locked != true {
                    Text(lang == .english
                         ? "Optional — write only what feels useful."
                         : "可选填写，写下对你有帮助的部分就好。")
                        .font(DSText.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    if let review = localExperiment.review, review.locked {
                        VStack(alignment: .leading, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.completedReflectionWhatDidITry(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(review.whatDidITry)
                                    .foregroundColor(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.completedReflectionWhatHappened(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(review.whatHappened)
                                    .foregroundColor(.secondary)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L.completedReflectionWhatNextTime(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(review.whatWillIDoDifferently)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: DSSpacing.lg) {
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                Text(L.completedReflectionWhatDidITry(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                TextEditor(text: $draftWhatDidITry)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 88)
                                    .padding(DSSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(primaryLavenderButton.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                                            )
                                    )
                            }

                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                Text(L.completedReflectionWhatHappened(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                TextEditor(text: $draftWhatHappened)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 88)
                                    .padding(DSSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(primaryLavenderButton.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                                            )
                                    )
                            }

                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                Text(L.completedReflectionWhatNextTime(lang))
                                    .font(DSText.headline)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                TextEditor(text: $draftWhatWillIDoDifferently)
                                    .scrollContentBackground(.hidden)
                                    .frame(minHeight: 88)
                                    .padding(DSSpacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(primaryLavenderButton.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                                            )
                                    )
                            }

                            Button {
                                saveReview()
                            } label: {
                                Text(L.saveReview(lang))
                                    .font(DSText.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .background(primaryLavenderButton)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .lightCardStyle(
                    cornerRadius: 18,
                    fillColor: Color(.systemBackground),
                    fillOpacity: 1.0,
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
            Text(L.history(lang))
                .font(DSText.section)
                .foregroundColor(.primary)
                .padding(.bottom, DSSpacing.xxs)

            if sortedLogs.isEmpty {
                Text(L.historyNoLogsYet(lang))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(visibleLogs) { log in
                    HistoryLogRow(log: log)
                }

                if sortedLogs.count > 10 {
                    Button(showFullHistory ? L.showLess(lang) : L.seeEarlierEntries(lang)) {
                        showFullHistory.toggle()
                    }
                    .font(DSText.subheadline)
                    .buttonStyle(.borderless)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
        }
        .padding(.top, DSSpacing.xs)
    }

    private func detailTag(_ text: String) -> some View {
        Text(text)
            .font(DSText.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var toastOverlay: some View {
        if showSavedToast {
            Text(L.savedToast(lang))
                .font(DSText.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(20)
                .shadow(radius: 4)
                .padding(.top, 8)
        } else if showFirstLogToast {
            Text(L.onboardingFirstLogToast(lang))
                .font(DSText.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.green)
                .cornerRadius(20)
                .shadow(radius: 4)
                .padding(.top, 8)
        } else if showBlankReviewToast {
            Text(L.savedReviewBlankToast(lang))
                .font(DSText.subheadline)
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
                Button(L.actionReopen(lang)) { showReopenConfirm = true }
                    .tint(primaryLavenderButton)
            }
        }
    }

    func completeExperiment() {
        // Phase 4.1: if the user completes the guided onboarding experiment
        // without ever logging it, the banner is suppressed by `!isCompleted`
        // but onboarding state would otherwise stay at `.experimentCreated`
        // (orphan cleanup can't help — the experiment still exists). Clear
        // it here using the same two-key guard as `saveTodayLog` so completing
        // any non-guided experiment is unaffected.
        if OnboardingState.stage == .experimentCreated
            && OnboardingState.guidedExperimentId == localExperiment.id.uuidString {
            OnboardingState.guidedExperimentId = ""
            OnboardingState.stage = .completed
        }

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
        // Snapshot the onboarding-guided-first-log condition BEFORE we mutate
        // any state. We require both the stage AND the per-experiment id
        // match, so saves on other experiments cannot complete onboarding.
        let isOnboardingFirstLog =
            OnboardingState.stage == .experimentCreated
            && OnboardingState.guidedExperimentId == localExperiment.id.uuidString

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
        draftNote = ""
        draftPhotoLocalPath = nil
        draftMood = nil
        didJustSaveEntry = true

        if isOnboardingFirstLog {
            // Complete onboarding. Clear the guided id first so any in-flight
            // observer reading `OnboardingState.guidedExperimentId` does not
            // briefly see a `.completed` stage paired with a stale id.
            OnboardingState.guidedExperimentId = ""
            OnboardingState.stage = .completed

            showFirstLogToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showFirstLogToast = false
            }
        } else {
            showSavedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSavedToast = false
            }
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
            photoErrorMessage = L.detailPhotoPickFailedMessage(lang)
            showPhotoErrorAlert = true
            return
        }
        guard let relativePath = LocalPhotoStore.saveImageData(data) else {
            photoErrorMessage = L.detailPhotoSaveFailedMessage(lang)
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
    let lang: AppLanguage
    fileprivate var preferences = AppPreferences()

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            Text(L.insightSnapshotTitle(lang))
                .font(DSText.headline)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines) { line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(emoji(for: line.kind))
                            .font(DSText.caption)

                        Text(line.text)
                            .font(DSText.subheadline)
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
    @State private var showPhotoPreview = false
    @State private var showFullLog = false
    @AppStorage("app_language") private var appLanguageRaw: String = ""
    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    private var historyImage: UIImage? {
        guard let path = log.photoLocalPath else { return nil }
        return LocalPhotoStore.loadImage(fromRelativePath: path)
    }

    /// Heuristic: the compact preview clamps the note to 2 lines via `.lineLimit(2)`.
    /// SwiftUI does not surface whether truncation actually occurred, so we approximate
    /// "needs See all" by checking for a newline (multi-line input is the most common
    /// truncation source) or a length comfortably beyond what 2 lines can fit.
    /// The 80-char threshold is conservative for typical iPhone widths.
    private var noteNeedsExpansion: Bool {
        let trimmed = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("\n") || trimmed.count > 80
    }

    private func relativeDateLabel(for date: Date, lang: AppLanguage) -> String {
        let calendar = Calendar.current
        let daysAgo = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: date),
                to: calendar.startOfDay(for: Date())
            ).day ?? 0
        )

        switch daysAgo {
        case 0:
            return lang == .english ? "Today" : "今天"
        case 1:
            return lang == .english ? "Yesterday" : "昨天"
        default:
            return lang == .english ? "\(daysAgo) days ago" : "\(daysAgo) 天前"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                if let emoji = log.mood?.emoji {
                    Text(emoji)
                        .font(.title3)
                }

                Text(relativeDateLabel(for: log.date, lang: lang))
                    .font(DSText.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Text(log.date, style: .date)
                    .font(DSText.caption)
                    .foregroundColor(.secondary)
            }

            if !log.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(log.note)
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            if let image = historyImage {
                Button {
                    showPhotoPreview = true
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showPhotoPreview) {
                    NavigationStack {
                        Color.black.opacity(0.98)
                            .ignoresSafeArea()
                            .overlay {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                            }
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(L.detailPhotoPreviewDone(lang)) {
                                        showPhotoPreview = false
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                    }
                }
            } else if log.photoLocalPath != nil {
                HStack(spacing: 8) {
                    Image(systemName: "photo.slash")
                        .font(DSText.caption)
                    Text(L.detailPhotoUnavailable(lang))
                        .font(DSText.caption)
                }
                .foregroundColor(.secondary)
            }

            // Separate bottom action row for opening the full entry. Lives below the
            // photo thumbnail with explicit spacing so it can't be confused with the
            // thumbnail tap target.
            if noteNeedsExpansion {
                HStack {
                    Spacer()
                    Button {
                        showFullLog = true
                    } label: {
                        Text(L.historyViewFullEntry(lang))
                            .font(DSText.subheadline)
                            .foregroundColor(.blue)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .lightCardStyle(
            cornerRadius: 14,
            fillColor: Color(.secondarySystemBackground),
            fillOpacity: 1.0,
            borderOpacity: 0.035,
            shadowOpacity: 0.015,
            shadowRadius: 4,
            shadowYOffset: 1,
            contentPadding: DSSpacing.md
        )
        .sheet(isPresented: $showFullLog) {
            FullLogSheet(log: log, lang: lang)
        }
    }
}

/// Modal that shows a daily log's full saved content (date, mood, complete note
/// preserving line breaks, optional photo). Display-only — no editing here, no
/// translation of user-entered note text.
private struct FullLogSheet: View {
    let log: DailyLog
    let lang: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoPreview = false

    private var image: UIImage? {
        guard let path = log.photoLocalPath else { return nil }
        return LocalPhotoStore.loadImage(fromRelativePath: path)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Text(log.date, style: .date)
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)

                        if let mood = log.mood {
                            Text(mood.emoji)
                                .font(.title2)
                        }

                        Spacer()
                    }

                    if !log.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(log.note)
                            .font(DSText.body)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let image {
                        Button {
                            showPhotoPreview = true
                        } label: {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    } else if log.photoLocalPath != nil {
                        HStack(spacing: 8) {
                            Image(systemName: "photo.slash")
                                .font(DSText.caption)
                            Text(L.detailPhotoUnavailable(lang))
                                .font(DSText.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.actionDone(lang)) { dismiss() }
                }
            }
            .sheet(isPresented: $showPhotoPreview) {
                if let image {
                    NavigationStack {
                        Color.black.opacity(0.98)
                            .ignoresSafeArea()
                            .overlay {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                            }
                            .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                    Button(L.detailPhotoPreviewDone(lang)) {
                                        showPhotoPreview = false
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                    }
                }
            }
        }
    }
}



