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
    @State private var isSavingToPhotos = false
    @State private var photoSaveMessage: String?
    @State private var photoSaveSucceeded = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                Text("計算や考えていることを手書きでメモできます。")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
                DrawingCanvasView(canvas: canvas, toolPicker: toolPicker)
                    .background(TKColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: TKRadius.medium)
                            .stroke(TKColor.divider, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))

                PrimaryButton(
                    isSavingToPhotos ? "保存中" : "写真に保存",
                    systemImage: "photo"
                ) {
                    saveMemoToPhotos()
                }
                .disabled(isSavingToPhotos)
                .opacity(isSavingToPhotos ? 0.55 : 1)

                if let photoSaveMessage {
                    Text(photoSaveMessage)
                        .font(TKType.caption)
                        .foregroundStyle(photoSaveSucceeded ? TKColor.success : TKColor.warm)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
                    Button("アプリに保存") {
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

    private func saveMemoToPhotos() {
        guard !isSavingToPhotos else { return }
        isSavingToPhotos = true
        photoSaveMessage = nil
        photoSaveSucceeded = false

        store.memoDrawingData = canvas.drawing.dataRepresentation()
        store.save()

        Task {
            do {
                try await PhotoLibrarySaveService.shared.saveDrawing(from: canvas)
                photoSaveSucceeded = true
                photoSaveMessage = "写真に保存しました。"
            } catch let error as PhotoLibrarySaveError {
                photoSaveSucceeded = false
                photoSaveMessage = error.studentMessage
            } catch {
                photoSaveSucceeded = false
                photoSaveMessage = "写真への保存で問題が起きました。もう一度試してください。"
            }
            isSavingToPhotos = false
        }
    }
}
