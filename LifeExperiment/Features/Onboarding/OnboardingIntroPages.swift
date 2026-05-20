//
//  OnboardingIntroPages.swift
//  LifeExperiment
//
//  Phase 2 of MiniLab v1.1 onboarding — placeholder intro page views shown
//  inside `OnboardingFlowView`. Copy is intentionally low-pressure and benefit-
//  first; final polish can happen in Phase 7.
//

import SwiftUI

/// Intro page 1: what MiniLab is.
struct OnboardingIntroPage1View: View {
    let lang: AppLanguage

    // Phase 5.3 breathing polish:
    //   - Outer VStack spacing  lg(20) → xl(24)  — more relaxed rhythm.
    //   - Icon bottom padding    xs(8) → sm(12) — pushes title slightly further
    //     from the sparkles glyph so the headline reads as the focal point.
    //   - Reassurance top padding xs(8) → md(16) — adds a deliberate "settle"
    //     before the reassurance line so it feels like its own beat rather
    //     than another body paragraph.
    // Token-only changes; no magic numbers, no copy edits, no alignment edits.
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(primaryLavenderButton)
                .padding(.bottom, DSSpacing.sm)

            Text(L.onboardingIntro1Title(lang))
                .font(DSText.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(L.onboardingIntro1Subtitle(lang))
                .font(DSText.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(L.onboardingIntro1Reassurance(lang))
                .font(DSText.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, DSSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Intro page 2: how MiniLab works (three short steps).
struct OnboardingIntroPage2View: View {
    let lang: AppLanguage

    private struct Bullet: Identifiable {
        let id = UUID()
        let icon: String
        let text: String
    }

    private var bullets: [Bullet] {
        [
            Bullet(icon: "lightbulb", text: L.onboardingIntro2Bullet1(lang)),
            Bullet(icon: "square.and.pencil", text: L.onboardingIntro2Bullet2(lang)),
            Bullet(icon: "calendar", text: L.onboardingIntro2Bullet3(lang)),
        ]
    }

    // Phase 5.3 breathing polish:
    //   - Outer VStack spacing       lg(20) → xl(24) — title sits further
    //     from the bullet list.
    //   - Bullet-to-bullet spacing   md(16) → lg(20) — each row gets its
    //     own breathing room without making the list feel sparse.
    //   - Bullet list top padding    xs(8)  → sm(12) — gentle extra beat
    //     between the title and the list.
    // Token-only changes; no magic numbers, no copy edits, no alignment edits.
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            Text(L.onboardingIntro2Title(lang))
                .font(DSText.title)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach(bullets) { bullet in
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        Image(systemName: bullet.icon)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(primaryLavenderButton)
                            .frame(width: 28, alignment: .leading)
                            .padding(.top, 2)

                        Text(bullet.text)
                            .font(DSText.body)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, DSSpacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
