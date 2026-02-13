//
//  SubscriptionService.swift
//  Aplyzia Planner
//
//  Manages StoreKit subscriptions and tier enforcement
//  7-day free trial (auto-start, no credit card required)
//  Free → Pro ($34.99/year) → Pro+ ($54.99/year)
//

import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var currentTier: SubscriptionTier = .free
    @Published var isTrialActive: Bool = false
    @Published var trialDaysRemaining: Int = 7
    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []

    // Trial tracking
    private let trialStartKey = "trial_start_date"
    private let trialUsedKey = "trial_used"

    // Daily usage tracking (for Smart Typist limits)
    @Published var dailySmartTypistConversions: Int = 0
    private let lastResetDateKey = "daily_reset_date"
    private let conversionsCountKey = "daily_conversions_count"

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
            checkAndStartTrialIfNeeded()
            resetDailyLimitsIfNeeded()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let productIDs: [String] = [
                "com.aplyzia.planner.pro.annual",
                "com.aplyzia.planner.pro.monthly",
                "com.aplyzia.planner.proplus.annual",
                "com.aplyzia.planner.proplus.monthly"
            ]

            products = try await Product.products(for: productIDs)
            print("✓ Loaded \(products.count) products")
        } catch {
            print("✗ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Update subscription status
            await updateSubscriptionStatus()

            // Finish the transaction
            await transaction.finish()

            print("✓ Purchase successful: \(product.id)")

        case .userCancelled, .pending:
            break

        @unknown default:
            break
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✓ Purchases restored")
        } catch {
            print("✗ Restore failed: \(error)")
        }
    }

    // MARK: - Update Subscription Status

    func updateSubscriptionStatus() async {
        var highestTier: SubscriptionTier = .free

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Determine tier from product ID
                if transaction.productID.contains("proplus") {
                    highestTier = .proPlus
                } else if transaction.productID.contains("pro") {
                    if highestTier != .proPlus {
                        highestTier = .pro
                    }
                }

            } catch {
                print("✗ Transaction verification failed: \(error)")
            }
        }

        // Check if trial is active
        if isTrialStillValid() {
            currentTier = .pro // Trial gives Pro access
            isTrialActive = true
            trialDaysRemaining = calculateTrialDaysRemaining()
        } else {
            currentTier = highestTier
            isTrialActive = false
        }

        print("✓ Current tier: \(currentTier.displayName)")
    }

    // MARK: - Trial Management

    func checkAndStartTrialIfNeeded() {
        let hasUsedTrial = UserDefaults.standard.bool(forKey: trialUsedKey)

        if !hasUsedTrial {
            // Start trial automatically on first launch
            startTrial()
        }
    }

    private func startTrial() {
        UserDefaults.standard.set(Date(), forKey: trialStartKey)
        UserDefaults.standard.set(true, forKey: trialUsedKey)
        isTrialActive = true
        trialDaysRemaining = 7
        currentTier = .pro
        print("✓ Started 7-day free trial (no credit card required)")
    }

    private func isTrialStillValid() -> Bool {
        guard let startDate = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            return false
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return daysSinceStart < 7
    }

    private func calculateTrialDaysRemaining() -> Int {
        guard let startDate = UserDefaults.standard.object(forKey: trialStartKey) as? Date else {
            return 0
        }

        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return max(0, 7 - daysSinceStart)
    }

    // MARK: - Daily Limits (Smart Typist)

    private func resetDailyLimitsIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastReset = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastReset)

            if lastResetDay < today {
                // New day - reset counters
                resetDailyCounters()
            } else {
                // Same day - load existing count
                dailySmartTypistConversions = UserDefaults.standard.integer(forKey: conversionsCountKey)
            }
        } else {
            // First time - initialize
            resetDailyCounters()
        }
    }

    private func resetDailyCounters() {
        dailySmartTypistConversions = 0
        UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
        UserDefaults.standard.set(0, forKey: conversionsCountKey)
    }

    func incrementSmartTypistConversions() {
        dailySmartTypistConversions += 1
        UserDefaults.standard.set(dailySmartTypistConversions, forKey: conversionsCountKey)
    }

    func canUseSmartTypist() -> Bool {
        guard let limit = currentTier.dailySmartTypistConversions else {
            return true // Unlimited for Pro/Pro+
        }

        return dailySmartTypistConversions < limit
    }

    // MARK: - Feature Access Checks

    func hasAccess(to feature: Feature) -> Bool {
        switch feature {
        case .dateIntelligence:
            return currentTier.hasDateIntelligence
        case .smartReminders:
            return currentTier.hasSmartReminders
        case .crossViewSync:
            return currentTier.hasCrossViewSync
        case .weeklyReview:
            return currentTier.hasWeeklyReview
        case .goalFramework:
            return currentTier.hasGoalFramework
        case .streakTracker:
            return currentTier.hasStreakTracker
        case .analytics:
            return currentTier.hasAnalyticsDashboard
        case .customTemplates:
            return currentTier.hasCustomTemplates
        case .widgets:
            return currentTier.hasWidgets
        }
    }

    func canCreateGoal() -> Bool {
        // Check if user has reached goal limit
        // This would integrate with SwiftData to count active goals
        return currentTier.hasGoalFramework
    }

    func canCreateHabit() -> Bool {
        return currentTier.hasStreakTracker
    }

    // MARK: - Conversion Messages

    func conversionMessage(for feature: Feature) -> String {
        switch feature {
        case .dateIntelligence:
            return SubscriptionTier.conversionTriggerForDateIntelligence()
        case .crossViewSync:
            return SubscriptionTier.conversionTriggerForStarSystem()
        case .goalFramework:
            return SubscriptionTier.conversionTriggerForGoals()
        case .streakTracker:
            return SubscriptionTier.conversionTriggerForStreaks()
        default:
            return currentTier.upgradeMessage(for: feature.displayName)
        }
    }

    // MARK: - Helpers

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum Feature {
    case dateIntelligence
    case smartReminders
    case crossViewSync
    case weeklyReview
    case goalFramework
    case streakTracker
    case analytics
    case customTemplates
    case widgets

    var displayName: String {
        switch self {
        case .dateIntelligence: return "Date Intelligence"
        case .smartReminders: return "Smart Reminders"
        case .crossViewSync: return "Cross-View Sync"
        case .weeklyReview: return "Weekly Review"
        case .goalFramework: return "SMARTER Goal Framework"
        case .streakTracker: return "StreakTracker"
        case .analytics: return "Analytics Dashboard"
        case .customTemplates: return "Custom Templates"
        case .widgets: return "Home Screen Widgets"
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
