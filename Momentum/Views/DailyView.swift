//
//  DailyView.swift
//  Aplyzia Planner
//
//  Daily view with three-column layout (Focus Points, Action List, Notes)
//

import SwiftUI
import SwiftData
import PencilKit

struct DailyView: View {
    let date: Date
    @Binding var selectedView: NavigationView
    @Binding var selectedDate: Date
    var searchText: String = ""
    var highlightedEntryID: UUID? = nil

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [Entry]

    // TODO: Re-enable handwriting when PKCanvasView is ported to macOS
    // @State private var canvasView = PKCanvasView()
    @State private var showHandwritingCanvas = false
    @State private var editingTaskID: UUID?
    @State private var newTaskText: String = ""
    @State private var showToolbar = true
    @State private var showActionListHelp = false

    private let calendar = Calendar.current

    // Filtered entries for today
    private var entries: [Entry] {
        let filtered = allEntries.filter { entry in
            let matches = calendar.isDate(entry.targetDate, inSameDayAs: date)
            // Debug: Print entry dates to console
            print("Entry '\(entry.content.prefix(20))' targetDate: \(entry.targetDate), currentDate: \(date), matches: \(matches)")
            return matches
        }
        print("Total entries for \(date): \(filtered.count) out of \(allEntries.count)")
        return filtered
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

            // Three-column layout
            GeometryReader { geometry in
                let focusPointsHeight: CGFloat = 310 // 280px box + 30px for title and spacing
                let timeBlockHeight = geometry.size.height - focusPointsHeight - 16
                let actionListHeight = geometry.size.height
                let todaysWinHeight: CGFloat = 84
                let notesHeight = geometry.size.height - todaysWinHeight - 16 - 60 - 20

                // Calculate responsive widths
                let availableWidth = geometry.size.width - 80 - 32 // minus padding and spacing
                let leftWidth = availableWidth * 0.278
                let centerWidth = availableWidth * 0.314
                let rightWidth = availableWidth * 0.408

                HStack(alignment: .top, spacing: 16) {
                    // Left Column
                    VStack(alignment: .leading, spacing: 0) {
                        focusPointsSection
                        Spacer()
                            .frame(height: 48)
                        timeBlockSection(height: timeBlockHeight - 48)
                    }
                    .frame(width: leftWidth)

                    // Center Column
                    VStack(spacing: 0) {
                        actionListSection(height: actionListHeight)
                    }
                    .frame(width: centerWidth)

                    // Right Column
                    VStack(spacing: 0) {
                        notesSectionView(gridHeight: notesHeight - 30)
                        Spacer()
                            .frame(height: 48)
                        todaysWinSection
                    }
                    .frame(width: rightWidth)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
        .background(Color(hex: "#F9F4EA"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture()
                .onEnded { value in
                    let horizontalMovement = value.translation.width

                    if horizontalMovement < -50 {
                        if let nextDay = calendar.date(byAdding: .day, value: 1, to: date) {
                            selectedDate = nextDay
                        }
                    } else if horizontalMovement > 50 {
                        if let previousDay = calendar.date(byAdding: .day, value: -1, to: date) {
                            selectedDate = previousDay
                        }
                    }
                }
        )
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .center) {
            // Date on the left
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(dayName)
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
    }

    // MARK: - Focus Points Section

    private var focusPointsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section title OUTSIDE the box
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("FOCUS POINTS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .tracking(0.3)

                Text("Most important tasks.")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color(hex: "#999999"))
            }
            .frame(height: 22, alignment: .leading)

            // Box with borders and content
            ZStack(alignment: .topLeading) {
                // Background same as page
                Color(hex: "#F9F4EA")

                // Task rows
                VStack(spacing: 0) {
                    ForEach(0..<10) { index in
                        VStack(spacing: 0) {
                            FocusPointRow(
                                entry: focusPointEntries.indices.contains(index) ? focusPointEntries[index] : nil,
                                rowIndex: index,
                                searchText: searchText,
                                isHighlighted: focusPointEntries.indices.contains(index) && focusPointEntries[index].id == highlightedEntryID,
                                onTextChange: { updateTaskContent($0, $1) },
                                onToggleComplete: { toggleTask($0) },
                                onCreateEntry: { _ in addNewTask(type: .focusPoint) }
                            )

                            // Horizontal ruled line
                            Rectangle()
                                .fill(Color(hex: "#CBCBCB"))
                                .frame(height: 0.5)
                        }
                    }
                }
                .overlay(alignment: .topLeading) {
                    // Custom drawing for borders and vertical margin line
                    GeometryReader { geometry in
                        Path { path in
                            // Draw left border
                            path.move(to: CGPoint(x: 0.5, y: 0))
                            path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))

                            // Draw top border
                            path.move(to: CGPoint(x: 0, y: 0.5))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: 0.5))

                            // Draw vertical margin line at x=28
                            path.move(to: CGPoint(x: 28, y: 0))
                            path.addLine(to: CGPoint(x: 28, y: geometry.size.height))
                        }
                        .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                    }
                }
            }
            .frame(minHeight: 280)
        }
    }

    // MARK: - Action List Section

    private func actionListSection(height: CGFloat) -> some View {
        let titleHeight: CGFloat = 30
        let rowCount = 22
        let boxHeight = CGFloat(rowCount) * 27.5

        return VStack(alignment: .leading, spacing: 8) {
            // Section title OUTSIDE the box
            HStack {
                Text("ACTION LIST")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .tracking(0.3)

                Button(action: {
                    showActionListHelp.toggle()
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                            .frame(width: 18, height: 18)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#666666"))
                    }
                    .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showActionListHelp, arrowEdge: .leading) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mark your task to finish, move, or make it important.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Making a task important or starring it, will show up on your monthly calendar and weekly focus.")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .frame(width: 16)
                                Text("DONE")
                                    .font(.system(size: 12, weight: .medium))
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .frame(width: 16)
                                Text("MOVE")
                                    .font(.system(size: 12, weight: .medium))
                            }

                            HStack(spacing: 8) {
                                Image(systemName: "star")
                                    .font(.system(size: 12))
                                    .frame(width: 16)
                                Text("IMPORTANT")
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                        .foregroundColor(Color(hex: "#666666"))
                    }
                    .padding(20)
                    .frame(width: 280)
                    .background(Color(hex: "#F1F1F1"))
                }
            }
            .frame(height: 22, alignment: .leading)

            // Box with borders and content
            ZStack(alignment: .topLeading) {
                Color(hex: "#F9F4EA")

                GeometryReader { geometry in
                    let verticalLineHeight: CGFloat = 605

                    Path { path in
                        // Draw left border
                        path.move(to: CGPoint(x: 0.5, y: 0))
                        path.addLine(to: CGPoint(x: 0.5, y: verticalLineHeight))

                        // Draw top border
                        path.move(to: CGPoint(x: 0, y: 0.5))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0.5))

                        // Draw vertical margin line at x=28
                        path.move(to: CGPoint(x: 28, y: 0))
                        path.addLine(to: CGPoint(x: 28, y: verticalLineHeight))
                    }
                    .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                }

                VStack(spacing: 0) {
                    ForEach(0..<min(actionListEntries.count, rowCount), id: \.self) { index in
                        SimpleTaskRow(
                            entry: actionListEntries[index],
                            onTextChange: { updateTaskContent($0, $1) },
                            leftPadding: 16,
                            showBottomLine: true
                        )
                    }

                    ForEach(min(actionListEntries.count, rowCount)..<rowCount, id: \.self) { index in
                        SimpleTaskRow(
                            entry: nil,
                            onTextChange: { _, _ in },
                            leftPadding: 16,
                            showBottomLine: true
                        )
                    }
                }
            }
            .frame(height: boxHeight)
        }
    }

    // MARK: - Notes Section

    private func notesSectionView(gridHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                selectedView = .notes
            }) {
                Text("NOTES")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .tracking(0.3)
            }
            .buttonStyle(.plain)
            .frame(height: 22, alignment: .leading)

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
            .frame(height: gridHeight)
        }
    }

    // MARK: - Time Block Section

    private func timeBlockSection(height: CGFloat) -> some View {
        let rowCount = 9
        let boxHeight: CGFloat = CGFloat(rowCount) * 27.5

        return VStack(alignment: .leading, spacing: 8) {
            Text("TIME BLOCK")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .tracking(0.3)
                .frame(height: 22, alignment: .leading)

            ZStack(alignment: .topLeading) {
                Color(hex: "#F9F4EA")

                GeometryReader { geometry in
                    let verticalLineHeight: CGFloat = CGFloat(rowCount - 1) * 27.5 + 27

                    Path { path in
                        // Draw top border
                        path.move(to: CGPoint(x: 0, y: 0.5))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0.5))

                        // Draw vertical margin line at x=65
                        path.move(to: CGPoint(x: 65, y: 0))
                        path.addLine(to: CGPoint(x: 65, y: verticalLineHeight))
                    }
                    .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                }

                VStack(spacing: 0) {
                    ForEach(0..<rowCount, id: \.self) { index in
                        SimpleTaskRow(
                            entry: nil,
                            onTextChange: { _, _ in },
                            leftPadding: 16,
                            showBottomLine: true
                        )
                    }
                }
            }
            .frame(height: boxHeight)
        }
    }

    // MARK: - Today's Win Section

    private var todaysWinSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY'S WIN")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#1A1A1A"))
                .tracking(0.3)
                .frame(height: 22, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(0..<2) { index in
                    SimpleTaskRow(
                        entry: nil,
                        onTextChange: { _, _ in },
                        showBottomLine: true
                    )
                }
            }
        }
    }


    // MARK: - Computed Properties

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).uppercased()
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private var timeSlots: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"

        var slots: [String] = []
        for hour in [6, 7, 8, 9, 10, 11, 12, 1, 2, 3, 4, 5] {
            let isPM = hour <= 5 && slots.count >= 7
            slots.append(hour == 12 ? "12 PM" : "\(hour) \(isPM ? "PM" : "AM")")
        }
        return slots
    }

    private var focusPointEntries: [Entry] {
        entries.filter { $0.entryType == .task && $0.taskSection == .focusPoint }
            .prefix(7)
            .map { $0 }
    }

    private var actionListEntries: [Entry] {
        entries.filter { $0.entryType == .task && $0.taskSection == .actionList }
    }

    // MARK: - Actions

    private func toggleTask(_ entry: Entry) {
        entry.isCompleted.toggle()
        entry.completedDate = entry.isCompleted ? Date() : nil
        try? modelContext.save()
    }

    private func toggleStar(_ entry: Entry) {
        entry.isStarred.toggle()
        try? modelContext.save()
    }

    private func updateTaskContent(_ entry: Entry, _ newContent: String) {
        entry.content = newContent
        try? modelContext.save()
    }

    private func addNewTask(type: TaskType) -> Entry {
        let newEntry = Entry(
            content: "",
            entryType: .task,
            targetDate: date,
            hasCheckbox: true
        )
        // Set taskSection based on type
        switch type {
        case .focusPoint:
            newEntry.taskSection = .focusPoint
        case .actionList:
            newEntry.taskSection = .actionList
        }
        modelContext.insert(newEntry)
        try? modelContext.save()
        return newEntry
    }

    private func handleRecognizedText(_ text: String, dates: [RecognizedDate], times: [RecognizedTime]) {
        // Create new entry with recognized text
        let newEntry = Entry(
            content: text,
            entryType: .task,
            targetDate: dates.first?.date ?? date,
            targetTime: times.first?.time,
            hasCheckbox: true
        )

        modelContext.insert(newEntry)
        try? modelContext.save()

        // Show routing prompt if dates/times were found
        if !dates.isEmpty || !times.isEmpty {
            // Show routing and reminder prompt
        }
    }
}

