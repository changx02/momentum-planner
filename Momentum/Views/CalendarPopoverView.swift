//
//  CalendarPopoverView.swift
//  Aplyzia Planner
//
//  Calendar popover displaying appointments ordered by date and time
//

import SwiftUI
import SwiftData

struct CalendarPopoverView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    private let calendar = Calendar.current

    // Get appointments (entries with targetTime) sorted by date and time
    private var appointments: [Entry] {
        allEntries
            .filter { $0.targetTime != nil }
            .sorted { entry1, entry2 in
                // Sort by targetDate first, then by targetTime
                if entry1.targetDate != entry2.targetDate {
                    return entry1.targetDate < entry2.targetDate
                }
                return (entry1.targetTime ?? Date()) < (entry2.targetTime ?? Date())
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Spacer()
                Text("Time Block")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Scrollable list of appointments
            ScrollView {
                VStack(spacing: 0) {
                    if appointments.isEmpty {
                        // Empty state
                        Text("No appointments scheduled")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#999999"))
                            .padding(.vertical, 40)
                    } else {
                        ForEach(appointments) { entry in
                            AppointmentRow(entry: entry)

                            // Divider between items
                            if entry.id != appointments.last?.id {
                                Rectangle()
                                    .fill(Color(hex: "#CBCBCB"))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .frame(maxHeight: 400)
        }
        .frame(width: 300)
        .background(Color(hex: "#FFFFFF"))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}

struct AppointmentRow: View {
    let entry: Entry

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Date
            Text(dateString)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color(hex: "#666666"))

            // Time
            if let time = entry.targetTime {
                Text(timeString(from: time))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
            }

            // Appointment content
            Text(entry.content)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: entry.targetDate)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarPopoverView()
}
