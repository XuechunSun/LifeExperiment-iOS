import Foundation

/// Display-time mapping from built-in English experiment titles to Simplified Chinese.
/// Persisted experiment data keeps the English source-of-truth string; this helper only
/// localizes at render time when `lang == .chinese` AND the stored title exactly matches
/// a known built-in title. Custom user-typed titles fall through unchanged.
///
/// Scope: experiment titles only. For categories/subcategories/dimensions use
/// `SeedTaxonomyDisplay`, `L.summarySeedCategoryTitle`, `L.seedSubcategoryLabel`,
/// or `L.dimensionDisplayTitle`.
enum BuiltInTitleDisplay {
    /// Returns the Chinese translation when `stored` exactly matches a known built-in
    /// title. Returns `stored` unchanged for English UI or for unknown (custom) titles.
    static func localizedTitle(stored: String, lang: AppLanguage) -> String {
        guard lang == .chinese else { return stored }
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        return englishToChinese[trimmed] ?? stored
    }

    /// English → Simplified Chinese map for built-in suggestion / starter titles.
    /// Keep keys in lockstep with `ExperimentSuggestions.json` and
    /// `PersonalizedSuggestionEngine.swift`.
    fileprivate static let englishToChinese: [String: String] = [
        // Onboarding starters (v1.1 first-run flow) — keep keys in lockstep
        // with `StarterExperiment.englishTitle`.
        "Take a 5-minute pause": "停5分钟，留意身体和能量",
        "Name what I'm feeling today": "说出今天的感受",
        "Clear one small task": "清掉一件小事",

        // ExperimentSuggestions.json — Body & Energy
        "Take a 10-minute walk without your phone": "放下手机，散步10分钟",
        "Drink a glass of water slowly and notice how you feel": "慢慢喝一杯水，留意身体的感受",
        "Try going to bed 30 minutes earlier tonight": "今晚试着早睡30分钟",
        "Stretch for 5 minutes and see if your energy shifts": "伸展5分钟，看看能量有没有变化",
        "Notice when your energy feels highest today": "留意今天能量最饱满的时刻",
        "Eat one meal a little more slowly than usual": "吃一顿饭，比平时慢一点",
        "Step outside for a few minutes in the morning": "早晨到外面待几分钟",
        "Take a short break without reaching for your phone": "短暂休息一下，先别碰手机",
        "Pause once today and notice how your body feels": "今天暂停一次，感受一下身体",
        "Move your body for 5 minutes just to reset": "活动身体5分钟，让自己重启一下",

        // ExperimentSuggestions.json — Self Understanding
        "Write down one thing you've been avoiding": "写下一件你一直在回避的事",
        "Ask yourself: what do I need a little more of today?": "问问自己：今天希望多一点什么？",
        "Change one thing you usually do on autopilot": "换一种方式做一件你一直自动完成的事",
        "Say no to one thing that drains you": "对一件让你消耗的事说不",
        "Go to one place you don't usually go": "去一个你平时不常去的地方",
        "Write one honest sentence about how things really feel": "写下一句真实的话，关于此刻的感受",
        "Notice one thing that drains your energy today": "留意今天有哪件事在消耗你的能量",
        "Notice one thing that makes today feel lighter": "留意一件让今天变得轻一点的小事",
        "Try one small choice that feels slightly unlike your usual self": "做一个有点不像你平时风格的小选择",
        "Notice where you feel resistance without trying to fix it": "留意哪里有抗拒，先不急着改变它",

        // ExperimentSuggestions.json — Connection
        "Text someone you've been thinking about": "给一个你最近常想起的人发条消息",
        "Send one small message of appreciation": "发一条小小的感谢信息",
        "Ask someone one real question instead of making small talk": "问对方一个真实的问题，不只是寒暄",
        "Invite someone to a simple coffee or lunch": "约一个人简单地喝杯咖啡或吃顿饭",
        "Reply to one message with a little more presence than usual": "回复一条消息，比平时多一点用心",
        "Check in with a family member, even briefly": "和家人简单地问候一下，哪怕几句话",
        "Share a small update about your day with someone you trust": "和你信任的人分享今天的一件小事",
        "Thank someone directly for something specific": "为一件具体的事，当面谢谢一个人",
        "Spend a few unhurried minutes with someone": "和某个人不慌不忙地待上几分钟",
        "Be the one who reaches out first today": "今天，做先开口的那一个",

        // ExperimentSuggestions.json — Expression & Creativity
        "Write for 3 minutes without trying to sound clear": "随意写3分钟，不用追求条理",
        "Take one photo of something that feels alive today": "拍一张照片，记录今天有生命力的瞬间",
        "Make a 3-song playlist for your current mood": "为现在的心情做一份3首歌的播放清单",
        "Draw something quickly without trying to make it good": "随手画点东西，不用画得多好",
        "Describe today in three words": "用三个词形容今天",
        "Record a short voice note about how today feels": "录一段简短的语音，关于今天的感受",
        "Save one image that matches your mood today": "保存一张能代表今天心情的图片",
        "Write a bad poem on purpose": "故意写一首糟糕的小诗",
        "Pick one color that feels like today": "选一种能代表今天的颜色",
        "Make something tiny just for yourself": "做一件小小的、只为自己的事",

        // PersonalizedSuggestionEngine.swift hardcoded titles
        "Reach out to someone you trust today": "今天联系一位你信任的人",
        "Write down one honest thought today": "写下今天一个真实的想法",
        "Pause and notice how you feel right now": "停下来，感受一下此刻",
        "Write for 3 minutes without editing": "写3分钟，不要修改",
        // (note: "Take a 10-minute walk without your phone" is shared with the JSON entry above)
        "Start one small task you've been postponing": "开始一件你一直推迟的小事",
        "Give one task 10 quiet minutes today": "给一件事10分钟安静的专注",

        // Seed starter title (English form, in case migration left an English copy on disk)
        "Your first check-in": "你的第一次记录",
        "My First Experiment": "你的第一次记录",

        // Create-flow title inspiration prompts (experiment_seed.json `prompts`).
        // Keys are the *English-normalized* form produced by `normalizedTitle(from:)`
        // (no trailing punctuation, conversational starters stripped, first letter
        // capitalized) — i.e. the title that gets persisted on tap. Values are the
        // Chinese display form shown both on the card and in the title field.

        // life_reset / self_reflection
        "3 things you no longer want to keep doing": "写下3件你不想再继续做的事",
        "Track moments that give you energy for 7 days": "连续7天记录让你有能量的时刻",
        "Answer: If money didn't matter, what would you try": "如果钱不是问题，你会想尝试什么",
        "One moment today that felt more like you": "今天有哪个瞬间更像你自己",
        "One sentence about what feels unclear right now": "用一句话写下此刻让你困惑的事",
        "List three things you want less of this month": "列出这个月你想少做的三件事",
        "Name one part of your life that feels ready for a reset": "找出生活中一个想要重启的部分",
        "Describe the kind of day that helps you feel more steady": "描述什么样的一天会让你更安定",
        "About one choice that has been quietly pulling at you": "写下一个一直在牵动你的选择",
        "Note one habit that no longer feels like a fit": "记下一个不再适合你的习惯",

        // life_reset / career_reorientation
        "List 3 projects that made you feel proud": "列出3个让你引以为傲的项目",
        "Talk to 3 people with different career paths": "和3位职业路径不同的人聊聊",
        "Draft an 'ideal resume' (not for applying)": "写一份「理想简历」（不用于求职）",
        "The kind of work that leaves you energized": "写下哪种工作让你充满能量",
        "Note one part of your current work life that feels misaligned": "记下当前工作中让你感到错位的部分",
        "Describe a small role or project you'd be curious to try": "描述一个你想尝试的小角色或项目",
        "Make a list of skills you want to use more often": "列出你希望更常使用的技能",
        "About one workday that felt meaningful": "写下一个让你觉得有意义的工作日",
        "What you want your next chapter to feel like": "想想你希望下一段人生有怎样的感觉",
        "Note one career experiment you could try this month": "记下这个月可以试试的一个职业小实验",

        // life_reset / daily_structure
        "Design your ideal low-stress day schedule": "设计一份理想的低压力日程",
        "A consistent wake-up time for 7 days": "连续7天保持固定的起床时间",
        "Track how your time is spent for 3 days": "记录3天的时间是怎么花掉的",
        "Which part of the day feels easiest to work with": "留意一天中哪个时段最容易进入状态",
        "Plan one calmer morning routine for tomorrow": "为明天安排一个更平静的早晨流程",
        "Choose one anchor habit to return to each day": "选一个每天都回到的锚点习惯",
        "What usually throws your day off course": "写下通常是什么让你的一天偏离轨道",
        "Ending the day with a simple reset ritual": "用一个简单的仪式来结束一天",
        "Block out one hour for what matters most today": "给今天最重要的事留出一小时",
        "Sketch a version of your day with a little more space": "勾画一份留白更多的一日版本",

        // life_list / new_experiences
        "One activity you've never done before": "尝试一件你从没做过的事",
        "Visit a new place alone": "独自去一个新地方",
        "Plan one 'no-plan day'": "安排一个「没有计划」的日子",
        "Say yes to one small experience that feels new": "答应一个让你觉得新鲜的小体验",
        "What kind of novelty actually feels energizing": "留意什么样的新鲜感真的让你兴奋",
        "A route, cafe, or park you haven't chosen before": "走一条没走过的路或去一家新店",
        "Make a short list of things you're curious about lately": "列一份你最近感兴趣的事的小清单",
        "Pick one experience that feels slightly outside your routine": "选一个略微跳出日常的体验",
        "Spend an hour doing something with no obvious outcome": "花一小时做一件没有明确目的的事",
        "One place or activity you want to remember to try": "记下一个想以后尝试的地方或活动",

        // life_list / creative_expression
        "One idea every day for 7 days": "连续7天每天写下一个想法",
        "Create something small without perfection": "做一件不追求完美的小作品",
        "Express your current mood in any form": "用任何方式表达此刻的心情",
        "Capture today in a photo, sketch, or note": "用照片、手绘或文字记录今天",
        "Make something in ten minutes with no plan": "在十分钟内随手做点什么",
        "Three lines about what feels alive right now": "用三句话写下此刻让你有生命力的事",
        "Creating with a material or format you don't usually use": "尝试用不熟悉的材料或形式创作",
        "Save one image, color, or phrase that matches today": "保存一张能代表今天的图片、颜色或句子",
        "Make a tiny piece just for yourself": "做一件只给自己的小作品",
        "What kind of expression feels easiest today": "留意今天哪种表达方式最自然",

        // life_list / personal_milestones
        "Do one important thing you've been avoiding": "去做一件你一直在回避的重要事",
        "A letter to your future self": "给未来的自己写一封信",
        "Organize photos or notes from a life chapter": "整理某个人生阶段的照片或笔记",
        "Name one milestone that matters to you, even if it's private": "写下一个对你重要、哪怕只属于自己的里程碑",
        "A step that would make this season feel complete": "想想一步什么样的行动会让这一阶段更完整",
        "Reflect on something you've grown through recently": "回想最近一件让你成长的事",
        "Mark one ending or beginning in a simple way": "用简单的方式纪念一个结束或开始",
        "List three moments from the past year you want to remember": "列出过去一年想留住的三个瞬间",
        "Choose one unfinished thing you'd like to close gently": "选一件想温柔结束的未完成事",
        "Describe what the next personal milestone could look like": "描述下一个属于你的里程碑会是什么样",

        // challenge_30 / daily_discipline
        "Do one focused 10-minute session every day": "每天做一次10分钟的专注练习",
        "One done-thing each day": "每天写下一件已经完成的事",
        "Walk 15 minutes without your phone": "不带手机走15分钟",
        "Pick one simple action you can repeat daily": "选一个可以每天重复的简单动作",
        "Decide what 'showing up' means for this month": "决定这个月「坚持出现」对你意味着什么",
        "Choose a time of day that makes consistency easier": "选一个更容易坚持的时段",
        "Keep one promise to yourself for 30 days": "对自己许下一个承诺，坚持30天",
        "Track whether a tiny daily action changes your mood": "记录一个小小的日常行动是否改变心情",
        "Set a version of the challenge that still counts on low-energy days": "为低能量日设一个仍然算数的挑战版本",
        "One line each day about how it felt to continue": "每天用一句话写下坚持的感受",

        // challenge_30 / skill_sprint
        "Learn one small concept every day for 30 days": "30天里每天学一个小概念",
        "Build a tiny project in 30 days": "用30天做一个小项目",
        "Publish something small daily (text/photo/code)": "每天发布一点小作品（文字/照片/代码）",
        "Pick one skill you want to get a little closer to": "选一个你想再靠近一点的技能",
        "Practice for ten minutes without worrying about progress": "练习十分钟，不在意进度",
        "Make a list of very small outputs you could create this month": "列出这个月可以做的一些极小产出",
        "Choose a learning format that feels easy to return to": "选一种容易重新打开的学习方式",
        "What makes practice feel lighter or heavier": "留意是什么让练习变轻或变重",
        "Define the smallest version of your skill challenge": "定义你这次技能挑战的最小版本",
        "End each session by naming one thing you noticed": "每次结束时写下一个你注意到的点",

        // challenge_30 / habit_reset
        "Sleep earlier for 30 days": "连续30天早睡",
        "Reduce late-night scrolling for 30 days": "连续30天减少深夜刷手机",
        "Remove one small bad habit for a month": "一个月内戒掉一个小坏习惯",
        "Pick one pattern you'd like to interrupt gently": "选一个你想温和打断的模式",
        "What usually leads into the habit you want to reset": "留意通常是什么把你带进想调整的习惯",
        "Replace one draining habit with a smaller steadier one": "用一个更稳的小习惯替代一个消耗的习惯",
        "One version of the reset that feels realistic this week": "这一周可以做到的、最现实的调整版本",
        "Name what would make the habit easier to leave behind": "写下什么会让这个习惯更容易放下",
        "Track one moment each day when you choose differently": "每天记录一个你做出不同选择的瞬间",
        "Why this reset matters to you right now": "写下为什么这次调整现在对你重要",

        // well_being / movement
        "Walk 20 minutes a day": "每天散步20分钟",
        "3 different workouts this week": "这周尝试3种不同的运动",
        "Note how your body feels after movement": "记下运动后身体的感受",
        "Choose one form of movement that sounds doable today": "选一种今天能轻松做到的运动",
        "Spend ten minutes moving without measuring it": "活动十分钟，不用记录",
        "A gentle stretch break and notice the shift": "做一次温和的拉伸，留意身体的变化",
        "Walk at a pace that matches how you actually feel": "用真实匹配你状态的节奏散步",
        "Move in a way that feels grounding instead of intense": "用让自己安定而不是激烈的方式活动",
        "What kind of movement leaves you clearer": "留意哪种运动让你更清醒",
        "Make a short list of movement you don't mind repeating": "列一份你不介意重复做的运动",

        // well_being / sleep_rest
        "No screens 60 minutes before bed": "睡前60分钟不看屏幕",
        "Create a 10-minute bedtime routine": "建立一个10分钟的睡前流程",
        "Track sleep quality for 7 days": "连续7天记录睡眠质量",
        "What helps your mind slow down at night": "留意是什么让你晚上的思绪慢下来",
        "Choose one small rest ritual for this evening": "为今晚选一个小小的休息仪式",
        "Making your room a little calmer before sleep": "在入睡前让房间更安静一点",
        "Let yourself rest before you feel completely depleted": "在彻底耗尽前先让自己休息",
        "What usually interrupts your rest": "写下通常是什么打断你的休息",
        "Pick one change that might help tonight feel softer": "挑一个可能让今晚更柔软的小调整",
        "How a little more rest changes the next day": "留意多一点休息如何改变第二天",

        // well_being / nutrition_awareness
        "Drink enough water daily": "每天喝够水",
        "Note how food affects your mood for 7 days": "连续7天记录食物对心情的影响",
        "Reduce one sugary snack for a week": "一周内减少一种含糖零食",
        "Eat one meal with a little more attention today": "今天吃一顿饭时多一点专注",
        "When you feel most nourished versus just full": "留意什么时候是真正被滋养，什么时候只是吃饱",
        "One food habit you want to understand better": "记下一个想更深入了解的饮食习惯",
        "Adding something supportive instead of cutting something out": "试着加入一种有益的食物，而不是去戒掉什么",
        "Pay attention to how your energy changes after lunch": "留意午饭后能量如何变化",
        "Choose one meal this week to slow down and notice": "挑这一周里的一顿饭，慢下来用心吃",
        "Reflect on what eating well means for your real life": "想想「吃得好」在你真实生活里意味着什么",

        // emotional_care / emotional_awareness
        "Describe your mood in one sentence daily": "每天用一句话描述心情",
        "What triggers mood changes for 7 days": "连续7天记录心情变化的触发点",
        "The best and hardest moment today": "找出今天最好的和最难的瞬间",
        "Name what you're feeling without trying to fix it": "说出当下的情绪，不急着去解决",
        "Where emotion shows up in your body": "留意情绪在身体哪里出现",
        "One feeling that has been easy to ignore": "写下一个一直被你忽略的感受",
        "Check in with yourself at one point during the day": "在一天中的某个时刻和自己确认一下",
        "What helps a feeling move instead of stay stuck": "留意是什么让情绪流动，而不是卡住",
        "Reflect on what your mood may be responding to lately": "想想最近的心情可能在回应什么",
        "End the day by naming one emotional pattern you noticed": "在一天结束时写下一个你注意到的情绪模式",

        // emotional_care / self_compassion
        "One thing you did well today": "写下今天你做得好的一件事",
        "Say one non-judgmental sentence to yourself": "对自己说一句不带评判的话",
        "Plan one real rest moment today": "今天安排一个真正的休息时刻",
        "How you speak to yourself when things go wrong": "留意事情不顺时你如何对自己说话",
        "The kindest interpretation of your day": "用最温柔的方式解读今天",
        "Let one imperfect thing stay unfinished without criticism": "允许一件不完美的事保持未完成，不去苛责",
        "Ask what support would feel gentle right now": "问问此刻什么样的支持会让你觉得温柔",
        "Offer yourself the same tone you'd give a friend": "用对朋友的语气对自己说话",
        "Name one pressure you can loosen today": "写下今天可以放松一点的一个压力",
        "One way you were trying, even quietly": "写下一种你即使悄悄也在努力的方式",

        // emotional_care / mental_reset
        "Do a 10-minute breathing practice": "做一次10分钟的呼吸练习",
        "What's making you anxious": "写下让你焦虑的事",
        "Allow one day with zero achievement goals": "给自己一天不带任何成就目标",
        "Step away from inputs for a short while": "暂时离开各种信息输入",
        "Choose one small thing that helps your mind settle": "挑一件能让心安下来的小事",
        "What happens when you stop pushing for a moment": "留意暂停推进时会发生什么",
        "Make space for ten quiet minutes with no task attached": "腾出十分钟的安静时间，不带任务",
        "Everything on your mind, then leave it there": "把心里的一切写下来，然后留在那里",
        "A reset that feels grounding rather than productive": "选一种让人安定、而不是高产的休整方式",
        "Ask what would make today feel mentally lighter": "问问今天怎样会让你心理上更轻"
    ]
}

#if DEBUG
extension BuiltInTitleDisplay {
    /// DEBUG-only coverage check. Logs (does not crash) any title in `titles` that
    /// is not present in the English→Chinese dictionary. Safe to call repeatedly.
    static func debugAssertCoverage(_ titles: [String], context: String) {
        let known = Set(englishToChinese.keys)
        let missing = titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !known.contains($0) }
        guard !missing.isEmpty else { return }
        print("⚠️ BuiltInTitleDisplay missing \(context) translations:")
        for title in missing {
            print("  - \(title)")
        }
    }
}
#endif
