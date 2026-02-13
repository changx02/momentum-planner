//
//  Sidebar.swift
//  MOMENTUM Planner
//
//  Navigation sidebar with month/week navigation
//  V9 Design: Collapsed by default
//

import SwiftUI

struct Sidebar: View {
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date
    var onCollapse: () -> Void

    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Yearly view button (12)
            Button(action: { selectedView = .yearly }) {
                Text("12")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selectedView == .yearly ? Color(hex: "#1A1A1A") : Color(hex: "#666666"))
                    .frame(width: 50, height: 40)
                    .background(selectedView == .yearly ? Color(hex: "#CBCBCB") : Color.clear)
                    .cornerRadius(4)
            }
            .padding(.top, 100)

            // Daily view button (DAY)
            Button(action: {
                selectedDate = Date() // Set to current date/time
                selectedView = .daily
            }) {
                Text("DAY")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedView == .daily ? Color(hex: "#1A1A1A") : Color(hex: "#666666"))
                    .frame(width: 50, height: 40)
                    .background(selectedView == .daily ? Color(hex: "#CBCBCB") : Color.clear)
                    .cornerRadius(4)
            }

            // Weekly view button (WKS)
            Button(action: {
                selectedDate = Date() // Set to current date/time
                selectedView = .weekly
            }) {
                Text("WKS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedView == .weekly ? Color(hex: "#1A1A1A") : Color(hex: "#666666"))
                    .frame(width: 50, height: 40)
                    .background(selectedView == .weekly ? Color(hex: "#CBCBCB") : Color.clear)
                    .cornerRadius(4)
            }

            // All 12 months (JAN-DEC) - expandable/collapsible
            if isExpanded {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(monthNames.enumerated()), id: \.element) { index, month in
                            Button(action: {
                                // Create date for first day of this month in current year
                                let calendar = Calendar.current
                                let currentYear = calendar.component(.year, from: selectedDate)
                                var components = DateComponents()
                                components.year = currentYear
                                components.month = index + 1 // month is 1-indexed
                                components.day = 1

                                if let newDate = calendar.date(from: components) {
                                    selectedDate = newDate
                                    selectedView = .monthly
                                }
                            }) {
                                Text(month)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "#666666"))
                                    .frame(width: 50, height: 28)
                            }
                        }
                    }
                }
            } else {
                // Collapsed: Show current month only
                Button(action: { isExpanded.toggle() }) {
                    Text(currentMonthAbbreviation)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#666666"))
                        .frame(width: 50, height: 28)
                }
            }

            // Spacer to push NOTE to the bottom
            Spacer()

            // Notes button
            Button(action: { selectedView = .notes }) {
                Text("NOTE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedView == .notes ? Color(hex: "#1A1A1A") : Color(hex: "#666666"))
                    .frame(width: 50, height: 40)
                    .background(selectedView == .notes ? Color(hex: "#CBCBCB") : Color.clear)
                    .cornerRadius(4)
            }

            // Bottom padding
            Spacer()
                .frame(height: 30)
        }
        .frame(width: 60)
        .padding(.vertical, 0)
        .background(Color(hex: "#F9F4EA"))
        .edgesIgnoringSafeArea(.all)
    }

    private var monthNames: [String] {
        ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    }

    private var currentMonthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedDate).uppercased()
    }
}

#Preview {
    Sidebar(
        selectedView: .constant(.daily),
        selectedDate: .constant(Date()),
        onCollapse: { }
    )
}
