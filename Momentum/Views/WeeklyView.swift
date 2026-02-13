//
//  WeeklyView.swift
//  MOMENTUM Planner
//
//  Weekly planner view - Time grid layout
//

import SwiftUI
import SwiftData

struct WeeklyView: View {
    let date: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    private let calendar = Calendar.current

    // Time slots for the grid (24-hour format) - extended to fill the view
    private let timeSlots = ["05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "00"]

    // Get the week's date range (Monday to Sunday)
    private var weekDates: [Date] {
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return []
        }
        // Adjust to start from Monday
        let weekday = calendar.component(.weekday, from: weekStart)
        let daysToMonday = (weekday == 1) ? -6 : -(weekday - 2)
        guard let monday = calendar.date(byAdding: .day, value: daysToMonday, to: weekStart) else {
            return []
        }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: monday)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Spacer for top menu bar
            Spacer()
                .frame(height: 50)

            // Additional padding to align with sidebar 12 icon
            Spacer()
                .frame(height: 33)

            // Header
            headerView

            // Weekly time grid
            ScrollView {
                timeGridView
                    .padding(.horizontal, 40)
                    .padding(.bottom, 45)
            }
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(monthAbbreviation)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Text("WEEK \(weekNumber)")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(hex: "#1A1A1A"))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Time Grid

    private var timeGridView: some View {
        VStack(spacing: 0) {
            // Day headers row
            HStack(spacing: 0) {
                // Empty corner cell for time column
                Color.clear
                    .frame(width: 32)

                // Day names with dates - each in their own column
                ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                    VStack(spacing: 0) {
                        Text("\(dayName(for: date)) \(dayNumber(for: date))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .tracking(0.3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 16)

            // Grid with time slots
            VStack(spacing: 0) {
                ForEach(timeSlots, id: \.self) { timeSlot in
                    HStack(spacing: 0) {
                        // Time label (no border, left-aligned)
                        HStack {
                            Text(timeSlot)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(Color(hex: "#999999"))
                            Spacer()
                        }
                        .frame(width: 32, height: 29.7)

                        // Day cells for this time slot
                        GeometryReader { geometry in
                            let cellWidth = geometry.size.width / 7

                            ZStack(alignment: .topLeading) {
                                // Day cells
                                HStack(spacing: 0) {
                                    ForEach(Array(weekDates.enumerated()), id: \.offset) { dayIndex, date in
                                        TimeSlotCell(
                                            date: date,
                                            timeSlot: timeSlot,
                                            entries: entriesForDateTime(date, timeSlot: timeSlot),
                                            modelContext: modelContext,
                                            cellHeight: 29.7
                                        )
                                        .frame(width: cellWidth)
                                    }
                                }

                                // Vertical lines overlay
                                Path { path in
                                    for i in 1..<7 {
                                        let x = cellWidth * CGFloat(i)
                                        path.move(to: CGPoint(x: x, y: 0))
                                        path.addLine(to: CGPoint(x: x, y: 29.7))
                                    }
                                }
                                .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                            }
                        }
                        .frame(height: 29.7)
                        .overlay(
                            Rectangle()
                                .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                        )
                    }

                    // Horizontal divider
                    if timeSlot != timeSlots.last {
                        HStack(spacing: 0) {
                            // Empty space for time column
                            Color.clear
                                .frame(width: 32, height: 0.5)

                            // Divider across day columns
                            Rectangle()
                                .fill(Color(hex: "#CBCBCB"))
                                .frame(height: 0.5)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var weekNumber: String {
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        return String(format: "%02d", weekOfYear)
    }

    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func dayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func fullDayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(for date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func entriesForDate(_ date: Date) -> [Entry] {
        allEntries.filter { entry in
            calendar.isDate(entry.targetDate, inSameDayAs: date)
        }
    }

    private func entriesForDateTime(_ date: Date, timeSlot: String) -> [Entry] {
        let hour = Int(timeSlot) ?? 0
        return allEntries.filter { entry in
            guard calendar.isDate(entry.targetDate, inSameDayAs: date),
                  let targetTime = entry.targetTime else {
                return false
            }
            let entryHour = calendar.component(.hour, from: targetTime)
            return entryHour == hour
        }
    }
}

// MARK: - Time Slot Cell

struct TimeSlotCell: View {
    let date: Date
    let timeSlot: String
    let entries: [Entry]
    let modelContext: ModelContext
    let cellHeight: CGFloat

    private let calendar = Calendar.current

    var body: some View {
        Rectangle()
            .fill(Color(hex: "#F9F4EA"))
            .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
            .overlay(
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entries.prefix(2)) { entry in
                        HStack(spacing: 4) {
                            // Small checkbox indicator
                            Circle()
                                .fill(entry.isCompleted ? Color(hex: "#4CAF50") : Color(hex: "#CCCCCC"))
                                .frame(width: 5, height: 5)

                            // Entry text (truncated)
                            Text(entry.content)
                                .font(.system(size: 8))
                                .foregroundColor(Color(hex: "#1A1A1A"))
                                .lineLimit(1)
                        }
                    }
                }
                .padding(4),
                alignment: .topLeading
            )
            .contentShape(Rectangle())
            .onTapGesture {
                // Add new entry for this time slot
                addNewEntry()
            }
    }

    private func addNewEntry() {
        // Create date-time by combining date and time slot
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let hour = Int(timeSlot) ?? 0
        components.hour = hour
        components.minute = 0

        guard let targetDateTime = calendar.date(from: components) else { return }

        let newEntry = Entry(
            content: "",
            entryType: .event,
            targetDate: date,
            targetTime: targetDateTime
        )
        modelContext.insert(newEntry)
        try? modelContext.save()
    }
}

#Preview {
    WeeklyView(date: Date())
}
