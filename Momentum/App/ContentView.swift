//
//  ContentView.swift
//  Aplyzia Planner
//
//  Main container view with sidebar navigation
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedView: NavigationView = .home
    @State private var selectedDate: Date = Date()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isSearchActive: Bool = false
    @State private var searchText: String = ""
    @State private var showCalendarPopover: Bool = false
    @StateObject private var searchManager = SearchManager()

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    var body: some View {
        ZStack {
            // Main layout with manual sidebar
            HStack(spacing: 0) {
                // Sidebar
                if columnVisibility == .all {
                    Sidebar(
                        selectedView: $selectedView,
                        selectedDate: $selectedDate,
                        onCollapse: {
                            columnVisibility = .detailOnly
                        }
                    )
                    .frame(width: 60)
                }

                // Main content area
                ZStack {
                    // Canvas background - warm cream
                    Color(hex: "#FBF8F3")
                        .ignoresSafeArea()

                    // Main view
                    viewForSelection()
                }
            }
            .background(Color(hex: "#F9F4EA"))
            .ignoresSafeArea()

            // Fixed top menu bar overlay (top layer over everything)
            VStack(spacing: 0) {
                ZStack {
                    // Left side: Sidebar toggle, Home, Undo, Redo
                    HStack(spacing: 12) {
                        // Sidebar toggle button (always visible)
                        Button(action: {
                            withAnimation {
                                columnVisibility = columnVisibility == .all ? .detailOnly : .all
                            }
                        }) {
                            Image(systemName: "sidebar.left")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "#666666"))
                        }
                        .buttonStyle(.plain)

                        // Hide these buttons on home page
                        if selectedView != .home {
                            Button(action: {
                                selectedView = .home
                            }) {
                                Image(systemName: "house")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color(hex: "#666666"))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                // Undo action
                            }) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color(hex: "#666666"))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                // Redo action
                            }) {
                                Image(systemName: "arrow.uturn.forward")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color(hex: "#666666"))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Center: Toolbar (hide on home page)
                    if selectedView != .home {
                        Toolbar()
                    }

                    // Right side: Calendar and Search
                    HStack(spacing: 12) {
                        Spacer()

                        Button(action: {
                            showCalendarPopover.toggle()
                        }) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "#666666"))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showCalendarPopover, arrowEdge: .top) {
                            CalendarPopoverView()
                                .frame(width: 300)
                        }

                        // Search bar with fixed width
                        HStack(spacing: 8) {
                            if isSearchActive {
                                HStack(spacing: 8) {
                                    TextField("Search", text: $searchText)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#1A1A1A"))
                                        .onChange(of: searchText) { newValue in
                                            searchManager.search(query: newValue, in: allEntries)
                                        }

                                    Spacer()

                                    if !searchText.isEmpty {
                                        // Result counter
                                        if !searchManager.results.isEmpty {
                                            Text("\(searchManager.currentIndex + 1)/\(searchManager.results.count)")
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "#666666"))
                                                .fixedSize()
                                        }

                                        // Navigation arrows
                                        if searchManager.results.count > 1 {
                                            Button(action: {
                                                searchManager.previousResult()
                                                navigateToResult()
                                            }) {
                                                Image(systemName: "chevron.up")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(hex: "#666666"))
                                            }
                                            .buttonStyle(.plain)

                                            Button(action: {
                                                searchManager.nextResult()
                                                navigateToResult()
                                            }) {
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color(hex: "#666666"))
                                            }
                                            .buttonStyle(.plain)
                                        }

                                        Button(action: {
                                            searchText = ""
                                            searchManager.results = []
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(hex: "#999999"))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .frame(width: 300)
                                .background(Color(hex: "#FFFFFF"))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isSearchActive.toggle()
                                    if !isSearchActive {
                                        searchText = ""
                                        searchManager.results = []
                                    }
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(Color(hex: "#666666"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing, 40)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color(hex: "#F9F4EA"))
                .frame(height: 50)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func viewForSelection() -> some View {
        switch selectedView {
        case .home:
            HomeView(selectedView: $selectedView)
        case .daily:
            DailyView(
                date: selectedDate,
                selectedView: $selectedView,
                selectedDate: $selectedDate,
                searchText: searchText,
                highlightedEntryID: searchManager.currentResult?.entry.id
            )
        case .weekly:
            WeeklyView(date: $selectedDate)
        case .monthly:
            MonthlyView(date: selectedDate, selectedView: $selectedView, selectedDate: $selectedDate)
        case .yearly:
            YearlyView(year: Calendar.current.component(.year, from: selectedDate), selectedView: $selectedView, selectedDate: $selectedDate)
        case .notes:
            NotesView(selectedView: $selectedView, selectedDate: $selectedDate)
        }
    }

    // MARK: - Search Navigation

    private func navigateToResult() {
        guard let result = searchManager.currentResult else { return }

        // Navigate to the date of the current search result
        selectedDate = result.date
        selectedView = .daily
    }
}

enum NavigationView {
    case home
    case yearly
    case monthly
    case weekly
    case daily
    case notes
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
