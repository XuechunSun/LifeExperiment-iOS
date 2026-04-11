import Foundation

enum HomeGuideState {
    case noActive
    case activeNoLogToday
    case loggedToday
}

struct GuideCopy {
    let headline: String
    let subheadline: String
}

enum GuideCopyProvider {

    static func copy(for state: HomeGuideState, sessionIndex: Int) -> GuideCopy {
        let pool = copies(for: state)
        guard !pool.isEmpty else {
            return GuideCopy(headline: "", subheadline: "")
        }
        let idx = ((sessionIndex % pool.count) + pool.count) % pool.count
        return pool[idx]
    }

    // MARK: - Copy pools per state

    private static func copies(for state: HomeGuideState) -> [GuideCopy] {
        switch state {
        case .noActive:       return noActiveCopies
        case .activeNoLogToday: return activeNoLogCopies
        case .loggedToday:    return loggedTodayCopies
        }
    }

    private static let noActiveCopies: [GuideCopy] = [
        GuideCopy(
            headline: "You can begin with something small.",
            subheadline: "Pick one experiment for today, if you'd like."
        ),
        GuideCopy(
            headline: "Today could be a good day to start.",
            subheadline: "Even something tiny counts."
        ),
        GuideCopy(
            headline: "There's no right way to begin.",
            subheadline: "Just pick something that sounds interesting."
        ),
        GuideCopy(
            headline: "You don't need a big plan.",
            subheadline: "One small thing is enough."
        ),
        GuideCopy(
            headline: "Start where you are.",
            subheadline: "A single experiment can teach you a lot."
        ),
        GuideCopy(
            headline: "What if you tried just one thing today?",
            subheadline: "It doesn't have to be perfect."
        ),
        GuideCopy(
            headline: "Something small is still something.",
            subheadline: "You can always adjust as you go."
        ),
        GuideCopy(
            headline: "The beginning is the easiest part.",
            subheadline: "You just have to pick one thing."
        ),
    ]

    private static let activeNoLogCopies: [GuideCopy] = [
        GuideCopy(
            headline: "You already have something in motion.",
            subheadline: "You can continue a little today, if you want."
        ),
        GuideCopy(
            headline: "You've already started something.",
            subheadline: "A quick check-in is all it takes."
        ),
        GuideCopy(
            headline: "Your experiments are waiting for you.",
            subheadline: "Even a small note counts."
        ),
        GuideCopy(
            headline: "Pick up where you left off.",
            subheadline: "Just a moment of attention is enough."
        ),
        GuideCopy(
            headline: "There's something here for you to continue.",
            subheadline: "Show up in whatever way feels right."
        ),
        GuideCopy(
            headline: "You don't have to do a lot.",
            subheadline: "Just notice how today feels."
        ),
        GuideCopy(
            headline: "A little goes a long way.",
            subheadline: "Check in when you're ready."
        ),
        GuideCopy(
            headline: "You're already in the middle of something.",
            subheadline: "Today's a good day to keep going."
        ),
        GuideCopy(
            headline: "Still here. Still going.",
            subheadline: "Add a small note when it feels right."
        ),
        GuideCopy(
            headline: "What did you notice today?",
            subheadline: "Even one thought is worth recording."
        ),
    ]

    private static let loggedTodayCopies: [GuideCopy] = [
        GuideCopy(
            headline: "You've done a little today.",
            subheadline: "If you want, try something new."
        ),
        GuideCopy(
            headline: "You showed up today.",
            subheadline: "That's more than enough."
        ),
        GuideCopy(
            headline: "Nice. You've already checked in.",
            subheadline: "Try something different, or just rest."
        ),
        GuideCopy(
            headline: "Today's log is in.",
            subheadline: "Explore something new if you feel like it."
        ),
        GuideCopy(
            headline: "You've been here today.",
            subheadline: "If you want more, there's always something to try."
        ),
        GuideCopy(
            headline: "You're building something quietly.",
            subheadline: "Keep going, or take a break."
        ),
        GuideCopy(
            headline: "One step done.",
            subheadline: "The rest is up to you."
        ),
        GuideCopy(
            headline: "Good. You paid attention today.",
            subheadline: "That matters more than you think."
        ),
    ]
}
