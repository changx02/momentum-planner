//
//  Entry.swift
//  Aplyzia Planner
//
//  Core entry model for tasks, events, and notes
//

import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var content: String
    var entryType: EntryType
    var createdDate: Date
    var targetDate: Date
    var targetTime: Date?
    var hasCheckbox: Bool
    var isCompleted: Bool
    var isStarred: Bool
    var hasReminder: Bool

    // Relationships
    @Relationship(deleteRule: .cascade) var reminders: [Reminder]?
    @Relationship(deleteRule: .cascade) var routingRecords: [RoutingRecord]?

    // Handwriting data
    var originalHandwriting: Data? // Serialized handwriting strokes
    var handwritingPreserved: Bool

    // Text box association
    var textBoxID: UUID?

    // Section/Category for organizing tasks
    var taskSection: TaskSection?

    // Completion metadata
    var completionMethod: CompletionMethod?
    var completedDate: Date?

    // Reminder offset for TIME BLOCK entries (in minutes)
    var reminderOffsetMinutes: Int?

    // Important flag for monthly view display
    var isImportant: Bool = false

    init(
        id: UUID = UUID(),
        content: String,
        entryType: EntryType = .task,
        createdDate: Date = Date(),
        targetDate: Date = Date(),
        targetTime: Date? = nil,
        hasCheckbox: Bool = false,
        isCompleted: Bool = false,
        isStarred: Bool = false,
        hasReminder: Bool = false,
        originalHandwriting: Data? = nil,
        handwritingPreserved: Bool = false,
        textBoxID: UUID? = nil,
        isImportant: Bool = false
    ) {
        self.id = id
        self.content = content
        self.entryType = entryType
        self.createdDate = createdDate
        self.targetDate = targetDate
        self.targetTime = targetTime
        self.hasCheckbox = hasCheckbox
        self.isCompleted = isCompleted
        self.isStarred = isStarred
        self.hasReminder = hasReminder
        self.originalHandwriting = originalHandwriting
        self.handwritingPreserved = handwritingPreserved
        self.textBoxID = textBoxID
        self.isImportant = isImportant
    }
}

enum EntryType: String, Codable {
    case task
    case event
    case note
    case goal
}

enum CompletionMethod: String, Codable {
    case checkboxTap
    case crossOut
    case checkmarkDrawing
}

enum TaskSection: String, Codable {
    case focusPoint
    case actionList
    case timeBlock
    case todaysWin
}
