//
//  TextBox.swift
//  Aplyzia Planner
//
//  Text box model for flexible text placement
//

import Foundation
import SwiftData
import CoreGraphics

@Model
final class TextBox {
    var id: UUID
    var pageID: UUID
    var positionX: CGFloat
    var positionY: CGFloat
    var width: CGFloat
    var height: CGFloat
    var fontPreset: FontPreset
    var label: String?
    var alignment: TextAlignment
    var autoExpand: Bool
    var backgroundColor: String? // Hex color
    var borderColor: String? // Hex color
    var padding: CGFloat
    var isActive: Bool

    init(
        id: UUID = UUID(),
        pageID: UUID,
        positionX: CGFloat,
        positionY: CGFloat,
        width: CGFloat = 300,
        height: CGFloat = 200,
        fontPreset: FontPreset = .body,
        label: String? = nil,
        alignment: TextAlignment = .left,
        autoExpand: Bool = true,
        backgroundColor: String? = nil,
        borderColor: String? = "#CBCBCB",
        padding: CGFloat = 12,
        isActive: Bool = false
    ) {
        self.id = id
        self.pageID = pageID
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.fontPreset = fontPreset
        self.label = label
        self.alignment = alignment
        self.autoExpand = autoExpand
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.padding = padding
        self.isActive = isActive
    }
}

enum FontPreset: String, Codable {
    case headers // Bold sans-serif, 18pt
    case body // Regular sans-serif, 14pt
    case notes // Light serif, 12pt

    var fontName: String {
        switch self {
        case .headers: return "SFPro-Bold"
        case .body: return "SFPro-Regular"
        case .notes: return "NewYork-Regular"
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .headers: return 18
        case .body: return 14
        case .notes: return 12
        }
    }

    var lineHeight: CGFloat {
        switch self {
        case .headers: return 24
        case .body: return 20
        case .notes: return 18
        }
    }
}

enum TextAlignment: String, Codable {
    case left
    case center
    case right
    case justify
}
