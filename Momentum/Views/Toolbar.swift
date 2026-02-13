//
//  Toolbar.swift
//  MOMENTUM Planner
//
//  Floating toolbar with collapsible 3-dot toggle
//

import SwiftUI

struct Toolbar: View {
    @State private var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            // Toggle button - 3-dot pill shape
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#666666"))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color(hex: "#666666"))
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color(hex: "#666666"))
                        .frame(width: 4, height: 4)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .stroke(Color(hex: "#CBCBCB"), lineWidth: 0.5)
                )
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            // Tool buttons that slide in from the right
            if isExpanded {
                HStack(spacing: 20) {
                    ToolButton(icon: "square", title: "Image")
                    ToolButton(icon: "pencil.tip", title: "Handwriting")
                    ToolButton(icon: "textformat", title: "Text")
                    ToolButton(icon: "square.on.circle", title: "Shapes")
                    ToolButton(icon: "lasso", title: "Lasso")

                    // Custom A-in-heart icon
                    ZStack {
                        Image(systemName: "suit.heart")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(Color(hex: "#666666"))

                        Text("A")
                            .font(.system(size: 7, weight: .semibold))
                            .foregroundColor(Color(hex: "#666666"))
                            .offset(y: -0.5)
                    }
                    .frame(width: 24, height: 24)
                }
                .padding(.leading, 20)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: "#F9F4EA"))
        .cornerRadius(25)
    }
}

struct ToolButton: View {
    let icon: String
    let title: String

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(Color(hex: "#666666"))
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
    }
}

#Preview {
    Toolbar()
        .background(Color(hex: "#F9F4EA"))
}
