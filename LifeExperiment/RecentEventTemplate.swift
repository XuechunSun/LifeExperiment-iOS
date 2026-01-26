import Foundation

// MARK: - Recent Event Model (UI layer can render icon + text)
struct RecentEvent: Identifiable, Equatable {
    let id = UUID()
    let iconSystemName: String
    let title: String
    let subtitle: String?
}

// MARK: - Templates (logic renders variables into copy)
enum RecentEventTemplate {
    // Use this to choose icons consistently
    enum Icon {
        static let streak = "flame.fill"
        static let firstTime = "sparkles"
        static let completion = "checkmark.seal.fill"
        static let updated = "square.and.pencil"
        static let comeback = "arrow.clockwise"
        static let empty = "heart"
    }

    // A small typed template so you don't end up with stringly-typed spaghetti.
    enum Kind: Equatable {
        // A) Streak / consistency
        case streakDays(Int)                  // N days in a row
        case recordedThisWeek(Int)            // N records this week

        // B) First-time milestones
        case firstExperimentInCategory(String)
        case firstCompletion
        case firstLog

        // C) Completion
        case completedYesterday(Int)          // N completed yesterday
        case completedThisWeek(Int)           // N completed this week

        // D) Resume / come back
        case cameBackToday
        case resumedAfterBreak

        // E) General updates
        case updatedToday(Int)                // N experiments updated today
        case notesAcrossExperiments(Int)      // notes across N experiments

        // Empty
        case emptyState
    }

    static func render(_ kind: Kind) -> RecentEvent {
        switch kind {
        case .streakDays(let n):
            return RecentEvent(
                iconSystemName: Icon.streak,
                title: "You’ve recorded for \(n) day\(pluralS(n)) in a row.",
                subtitle: nil
            )

        case .recordedThisWeek(let n):
            return RecentEvent(
                iconSystemName: "calendar.badge.clock",
                title: "You’ve recorded \(n) time\(pluralS(n)) this week.",
                subtitle: nil
            )

        case .firstExperimentInCategory(let category):
            return RecentEvent(
                iconSystemName: Icon.firstTime,
                title: "First experiment in \(quoted(category)).",
                subtitle: nil
            )

        case .firstCompletion:
            return RecentEvent(
                iconSystemName: Icon.completion,
                title: "First experiment completed.",
                subtitle: "A real milestone."
            )

        case .firstLog:
            return RecentEvent(
                iconSystemName: "pencil.and.outline",
                title: "You wrote your first note.",
                subtitle: nil
            )

        case .completedYesterday(let n):
            return RecentEvent(
                iconSystemName: Icon.completion,
                title: "You completed \(n) experiment\(pluralS(n)) yesterday.",
                subtitle: "That’s a real milestone."
            )

        case .completedThisWeek(let n):
            return RecentEvent(
                iconSystemName: Icon.completion,
                title: "\(n) experiment\(pluralS(n)) completed this week.",
                subtitle: nil
            )

        case .cameBackToday:
            return RecentEvent(
                iconSystemName: Icon.comeback,
                title: "You came back today.",
                subtitle: nil
            )

        case .resumedAfterBreak:
            return RecentEvent(
                iconSystemName: "arrow.triangle.2.circlepath",
                title: "You picked this up again after a break.",
                subtitle: nil
            )

        case .updatedToday(let count):
            return RecentEvent(
                iconSystemName: Icon.updated,
                title: "You updated \(count) experiment\(pluralS(count)) today.",
                subtitle: nil
            )

        case .notesAcrossExperiments(let count):
            return RecentEvent(
                iconSystemName: "square.grid.2x2.fill",
                title: "Notes across \(count) experiment\(pluralS(count)) — nice range.",
                subtitle: nil
            )

        case .emptyState:
            return RecentEvent(
                iconSystemName: Icon.empty,
                title: "You’re at the very beginning. That counts.",
                subtitle: nil
            )
        }
    }

    // MARK: - Helpers
    private static func pluralS(_ n: Int) -> String { n == 1 ? "" : "s" }

    private static func quoted(_ s: String) -> String {
        // Keep it simple; no fancy punctuation.
        "\"\(s)\""
    }
}
//
//  RecentEventTemplate.swift
//  LifeExperiment
//
//  Created by Xuechun Sun on 1/25/26.
//

