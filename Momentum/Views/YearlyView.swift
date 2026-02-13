//
//  YearlyView.swift
//  MOMENTUM Planner
//
//  Yearly planner view - 12-month overview
//

import SwiftUI
import SwiftData

struct YearlyView: View {
    let year: Int
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    private let calendar = Calendar.current
    private let monthNames = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]

    var body: some View {
        VStack(spacing: 0) {
            // Spacer for top menu bar
            Spacer()
                .frame(height: 50)

            // Additional padding to align with sidebar 12 icon
            Spacer()
                .frame(height: 33)

            // Header - same position as DailyView
            headerView

            // 12-month grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(1...12, id: \.self) { month in
                        MonthCard(
                            year: year,
                            month: month,
                            entries: entriesForMonth(month),
                            monthName: monthNames[month - 1],
                            selectedView: $selectedView,
                            selectedDate: $selectedDate
                        )
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 45)
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("YEAR")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Text(String(format: "%d", year))
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(hex: "#1A1A1A"))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Helper Methods

    private func entriesForMonth(_ month: Int) -> [Entry] {
        allEntries.filter { entry in
            let entryYear = calendar.component(.year, from: entry.targetDate)
            let entryMonth = calendar.component(.month, from: entry.targetDate)
            return entryYear == year && entryMonth == month
        }
    }
}

// MARK: - Month Card

struct MonthCard: View {
    let year: Int
    let month: Int
    let entries: [Entry]
    let monthName: String
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let daysOfWeek = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        Button(action: {
            // Create date for first day of this month
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1

            if let newDate = calendar.date(from: components) {
                selectedDate = newDate
                selectedView = .monthly
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                // Month name
                HStack {
                    Spacer()
                    Text(monthName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                    Spacer()
                }

                // Calendar grid with lines
                calendarGridView
            }
            .padding(12)
            .frame(height: 200)
            .background(Color(hex: "#F9F4EA"))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calendar Grid View

    private var calendarGridView: some View {
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStartDate)?.count ?? 31
        // Adjust for Monday start: weekday 1 (Sunday) becomes 6, weekday 2 (Monday) becomes 0
        let weekday = calendar.component(.weekday, from: monthStartDate)
        let firstWeekday = (weekday + 5) % 7
        let rows = 6
        let columns = 7

        return GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(columns)
            let cellHeight = (geometry.size.height - 16) / CGFloat(rows + 1) // +1 for header row

            ZStack(alignment: .topLeading) {
                // Background
                Color(hex: "#F9F4EA")

                // Week day headers
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        Text(daysOfWeek[col])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(hex: "#999999"))
                            .frame(width: cellWidth, height: 16)
                    }
                }

                // Day numbers
                ForEach(0..<(rows * columns), id: \.self) { index in
                    let row = index / columns
                    let col = index % columns
                    let dayNumber = index - firstWeekday + 1

                    if dayNumber > 0 && dayNumber <= daysInMonth {
                        Text("\(dayNumber)")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .frame(width: cellWidth, height: cellHeight)
                            .position(
                                x: CGFloat(col) * cellWidth + cellWidth / 2,
                                y: CGFloat(row) * cellHeight + cellHeight / 2 + 16
                            )
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var monthStartDate: Date {
        let components = DateComponents(year: year, month: month, day: 1)
        return calendar.date(from: components) ?? Date()
    }

    private var isCurrentMonth: Bool {
        let now = Date()
        return calendar.component(.year, from: now) == year &&
               calendar.component(.month, from: now) == month
    }

    private var completedCount: Int {
        entries.filter { $0.isCompleted }.count
    }

    private func entriesForDay(_ day: Int) -> [Entry] {
        entries.filter { entry in
            calendar.component(.day, from: entry.targetDate) == day
        }
    }
}

#Preview {
    YearlyView(year: 2026, selectedView: .constant(.yearly), selectedDate: .constant(Date()))
}
