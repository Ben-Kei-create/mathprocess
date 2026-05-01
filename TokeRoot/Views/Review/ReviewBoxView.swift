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
                    case .problem(let id):     ProblemView(problemId: id)
                    case .practice(let id):    PracticeRunnerView(practiceSetId: id)
                    case .unitSelect:          UnitSelectView()
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
                VStack(spacing: TKSpacing.sm) {
                    ForEach(store.reviewItems) { item in
                        row(item)
                    }
                    AdSlot(placement: .logBottom)
                        .padding(.top, TKSpacing.lg)
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
        }
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

    @ViewBuilder
    private func row(_ item: ReviewItem) -> some View {
        if let problem = data.problem(id: item.problemId) {
            Button {
                path.append(HomeView.NavTarget.problem(problem.id))
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(problem.equation)
                            .font(TKType.subtitle)
                            .foregroundStyle(TKColor.textPrimary)
                        Text(item.reason.rawValue)
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textSecondary)
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
}
