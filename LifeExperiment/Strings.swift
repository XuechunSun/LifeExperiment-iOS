//
//  Strings.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import Foundation

// MARK: - Language Support

enum AppLanguage {
    case en
    case zh
}

// MARK: - Centralized Strings (v1: English only, prepared for future bilingual)

enum S {
    static var lang: AppLanguage = .en  // v1 fixed to English
    
    // MARK: - Tab Bar
    
    static var tabHome: String {
        lang == .en ? "Home" : "主页"
    }
    
    static var tabActive: String {
        lang == .en ? "Active" : "进行中"
    }
    
    static var tabCreate: String {
        lang == .en ? "Create" : "创建"
    }
    
    static var tabSummary: String {
        lang == .en ? "Summary" : "总览"
    }
    
    static var tabProfile: String {
        lang == .en ? "Profile" : "个人"
    }
    
    // MARK: - Common Actions
    
    static var actionMore: String {
        lang == .en ? "More" : "更多"
    }
    
    static var actionSave: String {
        lang == .en ? "Save" : "保存"
    }
    
    static var actionCancel: String {
        lang == .en ? "Cancel" : "取消"
    }
    
    static var actionDelete: String {
        lang == .en ? "Delete" : "删除"
    }
    
    static var actionCreate: String {
        lang == .en ? "Create" : "创建"
    }
    
    static var actionComplete: String {
        lang == .en ? "Complete" : "完成"
    }
    
    static var actionReopen: String {
        lang == .en ? "Reopen" : "重新开始"
    }
    
    // MARK: - Section Headers
    
    static var sectionRecentEvents: String {
        lang == .en ? "Recent Events" : "最近事件"
    }
    
    static var sectionContinueRecording: String {
        lang == .en ? "Continue Recording" : "继续记录"
    }
    
    static var sectionStartNewExperiment: String {
        lang == .en ? "Start New Experiment" : "开始新实验"
    }
    
    static var sectionCompleted: String {
        lang == .en ? "Completed" : "已完成"
    }
    
    static var sectionActiveExperiments: String {
        lang == .en ? "Active Experiments" : "进行中的实验"
    }
    
    static var sectionUpdatedToday: String {
        lang == .en ? "Updated Today" : "今日更新"
    }
    
    static var sectionNotUpdatedToday: String {
        lang == .en ? "Not Updated Today" : "未在今日更新"
    }
    
    static var sectionThisWeek: String {
        lang == .en ? "This week" : "本周"
    }
    
    static var sectionEarlier: String {
        lang == .en ? "Earlier" : "更早"
    }
    
    // MARK: - Empty States
    
    static var emptyNoActiveExperiments: String {
        lang == .en ? "No Active Experiments" : "没有进行中的实验"
    }
    
    static var emptyNoActiveSubtitle: String {
        lang == .en ? "Start your first experiment to begin tracking" : "开始你的第一个实验"
    }
    
    static var emptyNoCompletedExperiments: String {
        lang == .en ? "No completed experiments yet" : "还没有完成的实验"
    }
    
    static var emptyNoCompletedSubtitle: String {
        lang == .en ? "When you finish an experiment, it will show up here as a small milestone." : "完成的实验会显示在这里"
    }
    
    static var emptyNoUpdatesToday: String {
        lang == .en ? "No updates yet today" : "今天还没有更新"
    }
    
    static var emptyAllUpdated: String {
        lang == .en ? "All active experiments have been updated" : "所有实验都已更新"
    }
    
    // MARK: - Experiment Detail
    
    static var experimentCompleteButton: String {
        lang == .en ? "Complete Experiment" : "完成实验"
    }
    
    static var experimentCompleteConfirm: String {
        lang == .en ? "Complete this experiment?" : "完成这个实验？"
    }
    
    static var experimentCompleteMessage: String {
        lang == .en ? "You won't be able to add new logs after completion." : "完成后将无法添加新记录。"
    }
    
    static var experimentReopenConfirm: String {
        lang == .en ? "Reopen this experiment?" : "重新开始这个实验？"
    }
    
    static var experimentDeleteConfirm: String {
        lang == .en ? "Delete Experiment?" : "删除实验？"
    }
    
    static var experimentDeleteMessage: String {
        lang == .en ? "All logs and data will be deleted. This cannot be undone." : "所有记录和数据将被删除，无法撤销。"
    }
    
    // MARK: - Mood Labels
    
    static func moodLabel(_ mood: Mood) -> String {
        switch mood {
        case .veryBad:
            return lang == .en ? "Very Bad" : "很差"
        case .bad:
            return lang == .en ? "Bad" : "不太好"
        case .neutral:
            return lang == .en ? "Neutral" : "一般"
        case .good:
            return lang == .en ? "Good" : "不错"
        case .veryGood:
            return lang == .en ? "Very Good" : "很好"
        }
    }
    
    // MARK: - Editor
    
    static var editorTitleNew: String {
        lang == .en ? "New Experiment" : "新实验"
    }
    
    static var editorTitleEdit: String {
        lang == .en ? "Edit Experiment" : "编辑实验"
    }
    
    static var editorTitleDuplicate: String {
        lang == .en ? "Duplicate Experiment" : "复制实验"
    }
}

// MARK: - Mood enum reference (for type safety)
// This assumes Mood is defined in ContentView.swift
// We can't import it here, so we'll use this for the function signature
