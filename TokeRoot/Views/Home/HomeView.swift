import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(DataService.self) private var data
    @State private var path = NavigationPath()

    enum NavTarget: Hashable {
        case unitSelect
        case unitDetail(String)
        case problem(String)
        case practice(String)
    }

    private var engine: RouteEngine { RouteEngine() }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    header
                    routeMessage
                    continueCTA
                    recommendation
                    todaysFocus
                    weeklyStrip
                    AdSlot(placement: .homeBottom)
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
            .navigationDestination(for: NavTarget.self) { target in
                switch target {
                case .unitSelect:               UnitSelectView()
                case .unitDetail(let unitId):   UnitDetailView(unitId: unitId)
                case .problem(let id):          ProblemView(problemId: id)
                case .practice(let setId):      PracticeRunnerView(practiceSetId: setId)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            Text("解け√ルート")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text("中1 > 一次方程式")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
        }
    }

    private var routeMessage: some View {
        SectionCard("今日のルート診断") {
            Text(engine.todayHomeMessage())
                .font(TKType.body)
                .foregroundStyle(TKColor.textPrimary)
                .lineSpacing(4)
        }
    }

    private var continueCTA: some View {
        VStack(spacing: TKSpacing.sm) {
            PrimaryButton("つづきから", systemImage: "arrow.right.circle.fill") {
                openContinue()
            }
            Button {
                path.append(NavTarget.unitSelect)
            } label: {
                Text("単元をえらぶ")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
        }
    }

    private var recommendation: some View {
        SectionCard("今日のおすすめ") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.todaysRecommendation())
                        .font(TKType.subtitle)
                        .foregroundStyle(TKColor.textPrimary)
                    Text("短時間で終わります")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(TKColor.textTertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture { openContinue() }
        }
    }

    private var todaysFocus: some View {
        SectionCard("今日の集中") {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int((Double(store.todaySeconds()) / 60).rounded()))")
                    .font(TKType.display)
                    .foregroundStyle(TKColor.textPrimary)
                Text("分")
                    .font(TKType.body)
                    .foregroundStyle(TKColor.textSecondary)
                Spacer()
                Text("目標 \(store.profile.dailyTime.rawValue) 分")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textTertiary)
            }
        }
    }

    private var weeklyStrip: some View {
        SectionCard("今週") {
            WeeklyCalendarStrip(marks: weekMarks)
        }
    }

    private var weekMarks: [DailyMark] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let goal = store.profile.dailyTime.goalSeconds
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            return store.dailyMark(for: day, goalSeconds: goal)
        }
    }

    private func openContinue() {
        switch engine.continueTarget() {
        case .onboarding, .diagnosis, .unitSelect:
            // Show the active unit's difficulty ladder rather than the
            // raw unit list — that's where progression is visible.
            let unitId = ProgressStore.shared.lastUnitId ?? "g1-linear-eq"
            path.append(NavTarget.unitDetail(unitId))
        case .problem(let id):
            path.append(NavTarget.problem(id))
        }
    }
}
