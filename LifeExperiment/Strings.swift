//
//  Strings.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import Foundation

// MARK: - Centralized Strings (v1: English only, prepared for future bilingual)

enum S {
    static var lang: AppLanguage = .english // v1 fixed to English; use AppLanguage from L.swift
    
    // MARK: - Tab Bar
    
    static var tabHome: String {
        lang == .english ? "Home" : "主页"
    }
    
    static var tabActive: String {
        lang == .english ? "Active" : "进行中"
    }
    
    static var tabCreate: String {
        lang == .english ? "Create" : "创建"
    }
    
    static var tabSummary: String {
        lang == .english ? "Summary" : "总览"
    }
    
    static var tabProfile: String {
        lang == .english ? "Profile" : "个人"
    }
    
    // MARK: - Common Actions
    
    static var actionMore: String {
        lang == .english ? "More" : "更多"
    }
    
    static var actionSave: String {
        lang == .english ? "Save" : "保存"
    }
    
    static var actionCancel: String {
        lang == .english ? "Cancel" : "取消"
    }
    
    static var actionDelete: String {
        lang == .english ? "Delete" : "删除"
    }
    
    static var actionCreate: String {
        lang == .english ? "Create" : "创建"
    }
    
    static var actionComplete: String {
        lang == .english ? "Complete" : "完成"
    }
    
    static var actionReopen: String {
        lang == .english ? "Reopen" : "重新开始"
    }
    
    // MARK: - Section Headers
    
    static var sectionRecentEvents: String {
        lang == .english ? "Recent Events" : "最近事件"
    }
    
    static var sectionContinueRecording: String {
        lang == .english ? "Continue Recording" : "继续记录"
    }
    
    static var sectionStartNewExperiment: String {
        lang == .english ? "Start New Experiment" : "开始新实验"
    }
    
    static var sectionCompleted: String {
        lang == .english ? "Completed" : "已完成"
    }
    
    static var sectionActiveExperiments: String {
        lang == .english ? "Active Experiments" : "进行中的实验"
    }
    
    static var sectionUpdatedToday: String {
        lang == .english ? "Updated Today" : "今日更新"
    }
    
    static var sectionNotUpdatedToday: String {
        lang == .english ? "Not Updated Today" : "未在今日更新"
    }
    
    static var sectionThisWeek: String {
        lang == .english ? "This week" : "本周"
    }
    
    static var sectionEarlier: String {
        lang == .english ? "Earlier" : "更早"
    }
    
    // MARK: - Empty States
    
    static var emptyNoActiveExperiments: String {
        lang == .english ? "No Active Experiments" : "没有进行中的实验"
    }
    
    static var emptyNoActiveSubtitle: String {
        lang == .english ? "Start your first experiment to begin tracking" : "开始你的第一个实验"
    }
    
    static var emptyNoCompletedExperiments: String {
        lang == .english ? "No completed experiments yet" : "还没有完成的实验"
    }
    
    static var emptyNoCompletedSubtitle: String {
        lang == .english ? "When you finish an experiment, it will show up here as a small milestone." : "完成的实验会显示在这里"
    }
    
    static var emptyNoUpdatesToday: String {
        lang == .english ? "No updates yet today" : "今天还没有更新"
    }
    
    static var emptyAllUpdated: String {
        lang == .english ? "All active experiments have been updated" : "所有实验都已更新"
    }
    
    // MARK: - Experiment Detail
    
    static var experimentCompleteButton: String {
        lang == .english ? "Complete Experiment" : "完成实验"
    }
    
    static var experimentCompleteConfirm: String {
        lang == .english ? "Complete this experiment?" : "完成这个实验？"
    }
    
    static var experimentCompleteMessage: String {
        lang == .english ? "You won't be able to add new logs after completion." : "完成后将无法添加新记录。"
    }
    
    static var experimentReopenConfirm: String {
        lang == .english ? "Reopen this experiment?" : "重新开始这个实验？"
    }
    
    static var experimentDeleteConfirm: String {
        lang == .english ? "Delete Experiment?" : "删除实验？"
    }
    
    static var experimentDeleteMessage: String {
        lang == .english ? "All logs and data will be deleted. This cannot be undone." : "所有记录和数据将被删除，无法撤销。"
    }
    
    // MARK: - Mood Labels
    
    static func moodLabel(_ mood: Mood) -> String {
        switch mood {
        case .veryBad:
            return lang == .english ? "Very Bad" : "很差"
        case .bad:
            return lang == .english ? "Bad" : "不太好"
        case .neutral:
            return lang == .english ? "Neutral" : "一般"
        case .good:
            return lang == .english ? "Good" : "不错"
        case .veryGood:
            return lang == .english ? "Very Good" : "很好"
        }
    }
    
    // MARK: - Editor
    
    static var editorTitleNew: String {
        lang == .english ? "New Experiment" : "新实验"
    }
    
    static var editorTitleEdit: String {
        lang == .english ? "Edit Experiment" : "编辑实验"
    }
    
    static var editorTitleDuplicate: String {
        lang == .english ? "Duplicate Experiment" : "复制实验"
    }
}

// MARK: - Mood enum reference (for type safety)
// This assumes Mood is defined in ContentView.swift
// We can't import it here, so we'll use this for the function signature