// MARK: - Supporting Views

// Custom Shape for drawing partial borders
struct EdgeBorder: Shape {
    var edges: [Edge]
    var lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for edge in edges {
            switch edge {
            case .top:
                path.move(to: CGPoint(x: rect.minX, y: rect.minY + lineWidth / 2))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + lineWidth / 2))
            case .bottom:
                path.move(to: CGPoint(x: rect.minX, y: rect.maxY - lineWidth / 2))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - lineWidth / 2))
            case .leading:
                path.move(to: CGPoint(x: rect.minX + lineWidth / 2, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.minX + lineWidth / 2, y: rect.maxY))
            case .trailing:
                path.move(to: CGPoint(x: rect.maxX - lineWidth / 2, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.maxX - lineWidth / 2, y: rect.maxY))
            }
        }

        return path
    }
}

struct FocusPointRow: View {
    let entry: Entry?
    let rowIndex: Int
    var searchText: String = ""
    var isHighlighted: Bool = false
    let onTextChange: ((Entry, String) -> Void)?
    let onToggleComplete: ((Entry) -> Void)?
    let onCreateEntry: ((Int) -> Entry)?

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Column 1: Invisible checkbox (28px wide to match the vertical line)
            Button(action: {
                if let entry = entry {
                    onToggleComplete?(entry)
                }
            }) {
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 28, height: 27)

