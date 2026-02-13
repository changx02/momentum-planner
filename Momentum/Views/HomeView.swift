//
//  HomeView.swift
//  MOMENTUM Planner
//
//  Home view with planner grid
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedView: NavigationView
    @State private var showNewPlannerPopover = false

    private let planners = [
        PlannerItem(title: "SAAS Planner 2024", image: "saas"),
        PlannerItem(title: "Market Planner 2025", image: "market"),
        PlannerItem(title: "Notebook 2025", image: "notebook"),
        PlannerItem(title: "Art Planner 2025", image: "art")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Spacer for top menu bar
                Spacer()
                    .frame(height: 50)

                // Additional padding to align with sidebar 12 icon
                Spacer()
                    .frame(height: 33)

                // Header - same position as DailyView
                HStack(alignment: .center) {
                    Text("PLANNER")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 20)

                // Planner grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 32) {
                        ForEach(planners) { planner in
                            PlannerCard(planner: planner, selectedView: $selectedView)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(hex: "#F9F4EA"))
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showNewPlannerPopover = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#1A1A1A"))
                                .frame(width: 48, height: 48)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(Color.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showNewPlannerPopover, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
                        NewPlannerPopoverView(isPresented: $showNewPlannerPopover)
                            .presentationCompactAdaptation(.popover)
                    }
                    .padding(40)
                }
            }
        }
    }
}

struct PlannerItem: Identifiable {
    let id = UUID()
    let title: String
    let image: String
}

struct PlannerCard: View {
    let planner: PlannerItem
    @Binding var selectedView: NavigationView

    var body: some View {
        Button(action: {
            selectedView = .daily
        }) {
            VStack(spacing: 0) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#E5E5E5"))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                    )

                // Title
                Text(planner.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))
                    .padding(.top, 12)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AddPlannerCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#F9F4EA"))
            .frame(height: 200)
            .overlay(
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1A1A1A"))
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(12)
            )
    }
}

struct NewPlannerPopoverView: View {
    @Binding var isPresented: Bool
    @State private var plannerName: String = "Untitled Planner"
    @State private var selectedSprint: String = "Three Months"
    @State private var selectedCover: Int? = nil
    @State private var showSprintOptions: Bool = false

    private let sprintOptions = ["Three Months", "Six Months", "One Year"]
    private let coverImages = ["lotus", "lemon", "fruit"] // Placeholder names

    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("NEW PLANNER")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: "#1A1A1A"))

            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                TextField("Untitled Planner", text: $plannerName)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(hex: "#F5F5F5"))
                    .cornerRadius(8)
            }

            // Sprint picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Sprint")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                ZStack(alignment: .topLeading) {
                    // Selected value display
                    Button(action: {
                        showSprintOptions.toggle()
                    }) {
                        HStack {
                            Text(selectedSprint)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#1A1A1A"))
                            Spacer()
                            Image(systemName: showSprintOptions ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#999999"))
                        }
                        .padding(12)
                        .background(Color(hex: "#F5F5F5"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .zIndex(1)

                    // Dropdown options (overlay on top)
                    if showSprintOptions {
                        VStack(spacing: 0) {
                            // Spacer for the button height
                            Color.clear
                                .frame(height: 44)

                            VStack(spacing: 0) {
                                ForEach(sprintOptions.filter { $0 != selectedSprint }, id: \.self) { option in
                                    Button(action: {
                                        selectedSprint = option
                                        showSprintOptions = false
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(Color(hex: "#1A1A1A"))
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color(hex: "#F5F5F5"))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .zIndex(2)
                    }
                }
                .frame(height: 44)
            }

            // Cover selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Cover")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#1A1A1A"))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Import button
                    Button(action: {
                        // Import cover action
                    }) {
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "#999999"))
                            Text("Import")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#999999"))
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundColor(Color(hex: "#CCCCCC"))
                        )
                    }
                    .buttonStyle(.plain)

                    // Cover options
                    ForEach(0..<3, id: \.self) { index in
                        Button(action: {
                            selectedCover = index
                        }) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(index == 0 ? Color(hex: "#5A8F7B") : (index == 1 ? Color(hex: "#C4B454") : Color(hex: "#7B9AC4")))
                                .frame(height: 120)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedCover == index ? Color(hex: "#1A1A1A") : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Create Planner button
            Button(action: {
                // Create planner action
                isPresented = false
            }) {
                Text("Create Planner")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(hex: "#1A1A1A"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(width: 480)
        .background(Color.white)
    }
}

// Extension for selective corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HomeView(selectedView: .constant(.home))
}
