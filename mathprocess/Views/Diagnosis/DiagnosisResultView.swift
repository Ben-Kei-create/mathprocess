import SwiftUI

/// Result screen — strengths first, then a single positive recommendation.
/// Deliberately no score, no percentage, no big number.
struct DiagnosisResultView: View {
    let result: DiagnosisResult
    let onContinue: () -> Void
    @Environment(DataService.self) private var data

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.lg) {
            Text("ルートが決まりました")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)

            Text(result.kindMessage)
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
                .padding(TKSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TKColor.successSoft)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))

            if !result.strengths.isEmpty {
                SectionCard("できていること") {
                    VStack(alignment: .leading, spacing: TKSpacing.xs) {
                        ForEach(result.strengths, id: \.self) { s in
                            HStack(spacing: TKSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(TKColor.success)
                                Text(s).foregroundStyle(TKColor.textPrimary)
                            }
                        }
                    }
                }
            }

            if let set = data.practiceSet(id: result.recommendedPracticeSetId) {
                SectionCard("次に練習すること") {
                    VStack(alignment: .leading, spacing: TKSpacing.xs) {
                        Text(set.title)
                            .font(TKType.subtitle)
                            .foregroundStyle(TKColor.textPrimary)
                        Text("\(set.problemIds.count)問・短時間で終わります")
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textSecondary)
                    }
                }
            }

            Spacer()

            PrimaryButton("おすすめルートで始める", systemImage: "arrow.right") {
                onContinue()
            }
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.lg)
        .padding(.bottom, TKSpacing.lg)
        .background(TKColor.background.ignoresSafeArea())
    }
}
