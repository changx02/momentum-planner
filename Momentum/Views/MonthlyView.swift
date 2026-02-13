//
//  MonthlyView.swift
//  MOMENTUM Planner
//
//  Monthly planner view - Calendar grid with task preview
//

import SwiftUI
import SwiftData

struct MonthlyView: View {
    let date: Date
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    private let calendar = Calendar.current
    private let daysOfWeek = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]

    // Get all dates for the month's calendar grid
    private var calendarDates: [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        let daysInMonth = calendar.component(.day, from: monthEnd)

        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                dates.append(date)
            }
        }

        // Pad to complete weeks (35 cells = 5 weeks)
        while dates.count < 35 {
            dates.append(nil)
        }

        return dates
    }

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
                .padding(.bottom, 20)

            // Calendar grid with headers
            VStack(spacing: 0) {
                // Day of week headers
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }

                // Calendar grid - only show rows with dates
                GeometryReader { geometry in
                    let cellWidth = geometry.size.width / 7

                    VStack(spacing: 0) {
                        ForEach(0..<numberOfWeeks, id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7) { col in
                                    let index = row * 7 + col
                                    if index < calendarDates.count, let cellDate = calendarDates[index] {
                                        Button(action: {
                                            selectedDate = cellDate
                                            selectedView = .daily
                                        }) {
                                            CalendarDayCell(
                                                date: cellDate,
                                                entries: entriesForDate(cellDate),
                                                isToday: calendar.isDateInToday(cellDate),
                                                isCurrentMonth: calendar.isDate(cellDate, equalTo: date, toGranularity: .month)
                                            )
                                            .frame(width: cellWidth, height: cellHeight)
                                        }
                                        .buttonStyle(.plain)
                                    } else if row < numberOfWeeks - 1 || hasDateInWeek(row) {
                                        Rectangle()
                                            .fill(Color(hex: "#F9F4EA"))
                                            .frame(width: cellWidth, height: cellHeight)
                                            .overlay(
                                                Rectangle()
                                                    .strokeBorder(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: CGFloat(numberOfWeeks) * cellHeight)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)

            Spacer()
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Swipe left = next month, Swipe right = previous month
                    if value.translation.width < -50 {
                        // Swipe left - go to next month
                        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) {
                            selectedDate = nextMonth
                        }
                    } else if value.translation.width > 50 {
                        // Swipe right - go to previous month
                        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: date) {
                            selectedDate = prevMonth
                        }
                    }
                }
        )
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(monthName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                Text(String(format: "%d", yearNumber))
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(Color(hex: "#1A1A1A"))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.top, 20)
    }

    // MARK: - Computed Properties

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date).uppercased()
    }

    private var yearNumber: Int {
        calendar.component(.year, from: date)
    }

    private func entriesForDate(_ date: Date) -> [Entry] {
        allEntries.filter { entry in
            calendar.isDate(entry.targetDate, inSameDayAs: date)
        }
    }

    private var numberOfWeeks: Int {
        let datesWithContent = calendarDates.compactMap { $0 }
        if datesWithContent.isEmpty {
            return 5
        }
        let lastDateIndex = calendarDates.lastIndex(where: { $0 != nil }) ?? 34
        return (lastDateIndex / 7) + 1
    }

    private var cellHeight: CGFloat {
        // Use smaller cells for 6-row months to maintain consistent total height
        return numberOfWeeks == 6 ? 86 : 105
    }

    private func hasDateInWeek(_ week: Int) -> Bool {
        let startIndex = week * 7
        let endIndex = min(startIndex + 7, calendarDates.count)
        for i in startIndex..<endIndex {
            if calendarDates[i] != nil {
                return true
            }
        }
        return false
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let entries: [Entry]
    let isToday: Bool
    let isCurrentMonth: Bool

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Day number
            Text("\(dayNumber)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isToday ? Color.white : (isCurrentMonth ? Color(hex: "#1A1A1A") : Color(hex: "#CCCCCC")))
                .frame(width: 24, height: 24)
                .background(isToday ? Color(hex: "#1A1A1A") : Color.clear)
                .clipShape(Circle())

            Spacer()
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: "#F9F4EA"))
        .overlay(
            Rectangle()
                .strokeBorder(Color(hex: "#CBCBCB"), lineWidth: 0.5)
        )
        .opacity(isCurrentMonth ? 1.0 : 0.4)
    }

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }
}

#Preview {
    MonthlyView(date: Date(), selectedView: .constant(.monthly), selectedDate: .constant(Date()))
}
