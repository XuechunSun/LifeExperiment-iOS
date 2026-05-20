//
//  MiniLabGuideView.swift
//  LifeExperiment
//
//  Phase 6 of MiniLab v1.1 — a read-only, page-driven product guide reached
//  from Profile → "How MiniLab works". Reuses the visual leaf views
//  `OnboardingIntroPage1View` and `OnboardingIntroPage2View` but DELIBERATELY
//  does not reuse `OnboardingFlowView` because that view writes
//  `OnboardingState.stage = .introSeen` on its intro-2 CTA — which is correct
//  for first-run onboarding but destructive for a replay context.
//
//  Architecture
//  ------------
//  Pages are modelled as an `enum MiniLabGuidePage: CaseIterable` whose
//  case order is the display order. `MiniLabGuideView` walks the cases via a
//  single `currentPageIndex: Int` local `@State`. Adding a future page is a
//  two-line change:
//    1. Add a new case to `MiniLabGuidePage` in the desired position.
//    2. Add a matching branch in the `pageContent` switch returning the new
//       leaf view.
//  No other code (CTA, indexing, dismissal, persistence) needs to change.
//
//  Hard guarantees (verified by inspection — see Phase 6 QA notes):
//    - This file does NOT reference `OnboardingState.stage`.
//    - This file does NOT reference `OnboardingState.guidedExperimentId`.
//    - This file does NOT mutate any `UserDefaults` key.
//    - This file does NOT present a starter picker or open Create.
//  The guide is safe to show to any user at any time and never affects
//  first-run onboarding behavior.
//

import SwiftUI

/// Ordered sequence of pages presented inside `MiniLabGuideView`.
/// Add a new case to extend the guide; the case order is the display order.
enum MiniLabGuidePage: CaseIterable, Identifiable {
    case intro
    case howItWorks

    var id: String { String(describing: self) }
}

struct MiniLabGuideView: View {
    @AppStorage("app_language") private var appLanguageRaw: String = ""

    /// Local-only navigation state. No persistence, no shared model.
    @State private var currentPageIndex: Int = 0

    /// Called when the user finishes the guide (final-page CTA tap).
    /// Swipe-down dismiss bypasses this — the host's `.sheet` binding will
    /// flip to `false` either way, so the host should treat both paths the
    /// same when teardown logic is needed.
    let onDismiss: () -> Void

    private var lang: AppLanguage { L.currentLanguage(from: appLanguageRaw) }

    private var pages: [MiniLabGuidePage] { MiniLabGuidePage.allCases }

    private var currentPage: MiniLabGuidePage {
        // Defensive bounds clamp — `currentPageIndex` is only ever advanced
        // via the bottom CTA, but this keeps the view total-on inputs.
        let safeIndex = max(0, min(currentPageIndex, pages.count - 1))
        return pages[safeIndex]
    }

    private var isLastPage: Bool {
        currentPageIndex >= pages.count - 1
    }

    var body: some View {
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
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    // MARK: - Layout

    /// Mirrors `OnboardingFlowView.contentArea` for intro steps so the guide's
    /// visual rhythm matches first-run onboarding exactly.
    @ViewBuilder
    private var contentArea: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: max(DSSpacing.xl * 2, geo.size.height * 0.22))
                    pageContent
                        .padding(.horizontal, DSSpacing.lg)
                    Spacer(minLength: DSSpacing.lg)
                }
                .frame(minHeight: geo.size.height, alignment: .topLeading)
            }
        }
    }

    /// Map page enum → leaf view. Add a new branch here when adding a new
    /// case to `MiniLabGuidePage`.
    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case .intro:
            OnboardingIntroPage1View(lang: lang)
        case .howItWorks:
            OnboardingIntroPage2View(lang: lang)
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        Button {
            if isLastPage {
                onDismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentPageIndex += 1
                }
            }
        } label: {
            Text(isLastPage ? L.guideGotIt(lang) : L.onboardingIntro1CTA(lang))
                .font(DSText.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(primaryLavenderButton)
                .cornerRadius(12)
        }
    }
}
