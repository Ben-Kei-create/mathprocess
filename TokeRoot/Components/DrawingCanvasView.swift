import PencilKit
import SwiftUI

struct DrawingCanvasView: UIViewRepresentable {
    let canvas: PKCanvasView
    let toolPicker: PKToolPicker
    var becomesFirstResponder: Bool = true

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        if becomesFirstResponder {
            DispatchQueue.main.async { canvas.becomeFirstResponder() }
        }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
