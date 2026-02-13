//
//  NotesView.swift
//  MOMENTUM Planner
//
//  Notes view with grid pattern
//

import SwiftUI
import SwiftData

struct NotesView: View {
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 1
    @State private var showDeleteAlert: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Query private var allNotePages: [NotePage]

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

                // Page indicator/add button on the right
                if totalPages > 1 {
                    HStack(spacing: 8) {
                        Text("\(currentPage)/\(totalPages)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .padding(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                            )

                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(Color(hex: "#999999"))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: 28)
                } else {
                    HStack(spacing: 8) {
                        Text("Swipe up to add.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "#999999"))

                        Button(action: {
                            addNewPage()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(hex: "#1A1A1A"))
                                .padding(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: 28)
                }
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
            .onAppear {
                updatePageInfo()
            }
            .onChange(of: selectedDate) { _, _ in
                updatePageInfo()
            }
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Delete Page", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCurrentPage()
            }
        } message: {
            Text("Are you sure you want to delete this page?")
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    let horizontalSwipe = abs(value.translation.width) > abs(value.translation.height)

                    if horizontalSwipe {
                        // Horizontal swipe - change day
                        if value.translation.width < -50 {
                            // Swipe left - go to next day
                            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                                selectedDate = nextDay
                                currentPage = 1
                            }
                        } else if value.translation.width > 50 {
                            // Swipe right - go to previous day
                            if let prevDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
                                selectedDate = prevDay
                                currentPage = 1
                            }
                        }
                    } else {
                        // Vertical swipe - change page within the same day
                        if value.translation.height < -50 {
                            // Swipe up - go to next page
                            if currentPage < totalPages {
                                currentPage += 1
                            } else {
                                // Create new page
                                addNewPage()
                            }
                        } else if value.translation.height > 50 {
                            // Swipe down - go to previous page
                            if currentPage > 1 {
                                currentPage -= 1
                            }
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

    // MARK: - Page Management

    private func updatePageInfo() {
        let pagesForDate = allNotePages.filter { page in
            calendar.isDate(page.date, inSameDayAs: selectedDate)
        }.sorted { $0.pageNumber < $1.pageNumber }

        totalPages = max(pagesForDate.count, 1)

        // Ensure current page is valid
        if currentPage > totalPages {
            currentPage = totalPages
        }

        // Create first page if none exists
        if pagesForDate.isEmpty {
            addNewPage()
        }
    }

    private func addNewPage() {
        let pagesForDate = allNotePages.filter { page in
            calendar.isDate(page.date, inSameDayAs: selectedDate)
        }

        let newPageNumber = pagesForDate.count + 1
        let newPage = NotePage(date: selectedDate, pageNumber: newPageNumber, content: "")

        modelContext.insert(newPage)
        try? modelContext.save()

        totalPages = newPageNumber
        currentPage = newPageNumber
    }

    private func deleteCurrentPage() {
        let pagesForDate = allNotePages.filter { page in
            calendar.isDate(page.date, inSameDayAs: selectedDate)
        }.sorted { $0.pageNumber < $1.pageNumber }

        guard currentPage <= pagesForDate.count else { return }

        let pageToDelete = pagesForDate[currentPage - 1]
        modelContext.delete(pageToDelete)

        // Renumber remaining pages
        for (index, page) in pagesForDate.enumerated() where page.pageNumber > currentPage {
            page.pageNumber = index
        }

        try? modelContext.save()

        // Update state
        totalPages = max(pagesForDate.count - 1, 1)
        if currentPage > totalPages {
            currentPage = totalPages
        }

        // If we deleted the last page, create a new one
        if pagesForDate.count == 1 {
            addNewPage()
        }
    }
}

#Preview {
    NotesView(selectedView: .constant(.notes), selectedDate: .constant(Date()))
}
