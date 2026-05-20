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

    /// Stable for the calendar day + state + language (not re-picked on every `body` refresh).
    static func stableCopy(for state: HomeGuideState, lang: AppLanguage) -> GuideCopy {
        let pool = copies(for: state, lang: lang)
        guard !pool.isEmpty else {
            return GuideCopy(headline: "", subheadline: "")
        }
        let idx = dayStableBucket(state: state, lang: lang) % pool.count
        return pool[idx]
    }

    private static func dayStableBucket(state: HomeGuideState, lang: AppLanguage) -> Int {
        let cal = Calendar.current
        let now = Date()
        let y = cal.component(.year, from: now)
        let m = cal.component(.month, from: now)
        let d = cal.component(.day, from: now)
        let stateTag: Int
        switch state {
        case .noActive: stateTag = 0
        case .activeNoLogToday: stateTag = 1
        case .loggedToday: stateTag = 2
        }
        let langTag = lang == .chinese ? 31 : 17
        return abs(y &* 10_000 &+ m &* 100 &+ d &+ stateTag &* 13 &+ langTag)
    }

    // MARK: - Copy pools per state

    private static func copies(for state: HomeGuideState, lang: AppLanguage) -> [GuideCopy] {
        switch lang {
        case .english:
            switch state {
            case .noActive: return noActiveCopies
            case .activeNoLogToday: return activeNoLogCopies
            case .loggedToday: return loggedTodayCopies
            }
        case .chinese:
            switch state {
            case .noActive: return noActiveCopiesZh
            case .activeNoLogToday: return activeNoLogCopiesZh
            case .loggedToday: return loggedTodayCopiesZh
            }
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

    // MARK: - Chinese pools (independent copy; counts need not match English)

    // Phase 7 P2: trailing ASCII spaces stripped from every ZH headline /
    // subheadline below. Wording is unchanged — trim only.
    private static let noActiveCopiesZh: [GuideCopy] = [
        GuideCopy(headline: "可以从一件很小的事开始", subheadline: "今天想试的话，挑一个就好"),
        GuideCopy(headline: "今天也许适合轻轻开个头", subheadline: "再小的一步也算数"),
        GuideCopy(headline: "开始没有标准答案", subheadline: "选一件听起来有趣的就行"),
        GuideCopy(headline: "不用一开始就想得很大", subheadline: "一件小事就够了"),
        GuideCopy(headline: "就从现在开始", subheadline: "一个小实验，也会让你看见不少东西"),
        GuideCopy(headline: "今天要不要试一件小事？", subheadline: "不必完美，先试试"),
        GuideCopy(headline: "再小的事也算一件事", subheadline: "边做边调整就好"),
        GuideCopy(headline: "开始往往是最简单的一步", subheadline: "先选一个方向就好"),
    ]

    private static let activeNoLogCopiesZh: [GuideCopy] = [
        GuideCopy(headline: "你手上已经有几件开始了的小事", subheadline: "今天想的话，可以继续一点点"),
        GuideCopy(headline: "你已经开始了", subheadline: "想到什么，写一句就好"),
        GuideCopy(headline: "还有几个实验可以接着做", subheadline: "写一句简短的也好"),
        GuideCopy(headline: "从上次停下的地方接着来", subheadline: "稍微留意一下今天就好"),
        GuideCopy(headline: "还有几件事，可以接着做", subheadline: "怎么舒服怎么来"),
        GuideCopy(headline: "不必做很多", subheadline: "感受一下今天也可以"),
        GuideCopy(headline: "一点点也很好", subheadline: "想记的时候，再写一句就好"),
        GuideCopy(headline: "你已经在路上了", subheadline: "今天也可以慢慢往前"),
        GuideCopy(headline: "你还在，挺好的", subheadline: "想记的时候，写一句就好"),
        GuideCopy(headline: "今天注意到了什么？", subheadline: "一个念头也值得留下"),
    ]

    private static let loggedTodayCopiesZh: [GuideCopy] = [
        GuideCopy(headline: "今天你已经做了一点点", subheadline: "如果想，可以试试新的"),
        GuideCopy(headline: "今天你也来了", subheadline: "这样就很好"),
        GuideCopy(headline: "不错，今天已经记了一笔", subheadline: "换一件事试试，或休息一下"),
        GuideCopy(headline: "今天的记录写完了", subheadline: "有心情的话，可以再试点新的"),
        GuideCopy(headline: "今天你来过这里", subheadline: "想再多试一点，也可以"),
        GuideCopy(headline: "这些小事在慢慢累起来", subheadline: "继续或休息一下，都可以"),
        GuideCopy(headline: "完成了一小步", subheadline: "接下来随你"),
        GuideCopy(headline: "今天你有停下来看看自己", subheadline: "这样的小事，其实很难得"),
    ]
}
