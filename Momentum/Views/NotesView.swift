//
//  NotesView.swift
//  MOMENTUM Planner
//
//  Notes view with grid pattern
//

import SwiftUI

struct NotesView: View {
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date

    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 0) {
            // Spacer for top menu bar
            Spacer()
                .frame(height: 50)

            // Additional padding to align with sidebar 12 icon
            Spacer()
                .frame(height: 33)

            // Header - same position as DailyView
            HStack(alignment: .center) {
                // Date on the left
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("NOTES")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text(dateString)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                }

                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 20)

            // Grid area
            ZStack(alignment: .topLeading) {
                Color(hex: "#F9F4EA")

                GridPatternView()

                GeometryReader { geometry in
                    Path { path in
                        path.addRect(CGRect(x: 0.5, y: 0.5, width: geometry.size.width - 1, height: geometry.size.height - 1))
                    }
                    .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 45)
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    // Swipe left = next day, Swipe right = previous day
                    if value.translation.width < -50 {
                        // Swipe left - go to next day
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                            selectedDate = nextDay
                        }
                    } else if value.translation.width > 50 {
                        // Swipe right - go to previous day
                        if let prevDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                            selectedDate = prevDay
                        }
                    }
                }
        )
    }

    // MARK: - Date Formatting

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: selectedDate)
    }
}

#Preview {
    NotesView(selectedView: .constant(.notes), selectedDate: .constant(Date()))
}
