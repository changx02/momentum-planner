//
//  NotePage.swift
//  MOMENTUM Planner
//
//  Model for note pages
//

import Foundation
import SwiftData

@Model
final class NotePage {
    var id: UUID
    var date: Date
    var pageNumber: Int
    var content: String
    var createdDate: Date

    init(
        id: UUID = UUID(),
        date: Date,
        pageNumber: Int,
        content: String = "",
        createdDate: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.pageNumber = pageNumber
        self.content = content
        self.createdDate = createdDate
    }
}