                    if let entry = entry, entry.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(hex: "#1A1A1A"))
                    }
                }
            }
            .buttonStyle(.plain)

            // Column 2: Read-only text with wrapping and highlighting
            ZStack(alignment: .leading) {
                if isHighlighted && !searchText.isEmpty && entry != nil {
                    // Show highlighted text view when searching
                    highlightedTextView(text: entry?.content ?? "", searchText: searchText)
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 6)
                } else {
                    // Show read-only text
                    Text(entry?.content ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                        .padding(.trailing, 8)
                        .padding(.vertical, 6)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHighlighted ? Color.yellow.opacity(0.3) : Color.clear)
        }
        .frame(minHeight: 27)
    }

    private func highlightedTextView(text: String, searchText: String) -> some View {
        let attributedString = highlightMatches(in: text, searchText: searchText)
        return Text(attributedString)
            .font(.system(size: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func highlightMatches(in text: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(text)
        let lowercasedText = text.lowercased()
        let lowercasedSearch = searchText.lowercased()

        var searchStartIndex = lowercasedText.startIndex
        while searchStartIndex < lowercasedText.endIndex,
              let range = lowercasedText.range(of: lowercasedSearch, range: searchStartIndex..<lowercasedText.endIndex) {

            let attributedRange = Range(range, in: attributedString)
            if let attributedRange = attributedRange {
                attributedString[attributedRange].backgroundColor = .yellow
                attributedString[attributedRange].foregroundColor = .black
            }
            searchStartIndex = range.upperBound
        }

        return attributedString
    }
}

struct SimpleTaskRow: View {
    let entry: Entry?
    let onTextChange: ((Entry, String) -> Void)?
    let leftPadding: CGFloat
    let showBottomLine: Bool

    @State private var editText: String = ""
    @FocusState private var isFocused: Bool

    init(entry: Entry?,
         onTextChange: ((Entry, String) -> Void)?,
         leftPadding: CGFloat = 16,
         showBottomLine: Bool = true) {
        self.entry = entry
        self.onTextChange = onTextChange
        self.leftPadding = leftPadding
        self.showBottomLine = showBottomLine
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Action box on the left (no checkbox)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 10, height: 10)

                if let entry = entry {
                    // Editable text field
                    TextField("", text: $editText, axis: .vertical)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#1A1A1A"))
                        .focused($isFocused)
                        .onAppear {
                            editText = entry.content
                        }
                        .onChange(of: editText) { oldValue, newValue in
                            onTextChange?(entry, newValue)
                        }
                        .onSubmit {
                            isFocused = false
                        }
                } else {
                    Spacer()
                }

                Spacer()
            }
            .padding(.leading, leftPadding)
            .frame(height: 27)

            // Horizontal ruled line
            if showBottomLine {
                Rectangle()
                    .fill(Color(hex: "#CBCBCB"))
                    .frame(height: 0.5)
            }
        }
    }
}

struct GridPatternView: View {
    let gridSize: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let columns = Int(geometry.size.width / gridSize)
                let rows = Int(geometry.size.height / gridSize)

                let horizontalSpacing = geometry.size.width / CGFloat(columns)
                let verticalSpacing = geometry.size.height / CGFloat(rows)

                // Draw horizontal lines
                for row in 0...rows {
                    let y = CGFloat(row) * verticalSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }

                // Draw vertical lines
                for column in 0...columns {
                    let x = CGFloat(column) * horizontalSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                }
            }
            .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
            .opacity(0.65)
        }
    }
}

enum TaskType {
    case focusPoint
    case actionList
}
