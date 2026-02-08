//
//  Haptics.swift
//  LifeExperiment
//
//  Created on 1/27/26.
//

import UIKit

/// Safe haptics wrapper that prevents simulator console spam
/// All haptic feedback is disabled on simulator to avoid "hapticpatternlibrary.plist couldn't be opened" errors
enum Haptics {
    
    /// Trigger an impact haptic feedback
    /// - Parameter style: The intensity of the impact (light, medium, heavy, soft, rigid)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        #if targetEnvironment(simulator)
        // No-op on simulator to avoid console spam
        #else
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    /// Trigger a notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        #if targetEnvironment(simulator)
        // No-op on simulator to avoid console spam
        #else
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
    
    /// Trigger a selection change haptic feedback
    static func selection() {
        #if targetEnvironment(simulator)
        // No-op on simulator to avoid console spam
        #else
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
    
    // MARK: - Convenience methods
    
    /// Trigger a light impact (most common use case)
    static func lightImpact() {
        impact(.light)
    }
    
    /// Trigger a medium impact
    static func mediumImpact() {
        impact(.medium)
    }
    
    /// Trigger a heavy impact
    static func heavyImpact() {
        impact(.heavy)
    }
    
    /// Trigger a success notification
    static func success() {
        notification(.success)
    }
    
    /// Trigger a warning notification
    static func warning() {
        notification(.warning)
    }
    
    /// Trigger an error notification
    static func error() {
        notification(.error)
    }
}
