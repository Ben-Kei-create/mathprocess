import SwiftUI

/// 「ここだけ特訓」 — runs through the problems in a `PracticeSet` and,
/// when finished, gently invites the user to return to the original.
struct PracticeRunnerView: View {
    let practiceSetId: String
    @Environment(DataService.self) private var data
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var done = false

    var body: some View {
        Group {
            if let set = data.practiceSet(id: practiceSetId) {
                if done {
                    completion(set)
                } else if index < set.problemIds.count {
                    runner(set)
                } else {
                    completion(set)
                        .onAppear { done = true }
                }
            } else {
                Text("セットが見つかりませんでした。")
                    .padding()
            }
        }
        .background(TKColor.background.ignoresSafeArea())
        .navigationTitle("ここだけ特訓")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runner(_ set: PracticeSet) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(set.title)
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                Spacer()
                Text("\(index + 1) / \(set.problemIds.count)")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
            .padding(.horizontal, TKSpacing.md)
            .padding(.top, TKSpacing.sm)

            ProblemView(problemId: set.problemIds[index]) {
                if index + 1 < set.problemIds.count {
                    withAnimation { index += 1 }
                } else {
                    withAnimation { done = true }
                }
            }
            .id(set.problemIds[index])  // resets ProblemView state per problem
        }
    }

    private func completion(_ set: PracticeSet) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.lg) {
            Text("特訓おつかれさまでした。")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text("「\(set.title)」を最後までやりました。\n元の問題に戻ると、解きやすくなっています。")
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
            Spacer()
            PrimaryButton("元の問題に戻る", systemImage: "arrow.uturn.left") {
                dismiss()
            }
            PrimaryButton("ホームに戻る", style: .soft) {
                dismiss()
            }
        }
        .padding(TKSpacing.md)
    }
}
