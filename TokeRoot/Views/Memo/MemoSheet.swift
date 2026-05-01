import SwiftUI

/// Lightweight scratch sheet — a single shared memo, persisted across
/// problems. Just enough for "do the arithmetic on the side."
struct MemoSheet: View {
    @Environment(ProgressStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                Text("計算や考えていることをメモできます。")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
                TextEditor(text: $draft)
                    .font(TKType.body)
                    .scrollContentBackground(.hidden)
                    .padding(TKSpacing.sm)
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
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.memoText = draft
                        store.save()
                        dismiss()
                    }
                }
            }
            .onAppear { draft = store.memoText }
        }
    }
}
