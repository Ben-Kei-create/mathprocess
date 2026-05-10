import SwiftUI

struct ReviewBoxView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(DataService.self) private var data
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("ふくしゅう箱")
                .navigationDestination(for: HomeView.NavTarget.self) { target in
                    switch target {
                    case .problem(let id):       ProblemView(problemId: id)
                    case .practice(let id):      PracticeRunnerView(practiceSetId: id)
                    case .unitSelect:            UnitSelectView()
                    case .unitProblems(let id):  UnitProblemListView(unitId: id)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.reviewItems.isEmpty {
            empty
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    if !dueItems.isEmpty {
                        reviewSection(
                            title: "今日やる復習",
                            caption: "前にできた問題を、忘れる前に確認します。",
                            items: dueItems
                        )
                    }

                    if !upcomingItems.isEmpty {
                        reviewSection(
                            title: "これから出てくる復習",
                            caption: "1日後、3日後、7日後…と少しずつ間を空けます。",
                            items: upcomingItems
                        )
                    }

                    AdSlot(placement: .logBottom)
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
        }
    }

    private var dueItems: [ReviewItem] {
        store.dueReviewItems()
    }

    private var upcomingItems: [ReviewItem] {
        store.upcomingReviewItems()
    }

    private var empty: some View {
        VStack(spacing: TKSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(TKColor.textTertiary)
            Text("まだ何もありません。")
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textSecondary)
            Text("間違えた問題やあとで見たい問題は、\nここに入ります。")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TKColor.background.ignoresSafeArea())
    }

    private func reviewSection(title: String, caption: String, items: [ReviewItem]) -> some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                Text(caption)
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }

            VStack(spacing: TKSpacing.sm) {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: ReviewItem) -> some View {
        if let problem = data.problem(id: item.problemId) {
            Button {
                path.append(HomeView.NavTarget.problem(problem.id))
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        MathText(
                            text: problem.equation,
                            font: TKType.subtitle,
                            scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                            scriptOffset: 6
                        )
                            .foregroundStyle(TKColor.textPrimary)
                        MathText(
                            text: problem.title,
                            font: TKType.caption,
                            scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                            scriptOffset: 4
                        )
                            .foregroundStyle(TKColor.textSecondary)
                        HStack(spacing: TKSpacing.xs) {
                            Label(item.reason.rawValue, systemImage: reasonIcon(for: item.reason))
                            Text(reviewTimingText(for: item))
                            Text(masteryText(for: problem))
                        }
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(TKColor.textTertiary)
                }
                .padding(TKSpacing.md)
                .background(TKColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: TKRadius.medium)
                        .stroke(TKColor.divider, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .swipeActions {
                Button("削除", role: .destructive) {
                    store.removeReview(item.id)
                }
            }
        }
    }

    private func reasonIcon(for reason: ReviewItem.Reason) -> String {
        switch reason {
        case .mistake: return "arrow.uturn.left"
        case .shaky: return "questionmark.circle"
        case .manual: return "tray.and.arrow.down"
        case .scheduled: return "clock.arrow.circlepath"
        }
    }

    private func reviewTimingText(for item: ReviewItem) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let due = cal.startOfDay(for: item.dueAt)
        let days = cal.dateComponents([.day], from: today, to: due).day ?? 0

        if days < 0 {
            return "\(-days)日遅れ"
        }
        if days == 0 {
            return "今日"
        }
        if days == 1 {
            return "明日"
        }
        return "あと\(days)日"
    }

    private func masteryText(for problem: Problem) -> String {
        let count = store.masterySlots(for: problem.id)
        if count >= 3 {
            return "クリア 3/3"
        }
        return "クリア \(count)/3"
    }
}
