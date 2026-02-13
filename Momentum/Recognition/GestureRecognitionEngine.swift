//
//  GestureRecognitionEngine.swift
//  Momentum Planner
//
//  Recognizes handwritten gestures: checkmarks and directional arrows
//

import Foundation
import PencilKit
import CoreGraphics

struct RecognizedGesture {
    enum GestureType {
        case checkmark
        case arrowLeft
        case arrowRight
        case crossOut
        case unknown
    }

    let type: GestureType
    let confidence: Double
    let bounds: CGRect
}

class GestureRecognitionEngine {
    static let shared = GestureRecognitionEngine()

    private init() {}

    // MARK: - Public Recognition Methods

    /// Recognize gesture from PKDrawing (PencilKit)
    func recognizeGesture(from drawing: PKDrawing) -> RecognizedGesture? {
        guard !drawing.strokes.isEmpty else { return nil }

        // Extract points from all strokes
        let allPoints = drawing.strokes.flatMap { stroke -> [CGPoint] in
            stride(from: 0, to: stroke.path.count, by: 1).map { index in
                stroke.path.interpolatedLocation(at: CGFloat(index))
            }
        }

        guard allPoints.count >= 2 else { return nil }

        // Calculate bounds
        let bounds = calculateBounds(for: allPoints)

        // Try to recognize different gestures
        if let crossOut = recognizeCrossOut(points: allPoints, bounds: bounds) {
            return crossOut
        }

        if let checkmark = recognizeCheckmark(points: allPoints, bounds: bounds) {
            return checkmark
        }

        if let arrow = recognizeArrow(points: allPoints, bounds: bounds) {
            return arrow
        }

        return nil
    }

    /// Recognize gesture from raw points
    func recognizeGesture(from points: [CGPoint]) -> RecognizedGesture? {
        guard points.count >= 2 else { return nil }

        let bounds = calculateBounds(for: points)

        if let crossOut = recognizeCrossOut(points: points, bounds: bounds) {
            return crossOut
        }

        if let checkmark = recognizeCheckmark(points: points, bounds: bounds) {
            return checkmark
        }

        if let arrow = recognizeArrow(points: points, bounds: bounds) {
            return arrow
        }

        return nil
    }

    // MARK: - Cross Out Recognition (Line-through)

    private func recognizeCrossOut(points: [CGPoint], bounds: CGRect) -> RecognizedGesture? {
        guard points.count >= 2 else { return nil }

        // Line-through characteristics:
        // Horizontal line drawn through text (or diagonal line)
        // Primary movement should be horizontal

        let firstPoint = points.first!
        let lastPoint = points.last!
        let delta = calculateDelta(from: firstPoint, to: lastPoint)

        let horizontalDistance = abs(delta.dx)
        let verticalDistance = abs(delta.dy)

        // Require significant horizontal movement
        let minHorizontalDistance = bounds.width * 0.3
        guard horizontalDistance > minHorizontalDistance else {
            return nil
        }

        // Allow any vertical movement (can be horizontal or diagonal)
        // As long as horizontal movement is dominant or equal

        // Calculate confidence based on gesture characteristics
        let horizontalConfidence = min(1.0, Double(horizontalDistance) / Double(bounds.width))

        // Penalize excessive vertical movement (prefer more horizontal lines)
        let verticalRatio = horizontalDistance > 0 ? verticalDistance / horizontalDistance : 1.0
        let lineQuality = verticalRatio < 2.0 ? 1.0 : max(0.5, 1.0 - (verticalRatio - 2.0) / 2.0)

        let confidence = max(0.6, min(1.0, Double(horizontalConfidence * 0.7 + lineQuality * 0.3)))

        return RecognizedGesture(
            type: .crossOut,
            confidence: confidence,
            bounds: bounds
        )
    }

    // MARK: - Checkmark Recognition

    private func recognizeCheckmark(points: [CGPoint], bounds: CGRect) -> RecognizedGesture? {
        guard points.count >= 3 else { return nil }

        // Checkmark characteristics:
        // 1. Two distinct segments
        // 2. First segment goes down-right
        // 3. Second segment goes up-right
        // 4. Forms a "V" or "✓" shape

        // Find the lowest point (the valley of the checkmark)
        guard let lowestIndex = findLowestPoint(in: points) else { return nil }
        guard lowestIndex > 0 && lowestIndex < points.count - 1 else { return nil }

        let firstSegment = Array(points[0...lowestIndex])
        let secondSegment = Array(points[lowestIndex..<points.count])

        // Analyze first segment (should go down and slightly right)
        let firstDelta = calculateDelta(from: firstSegment.first!, to: firstSegment.last!)
        let firstGoesDown = firstDelta.dy > 0
        _ = firstDelta.dx >= -5 // Allow slight leftward movement (not used in validation)

        // Analyze second segment (should go up-right)
        let secondDelta = calculateDelta(from: secondSegment.first!, to: secondSegment.last!)
        let secondGoesUp = secondDelta.dy < 0
        let secondGoesRight = secondDelta.dx > 0

        // Calculate angle between segments
        let angle = angleBetweenVectors(v1: firstDelta, v2: secondDelta)
        let validAngle = angle > 30 && angle < 150 // V-shape angle

        // Check if it forms a checkmark shape
        if firstGoesDown && secondGoesUp && secondGoesRight && validAngle {
            let confidence = calculateCheckmarkConfidence(
                firstDelta: firstDelta,
                secondDelta: secondDelta,
                angle: angle
            )

            if confidence > 0.5 {
                return RecognizedGesture(
                    type: .checkmark,
                    confidence: confidence,
                    bounds: bounds
                )
            }
        }

        return nil
    }

    // MARK: - Chevron Recognition (> and <)

