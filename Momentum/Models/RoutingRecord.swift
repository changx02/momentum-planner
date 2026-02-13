//
//  RoutingRecord.swift
//  Aplyzia Planner
//
//  Tracks content routing across views
//

import Foundation
import SwiftData

@Model
final class RoutingRecord {
    var id: UUID
    var entryID: UUID
    var targetDate: Date
    var viewType: ViewType
    var routedAt: Date
    var sourceView: ViewType?

    init(
        id: UUID = UUID(),
        entryID: UUID,
        targetDate: Date,
        viewType: ViewType,
        routedAt: Date = Date(),
        sourceView: ViewType? = nil
    ) {
        self.id = id
        self.entryID = entryID
        self.targetDate = targetDate
        self.viewType = viewType
        self.routedAt = routedAt
        self.sourceView = sourceView
    }
}

enum ViewType: String, Codable {
    case daily
    case weekly
    case monthly
    case yearly
}
