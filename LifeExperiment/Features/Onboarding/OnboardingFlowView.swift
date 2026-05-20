//
//  OnboardingFlowView.swift
//  LifeExperiment
//
//  Phase 2 of MiniLab v1.1 onboarding — full-screen first-run flow that walks
//  the user through intro 1 → intro 2 → starter pick, then hands off a built
//  `ExperimentEditorPrefill` to the existing Create sheet via callback.
//
//  Stage transitions owned by this view:
//    - Intro 2 "Pick a starter" CTA   →  OnboardingState.stage = .introSeen
//    - Skip alert "Skip" button       →  OnboardingState.stage = .completed
//  (Stage `.experimentCreated` transition lives in Phase 3.)
//

import SwiftUI

/// Internal step state for the first-run onboarding flow.
enum OnboardingStep {
    case intro1
    case intro2
    case starterPick
}

struct OnboardingFlowView: View {
    @AppStorage("app_language") private var appLanguageRaw: String = ""

    @State private var step: OnboardingStep
    // Phase 5.2: default-select the first starter so "Choose this" is enabled
    // immediately when the picker appears. Users can still tap another card
    // to change selection or tap Skip. If the user cancels Create and the
    // cover re-presents at starter pick, a fresh view is created and this
    // default applies again — matches the spec.
    @State private var selectedStarter: StarterExperiment? = .pause
    @State private var showSkipConfirm: Bool = false

    /// Called once the user taps "Choose this" with a starter selected.
    /// The host is responsible for dismissing this cover and presenting the
    /// existing Create sheet with the provided prefill.
    let onStarterChosen: (ExperimentEditorPrefill) -> Void

    /// Called after the user confirms Skip. The host should dismiss this cover.
    /// Stage is already advanced to `.completed` before this fires.
    let onSkipConfirmed: () -> Void

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    init(
        initialStep: OnboardingStep,
        onStarterChosen: @escaping (ExperimentEditorPrefill) -> Void,
        onSkipConfirmed: @escaping () -> Void
    ) {
        _step = State(initialValue: initialStep)
        self.onStarterChosen = onStarterChosen
        self.onSkipConfirmed = onSkipConfirmed
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                contentArea

                VStack(spacing: 0) {
                    Divider().opacity(0.08)
                    bottomCTA
                        .padding(.horizontal, DSSpacing.lg)
                        .padding(.top, DSSpacing.md)
                        .padding(.bottom, DSSpacing.md)
                }
                .background(Color(.systemBackground))
            }

            Button(action: { showSkipConfirm = true }) {
                Text(L.actionSkip(lang))
                    .font(DSText.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.vertical, DSSpacing.xs)
                    .contentShape(Rectangle())
            }
            .padding(.top, DSSpacing.xs)
            .padding(.trailing, DSSpacing.sm)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(L.onboardingSkipConfirmTitle(lang), isPresented: $showSkipConfirm) {
            Button(L.actionCancel(lang), role: .cancel) {}
            // Phase 7 P1: dropped `role: .destructive` — Skip is no longer
            // destructive since users can revisit the intro any time from
            // Profile → "How MiniLab works" (Phase 6). State transition is
            // unchanged: confirming still completes onboarding and dismisses.
            Button(L.actionSkip(lang)) {
                OnboardingState.stage = .completed
                onSkipConfirmed()
            }
        } message: {
            Text(L.onboardingSkipConfirmMessage(lang))
        }
    }

    // MARK: - Step content

    /// Phase 5.2 layout polish: intro pages get a vertically balanced shell so
    /// the headline sits in the upper-middle (~22% from the top of the
    /// available area) instead of stuck to the top edge. We keep a ScrollView
    /// wrapper so accessibility text sizes can still scroll if they overflow,
    /// and we force the inner VStack to be at least viewport-tall so the
    /// trailing Spacer can claim available slack. Starter pick keeps the
    /// previous top-anchored ScrollView so the three cards stay visible
    /// without scrolling on most devices.
    @ViewBuilder
    private var contentArea: some View {
        switch step {
        case .intro1, .intro2:
            GeometryReader { geo in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                            .frame(height: max(DSSpacing.xl * 2, geo.size.height * 0.22))
                        content
                            .padding(.horizontal, DSSpacing.lg)
                        Spacer(minLength: DSSpacing.lg)
                    }
                    .frame(minHeight: geo.size.height, alignment: .topLeading)
                }
            }
        case .starterPick:
            ScrollView {
                content
                    .padding(.top, DSSpacing.xl + DSSpacing.md)
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.bottom, DSSpacing.lg)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .intro1:
            OnboardingIntroPage1View(lang: lang)
        case .intro2:
            OnboardingIntroPage2View(lang: lang)
        case .starterPick:
            starterPickContent
        }
    }

    private var starterPickContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text(L.onboardingStarterPickTitle(lang))
                .font(DSText.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(L.onboardingStarterPickReassurance(lang))
                .font(DSText.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, DSSpacing.xs)

            VStack(spacing: DSSpacing.sm) {
                ForEach(StarterExperiment.allCases) { starter in
                    StarterPickCard(
                        starter: starter,
                        lang: lang,
                        isSelected: selectedStarter == starter,
                        action: { selectedStarter = starter }
                    )
                }
            }
        }
    }

    // MARK: - Bottom CTA

    @ViewBuilder
    private var bottomCTA: some View {
        switch step {
        case .intro1:
            primaryButton(title: L.onboardingIntro1CTA(lang), enabled: true) {
                withAnimation(.easeInOut(duration: 0.2)) { step = .intro2 }
            }
        case .intro2:
            primaryButton(title: L.onboardingIntro2CTA(lang), enabled: true) {
                OnboardingState.stage = .introSeen
                withAnimation(.easeInOut(duration: 0.2)) { step = .starterPick }
            }
        case .starterPick:
            primaryButton(
                title: L.onboardingChooseThisCTA(lang),
                enabled: selectedStarter != nil
            ) {
                guard let starter = selectedStarter else { return }
                let prefill = StarterExperimentCatalog.prefill(for: starter, lang: lang)
                onStarterChosen(prefill)
            }
        }
    }

    private func primaryButton(
        title: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(DSText.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(enabled ? primaryLavenderButton : primaryLavenderButton.opacity(0.4))
                .cornerRadius(12)
        }
        .disabled(!enabled)
    }
}

// MARK: - Starter card

private struct StarterPickCard: View {
    let starter: StarterExperiment
    let lang: AppLanguage
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: DSSpacing.md) {
                Image(systemName: starter.iconSystemName)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(primaryLavenderButton)
                    .frame(width: 28, alignment: .center)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(starter.localizedTitle(lang))
                        .font(DSText.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(starter.localizedSubtitle(lang))
                        .font(DSText.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isSelected ? primaryLavenderButton : .secondary.opacity(0.4))
                    .padding(.top, 2)
            }
        }
        .buttonStyle(.plain)
        .lightCardStyle(
            cornerRadius: 14,
            fillColor: Color(.systemBackground),
            fillOpacity: 1.0,
            // Drop the default thin border when selected — the lavender overlay
            // below carries the selected appearance.
            borderOpacity: isSelected ? 0 : 0.06,
            shadowOpacity: isSelected ? 0.08 : 0.03,
            shadowRadius: isSelected ? 8 : 6,
            shadowYOffset: 2,
            contentPadding: DSSpacing.md
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(primaryLavenderButton, lineWidth: isSelected ? 2 : 0)
        )
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