    private func recognizeArrow(points: [CGPoint], bounds: CGRect) -> RecognizedGesture? {
        guard points.count >= 3 else { return nil }

        // Chevron characteristics:
        // ">" shape: two strokes forming a V rotated 90° clockwise (pointing right)
        // "<" shape: two strokes forming a V rotated 90° counter-clockwise (pointing left)

        // Find the rightmost or leftmost point (the apex of the chevron)
        var apexIndex = 0
        var maxX = points[0].x
        var minX = points[0].x

        for point in points {
            if point.x > maxX {
                maxX = point.x
            }
            if point.x < minX {
                minX = point.x
            }
        }

        // Determine if it's a right-pointing (>) or left-pointing (<) chevron
        let centerX = (minX + maxX) / 2

        // Find apex (the point furthest from center)
        var maxDistanceFromCenter: CGFloat = 0
        for (index, point) in points.enumerated() {
            let distance = abs(point.x - centerX)
            if distance > maxDistanceFromCenter {
                maxDistanceFromCenter = distance
                apexIndex = index
            }
        }

        guard apexIndex > 0 && apexIndex < points.count - 1 else { return nil }

        let apexPoint = points[apexIndex]
        let firstSegment = Array(points[0...apexIndex])
        let secondSegment = Array(points[apexIndex..<points.count])

        guard firstSegment.count >= 2 && secondSegment.count >= 2 else { return nil }

        let firstDelta = calculateDelta(from: firstSegment.first!, to: firstSegment.last!)
        let secondDelta = calculateDelta(from: secondSegment.first!, to: secondSegment.last!)

        // Calculate angle between segments
        let angle = angleBetweenVectors(v1: firstDelta, v2: secondDelta)

        // Chevron should have an angle between 30-150 degrees
        guard angle > 30 && angle < 150 else { return nil }

        // Determine direction based on apex position
        let isPointingRight = apexPoint.x > centerX
        let isPointingLeft = apexPoint.x < centerX

        // Verify chevron shape: both segments should move toward the apex
        let firstMovesRight = firstDelta.dx > 0
        let secondMovesLeft = secondDelta.dx < 0
        let firstMovesLeft = firstDelta.dx < 0
        let secondMovesRight = secondDelta.dx > 0

        if isPointingRight && firstMovesRight && secondMovesLeft {
            // ">" shape detected
            let confidence = calculateChevronConfidence(angle: angle, bounds: bounds)
            return RecognizedGesture(
                type: .arrowRight,
                confidence: confidence,
                bounds: bounds
            )
        } else if isPointingLeft && firstMovesLeft && secondMovesRight {
            // "<" shape detected
            let confidence = calculateChevronConfidence(angle: angle, bounds: bounds)
            return RecognizedGesture(
                type: .arrowLeft,
                confidence: confidence,
                bounds: bounds
            )
        }

        return nil
    }

    private func calculateChevronConfidence(angle: CGFloat, bounds: CGRect) -> Double {
        // Ideal chevron angle is around 60-90 degrees
        let angleConfidence = 1.0 - abs(angle - 75.0) / 75.0

        // Size confidence (chevron should be reasonably sized)
        let minSize = min(bounds.width, bounds.height)
        let sizeConfidence = min(1.0, Double(minSize) / 20.0)

        return max(0.5, min(1.0, (angleConfidence * 0.6 + sizeConfidence * 0.4)))
    }

    // MARK: - Helper Methods

    private func calculateBounds(for points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }

        var minX = points[0].x
        var maxX = points[0].x
        var minY = points[0].y
        var maxY = points[0].y

        for point in points {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func findLowestPoint(in points: [CGPoint]) -> Int? {
        guard !points.isEmpty else { return nil }

        var lowestIndex = 0
        var maxY = points[0].y

        for (index, point) in points.enumerated() {
            if point.y > maxY {
                maxY = point.y
                lowestIndex = index
            }
        }

        return lowestIndex
    }

    private func calculateDelta(from start: CGPoint, to end: CGPoint) -> (dx: CGFloat, dy: CGFloat) {
        return (dx: end.x - start.x, dy: end.y - start.y)
    }

    private func angleBetweenVectors(v1: (dx: CGFloat, dy: CGFloat), v2: (dx: CGFloat, dy: CGFloat)) -> CGFloat {
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let mag2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)

        guard mag1 > 0 && mag2 > 0 else { return 0 }

        let cosAngle = dot / (mag1 * mag2)
        let angle = acos(max(-1, min(1, cosAngle)))

        return angle * 180 / .pi
    }

    private func calculateCheckmarkConfidence(
        firstDelta: (dx: CGFloat, dy: CGFloat),
        secondDelta: (dx: CGFloat, dy: CGFloat),
        angle: CGFloat
    ) -> Double {
        // Ideal checkmark:
        // - First segment: down-right (or straight down)
        // - Second segment: up-right with more rightward movement
        // - Angle between 60-120 degrees

        var confidence = 0.0

        // Angle confidence (ideal: 90 degrees)
        let angleConfidence = 1.0 - abs(angle - 90.0) / 90.0
        confidence += angleConfidence * 0.4

        // Direction confidence
        let firstGoesDown = firstDelta.dy > 0
        let secondGoesUp = secondDelta.dy < 0
        let secondGoesRight = secondDelta.dx > abs(secondDelta.dy) // More right than vertical

        if firstGoesDown { confidence += 0.2 }
        if secondGoesUp { confidence += 0.2 }
        if secondGoesRight { confidence += 0.2 }

        return min(1.0, max(0.0, confidence))
    }
}

// MARK: - PKDrawing Extension for Point Extraction

extension PKStroke {
    var points: [CGPoint] {
        stride(from: 0, to: path.count, by: 1).map { index in
            path.interpolatedLocation(at: CGFloat(index))
        }
    }
}
