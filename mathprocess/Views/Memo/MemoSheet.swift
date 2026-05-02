import SwiftUI
import PencilKit

/// Lightweight scratch sheet — a single shared handwritten memo,
/// persisted across problems. Pen/finger input via PencilKit so users
/// can do arithmetic on the side the same way they would on paper.
struct MemoSheet: View {
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PKCanvasView()
    @State private var toolPicker = PKToolPicker()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                Text("計算や考えていることを手書きでメモできます。")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
                CanvasRepresentable(canvas: canvas, toolPicker: toolPicker)
                    .background(TKColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: TKRadius.medium)
                            .stroke(TKColor.divider, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            }
            .padding(TKSpacing.md)
            .background(TKColor.background)
            .navigationTitle("メモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Button("消去") { canvas.drawing = PKDrawing() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.memoDrawingData = canvas.drawing.dataRepresentation()
                        store.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let drawing = try? PKDrawing(data: store.memoDrawingData) {
                    canvas.drawing = drawing
                }
            }
        }
    }
}

private struct CanvasRepresentable: UIViewRepresentable {
    let canvas: PKCanvasView
    let toolPicker: PKToolPicker

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        DispatchQueue.main.async { canvas.becomeFirstResponder() }
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
