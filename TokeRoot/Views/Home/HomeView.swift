import SwiftUI

struct HomeView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(DataService.self) private var data
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path = NavigationPath()

    enum NavTarget: Hashable {
        case unitSelect
        case unitProblems(String)
        case problem(String)
        case practice(String)
    }

    private var engine: RouteEngine { RouteEngine() }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                homeContent
            }
            .background(TKColor.background.ignoresSafeArea())
            .navigationDestination(for: NavTarget.self) { target in
                switch target {
                case .unitSelect:           UnitSelectView()
                case .unitProblems(let id): UnitProblemListView(unitId: id)
                case .problem(let id):      ProblemView(problemId: id)
                case .practice(let setId):  PracticeRunnerView(practiceSetId: setId)
                }
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        if horizontalSizeClass == .regular {
            regularHomeContent
        } else {
            compactHomeContent
        }
    }

    private var compactHomeContent: some View {
        VStack(alignment: .leading, spacing: TKSpacing.lg) {
            header
            dailyWord
            continueCTA
            reviewReminder
            todaysFocus
            weeklyStrip
            AdSlot(placement: .homeBottom)
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.md)
        .padding(.bottom, TKSpacing.xl)
    }

    private var regularHomeContent: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xl) {
            header

            HStack(alignment: .top, spacing: TKSpacing.lg) {
                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    dailyWord
                    continueCTA
                    reviewReminder
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    todaysFocus
                    weeklyStrip
                    AdSlot(placement: .homeBottom)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, TKSpacing.xl)
        .padding(.top, TKSpacing.xl)
        .padding(.bottom, TKSpacing.xl)
        .frame(maxWidth: 920, alignment: .topLeading)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: TKSpacing.xs) {
            Text("解け√ルート")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text("中学数学 > つまずきを小さく直す")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
        }
    }

    private var dailyWord: some View {
        SectionCard("今日の言葉") {
            HStack(alignment: .top, spacing: TKSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(TKColor.warm)
                    .frame(width: 28, height: 28)
                    .background(TKColor.warmSoft)
                    .clipShape(Circle())

                Text(data.dailyWord())
                    .font(TKType.body)
                    .foregroundStyle(TKColor.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var continueCTA: some View {
        HStack(spacing: TKSpacing.sm) {
            PrimaryButton("つづきから", systemImage: "arrow.right.circle.fill") {
                openContinue()
            }

            Button {
                path.append(NavTarget.unitSelect)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                    Text("単元")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .font(TKType.subtitle)
                .foregroundStyle(.white)
                .frame(width: 112)
                .padding(.vertical, TKSpacing.md + 2)
                .background(TKColor.success)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.large))
                .shadow(color: TKColor.success.opacity(0.20), radius: 8, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("単元")
        }
    }

    @ViewBuilder
    private var reviewReminder: some View {
        let dueItems = store.dueReviewItems()
        if !dueItems.isEmpty {
            SectionCard {
                Button {
                    if let first = dueItems.first {
                        path.append(NavTarget.problem(first.problemId))
                    }
                } label: {
                    HStack(alignment: .center, spacing: TKSpacing.md) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(TKColor.accent)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dueItems.count)問だけ復習")
                                .font(TKType.subtitle)
                                .foregroundStyle(TKColor.textPrimary)
                            Text("前に解けた問題を、忘れる前に確認します")
                                .font(TKType.caption)
                                .foregroundStyle(TKColor.textSecondary)
                        }

                        Spacer()

                        HStack(spacing: 5) {
                            Text("復習する")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(TKType.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, TKSpacing.sm)
                        .padding(.vertical, 8)
                        .background(TKColor.accent)
                        .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var todaysFocus: some View {
        SectionCard("学習時間") {
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
            path.append(NavTarget.unitSelect)
        case .problem(let id):
            path.append(NavTarget.problem(id))
        }
    }
}
