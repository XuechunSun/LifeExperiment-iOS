//
//  LifeExperimentApp.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 12/20/25.
//

import SwiftUI
import CoreText

@main
struct LifeExperimentApp: App {
    init() {
        registerBundledFonts()
        configureTypographyAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(DSText.body)
        }
    }

    private func registerBundledFonts() {
        let fontFileNames = ["Figtree-Variable", "Caveat-Variable"]
        for name in fontFileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private func configureTypographyAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [
            .font: DSFont.uiPrimary(size: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .font: DSFont.uiPrimary(size: 34, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance

        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.titleTextAttributes = navAppearance.titleTextAttributes
        scrollEdge.largeTitleTextAttributes = navAppearance.largeTitleTextAttributes
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge

        let tabBarFont = DSFont.uiPrimary(size: 10, weight: .semibold)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: tabBarFont], for: .selected)
    }
}
