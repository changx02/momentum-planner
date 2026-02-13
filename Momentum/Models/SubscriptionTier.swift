//
//  SubscriptionTier.swift
//  Aplyzia Planner
//
//  Monetization model: Free → Pro ($34.99/year) → Pro+ ($54.99/year)
//  Based on competitive strategy vs. GoodNotes, Notability, Full Focus Planner
//

import Foundation
import StoreKit

enum SubscriptionTier: String, Codable {
    case free = "planner_lite"
    case pro = "full_focus"
    case proPlus = "planner_pro_plus"

    var displayName: String {
        switch self {
        case .free: return "Planner Lite"
        case .pro: return "Pro"
        case .proPlus: return "Pro+"
        }
    }

    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$34.99/year"
        case .proPlus: return "$54.99/year"
        }
    }

    var monthlyPrice: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$3.99/month"
        case .proPlus: return "$6.99/month"
        }
    }

    // MARK: - Feature Limits

    var maxDailyActionItems: Int? {
        switch self {
        case .free: return 10
        case .pro, .proPlus: return nil // unlimited
        }
    }

    var maxActiveGoals: Int? {
        switch self {
        case .free: return 0 // No goals in free
        case .pro: return 5
        case .proPlus: return nil // unlimited
        }
    }

    var maxHabits: Int? {
        switch self {
        case .free: return 0
        case .pro: return 5
        case .proPlus: return nil
        }
    }

    var maxNotebooks: Int {
        switch self {
        case .free: return 1
        case .pro: return 5
        case .proPlus: return 999 // unlimited
        }
    }

    var maxNotebookPages: Int? {
        switch self {
        case .free: return 20
        case .pro, .proPlus: return nil // unlimited
        }
    }

    var dailySmartTypistConversions: Int? {
        switch self {
        case .free: return 5
        case .pro, .proPlus: return nil // unlimited
        }
    }

    var maxPlanners: Int {
        switch self {
        case .free, .pro: return 1
        case .proPlus: return 3 // work + personal + project
        }
    }

    // MARK: - Feature Access

    var hasDateIntelligence: Bool {
        return self != .free
    }

    var hasSmartReminders: Bool {
        return self != .free
    }

    var hasCrossViewSync: Bool {
        return self != .free
    }

    var hasWeeklyReview: Bool {
        return self != .free
    }

    var hasGoalFramework: Bool {
        return self != .free
    }

    var hasStreakTracker: Bool {
        return self != .free
    }

    var hasRitualCheckboxes: Bool {
        return self != .free
    }

    var hasTaskStatusSystem: Bool {
        return self != .free
    }

    var hasAnalyticsDashboard: Bool {
        return self == .proPlus
    }

    var hasQuarterlyReview: Bool {
        return self == .proPlus
    }

    var hasCustomTemplates: Bool {
        return self == .proPlus
    }

    var hasTemplateMarketplaceAccess: Bool {
        switch self {
        case .free: return false // browse only
        case .pro: return true // free templates
        case .proPlus: return true // all templates + 3 credits/month
        }
    }

    var monthlyTemplateCredits: Int {
        switch self {
        case .free, .pro: return 0
        case .proPlus: return 3 // $9 value
        }
    }

    var canExportPDF: Bool {
        return self != .free
    }

    var canExportImages: Bool {
        return self == .proPlus
    }

    var hasWidgets: Bool {
        return self != .free
    }

    var themesCount: Int {
        switch self {
        case .free: return 1 // default only
        case .pro: return 5
        case .proPlus: return 999 // all themes
        }
    }

    var hasPrioritySupport: Bool {
        return self == .proPlus
    }
}

// MARK: - Product IDs for StoreKit

extension SubscriptionTier {
    var annualProductID: String? {
        switch self {
        case .free: return nil
        case .pro: return "com.aplyzia.planner.pro.annual"
        case .proPlus: return "com.aplyzia.planner.proplus.annual"
        }
    }

    var monthlyProductID: String? {
        switch self {
        case .free: return nil
        case .pro: return "com.aplyzia.planner.pro.monthly"
        case .proPlus: return "com.aplyzia.planner.proplus.monthly"
        }
    }
}

// MARK: - Conversion Messaging

extension SubscriptionTier {
    func upgradeMessage(for feature: String) -> String {
        switch self {
        case .free:
            return "Upgrade to Pro to unlock \(feature) and the full planning system"
        case .pro:
            return "Upgrade to Pro+ for \(feature) plus unlimited goals, habits, and analytics"
        case .proPlus:
            return ""
        }
    }

    static func conversionTriggerForDateIntelligence() -> String {
        return "Date Intelligence detected 'March 15' — upgrade to Pro to auto-route this to March 15"
    }

    static func conversionTriggerForStarSystem() -> String {
        return "⭐ Upgrade to Pro to see starred items flow to your weekly view automatically"
    }

    static func conversionTriggerForSmartTypist() -> String {
        return "You've used today's Smart Typist credits. Upgrade to Pro for unlimited conversions"
    }

    static func conversionTriggerForGoals() -> String {
        return "Track this with the SMARTER Goal framework — available with Pro"
    }

    static func conversionTriggerForStreaks() -> String {
        return "You've planned 7 days in a row! Unlock StreakTracker with Pro to visualize your consistency"
    }
}
