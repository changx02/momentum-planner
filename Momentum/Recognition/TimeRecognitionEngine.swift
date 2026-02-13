//
//  TimeRecognitionEngine.swift
//  Aplyzia Planner
//
//  Intelligent time recognition from handwritten and typed text
//  Target accuracy: 95%+ for explicit times, 85%+ for contextual
//

import Foundation

class TimeRecognitionEngine {
    static let shared = TimeRecognitionEngine()

    private init() {}

    // MARK: - Main Recognition Method

    func recognizeTimes(in text: String) -> [RecognizedTime] {
        var recognizedTimes: [RecognizedTime] = []

        // 1. 12-hour format
        recognizedTimes.append(contentsOf: recognize12HourFormat(in: text))

        // 2. 24-hour format
        recognizedTimes.append(contentsOf: recognize24HourFormat(in: text))

        // 3. Contextual times
        recognizedTimes.append(contentsOf: recognizeContextualTimes(in: text))

        return recognizedTimes
    }

    // MARK: - 12-Hour Format Recognition

    private func recognize12HourFormat(in text: String) -> [RecognizedTime] {
        var results: [RecognizedTime] = []

        // Pattern: 2pm, 2:30pm, 2:30 PM, 2 o'clock, 2p
        let pattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.|a|p|o'clock)?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsText = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) ?? []

        for match in matches {
            guard match.numberOfRanges >= 2 else { continue }

            let hourRange = match.range(at: 1)
            var hour = Int(nsText.substring(with: hourRange)) ?? 0

            let minute: Int
            if match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound {
                let minuteRange = match.range(at: 2)
                minute = Int(nsText.substring(with: minuteRange)) ?? 0
            } else {
                minute = 0
            }

            // Determine AM/PM
            var isPM = false
            if match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound {
                let periodRange = match.range(at: 3)
                let period = nsText.substring(with: periodRange).lowercased()
                isPM = period.contains("p")
            } else {
                // Contextual inference: 2 = 2pm if in typical working hours context
                isPM = inferAMPM(hour: hour, context: text)
            }

            // Convert to 24-hour
            if isPM && hour != 12 {
                hour += 12
            } else if !isPM && hour == 12 {
                hour = 0
            }

            // Validate
            guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else { continue }

            if let time = createTime(hour: hour, minute: minute) {
                results.append(RecognizedTime(
                    time: time,
                    range: match.range,
                    confidence: match.range(at: 3).location != NSNotFound ? 0.95 : 0.85,
                    format: .twelveHour
                ))
            }
        }

        return results
    }

    // MARK: - 24-Hour Format Recognition

    private func recognize24HourFormat(in text: String) -> [RecognizedTime] {
        var results: [RecognizedTime] = []

        // Pattern: 14:00, 14:30, 1430
        let pattern = #"(\d{2}):?(\d{2})"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let nsText = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) ?? []

        for match in matches {
            guard match.numberOfRanges == 3 else { continue }

            let hour = Int(nsText.substring(with: match.range(at: 1))) ?? 0
            let minute = Int(nsText.substring(with: match.range(at: 2))) ?? 0

            // Validate 24-hour time
            guard hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59 else { continue }

            if let time = createTime(hour: hour, minute: minute) {
                results.append(RecognizedTime(
                    time: time,
                    range: match.range,
                    confidence: 0.95,
                    format: .twentyFourHour
                ))
            }
        }

        return results
    }

    // MARK: - Contextual Time Recognition

    private func recognizeContextualTimes(in text: String) -> [RecognizedTime] {
        var results: [RecognizedTime] = []
        let lowercased = text.lowercased()

        let contextualTimes: [(keyword: String, hour: Int, minute: Int)] = [
            ("morning", 9, 0),
            ("afternoon", 14, 0),
            ("evening", 18, 0),
            ("noon", 12, 0),
            ("midnight", 0, 0)
        ]

        for (keyword, hour, minute) in contextualTimes {
            if let range = lowercased.range(of: keyword) {
                if let time = createTime(hour: hour, minute: minute) {
                    results.append(RecognizedTime(
                        time: time,
                        range: NSRange(range, in: text),
                        confidence: 0.85,
                        format: .contextual
                    ))
                }
            }
        }

        return results
    }

    // MARK: - Helper Methods

    private func inferAMPM(hour: Int, context: String) -> Bool {
        // Simple heuristic: hours 1-6 could be either, default to PM for typical work context
        // Hours 7-11 default to AM
        // Hour 12 defaults to PM (noon)

        if hour >= 7 && hour <= 11 {
            return false // AM
        } else if hour == 12 {
            return true // PM (noon)
        } else {
            // Check context for clues
            let lowercased = context.lowercased()
            if lowercased.contains("morning") || lowercased.contains("breakfast") {
                return false
            } else if lowercased.contains("evening") || lowercased.contains("dinner") || lowercased.contains("night") {
                return true
            }
            return true // Default to PM
        }
    }

    private func createTime(hour: Int, minute: Int) -> Date? {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0

        // Use today's date as base
        let calendar = Calendar.current
        let now = Date()
        components.year = calendar.component(.year, from: now)
        components.month = calendar.component(.month, from: now)
        components.day = calendar.component(.day, from: now)

        return calendar.date(from: components)
    }
}

// MARK: - Supporting Types

struct RecognizedTime {
    let time: Date
    let range: NSRange
    let confidence: Double // 0.0 to 1.0
    let format: TimeFormat
}

enum TimeFormat {
    case twelveHour
    case twentyFourHour
    case contextual
}
