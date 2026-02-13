//
//  Goal.swift
//  Aplyzia Planner
//
//  Goal model for SMARTER goal framework
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var category: LifeCategory
    var goalStatement: String
    var goalType: GoalType
    var keyMotivations: [String]
    var nextSteps: [GoalStep]
    var celebration: String
    var progressPercentage: Double // 0-100 for achievement goals
    var streakData: [Date: Bool] // Date -> completed on that day (for habit goals)
    var createdDate: Date
    var targetDate: Date?

    init(
        id: UUID = UUID(),
        category: LifeCategory,
        goalStatement: String = "",
        goalType: GoalType = .achievement,
        keyMotivations: [String] = [],
        nextSteps: [GoalStep] = [],
        celebration: String = "",
        progressPercentage: Double = 0,
        streakData: [Date: Bool] = [:],
        createdDate: Date = Date(),
        targetDate: Date? = nil
    ) {
        self.id = id
        self.category = category
        self.goalStatement = goalStatement
        self.goalType = goalType
        self.keyMotivations = keyMotivations
        self.nextSteps = nextSteps
        self.celebration = celebration
        self.progressPercentage = progressPercentage
        self.streakData = streakData
        self.createdDate = createdDate
        self.targetDate = targetDate
    }
}

enum LifeCategory: String, Codable, CaseIterable {
    case body = "Body"
    case mind = "Mind"
    case spirit = "Spirit"
    case love = "Love"
    case family = "Family"
    case community = "Community"
    case money = "Money"
    case work = "Work"
    case hobbies = "Hobbies"
}

enum GoalType: String, Codable {
    case achievement
    case habit
}

struct GoalStep: Codable, Identifiable {
    var id: UUID = UUID()
    var content: String
    var isCompleted: Bool = false
    var completedDate: Date?
}
