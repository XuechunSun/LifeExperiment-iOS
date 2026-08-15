//
//  ProfileView.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import SwiftUI

struct ProfileView: View {
    let loadExperiments: () -> [Experiment]
    var lowEnergyLogs: [LowEnergyLog] = []
    let onResetAllData: () -> Void
    /// DEBUG-only: replaces stored experiments with `DebugSampleData` fixtures.
    let onLoadSampleData: () -> Void

    @AppStorage("app_language") private var appLanguageRaw: String = ""
    /// Persisted unlock for Debug tools (also cleared when defaults domain is wiped on reset).
    @AppStorage("profile_developer_tools_unlocked") private var developerToolsUnlocked = false
    @State private var showResetAllDataConfirm = false
    @State private var showDeveloperToolsBanner = false
    @State private var developerToolsBannerText = ""
    // Phase 6: drives the "How MiniLab works" read-only guide sheet. The
    // guide reuses the onboarding intro leaf views but DOES NOT write to
    // `OnboardingState` — see `MiniLabGuideView.swift` for the invariants.
    @State private var showMiniLabGuide = false

    private var preferences = AppPreferences()

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    init(
        loadExperiments: @escaping () -> [Experiment],
        lowEnergyLogs: [LowEnergyLog] = [],
        onResetAllData: @escaping () -> Void = {},
        onLoadSampleData: @escaping () -> Void = {}
    ) {
        self.loadExperiments = loadExperiments
        self.lowEnergyLogs = lowEnergyLogs
        self.onResetAllData = onResetAllData
        self.onLoadSampleData = onLoadSampleData
    }

    private var experiments: [Experiment] {
        loadExperiments()
    }

    // CL#2: Day-based shown-up count (distinct calendar days with any activity)
    private var shownUpCount: Int {
        let calendar = Calendar.current
        var activeDays = Set<Date>()

        for experiment in experiments {
            activeDays.insert(calendar.startOfDay(for: experiment.createdAt))
            if let completedAt = experiment.completedAt {
                activeDays.insert(calendar.startOfDay(for: completedAt))
            }
            for log in experiment.logs {
                let trimmedNote = log.note.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedNote.isEmpty || log.mood != nil {
                    activeDays.insert(calendar.startOfDay(for: log.date))
                }
            }
        }

        for leLog in lowEnergyLogs {
            activeDays.insert(calendar.startOfDay(for: leLog.date))
        }

        return activeDays.count
    }

