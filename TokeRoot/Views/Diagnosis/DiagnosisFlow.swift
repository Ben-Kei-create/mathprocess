import SwiftUI

/// 「ルート診断テスト」 — 5 problems, no score reveal. Used to pick the
/// initial practice set. The result screen leads with strengths.
struct DiagnosisFlow: View {
    @Environment(ProgressStore.self) private var store
    @Environment(DataService.self) private var data

    let unitId: String

    @State private var index: Int = 0
    @State private var answers: [String: String] = [:]
    @State private var result: DiagnosisResult? = nil

    var body: some View {
        if let result {
            DiagnosisResultView(result: result) {
                store.profile.hasCompletedDiagnosis = true
                store.profile.diagnosisRecommendedSetId = result.recommendedPracticeSetId
                store.lastUnitId = unitId
                if let set = data.practiceSet(id: result.recommendedPracticeSetId),
                   let firstProblem = set.problemIds.first {
                    store.lastProblemId = firstProblem
                }
                store.checkAchievements()
                store.save()
            }
        } else {
            quizContent
        }
    }

    private var problems: [DiagnosisProblem] { data.diagnosis(for: unitId) }

    private var quizContent: some View {
        let p = problems[index]
        return VStack(alignment: .leading, spacing: TKSpacing.lg) {
            HStack {
                Text("ルート診断テスト")
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                Spacer()
                Text("\(index + 1) / \(problems.count)")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }

            ProgressView(value: Double(index + 1), total: Double(problems.count))
                .tint(TKColor.accent)

            EquationCard(text: p.equation, highlight: nil)
                .padding(.top, TKSpacing.sm)

            Text(p.questionPrompt)
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)

            VStack(spacing: TKSpacing.sm) {
                ForEach(p.choices) { c in
                    ChoiceButton(label: c.label, state: .idle) {
                        answers[p.id] = c.id
                        advance()
                    }
                }
            }

            Spacer()

            Button("わからないので飛ばす") { advance() }
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.lg)
        .background(TKColor.background.ignoresSafeArea())
    }

    private func advance() {
        if index + 1 < problems.count {
            withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
        } else {
            let r = RouteEngine().diagnose(answers: answers)
            withAnimation(.easeInOut) { result = r }
        }
    }
}
