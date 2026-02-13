//
//  RoutingService.swift
//  Aplyzia Planner
//
//  Manages content routing and propagation across views
//  Target: <1 second routing, 99.5%+ sync success
//

import Foundation
import SwiftData
import Combine

@MainActor
class RoutingService: ObservableObject {
    static let shared = RoutingService()

    @Published var isRouting: Bool = false

    private init() {}

    // MARK: - Route Entry to Date/Views

    func routeEntry(
        _ entry: Entry,
        to targetDate: Date,
        views: [ViewType],
        modelContext: ModelContext
    ) async -> Bool {
        isRouting = true
        defer { isRouting = false }

        do {
            // Update entry's target date
            entry.targetDate = targetDate

            // Create routing records for each view
            for viewType in views {
                let record = RoutingRecord(
                    entryID: entry.id,
                    targetDate: targetDate,
                    viewType: viewType,
                    sourceView: determineSourceView(from: entry.createdDate)
                )

                modelContext.insert(record)

                // Add relationship
                if entry.routingRecords == nil {
                    entry.routingRecords = []
                }
                entry.routingRecords?.append(record)
            }

            // Save changes
            try modelContext.save()

            print("✓ Routed entry '\(entry.content)' to \(targetDate) in \(views.count) views")
            return true

        } catch {
            print("✗ Error routing entry: \(error)")
            return false
        }
    }

    // MARK: - Batch Routing

    func routeMultipleEntries(
        _ entries: [(entry: Entry, targetDate: Date, views: [ViewType])],
        modelContext: ModelContext
    ) async -> (successCount: Int, failureCount: Int) {
        var successCount = 0
        var failureCount = 0

        for item in entries {
            let success = await routeEntry(item.entry, to: item.targetDate, views: item.views, modelContext: modelContext)
            if success {
                successCount += 1
            } else {
                failureCount += 1
            }
        }

        return (successCount, failureCount)
    }

    // MARK: - Content Propagation (Starring System)

    func propagateStarredContent(
        _ entry: Entry,
        toViews views: [ViewType],
        modelContext: ModelContext
    ) async -> Bool {
        guard entry.isStarred else {
            print("Entry is not starred, skipping propagation")
            return false
        }

        // Propagate to weekly and monthly views based on entry's date
        return await routeEntry(entry, to: entry.targetDate, views: views, modelContext: modelContext)
    }

    // MARK: - Downward Content Flow

    func propagateFromMonthlyToWeekly(
        monthlyEntry: Entry,
        modelContext: ModelContext
    ) async -> Bool {
        // Monthly content automatically appears in all weekly views within that month
        let calendar = Calendar.current
        let month = calendar.component(.month, from: monthlyEntry.targetDate)
        let year = calendar.component(.year, from: monthlyEntry.targetDate)

        // Get all weeks in the month
        let weeksInMonth = calendar.range(of: .weekOfMonth, in: .month, for: monthlyEntry.targetDate)?.count ?? 4

        var views: [ViewType] = [.weekly]

        return await routeEntry(monthlyEntry, to: monthlyEntry.targetDate, views: views, modelContext: modelContext)
    }

    func propagateFromWeeklyToDaily(
        weeklyEntry: Entry,
        modelContext: ModelContext
    ) async -> Bool {
        // Weekly content appears in all 7 daily views for that week
        return await routeEntry(weeklyEntry, to: weeklyEntry.targetDate, views: [.daily], modelContext: modelContext)
    }

    // MARK: - Query Routed Entries

    func getRoutedEntries(
        for date: Date,
        viewType: ViewType,
        modelContext: ModelContext
    ) -> [Entry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchDescriptor = FetchDescriptor<RoutingRecord>(
            predicate: #Predicate { record in
                record.targetDate >= startOfDay &&
                record.targetDate < endOfDay &&
                record.viewType == viewType
            }
        )

        do {
            let records = try modelContext.fetch(fetchDescriptor)
            let entryIDs = records.map { $0.entryID }

            // Fetch entries
            let entryFetchDescriptor = FetchDescriptor<Entry>(
                predicate: #Predicate { entry in
                    entryIDs.contains(entry.id)
                }
            )

            return try modelContext.fetch(entryFetchDescriptor)

        } catch {
            print("Error fetching routed entries: \(error)")
            return []
        }
    }

    func getStarredEntries(
        for date: Date,
        modelContext: ModelContext
    ) -> [Entry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let fetchDescriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { entry in
                entry.isStarred &&
                entry.targetDate >= startOfDay &&
                entry.targetDate < endOfDay
            }
        )

        do {
            return try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error fetching starred entries: \(error)")
            return []
        }
    }

    // MARK: - Helper Methods

    private func determineSourceView(from createdDate: Date) -> ViewType? {
        // Logic to determine which view the entry was created in
        // For now, default to daily
        return .daily
    }

    // MARK: - Sync Across Devices

    func syncContentAcrossDevices(entry: Entry) async {
        // CloudKit sync will be handled automatically by SwiftData
        // This method can be used for custom sync logic if needed
        print("Syncing entry \(entry.id) across devices via CloudKit")
    }
}
