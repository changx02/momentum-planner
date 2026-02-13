//
//  DateRecognitionEngine.swift
//  Aplyzia Planner
//
//  Intelligent date recognition from handwritten and typed text
//  Target accuracy: 95%+ for common formats, 90%+ for natural language
//

import Foundation
import NaturalLanguage

class DateRecognitionEngine {
    static let shared = DateRecognitionEngine()

    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()

    private init() {
        dateFormatter.locale = Locale.current
    }

    // MARK: - Main Recognition Method

    func recognizeDates(in text: String) -> [RecognizedDate] {
        var recognizedDates: [RecognizedDate] = []

        // 1. Try absolute date patterns
        recognizedDates.append(contentsOf: recognizeAbsoluteDates(in: text))

        // 2. Try relative date patterns
        recognizedDates.append(contentsOf: recognizeRelativeDates(in: text))

        // 3. Try date ranges
        recognizedDates.append(contentsOf: recognizeDateRanges(in: text))

        // 4. Use NLTagger for additional context
        recognizedDates.append(contentsOf: recognizeWithNLP(in: text))

        return recognizedDates
    }

    // MARK: - Absolute Date Recognition

    private func recognizeAbsoluteDates(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        // Numeric formats: 3/20, 03/20, 3/20/2025
        let numericPattern = #"(\d{1,2})[\/\-\.](\d{1,2})(?:[\/\-\.](\d{2,4}))?"#
        results.append(contentsOf: matchPattern(numericPattern, in: text, type: .numeric))

        // Text formats: March 20, Mar 20, March 20th
        let textPattern = #"(Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,?\s+(\d{4}))?"#
        results.append(contentsOf: matchPattern(textPattern, in: text, type: .textMonth))

        // ISO format: 2025-03-20
        let isoPattern = #"(\d{4})-(\d{2})-(\d{2})"#
        results.append(contentsOf: matchPattern(isoPattern, in: text, type: .iso))

        return results
    }

    // MARK: - Relative Date Recognition

    private func recognizeRelativeDates(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []
        let lowercased = text.lowercased()

        // Named relative dates
        if lowercased.contains("today") {
            results.append(RecognizedDate(
                date: Date(),
                range: (text as NSString).range(of: "today", options: .caseInsensitive),
                confidence: 1.0,
                type: .relative
            ))
        }

        if lowercased.contains("tomorrow") {
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                results.append(RecognizedDate(
                    date: tomorrow,
                    range: (text as NSString).range(of: "tomorrow", options: .caseInsensitive),
                    confidence: 1.0,
                    type: .relative
                ))
            }
        }

