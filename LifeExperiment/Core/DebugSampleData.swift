#if DEBUG
import Foundation
import UIKit

/// DEBUG-only fixture builder for manual UI testing.
///
/// Produces a spread of experiments that exercises every Home hero-card branch.
/// The `updatedAt` values are staggered so the hero rotates predictably as you
/// log into each one: A (photo) → B (no photo) → C (no logs). D already has a
/// log for today, so it is never the hero; E is completed.
///
/// Photos are real JPEGs written through `LocalPhotoStore`, so the hero card
/// goes through the same load path as user-attached photos.
enum DebugSampleData {

    static func makeExperiments() -> [Experiment] {
        [
            photoExperiment(),
            noPhotoExperiment(),
            noLogsExperiment(),
            loggedTodayExperiment(),
            completedExperiment()
        ]
    }

    // MARK: - Fixtures

    /// Hero by default: newest `updatedAt` among experiments without a log today.
    /// Carries two photos on different days so you can verify the *latest* wins.
    private static func photoExperiment() -> Experiment {
        let olderPhoto = savePlaceholderPhoto(.systemTeal, .systemGreen)
        let newerPhoto = savePlaceholderPhoto(.systemOrange, .systemPink)

        return Experiment(
            title: "Morning light walk",
            category: "well_being",
            subcategory: "Movement",
            impact: ExperimentImpact(
                primary: .body_energy,
                secondary: .emotion_awareness,
                tertiary: .expression_creativity
            ),
            status: .active,
            createdAt: daysAgo(24),
            updatedAt: daysAgo(2),
            logs: [
                DailyLog(
                    date: daysAgo(11),
                    note: "Went out before the noise started. Colder than expected but the street was completely empty.",
                    mood: .good,
                    photoLocalPath: olderPhoto
                ),
                DailyLog(
                    date: daysAgo(6),
                    note: "Skipped the long loop and just circled the block. Still counted.",
                    mood: .neutral
                ),
                DailyLog(
                    date: daysAgo(2),
                    note: "Twenty minutes outside before opening the laptop. The whole morning felt slower in a good way — less scrambling, fewer half-finished thoughts.",
                    mood: .veryGood,
                    photoLocalPath: newerPhoto
                )
            ]
        )
    }

    /// Becomes the hero once the photo experiment has a log for today.
    /// Verifies the default illustration fallback.
    private static func noPhotoExperiment() -> Experiment {
        Experiment(
            title: "One page before bed",
            category: "challenge_30",
            subcategory: "Daily Discipline",
            impact: ExperimentImpact(primary: .focus_flow, secondary: .self_understanding),
            status: .active,
            createdAt: daysAgo(18),
            updatedAt: daysAgo(5),
            logs: [
                DailyLog(date: daysAgo(9), note: "Read four pages instead of one. Easier when the phone is in the other room.", mood: .good),
                DailyLog(date: daysAgo(5), note: "Fell asleep on page two.", mood: .neutral)
            ]
        )
    }

    /// Verifies the hero card's empty-note state.
    private static func noLogsExperiment() -> Experiment {
        Experiment(
            title: "Message one friend a week",
            category: "emotional_care",
            subcategory: "Emotional Awareness",
            impact: ExperimentImpact(primary: .connection),
            status: .active,
            createdAt: daysAgo(9),
            updatedAt: daysAgo(9)
        )
    }

    /// Already logged today — must be excluded from both hero and Continue.
    private static func loggedTodayExperiment() -> Experiment {
        Experiment(
            title: "No screens during lunch",
            category: "well_being",
            subcategory: "Nutrition Awareness",
            impact: ExperimentImpact(primary: .self_understanding, secondary: .focus_flow),
            status: .active,
            createdAt: daysAgo(13),
            updatedAt: Date(),
            logs: [
                DailyLog(date: daysAgo(4), note: "Ate at my desk anyway. Noticed it, didn't fix it.", mood: .bad),
                DailyLog(date: Date(), note: "Actually sat outside for the whole thing today.", mood: .good)
            ]
        )
    }

    private static func completedExperiment() -> Experiment {
        Experiment(
            title: "Two weeks of earlier alarms",
            category: "life_reset",
            subcategory: "Daily Structure",
            impact: ExperimentImpact(primary: .execution, secondary: .body_energy),
            status: .active,
            createdAt: daysAgo(46),
            updatedAt: daysAgo(17),
            logs: [
                DailyLog(date: daysAgo(31), note: "Day one. Painful.", mood: .bad),
                DailyLog(date: daysAgo(24), note: "Getting easier. The trick was moving the alarm across the room.", mood: .good),
                DailyLog(date: daysAgo(17), note: "Kept it up for two weeks. Worth keeping.", mood: .veryGood)
            ]
        ).completed(on: daysAgo(17))
    }

    // MARK: - Helpers

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    /// Renders a simple gradient JPEG and stores it the same way a picked photo
    /// would be stored. Returns the relative path, or nil if writing failed.
    private static func savePlaceholderPhoto(_ top: UIColor, _ bottom: UIColor) -> String? {
        let size = CGSize(width: 700, height: 364)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            let colors = [top.cgColor, bottom.cgColor] as CFArray
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            ) else {
                top.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                return
            }
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }

        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        return LocalPhotoStore.saveImageData(data)
    }
}

private extension Experiment {
    func completed(on date: Date) -> Experiment {
        var copy = self
        copy.status = .completed
        copy.completedAt = date
        return copy
    }
}
#endif