    private var gentleDayCount: Int {
        let calendar = Calendar.current
        let days = Set(lowEnergyLogs.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    private var headerSubtitle: String {
        shownUpCount > 0 ? L.profileShownUp(lang, count: shownUpCount) : L.profileStillExploring(lang)
    }

    private var currentLanguageDisplay: String {
        L.currentLanguage(from: appLanguageRaw).displayName
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 28) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        highlightCardStart,
                                        primaryLavenderButton.opacity(0.88),
                                        highlightCardEnd
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
                            )
                            .frame(width: 72, height: 72)
                            .shadow(color: primaryLavenderButton.opacity(0.18), radius: 10, x: 0, y: 4)

                        Image(systemName: "sparkles")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: 6) {
                        Text(L.lifeExperimenter(lang))
                            .font(DSText.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)

                        Text(headerSubtitle)
                            .font(DSText.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if gentleDayCount > 0 {
                            Text(L.gentleDays(lang, count: gentleDayCount))
                                .font(DSText.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Text(L.usingThisDeviceOnly(lang))
                            .font(DSText.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .lightCardStyle(
                    cornerRadius: 16,
                    fillColor: Color(.systemBackground),
                    fillOpacity: 1.0,
                    borderOpacity: 0.04,
                    shadowOpacity: 0.02,
                    shadowRadius: 6,
                    shadowYOffset: 2,
                    contentPadding: preferences.uiStyle.cardPadding
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(L.yourExperience(lang))
                        .font(DSText.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top, spacing: DSSpacing.md) {
                            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                Text(L.imageLogging(lang))
                                    .font(DSText.subheadline)
                                    .fontWeight(.medium)

                                Text(L.profileImageLoggingSubtitle(lang))
                                    .lifeCaption()
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Toggle("", isOn: preferences.imageLoggingEnabledBinding)
                                .labelsHidden()
                        }
                        .padding(.vertical, 12)

                        Divider()

                        HStack(alignment: .center, spacing: DSSpacing.md) {
                            Text(L.language(lang))
                                .font(DSText.subheadline)
                                .fontWeight(.medium)

                            Spacer(minLength: 0)

                            Menu {
                                ForEach(AppLanguage.allCases) { option in
                                    Button(option.displayName) {
                                        appLanguageRaw = option.rawValue
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(currentLanguageDisplay)
                                        .font(DSText.subheadline)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .frame(minHeight: 32)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
                        .padding(.vertical, 12)

                        Divider()

                        Button {
                            showMiniLabGuide = true
                        } label: {
                            HStack(alignment: .top, spacing: DSSpacing.md) {
                                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                    Text(L.profileHowMiniLabWorksTitle(lang))
                                        .font(DSText.subheadline)
                                        .fontWeight(.medium)

                                    Text(L.profileHowMiniLabWorksSubtitle(lang))
                                        .lifeCaption()
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(DSText.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()

                        NavigationLink(value: Route.completedMore) {
                            HStack(alignment: .top, spacing: DSSpacing.md) {
                                VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                                    Text(L.completedExperiments(lang))
                                        .font(DSText.subheadline)
                                        .fontWeight(.medium)

                                    Text(L.profileCompletedSubtitle(lang))
                                        .lifeCaption()
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(DSText.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .lightCardStyle(
                        cornerRadius: preferences.uiStyle.cardCornerRadius,
                        fillColor: Color(.systemBackground),
                        fillOpacity: 1.0,
                        borderOpacity: 0.04,
                        shadowOpacity: 0.02,
                        shadowRadius: 6,
                        shadowYOffset: 2,
                        contentPadding: preferences.uiStyle.cardPadding
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L.profileDataAndSystemSection(lang))
                        .font(DSText.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text(L.dataStorage(lang))
                                .font(DSText.subheadline)
                                .fontWeight(.medium)

                            Text(L.dataStoredOnDeviceOnly(lang))
                                .lifeCaption()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity)
                    .lightCardStyle(
                        cornerRadius: preferences.uiStyle.cardCornerRadius,
                        fillColor: Color(.systemBackground),
                        fillOpacity: 1.0,
                        borderOpacity: 0.04,
                        shadowOpacity: 0.02,
                        shadowRadius: 6,
                        shadowYOffset: 2,
                        contentPadding: preferences.uiStyle.cardPadding
                    )
                }

                if developerToolsUnlocked {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L.profileDebugSectionTitle(lang))
                            .font(DSText.headline)

                        VStack(alignment: .leading, spacing: 0) {
                            #if DEBUG
                            Button {
                                onLoadSampleData()
                            } label: {
                                Text(L.profileDebugLoadSampleData(lang))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 12)

                            Divider()
                            #endif

                            Button(role: .destructive) {
                                showResetAllDataConfirm = true
                            } label: {
                                Text(L.profileDebugResetAllData(lang))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 12)
                        }
                        .lightCardStyle(
                            cornerRadius: preferences.uiStyle.cardCornerRadius,
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

                Text(L.builtForCuriosity(lang))
                    .font(DSText.caption2)
                    .foregroundColor(.secondary.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 32)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 6) {
                        developerToolsUnlocked.toggle()
                        developerToolsBannerText = developerToolsUnlocked
                            ? L.profileDeveloperToolsBannerShown(lang)
                            : L.profileDeveloperToolsBannerHidden(lang)
                        withAnimation(.easeOut(duration: 0.2)) {
                            showDeveloperToolsBanner = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showDeveloperToolsBanner = false
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        }
        .overlay(alignment: .bottom) {
            if showDeveloperToolsBanner {
                Text(developerToolsBannerText)
                    .font(DSText.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .padding(.bottom, 12)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showDeveloperToolsBanner)
        .navigationTitle(L.profile(lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(L.profileResetTitle(lang), isPresented: $showResetAllDataConfirm) {
            Button(L.profileResetCancel(lang), role: .cancel) { }
            Button(L.profileResetConfirm(lang), role: .destructive) {
                onResetAllData()
            }
        } message: {
            Text(L.profileResetMessage(lang))
        }
        .sheet(isPresented: $showMiniLabGuide) {
            MiniLabGuideView(onDismiss: {
                showMiniLabGuide = false
            })
        }
    }
}
