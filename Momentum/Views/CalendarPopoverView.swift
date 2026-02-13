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

    // Get appointments (entries with targetTime from TIME BLOCK only) sorted by date and time
    private var appointments: [Entry] {
        allEntries
            .filter { $0.targetTime != nil && $0.taskSection == .timeBlock }
            .sorted { entry1, entry2 in
                // Sort by targetDate first, then by targetTime
                if entry1.targetDate != entry2.targetDate {
                    return entry1.targetDate < entry2.targetDate
                }
                return (entry1.targetTime ?? Date()) < (entry2.targetTime ?? Date())
            }
    }

    // Group appointments by date
    private var groupedAppointments: [(date: Date, entries: [Entry])] {
        let grouped = Dictionary(grouping: appointments) { entry in
            calendar.startOfDay(for: entry.targetDate)
        }
        return grouped.sorted { $0.key < $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { ($0.targetTime ?? Date()) < ($1.targetTime ?? Date()) }) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Spacer()
                Text("TIME BLOCK")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .tracking(0.3)
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
                        ForEach(groupedAppointments, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                // Date header (larger font)
                                Text(dateHeaderString(for: group.date))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "#1A1A1A"))
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)

                                // Appointments for this date
                                ForEach(group.entries) { entry in
                                    AppointmentTimeRow(entry: entry)
                                }
                            }

                            // Divider between date groups
                            if group.date != groupedAppointments.last?.date {
                                Rectangle()
                                    .fill(Color(hex: "#CBCBCB"))
                                    .frame(height: 0.5)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
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

    private func dateHeaderString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct AppointmentTimeRow: View {
    let entry: Entry

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationService: NotificationService
    @State private var showReminderMenu: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                // Time
                if let time = entry.targetTime {
                    Text(timeString(from: time))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                }

                // Appointment content
                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#666666"))
                        .lineLimit(2)
                }
            }

            Spacer()

            // Reminder info on the right - tappable to adjust or add
            Button(action: {
                showReminderMenu = true
            }) {
                if let reminderOffset = entry.reminderOffsetMinutes {
                    Text(reminderText(minutes: reminderOffset))
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#999999"))
                } else {
                    Image(systemName: "bell")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#CBCBCB"))
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showReminderMenu, arrowEdge: .trailing) {
                VStack(spacing: 8) {
                    Text("REMINDER")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .padding(.bottom, 4)

                    Button("1 day") {
                        setReminder(minutes: 1440)
                    }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

                    Button("1 hour") {
                        setReminder(minutes: 60)
                    }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

                    Button("30 min") {
                        setReminder(minutes: 30)
                    }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)

                    Button("None") {
                        setReminder(minutes: nil)
                    }
                    .font(.system(size: 12))
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .foregroundColor(Color(hex: "#999999"))
                }
                .padding(12)
                .frame(width: 120)
                .background(Color(hex: "#F9F4EA"))
            }

            // Delete button
            Button(action: {
                deleteEntry()
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#CBCBCB"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func setReminder(minutes: Int?) {
        guard let targetTime = entry.targetTime else {
            showReminderMenu = false
            return
        }

        // Update the reminder offset
        entry.reminderOffsetMinutes = minutes
        try? modelContext.save()

        // Cancel any existing notifications for this entry
        notificationService.cancelAllReminders(for: entry.id)

        // Schedule new notification if reminder is set
        if let offsetMinutes = minutes {
            Task {
                // Calculate reminder time
                let reminderTime = targetTime.addingTimeInterval(TimeInterval(-offsetMinutes * 60))

                // Create reminder object
                let reminder = Reminder(
                    entryID: entry.id,
                    reminderTime: reminderTime,
                    offsetMinutes: offsetMinutes,
                    offsetType: .before,
                    notificationTitle: "Upcoming: \(entry.content.isEmpty ? "Event" : entry.content)",
                    notificationBody: "Starting at \(timeString(from: targetTime))"
                )

                // Schedule notification
                let success = await notificationService.scheduleReminder(reminder, for: entry)
                if success {
                    print("✓ Updated notification for \(entry.content) at \(reminderTime)")
                } else {
                    print("✗ Failed to update notification")
                }
            }
        }

        showReminderMenu = false
    }

    private func deleteEntry() {
        // Cancel any notifications for this entry
        notificationService.cancelAllReminders(for: entry.id)

        // Delete the entry from the database
        modelContext.delete(entry)
        try? modelContext.save()
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func reminderText(minutes: Int) -> String {
        switch minutes {
        case 1440:
            return "1d"
        case 60:
            return "1h"
        case 30:
            return "30m"
        default:
            if minutes >= 1440 {
                return "\(minutes / 1440)d"
            } else if minutes >= 60 {
                return "\(minutes / 60)h"
            } else {
                return "\(minutes)m"
            }
        }
    }
}

#Preview {
    CalendarPopoverView()
}
