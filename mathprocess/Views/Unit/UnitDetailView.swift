import SwiftUI

/// Shows all main problems of a unit grouped by 難易度 (Lv.1 → Lv.5).
/// Each row shows: title, equation, ✓ if cleared, 🔒 if locked behind a
/// difficulty gate. Tapping an unlocked row opens that problem.
struct UnitDetailView: View {
    let unitId: String
    @Environment(DataService.self) private var data
    @Environment(ProgressStore.self) private var store

    private var engine: RouteEngine { RouteEngine() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TKSpacing.lg) {
                header
                progressBar
                ForEach(difficultyLevels, id: \.self) { lv in
                    levelSection(lv)
                }
            }
            .padding(.horizontal, TKSpacing.md)
            .padding(.top, TKSpacing.md)
            .padding(.bottom, TKSpacing.xl)
        }
        .background(TKColor.background.ignoresSafeArea())
        .navigationTitle(unit?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var unit: MathUnit? { data.unit(id: unitId) }
    private var unitProblems: [Problem] { data.problems(in: unitId) }

    private var difficultyLevels: [Int] {
        Array(Set(unitProblems.map(\.difficulty))).sorted()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            if let sub = unit?.subtitle {
                Text(sub)
                    .font(TKType.body)
                    .foregroundStyle(TKColor.textSecondary)
            }
            Text("難易度が上がるごとに、新しい考え方が1つだけ増えます。")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
        }
    }

    private var progressBar: some View {
        let total = unitProblems.count
        let done  = unitProblems.filter { store.isSolved($0.id) }.count
        let pct   = total == 0 ? 0 : Double(done) / Double(total)
        return SectionCard("進み具合") {
            VStack(alignment: .leading, spacing: TKSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(done) / \(total)")
                        .font(TKType.title)
                        .foregroundStyle(TKColor.textPrimary)
                    Text("問クリア")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                    Spacer()
                    Text("Lv.\(maxClearedLevel) まで開放")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.success)
                }
                ProgressView(value: pct)
                    .tint(TKColor.accent)
            }
        }
    }

    private var maxClearedLevel: Int {
        max(1, engine.clearedDifficulty(in: unitId) + 1)
    }

    @ViewBuilder
    private func levelSection(_ lv: Int) -> some View {
        let group = unitProblems.filter { $0.difficulty == lv }
        let unlocked = group.first.map { engine.isUnlocked($0) } ?? false
        let bonusOpened = (store.bonusUnlockedLevels[unitId] ?? 0) >= lv
            && engine.clearedDifficulty(in: unitId) < lv - 1
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            HStack(spacing: TKSpacing.sm) {
                Text("Lv.\(lv)")
                    .font(TKType.subtitle)
                    .foregroundStyle(unlocked ? TKColor.textPrimary : TKColor.textTertiary)
                Text(levelTitle(lv))
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
                Spacer()
                if bonusOpened {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                        Text("ボーナス開放")
                    }
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.warm)
                } else if !unlocked {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(TKColor.textTertiary)
                }
            }
            VStack(spacing: TKSpacing.sm) {
                ForEach(group) { problem in
                    row(for: problem, unlocked: unlocked)
                }
            }
        }
        .opacity(unlocked ? 1 : 0.65)
    }

    @ViewBuilder
    private func row(for problem: Problem, unlocked: Bool) -> some View {
        if unlocked {
            NavigationLink(value: HomeView.NavTarget.problem(problem.id)) {
                rowBody(problem)
            }
            .buttonStyle(.plain)
        } else {
            rowBody(problem)
        }
    }

    private func rowBody(_ problem: Problem) -> some View {
        let solved = store.isSolved(problem.id)
        return HStack(alignment: .center, spacing: TKSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(problem.title)
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                Text(problem.equation)
                    .font(TKType.caption.monospacedDigit())
                    .foregroundStyle(TKColor.textSecondary)
            }
            Spacer()
            if solved {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(TKColor.success)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(TKColor.textTertiary)
            }
        }
        .padding(TKSpacing.md)
        .background(solved ? TKColor.successSoft : TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(solved ? TKColor.success.opacity(0.4) : TKColor.divider,
                        lineWidth: 1)
        )
    }

    private func levelTitle(_ lv: Int) -> String {
        switch lv {
        case 1: return "まずはここから"
        case 2: return "符号と組み合わせ"
        case 3: return "両辺に同じ操作"
        case 4: return "カッコ・分数・文章題"
        case 5: return "総合"
        default: return ""
        }
    }
}
