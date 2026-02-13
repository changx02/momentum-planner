//
//  Reminder.swift
//  Aplyzia Planner
//
//  Reminder model for intelligent notifications
//

import Foundation
import SwiftData

@Model
final class Reminder {
    var id: UUID
    var entryID: UUID
    var reminderTime: Date
    var offsetMinutes: Int // Minutes before target time
    var offsetType: ReminderOffsetType
    var notificationTitle: String
    var notificationBody: String
    var isFired: Bool
    var isDismissed: Bool
    var isSnoozed: Bool
    var snoozeUntil: Date?
    var platformNotificationID: String?
    var createdAt: Date

    // Timezone handling (stored as identifier string for SwiftData compatibility)
    var originalTimezoneIdentifier: String
    var useCurrentTimezone: Bool

    // Computed property for TimeZone
    var originalTimezone: TimeZone {
        get { TimeZone(identifier: originalTimezoneIdentifier) ?? .current }
        set { originalTimezoneIdentifier = newValue.identifier }
    }

    init(
        id: UUID = UUID(),
        entryID: UUID,
        reminderTime: Date,
        offsetMinutes: Int = 15,
        offsetType: ReminderOffsetType = .before,
        notificationTitle: String,
        notificationBody: String,
        isFired: Bool = false,
        isDismissed: Bool = false,
        isSnoozed: Bool = false,
        snoozeUntil: Date? = nil,
        platformNotificationID: String? = nil,
        createdAt: Date = Date(),
        originalTimezone: TimeZone = .current,
        useCurrentTimezone: Bool = false
    ) {
        self.id = id
        self.entryID = entryID
        self.reminderTime = reminderTime
        self.offsetMinutes = offsetMinutes
        self.offsetType = offsetType
        self.notificationTitle = notificationTitle
        self.notificationBody = notificationBody
        self.isFired = isFired
        self.isDismissed = isDismissed
        self.isSnoozed = isSnoozed
        self.snoozeUntil = snoozeUntil
        self.platformNotificationID = platformNotificationID
        self.createdAt = createdAt
        self.originalTimezoneIdentifier = originalTimezone.identifier
        self.useCurrentTimezone = useCurrentTimezone
    }
}

enum ReminderOffsetType: String, Codable {
    case before
    case at
    case after
    case custom
}

// Smart defaults based on entry type
extension Reminder {
    static func smartDefaults(for content: String, eventTime: Date) -> [Int] {
        let lowercased = content.lowercased()

        if lowercased.contains("meeting") || lowercased.contains("call") {
            return [15] // 15 minutes before
        } else if lowercased.contains("appointment") || lowercased.contains("doctor") || lowercased.contains("dentist") {
            return [60, 1440] // 1 hour + 1 day before
        } else if lowercased.contains("deadline") || lowercased.contains("due") || lowercased.contains("submit") {
            return [120] // 2 hours before
        } else if lowercased.contains("event") || lowercased.contains("conference") || lowercased.contains("presentation") {
            return [60, 1440] // 1 hour + 1 day before
        } else if lowercased.contains("pick up") || lowercased.contains("drop off") {
            return [30] // 30 minutes before
        }

        return [15] // Default: 15 minutes
    }
}
