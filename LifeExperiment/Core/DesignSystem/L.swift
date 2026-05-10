import SwiftUI
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

enum L {
    static func currentLanguage(from storedValue: String) -> AppLanguage {
        if let language = AppLanguage(rawValue: storedValue) {
            return language
        }

        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        if preferred.hasPrefix("zh") {
            return .chinese
        }
        return .english
    }

    // MARK: - App / Brand

    static func appName(_ lang: AppLanguage) -> String {
        "MiniLab"
    }

    static func slogan(_ lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "Explore something small. Keep a trace. Grow in your own way."
        case .chinese:
            return "试试一点小事，留下一点痕迹，用自己的方式慢慢成长。"
        }
    }

    // MARK: - Home

    static func thisWeek(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "This Week"
        case .chinese: return "这一周"
        }
    }

    static func worthNoticing(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Something worth noticing"
        case .chinese: return "最近的一个小发现"
        }
    }

    static func exploreSomethingNew(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Explore something new"
        case .chinese: return "试试一点新的"
        }
    }

    static func seeMore(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "See more"
        case .chinese: return "看看更多"
        }
    }

    static func continueText(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Continue"
        case .chinese: return "继续一下"
        }
    }

    static func recentMoments(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Recent moments"
        case .chinese: return "最近的片刻"
        }
    }

    // MARK: - Home — recent event cards (RecentEventBuilder)

    static func homeRecentStreakTitle(_ lang: AppLanguage, streakDays: Int) -> String {
        switch lang {
        case .english:
            if streakDays == 1 {
                return "1 day of showing up"
            }
            return "\(streakDays) days of showing up"
        case .chinese:
            return "连着 \(streakDays) 天，你都在这里"
        }
    }

    static func homeRecentStreakSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You’re building a rhythm"
        case .chinese: return "你在慢慢形成自己的节奏"
        }
    }

    static func homeRecentFirstTimeTitle(_ lang: AppLanguage, categoryName: String) -> String {
        switch lang {
        case .english: return "✨ First time in \(categoryName)"
        case .chinese: return "✨ 第一次试试「\(categoryName)」"
        }
    }

    static func homeRecentFirstTimeSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A new area to explore"
        case .chinese: return "一个可以慢慢探索的新方向"
        }
    }

    static func homeRecentShowedUpTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "🌱 You showed up today"
        case .chinese: return "🌱 今天你也来了"
        }
    }

    static func homeRecentShowedUpSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A small return still counts"
        case .chinese: return "哪怕只是一小步，也很算数"
        }
    }

    static func homeRecentReflectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "🧠 You’ve been checking in with yourself"
        case .chinese: return "🧠 你最近常常停下来想想"
        }
    }

    static func homeRecentReflectionSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A few small patterns are starting to show"
        case .chinese: return "一些小规律，正在慢慢浮现"
        }
    }

    static func homeRecentMilestoneFirstDayTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your first day with MiniLab"
        case .chinese: return "和 MiniLab 一起的第一天"
        }
    }

    static func homeRecentMilestoneFirstDaySubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A small beginning counts"
        case .chinese: return "再小的开始，也值得被看见"
        }
    }

    static func homeRecentMilestone7DaysTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "7 days with MiniLab"
        case .chinese: return "和 MiniLab 一起到了第 7 天"
        }
    }

    static func homeRecentMilestone7DaysSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You’ve stayed with it"
        case .chinese: return "你一直都在"
        }
    }

    static func homeRecentMilestone30DaysTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "30 days with MiniLab"
        case .chinese: return "和 MiniLab 一起到了第 30 天"
        }
    }

    static func homeRecentMilestone30DaysSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Small steps add up"
        case .chinese: return "小步也会堆成很远的距离"
        }
    }

    static func sectionCompleted(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Completed"
        case .chinese: return "已完成"
        }
    }

    static func exploreTakeItEasyToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "or take it easy today"
        case .chinese: return "或者今天轻松一点"
        }
    }

    static func exploreTakeItEasyAgain(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "or take it easy again"
        case .chinese: return "或者再轻松一点"
        }
    }

    static func exploreMore(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Explore more"
        case .chinese: return "看看更多"
        }
    }

    static func calendarToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Today"
        case .chinese: return "今天"
        }
    }

    static func calendarSeeFullCalendar(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "See full calendar"
        case .chinese: return "查看完整日历"
        }
    }

    static func calendarFullTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Full Calendar"
        case .chinese: return "完整日历"
        }
    }

    /// Inserts a locale-formatted week start date (caller formats the date).
    static func calendarWeekOf(_ lang: AppLanguage, weekStartFormatted: String) -> String {
        switch lang {
        case .english: return "Week of \(weekStartFormatted)"
        case .chinese: return "\(weekStartFormatted) 这一周"
        }
    }

    // MARK: - Home — worth noticing (generalized body lines, variant 0...2)

    static func worthNoticingBodyPrimary(_ lang: AppLanguage, variant: Int) -> String {
        let v = ((variant % 3) + 3) % 3
        switch lang {
        case .english:
            switch v {
            case 0: return "You’ve been noticing how your days land lately."
            case 1: return "Small shifts in your routine can be worth a second look."
            default: return "There’s a thread in your recent experiments worth following."
            }
        case .chinese:
            switch v {
            case 0: return "你最近可能也感觉到了一些细微的变化。"
            case 1: return "生活里的小起伏，也值得多看一眼。"
            default: return "最近的记录里，也许有一条线正在慢慢成形。"
            }
        }
    }

    static func worthNoticingBodySecondary(_ lang: AppLanguage, variant: Int) -> String {
        let v = ((variant % 3) + 3) % 3
        switch lang {
        case .english:
            switch v {
            case 0: return "Here’s something different you could explore."
            case 1: return "If you’re curious, try one gentle experiment below."
            default: return "When you’re ready, pick one idea that sparks interest."
            }
        case .chinese:
            switch v {
            case 0: return "如果想试试新的，可以从下面挑一个。"
            case 1: return "好奇的话，选一个轻松的小实验就好。"
            default: return "准备好了，再选一个让你有点兴趣的方向。"
            }
        }
    }

    // MARK: - Summary

    static func summary(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Summary"
        case .chinese: return "总结"
        }
    }

    static func smallPattern(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A small pattern"
        case .chinese: return "一个小规律"
        }
    }

    static func basedOnLoggedDays(_ lang: AppLanguage, days: Int) -> String {
        switch lang {
        case .english:
            return "Based on \(days) logged days"
        case .chinese:
            return "来自 \(days) 天的记录"
        }
    }

    static func basedOnLoggedDaysEarly(_ lang: AppLanguage, days: Int) -> String {
        switch lang {
        case .english:
            return "Based on \(days) logged days — still early"
        case .chinese:
            return "来自 \(days) 天的记录，还在慢慢成形"
        }
    }

    static func yourGrowth(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your growth"
        case .chinese: return "你的变化"
        }
    }

    static func whereExploring(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Where you’ve been exploring"
        case .chinese: return "你最近在探索的方向"
        }
    }

    static func whereExploringSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "The life areas your experiments have touched so far."
        case .chinese: return "你的实验目前走过了这些生活方向。"
        }
    }

    static func highlightFeltBetterOnDaysDid(_ lang: AppLanguage, experimentTitle: String) -> String {
        switch lang {
        case .english: return "You felt better on days you did \(experimentTitle)"
        case .chinese: return "做「\(experimentTitle)」的那些日子，你的感觉好像会好一点。"
        }
    }

    static func highlightEmptyEncouragement(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Small patterns tend to show up as you keep showing up"
        case .chinese: return "多记录几次，小规律会慢慢浮现。"
        }
    }

    static func highlightGentleDaysAlong(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .english:
            if count == 1 {
                return "You also had 1 gentle day along the way"
            }
            return "You also had \(count) gentle days along the way"
        case .chinese:
            return "这一路上还有 \(count) 天过得更松一点。"
        }
    }

    // MARK: - Profile

    static func profile(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Profile"
        case .chinese: return "我的"
        }
    }

    static func lifeExperimenter(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Life Experimenter"
        case .chinese: return "生活实验者"
        }
    }

    static func usingThisDeviceOnly(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Using this device only"
        case .chinese: return "仅在这台设备上使用"
        }
    }

    static func gentleDays(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .english:
            return "\(count) of them were gentle days"
        case .chinese:
            return "其中 \(count) 天过得温柔一点"
        }
    }

    static func yourExperience(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your experience"
        case .chinese: return "你的使用情况"
        }
    }

    static func imageLogging(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Photo logging"
        case .chinese: return "照片记录"
        }
    }

    static func completedExperiments(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Completed Experiments"
        case .chinese: return "已完成的实验"
        }
    }

    static func dataStorage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Data"
        case .chinese: return "数据"
        }
    }

    static func dataStoredOnDeviceOnly(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your data stays on this device."
        case .chinese: return "你的数据只保留在这台设备上。"
        }
    }

    static func builtForCuriosity(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Built for curiosity"
        case .chinese: return "给好奇心的小工具"
        }
    }

    static func language(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Language"
        case .chinese: return "语言"
        }
    }

    static func profileShownUp(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .english: return "You've shown up \(count) times"
        case .chinese: return "你已经来过 \(count) 次"
        }
    }

    static func profileStillExploring(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Still exploring"
        case .chinese: return "还在慢慢探索"
        }
    }

    static func profileImageLoggingSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add photos to your daily logs"
        case .chinese: return "在每天的记录里加上照片"
        }
    }

    static func profileCompletedSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Look back at experiments you've finished"
        case .chinese: return "回看你已经完成的实验"
        }
    }

    static func profileDataAndSystemSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Data & System"
        case .chinese: return "数据与系统"
        }
    }

    static func profileResetTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Reset all app data?"
        case .chinese: return "清除所有应用数据？"
        }
    }

    static func profileResetCancel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Cancel"
        case .chinese: return "取消"
        }
    }

    static func profileResetConfirm(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Reset"
        case .chinese: return "清除"
        }
    }

    static func profileResetMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english:
            return "This will permanently delete all experiments, logs, saved custom subcategories, and locally stored photos on this device."
        case .chinese:
            return "将永久删除本设备上的所有实验、记录、自定义子分类，以及保存的照片。"
        }
    }

    static func profileDeveloperToolsBannerShown(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Developer tools on"
        case .chinese: return "开发者选项已开启"
        }
    }

    static func profileDeveloperToolsBannerHidden(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Developer tools off"
        case .chinese: return "开发者选项已关闭"
        }
    }

    static func profileDebugSectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Debug"
        case .chinese: return "调试"
        }
    }

    static func profileDebugResetAllData(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Reset All Data"
        case .chinese: return "清除全部数据"
        }
    }

    /// Default title for the single seeded experiment when the store is empty (first launch).
    static func seedStarterExperimentTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your first check-in"
        case .chinese: return "你的第一次记录"
        }
    }

    // MARK: - Tab bar (visible labels)

    static func tabHome(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Home"
        case .chinese: return "主页"
        }
    }

    static func tabActive(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Active"
        case .chinese: return "进行中"
        }
    }

    static func tabCreate(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Create"
        case .chinese: return "创建"
        }
    }

    static func tabSummary(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Summary"
        case .chinese: return "总览"
        }
    }

    static func tabProfile(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Profile"
        case .chinese: return "个人"
        }
    }

    // MARK: - Active & lists

    /// Screen / nav title (same product string as the Active tab).
    static func active(_ lang: AppLanguage) -> String {
        tabActive(lang)
    }

    static func noActiveExperiments(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No active experiments yet"
        case .chinese: return "还没有进行中的实验"
        }
    }

    static func noActiveExperimentsSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Start your first experiment when you're ready."
        case .chinese: return "等你准备好，第一个实验可以从这里开始。"
        }
    }

    static func createExperimentButton(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Create Experiment"
        case .chinese: return "创建实验"
        }
    }

    static func showLess(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Show less"
        case .chinese: return "收起"
        }
    }

    static func lastUpdated(_ lang: AppLanguage, dateString: String) -> String {
        switch lang {
        case .english: return "Last updated \(dateString)"
        case .chinese: return "上次更新于 \(dateString)"
        }
    }

    static func sort(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Sort"
        case .chinese: return "排序"
        }
    }

    static func searchExperiments(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Search experiments"
        case .chinese: return "搜索实验"
        }
    }

    static func sectionUpdatedToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Updated Today"
        case .chinese: return "今日已更新"
        }
    }

    static func sectionNotUpdatedToday(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .english: return "Not Updated Today (\(count))"
        case .chinese: return "今天尚未更新（\(count)）"
        }
    }

    static func activeEmptyNoUpdatesToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No updates yet today"
        case .chinese: return "今天还没有更新"
        }
    }

    static func activeEmptyAllUpdated(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Everything's been updated for today"
        case .chinese: return "今天进行中的实验都记录过了"
        }
    }

    static func sortByLastUpdated(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Last Updated"
        case .chinese: return "按最近更新"
        }
    }

    static func sortByCreatedDate(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Created Date"
        case .chinese: return "按创建时间"
        }
    }

    // MARK: - Completed list

    static func noCompletedExperiments(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No completed experiments yet"
        case .chinese: return "还没有已完成的实验"
        }
    }

    static func noCompletedExperimentsSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Once you finish an experiment, it'll show up here as a small milestone."
        case .chinese: return "完成一个实验后，它会作为一个小小的里程碑出现在这里。"
        }
    }

    static func completedListEncouragement(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Try something tiny — one day still counts as an experiment."
        case .chinese: return "试试一件很小的事，哪怕只有一天，也算一次实验。"
        }
    }

    static func sectionThisWeekList(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "This week"
        case .chinese: return "本周"
        }
    }

    static func sectionEarlierList(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Earlier"
        case .chinese: return "更早"
        }
    }

    static func completedOnDate(_ lang: AppLanguage, dateString: String) -> String {
        switch lang {
        case .english: return "Completed \(dateString)"
        case .chinese: return "完成于 \(dateString)"
        }
    }

    // MARK: - Common actions (alerts, sheets)

    static func actionCancel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Cancel"
        case .chinese: return "取消"
        }
    }

    static func actionDelete(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Delete"
        case .chinese: return "删除"
        }
    }

    static func actionComplete(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Complete"
        case .chinese: return "完成"
        }
    }

    static func actionReopen(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Reopen"
        case .chinese: return "重新开始"
        }
    }

    static func experimentDeleteConfirm(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Delete this experiment?"
        case .chinese: return "删除这个实验？"
        }
    }

    static func experimentDeleteMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "All logs and data will be deleted. This can't be undone."
        case .chinese: return "所有记录和数据都会被删除，无法撤销。"
        }
    }

    static func experimentDeleteBody(_ lang: AppLanguage, experimentTitle: String) -> String {
        switch lang {
        case .english:
            return "All logs and data for \"\(experimentTitle)\" will be deleted. This can't be undone."
        case .chinese:
            return "「\(experimentTitle)」的所有记录和数据都会被删除，无法撤销。"
        }
    }

    static func experimentCompleteConfirm(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Complete this experiment?"
        case .chinese: return "完成这个实验？"
        }
    }

    static func experimentCompleteMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You won't be able to add new entries after this."
        case .chinese: return "完成之后，就不能再添加新的记录了。"
        }
    }

    static func experimentReopenConfirm(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Reopen this experiment?"
        case .chinese: return "重新开始这个实验？"
        }
    }

    static func experimentReopenMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You'll be able to add new entries again."
        case .chinese: return "你又可以添加新的记录了。"
        }
    }

    // MARK: - Experiment detail (today / history)

    static func howDoYouFeelToday(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "How do you feel today?"
        case .chinese: return "今天感觉怎么样？"
        }
    }

    static func notes(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Notes"
        case .chinese: return "笔记"
        }
    }

    static func addPhoto(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add photo"
        case .chinese: return "添加照片"
        }
    }

    static func photoAttached(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Photo attached"
        case .chinese: return "已添加照片"
        }
    }

    static func save(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Save"
        case .chinese: return "保存"
        }
    }

    static func remove(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Remove"
        case .chinese: return "移除"
        }
    }

    static func completeExperiment(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Complete Experiment"
        case .chinese: return "完成实验"
        }
    }

    static func history(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "History"
        case .chinese: return "历史记录"
        }
    }

    static func seeEarlierEntries(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "See earlier entries"
        case .chinese: return "查看更早的记录"
        }
    }

    static func historyNoLogsYet(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Nothing here yet. Today's a good place to start."
        case .chinese: return "还没有记录，今天开一个头就好。"
        }
    }

    /// Action shown on a history row when the saved log is long enough that the
    /// compact preview truncates it. Tapping opens the full log sheet (date, mood,
    /// full note, photo).
    static func historyViewFullEntry(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "View full entry"
        case .chinese: return "查看完整记录"
        }
    }

    static func saveReview(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Save Review"
        case .chinese: return "保存总结"
        }
    }

    static func savedToast(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Saved ✓"
        case .chinese: return "已保存 ✓"
        }
    }

    static func savedReviewBlankToast(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Saved. You can add a review later."
        case .chinese: return "已保存，想写总结可以之后再来。"
        }
    }

    // MARK: - Day detail

    static func dayDetailActiveUpdates(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Active Updates"
        case .chinese: return "今天有新记录的实验"
        }
    }

    static func dayDetailNoActiveUpdates(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No active updates on this day"
        case .chinese: return "这一天没有新的记录"
        }
    }

    static func dayDetailNoExperimentsCompleted(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No experiments completed on this day"
        case .chinese: return "这一天没有完成的实验"
        }
    }

    static func dayDetailTookItEasy(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Took it easy today"
        case .chinese: return "今天让自己稍微松一松"
        }
    }

    static func detailCreatedOn(_ lang: AppLanguage, dateString: String) -> String {
        switch lang {
        case .english: return "Created \(dateString)"
        case .chinese: return "创建于 \(dateString)"
        }
    }

    static func detailCompletedOn(_ lang: AppLanguage, dateString: String) -> String {
        switch lang {
        case .english: return "Completed on \(dateString)"
        case .chinese: return "完成于 \(dateString)"
        }
    }

    static func detailExperimentCompletedNoLogging(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "This experiment is complete. New entries are closed, but you can still look back."
        case .chinese: return "这个实验已经结束了，不能再添加新的记录，但可以随时回看。"
        }
    }

    static func experimentNotFound(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Experiment not found"
        case .chinese: return "找不到这个实验"
        }
    }

    static func photoWillSaveWhenSave(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Photo will be saved when you tap Save."
        case .chinese: return "轻点「保存」后会保存新照片。"
        }
    }

    static func photoWillRemoveWhenSave(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Photo will be removed when you tap Save."
        case .chinese: return "轻点「保存」后会移除照片。"
        }
    }

    // MARK: - Create (editor)

    static func createNavNewExperiment(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "New Experiment"
        case .chinese: return "新实验"
        }
    }

    static func createNavEditExperiment(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Edit Experiment"
        case .chinese: return "编辑实验"
        }
    }

    static func createNavDuplicateExperiment(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Duplicate Experiment"
        case .chinese: return "复制实验"
        }
    }

    static func createEditorPrimary(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Create"
        case .chinese: return "创建"
        }
    }

    static func createSelectPlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Select…"
        case .chinese: return "选择…"
        }
    }

    static func createEnterSubcategoryPlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Enter here…"
        case .chinese: return "在这里输入…"
        }
    }

    static func createCategoryOther(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Other"
        case .chinese: return "其他"
        }
    }

    static func createCategoryLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Category"
        case .chinese: return "分类"
        }
    }

    static func createSubcategoryLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Subcategory"
        case .chinese: return "子分类"
        }
    }

    static func createTitleLabel(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Title"
        case .chinese: return "标题"
        }
    }

    static func createTitleFieldPlaceholder(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Experiment Title"
        case .chinese: return "实验标题"
        }
    }

    static func createImageLoggingSectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Image Logging"
        case .chinese: return "图片记录"
        }
    }

    static func createImageLoggingHelper(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add photos if they help you remember today."
        case .chinese: return "想留点画面的话，加张照片也好。"
        }
    }

    static func createImageLoggingToggle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Allow photos for this experiment"
        case .chinese: return "这个实验可以加照片"
        }
    }

    static func createIntroUnsure(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Not sure where to start?"
        case .chinese: return "不知道从哪里开始？"
        }
    }

    static func createIntroBody(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick a category and we'll suggest a few gentle starting points."
        case .chinese: return "先选一个分类，我们给你一些温和的起点。"
        }
    }

    static func createSelectCategoryFirst(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Select a category first"
        case .chinese: return "先选一个分类吧"
        }
    }

    static func createValidationSelectCategory(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick a category to continue."
        case .chinese: return "先选一个分类就可以继续。"
        }
    }

    static func createValidationEnterSubcategory(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add a subcategory to continue."
        case .chinese: return "补一个子分类就可以继续。"
        }
    }

    static func createValidationSelectSubcategory(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick a subcategory to continue."
        case .chinese: return "选一个子分类就可以继续。"
        }
    }

    static func createSuggestedPrompts(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Suggested prompts"
        case .chinese: return "标题灵感"
        }
    }

    static func createSuggestedPromptsSub(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A few gentle starting points if you'd like help naming this experiment."
        case .chinese: return "想不到标题的话，看看下面这些起点。"
        }
    }

    static func createRevert(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Revert"
        case .chinese: return "还原"
        }
    }

    static func createManageSubcategories(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Manage"
        case .chinese: return "管理"
        }
    }

    static func createCustomSubcategoryMenu(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Custom…"
        case .chinese: return "自定义…"
        }
    }

    static func createSubcategoryHintEditSaved(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You can edit this subcategory below"
        case .chinese: return "下方可以继续编辑这个子分类"
        }
    }

    static func createSubcategoryHintEnter(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Enter a custom subcategory below"
        case .chinese: return "在下方输入一个自定义子分类"
        }
    }

    static func createCustomSubcategoryPlaceholderInput(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Custom Subcategory"
        case .chinese: return "自定义子分类"
        }
    }

    static func createSaveToCategoryList(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Save to this category’s list"
        case .chinese: return "保存到该分类的列表"
        }
    }

    static func createUpTo5Saved(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Up to 5 saved"
        case .chinese: return "最多保存 5 个"
        }
    }

    static func createMax5ReplaceNote(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You can save up to 5 — saving this will replace the oldest one."
        case .chinese: return "最多保存 5 个，新的会替换最早的一个。"
        }
    }

    static func createManageSavedTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Manage Saved"
        case .chinese: return "已保存的列表"
        }
    }

    static func createManageSavedFooter(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Up to 5 saved — the newest are kept."
        case .chinese: return "最多保存 5 个，会保留最新的几个。"
        }
    }

    static func createDeleteSavedSubcategoryTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Delete this saved subcategory?"
        case .chinese: return "删除这个已保存的子分类？"
        }
    }

    static func createDuplicateTitleSuffix(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return " (Copy)"
        case .chinese: return "（副本）"
        }
    }

    // MARK: - Dimensions (MVP)

    static func dimensionDisplayTitle(_ lang: AppLanguage, dimension: Dimension) -> String {
        switch (lang, dimension) {
        case (.english, .emotion_awareness): return "Emotional Awareness"
        case (.chinese, .emotion_awareness): return "情绪觉察"
        case (.english, .body_energy): return "Body & Energy"
        case (.chinese, .body_energy): return "身体与能量"
        case (.english, .execution): return "Execution"
        case (.chinese, .execution): return "执行力"
        case (.english, .focus_flow): return "Focus & Flow"
        case (.chinese, .focus_flow): return "专注与心流"
        case (.english, .expression_creativity): return "Expression & Creativity"
        case (.chinese, .expression_creativity): return "表达与创造"
        case (.english, .connection): return "Connection"
        case (.chinese, .connection): return "关系与连接"
        case (.english, .self_understanding): return "Self-Understanding"
        case (.chinese, .self_understanding): return "自我理解"
        }
    }

    static func dimensionShortLabel(_ lang: AppLanguage, dimension: Dimension) -> String {
        switch (lang, dimension) {
        case (.english, .emotion_awareness): return "Emotional"
        case (.chinese, .emotion_awareness): return "情绪"
        case (.english, .body_energy): return "Body"
        case (.chinese, .body_energy): return "身体"
        case (.english, .self_understanding): return "Self"
        case (.chinese, .self_understanding): return "自我"
        case (.english, .execution): return "Execution"
        case (.chinese, .execution): return "执行"
        case (.english, .focus_flow): return "Focus"
        case (.chinese, .focus_flow): return "专注"
        case (.english, .expression_creativity): return "Expression"
        case (.chinese, .expression_creativity): return "表达"
        case (.english, .connection): return "Connection"
        case (.chinese, .connection): return "连接"
        }
    }

    static func dimensionPickerSubtitle(_ lang: AppLanguage, dimension: Dimension) -> String {
        switch (lang, dimension) {
        case (.english, .emotion_awareness): return "Notice and understand emotions"
        case (.chinese, .emotion_awareness): return "看见并理解情绪"
        case (.english, .body_energy): return "Stabilize physical energy"
        case (.chinese, .body_energy): return "让身体的能量更稳"
        case (.english, .execution): return "Start and complete actions"
        case (.chinese, .execution): return "开始行动并完成"
        case (.english, .focus_flow): return "Stay focused and enter flow"
        case (.chinese, .focus_flow): return "保持专注、进入心流"
        case (.english, .expression_creativity): return "Create and express yourself"
        case (.chinese, .expression_creativity): return "创造与自我表达"
        case (.english, .connection): return "Strengthen relationships"
        case (.chinese, .connection): return "经营关系与连接"
        case (.english, .self_understanding): return "Learn what suits you"
        case (.chinese, .self_understanding): return "了解更适合自己的方式"
        }
    }

    static func createEditDimensions(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Edit Dimensions"
        case .chinese: return "编辑维度"
        }
    }

    static func createPrimaryDimensionIntro(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick the main dimension this experiment focuses on."
        case .chinese: return "选一个这个实验最主要关注的方向。"
        }
    }

    static func createPrimaryDimensionSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Primary Dimension (Required)"
        case .chinese: return "主要维度（必选）"
        }
    }

    static func createAdditionalDimensionsIntro(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You can add up to 2 more dimensions if they fit."
        case .chinese: return "如果合适，可以再加上最多 2 个相关维度。"
        }
    }

    static func createAdditionalDimensionsSection(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Additional Dimensions (Optional, max 2)"
        case .chinese: return "其他维度（可选，最多 2 个）"
        }
    }

    static func createAdditionalDimensionsMaxFooter(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You've reached the limit of 2 additional dimensions."
        case .chinese: return "其他维度最多选 2 个，已经满了。"
        }
    }

    static func createDimensionEditAction(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Edit"
        case .chinese: return "编辑"
        }
    }

    static func createDefaultDimensionsHeadline(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "This experiment might help you explore"
        case .chinese: return "这个实验也许能帮你探索"
        }
    }

    /// Helper text shown under "This experiment might help you explore" on the
    /// `DefaultDimensionsCard`. Composed in three pieces so the middle action phrase
    /// can be rendered as an inline underlined link that opens the dimension editor.
    static func createDefaultDimensionsHelperPrefix(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your main area is shown first. You can "
        case .chinese: return "主维度排在前面，你也可以"
        }
    }

    static func createDefaultDimensionsHelperAction(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "change it"
        case .chinese: return "调整"
        }
    }

    static func createDefaultDimensionsHelperSuffix(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return " to better fit this experiment."
        case .chinese: return "成更适合自己的维度。"
        }
    }

    static func createCustomDimensionsHeadline(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "This experiment helps with"
        case .chinese: return "这个实验侧重的方向"
        }
    }

    static func createCustomDimensionsSubWhenSelected(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Choose the dimensions that feel most true right now. You can adjust them later."
        case .chinese: return "选当下最贴近你感受的维度，之后也随时可以调整。"
        }
    }

    static func createCustomDimensionsHeadlineUnselected(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "What does this experiment help with most? (required)"
        case .chinese: return "这个实验最想帮助你的方向是什么？（必填）"
        }
    }

    static func createCustomDimensionsSubUnselected(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Start with the area that fits best, then add any that support it."
        case .chinese: return "先从最贴近的一块开始，再加上相关的几个就好。"
        }
    }

    static func createDimensionChooseCTA(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Choose dimensions"
        case .chinese: return "选择维度"
        }
    }

    static func createCustomDimensionsReassure(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Don’t overthink it — you can adjust later."
        case .chinese: return "先不用想太多，之后都可以再改。"
        }
    }

    // MARK: - Summary (MVP)

    static func summaryYourStrength(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your Strength"
        case .chinese: return "你的优势"
        }
    }

    static func summaryYourStrengthSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "How you tend to show up across completed experiments."
        case .chinese: return "在已完成的实验里，你更常从哪些面向投入。"
        }
    }

    static func summaryYourGrowth(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your Growth"
        case .chinese: return "你最近投入的方向"
        }
    }

    static func summaryYourGrowthSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Where your time and attention have been landing."
        case .chinese: return "你的时间和注意力，最近多落在这些方向。"
        }
    }

    static func summaryPatternsSoFar(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your patterns so far"
        case .chinese: return "目前看到的样子"
        }
    }

    static func summaryStrengthEmpty(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Finish an experiment and your first insights will show up here."
        case .chinese: return "完成一个实验后，第一份小观察就会出现在这里。"
        }
    }

    static func summaryStrengthFooter(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Based on completed experiments. This picture can shift over time."
        case .chinese: return "来自你已完成的实验，这份样子会随着你继续记录慢慢改变。"
        }
    }

    static func summaryHiddenDimensionsNote(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "* Dimensions with no logged days are hidden for now."
        case .chinese: return "* 暂时隐藏了还没有记录的维度。"
        }
    }

    static func summaryGrowthBarDays(_ lang: AppLanguage, count: Int) -> String {
        switch lang {
        case .english:
            if count == 1 { return "1 day" }
            return "\(count) days"
        case .chinese: return "\(count) 天"
        }
    }

    static func summaryDimensionInfoMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Each dimension is a way to name where you've been showing up."
        case .chinese: return "每个维度，都是在描述你最近投入的地方。"
        }
    }

    // MARK: - Completed (reflection on finished experiment)

    static func completedReflectionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A small reflection"
        case .chinese: return "一点点回顾"
        }
    }

    static func completedReflectionWhatDidITry(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "What did I try?"
        case .chinese: return "我试了什么？"
        }
    }

    static func completedReflectionWhatHappened(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "What happened?"
        case .chinese: return "后来怎么样？"
        }
    }

    static func completedReflectionWhatNextTime(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Anything to try differently next time?"
        case .chinese: return "下次想试试什么不一样的？"
        }
    }

    static func optionalField(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Optional"
        case .chinese: return "选填"
        }
    }

    static func detailPickMoodAlertTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick a mood?"
        case .chinese: return "选一下心情？"
        }
    }

    static func detailPickMoodAlertMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Just one tap — it helps you notice patterns over time."
        case .chinese: return "点一下就好，慢慢也能看出自己的规律。"
        }
    }

    static func detailEmptyNoteAlertTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add a quick note?"
        case .chinese: return "写一句简短备注？"
        }
    }

    static func detailEmptyNoteAlertMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A short note helps you remember what happened today."
        case .chinese: return "一句话也好，帮你记住今天发生了什么。"
        }
    }

    static func detailPhotoAttachFailedTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Couldn't attach photo."
        case .chinese: return "照片未能添加。"
        }
    }

    static func detailPhotoPickFailedMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Please try selecting another photo."
        case .chinese: return "请尝试重新选择一张照片。"
        }
    }

    static func detailPhotoSaveFailedMessage(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Unable to save this photo locally."
        case .chinese: return "无法在本地保存这张照片。"
        }
    }

    static func detailPhotoPreviewDone(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Done"
        case .chinese: return "完成"
        }
    }

    static func detailPhotoUnavailable(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Photo unavailable"
        case .chinese: return "照片不可用"
        }
    }

    // MARK: - Detail (check-in + insight snapshot)

    static func insightSnapshotTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Insight Snapshot"
        case .chinese: return "近期小观察"
        }
    }

    // Insight lines (InsightCalculator; logic unchanged, strings only)
    static func insightMoodFairlySteady(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been fairly steady recently."
        case .chinese: return "最近情绪整体比较稳定。"
        }
    }

    static func insightMoodSlightlyUp(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been trending up a little lately."
        case .chinese: return "最近情绪好像稍微往上一点。"
        }
    }

    static func insightMoodSlightlyDown(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been trending down a little lately."
        case .chinese: return "最近情绪好像稍微低一点。"
        }
    }

    static func insightCheckInMoreOften(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You've been checking in more often recently."
        case .chinese: return "你最近更常来记录了。"
        }
    }

    static func insightCheckInLessOften(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You've been checking in less often recently."
        case .chinese: return "你最近记录得少一些。"
        }
    }

    static func insightCheckInRhythmConsistent(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Your check-in rhythm has been consistent."
        case .chinese: return "你记录的节奏一直都挺稳的。"
        }
    }

    static func insightMoodSwingsSmoothingOut(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been feeling a bit more even lately."
        case .chinese: return "情绪的起伏最近缓和了一些。"
        }
    }

    static func insightMoodSwingsMoreVariable(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been a little more up and down lately."
        case .chinese: return "情绪的起伏最近稍微大一点。"
        }
    }

    static func insightMoodVariabilityConsistent(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Mood has been moving in a similar range."
        case .chinese: return "情绪的起伏和之前差不多。"
        }
    }

    // Today SuggestionCard (branches in ExperimentDetailView.todaySuggestion)
    static func todaySuggestionStartWithFelt(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Start here with how today felt."
        case .chinese: return "从这里开始，感受一下今天。"
        }
    }

    static func todaySuggestionFirstNoteSimple(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A short line is enough to start."
        case .chinese: return "一两句话就能开始。"
        }
    }

    static func todaySuggestionQuickCheckIn(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Start with a quick check-in"
        case .chinese: return "先简单记一下今天"
        }
    }

    static func todaySuggestionMoodCheckSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A simple mood check can be enough to mark how today feels."
        case .chinese: return "选一下情绪，就可以标记今天的大致感觉。"
        }
    }

    static func todaySuggestionAddOneNote(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Add one small note"
        case .chinese: return "加一句小记录"
        }
    }

    static func todaySuggestionNoteSentence(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A sentence is enough to remember what stood out today."
        case .chinese: return "一句话足够帮你记住今天特别的地方。"
        }
    }

    static func todaySuggestionPhotoOptional(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A photo is optional"
        case .chinese: return "想加张照片也可以"
        }
    }

    static func todaySuggestionPhotoClarify(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "If a photo helps capture today, feel free to add one."
        case .chinese: return "如果一张照片更能留下今天的感觉，可以加上。"
        }
    }

    static func todaySuggestionAlreadyStart(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You already have a start"
        case .chinese: return "你已经开始了"
        }
    }

    static func todaySuggestionSaveAgain(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Save again anytime if you want to adjust today’s entry."
        case .chinese: return "想调整的话，随时再保存一次就好。"
        }
    }

    static func todaySuggestionKeepSimple(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Keep today simple"
        case .chinese: return "今天可以简单点"
        }
    }

    static func todaySuggestionQuickEnough(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A quick check-in is enough to keep this experiment going."
        case .chinese: return "简单记一下，就够让这个实验继续下去了。"
        }
    }

    // MARK: - Storage (Summary)

    static func storageBoxEmpty(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Empty"
        case .chinese: return "空"
        }
    }

    static func storageBoxEmptyStateTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Empty Category"
        case .chinese: return "这个分类还是空的"
        }
    }

    static func storageBoxNoExperiments(_ lang: AppLanguage, categoryName: String) -> String {
        switch lang {
        case .english: return "Nothing in \"\(categoryName)\" yet."
        case .chinese: return "「\(categoryName)」里还没有实验。"
        }
    }

    /// Localized display title for a seed catalog category row (matches `experiment_seed.json` category `id`).
    static func summarySeedCategoryTitle(_ lang: AppLanguage, categoryId: String) -> String {
        switch (lang, categoryId) {
        case (.english, "life_reset"):
            return "Life Reset"
        case (.chinese, "life_reset"):
            return "生活重启"
        case (.english, "life_list"):
            return "Life List"
        case (.chinese, "life_list"):
            return "人生清单"
        case (.english, "challenge_30"):
            return "30-Day Challenge"
        case (.chinese, "challenge_30"):
            return "30 天挑战"
        case (.english, "well_being"):
            return "Well-being Habits"
        case (.chinese, "well_being"):
            return "身心状态"
        case (.english, "emotional_care"):
            return "Emotional Care"
        case (.chinese, "emotional_care"):
            return "情绪照护"
        default:
            return categoryId
        }
    }

    /// Localized display label for a seed catalog subcategory (matches `experiment_seed.json` subcategory `id`).
    static func seedSubcategoryLabel(_ lang: AppLanguage, subcategoryId: String) -> String {
        switch (lang, subcategoryId) {
        case (.english, "self_reflection"):
            return "Self Reflection"
        case (.chinese, "self_reflection"):
            return "自我反思"
        case (.english, "career_reorientation"):
            return "Career Reorientation"
        case (.chinese, "career_reorientation"):
            return "职业重定向"
        case (.english, "daily_structure"):
            return "Daily Structure"
        case (.chinese, "daily_structure"):
            return "日常结构"
        case (.english, "new_experiences"):
            return "New Experiences"
        case (.chinese, "new_experiences"):
            return "新体验"
        case (.english, "creative_expression"):
            return "Creative Expression"
        case (.chinese, "creative_expression"):
            return "创意表达"
        case (.english, "personal_milestones"):
            return "Personal Milestones"
        case (.chinese, "personal_milestones"):
            return "个人里程碑"
        case (.english, "daily_discipline"):
            return "Daily Discipline"
        case (.chinese, "daily_discipline"):
            return "每日自律"
        case (.english, "skill_sprint"):
            return "Skill Sprint"
        case (.chinese, "skill_sprint"):
            return "技能专项"
        case (.english, "habit_reset"):
            return "Habit Reset"
        case (.chinese, "habit_reset"):
            return "习惯调整"
        case (.english, "movement"):
            return "Movement"
        case (.chinese, "movement"):
            return "运动"
        case (.english, "sleep_rest"):
            return "Sleep & Rest"
        case (.chinese, "sleep_rest"):
            return "睡眠与休息"
        case (.english, "nutrition_awareness"):
            return "Nutrition Awareness"
        case (.chinese, "nutrition_awareness"):
            return "营养觉察"
        case (.english, "emotional_awareness"):
            return "Emotional Awareness"
        case (.chinese, "emotional_awareness"):
            return "情绪觉察"
        case (.english, "self_compassion"):
            return "Self Compassion"
        case (.chinese, "self_compassion"):
            return "自我关怀"
        case (.english, "mental_reset"):
            return "Mental Reset"
        case (.chinese, "mental_reset"):
            return "心理调整"
        default:
            return subcategoryId
        }
    }

    // MARK: - Common actions (extra)

    static func actionOK(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "OK"
        case .chinese: return "好"
        }
    }

    static func actionDone(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Done"
        case .chinese: return "完成"
        }
    }

    static func actionClose(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Close"
        case .chinese: return "关闭"
        }
    }

    static func actionRename(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Rename"
        case .chinese: return "重命名"
        }
    }

    static func actionDuplicate(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Duplicate"
        case .chinese: return "复制"
        }
    }

    static func actionSkip(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Skip"
        case .chinese: return "跳过"
        }
    }

    // MARK: - Low Energy / Take It Easy flow

    static func lowEnergyEnergyCheckTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "How are you feeling right now?"
        case .chinese: return "你现在感觉怎么样？"
        }
    }

    static func lowEnergyEnergyCheckSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "No right answer here."
        case .chinese: return "这里没有标准答案"
        }
    }

    static func lowEnergyNormalExitTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Sounds like you're doing okay today"
        case .chinese: return "听起来你今天还不错"
        }
    }

    static func lowEnergyNormalExitSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "That's a good thing."
        case .chinese: return "这是件好事"
        }
    }

    static func lowEnergyContinueWithExperiment(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Continue with an experiment"
        case .chinese: return "继续做实验"
        }
    }

    static func lowEnergyActionTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Pick one small thing"
        case .chinese: return "挑一件小事"
        }
    }

    static func lowEnergyActionSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Just enough to say you did something."
        case .chinese: return "说说自己做了点什么就好"
        }
    }

    static func lowEnergyRecoveryTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "How will you recharge?"
        case .chinese: return "你打算怎么充电？"
        }
    }

    static func lowEnergyRecoverySubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Optional. Skip if nothing fits."
        case .chinese: return "可选，没合适的就跳过吧"
        }
    }

    static func lowEnergyNoteTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "Anything on your mind?"
        case .chinese: return "有什么想法吗？"
        }
    }

    static func lowEnergyNoteSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "A word, a thought. Or nothing at all."
        case .chinese: return "一个词、一个念头，或者什么都不写也行"
        }
    }

    static func lowEnergyDoneTitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "That's enough for today"
        case .chinese: return "今天就到这里"
        }
    }

    static func lowEnergyDoneSubtitle(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return "You showed up. That counts."
        case .chinese: return "你来过了，这就算数"
        }
    }
}