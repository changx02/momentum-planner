//
//  GestureCanvasView.swift
//  Momentum Planner
//
//  Canvas for capturing handwritten gestures (checkmarks, arrows)
//

import SwiftUI
import PencilKit

struct GestureCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onGestureRecognized: (RecognizedGesture) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvas.drawingPolicy = .anyInput // Allow both finger and pencil

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: GestureCanvasView

        init(parent: GestureCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing

            // Recognize gesture after each stroke
            if let gesture = GestureRecognitionEngine.shared.recognizeGesture(from: canvasView.drawing) {
                // Clear the canvas after recognition
                canvasView.drawing = PKDrawing()

                // Notify parent
                parent.onGestureRecognized(gesture)
            }
        }
    }
}

// Simplified gesture canvas for SwiftUI
struct SimpleGestureCanvas: View {
    let onGestureRecognized: (RecognizedGesture) -> Void

    @State private var drawing = PKDrawing()

    var body: some View {
        GestureCanvasView(drawing: $drawing, onGestureRecognized: onGestureRecognized)
    }
}