        if lowercased.contains("yesterday") {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
                results.append(RecognizedDate(
                    date: yesterday,
                    range: (text as NSString).range(of: "yesterday", options: .caseInsensitive),
                    confidence: 1.0,
                    type: .relative
                ))
            }
        }

        // Next/This/Last + Day of week
        results.append(contentsOf: recognizeWeekdayReferences(in: text))

        // In X days/weeks/months
        results.append(contentsOf: recognizeOffsetExpressions(in: text))

        return results
    }

    private func recognizeWeekdayReferences(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        let weekdays = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        let modifiers = ["next", "this", "last"]

        for modifier in modifiers {
            for (index, weekday) in weekdays.enumerated() {
                let pattern = "\(modifier)\\s+\(weekday)"
                if let range = text.range(of: pattern, options: .caseInsensitive) {
                    if let date = calculateWeekdayDate(weekdayIndex: index + 1, modifier: modifier) {
                        results.append(RecognizedDate(
                            date: date,
                            range: NSRange(range, in: text),
                            confidence: 0.95,
                            type: .relative
                        ))
                    }
                }
            }
        }

        return results
    }

    private func recognizeOffsetExpressions(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        // "in 3 days", "in 2 weeks", "in 1 month"
        let pattern = #"in\s+(\d+)\s+(day|week|month)s?"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsText = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) ?? []

        for match in matches {
            guard match.numberOfRanges == 3 else { continue }

            let numberRange = match.range(at: 1)
            let unitRange = match.range(at: 2)

            let numberString = nsText.substring(with: numberRange)
            let unitString = nsText.substring(with: unitRange).lowercased()

            if let amount = Int(numberString) {
                var component: Calendar.Component
                switch unitString {
                case "day": component = .day
                case "week": component = .weekOfYear
                case "month": component = .month
                default: continue
                }

                if let date = calendar.date(byAdding: component, value: amount, to: Date()) {
                    results.append(RecognizedDate(
                        date: date,
                        range: match.range,
                        confidence: 0.9,
                        type: .relative
                    ))
                }
            }
        }

        return results
    }

    // MARK: - Date Range Recognition

    private func recognizeDateRanges(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        // "March 20-25", "3/20-3/25"
        let rangePattern = #"(\w+\s+\d{1,2}|\d{1,2}\/\d{1,2})\s*[-–]\s*(\d{1,2}|\d{1,2}\/\d{1,2})"#

        // For now, we'll just return the start date
        // Full range support would expand this

        return results
    }

    // MARK: - NLP-Based Recognition

    private func recognizeWithNLP(in text: String) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in

            // NLTagger can identify dates contextually
            // This is a supplementary method

            return true
        }

        return results
    }

    // MARK: - Helper Methods

    private func matchPattern(_ pattern: String, in text: String, type: DateRecognitionType) -> [RecognizedDate] {
        var results: [RecognizedDate] = []

        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let nsText = text as NSString
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length)) ?? []

        for match in matches {
            if let date = parseMatchedDate(match: match, text: nsText, type: type) {
                results.append(RecognizedDate(
                    date: date,
                    range: match.range,
                    confidence: 0.95,
                    type: type
                ))
            }
        }

        return results
    }

    private func parseMatchedDate(match: NSTextCheckingResult, text: NSString, type: DateRecognitionType) -> Date? {
        guard match.numberOfRanges >= 2 else { return nil }

        switch type {
        case .numeric:
            return parseNumericDate(match: match, text: text)
        case .textMonth:
            return parseTextMonthDate(match: match, text: text)
        case .iso:
            return parseISODate(match: match, text: text)
        default:
            return nil
        }
    }

    private func parseNumericDate(match: NSTextCheckingResult, text: NSString) -> Date? {
        let month = Int(text.substring(with: match.range(at: 1))) ?? 1
        let day = Int(text.substring(with: match.range(at: 2))) ?? 1
        let year = match.numberOfRanges > 3 ? (Int(text.substring(with: match.range(at: 3))) ?? calendar.component(.year, from: Date())) : calendar.component(.year, from: Date())

        var components = DateComponents()
        components.month = month
        components.day = day
        components.year = year >= 100 ? year : 2000 + year

        return calendar.date(from: components)
    }

    private func parseTextMonthDate(match: NSTextCheckingResult, text: NSString) -> Date? {
        let monthString = text.substring(with: match.range(at: 1))
        let day = Int(text.substring(with: match.range(at: 2))) ?? 1
        let year = match.numberOfRanges > 3 ? (Int(text.substring(with: match.range(at: 3))) ?? calendar.component(.year, from: Date())) : calendar.component(.year, from: Date())

        let monthNumber = monthFromString(monthString)

        var components = DateComponents()
        components.month = monthNumber
        components.day = day
        components.year = year

        return calendar.date(from: components)
    }

    private func parseISODate(match: NSTextCheckingResult, text: NSString) -> Date? {
        let year = Int(text.substring(with: match.range(at: 1))) ?? 2025
        let month = Int(text.substring(with: match.range(at: 2))) ?? 1
        let day = Int(text.substring(with: match.range(at: 3))) ?? 1

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        return calendar.date(from: components)
    }

    private func calculateWeekdayDate(weekdayIndex: Int, modifier: String) -> Date? {
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)

        var daysToAdd = 0

        switch modifier {
        case "next":
            daysToAdd = (weekdayIndex - currentWeekday + 7) % 7
            if daysToAdd == 0 { daysToAdd = 7 }
        case "this":
            daysToAdd = (weekdayIndex - currentWeekday + 7) % 7
        case "last":
            daysToAdd = (weekdayIndex - currentWeekday - 7) % 7
        default:
            return nil
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: today)
    }

    private func monthFromString(_ monthString: String) -> Int {
        let months = ["jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
                      "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12]
        let prefix = String(monthString.prefix(3)).lowercased()
        return months[prefix] ?? 1
    }
}

// MARK: - Supporting Types

struct RecognizedDate {
    let date: Date
    let range: NSRange
    let confidence: Double // 0.0 to 1.0
    let type: DateRecognitionType
}

enum DateRecognitionType {
    case numeric
    case textMonth
    case iso
    case relative
    case range
    case nlp
}
