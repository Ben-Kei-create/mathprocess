import SwiftUI

struct UnitProblemListView: View {
    let unitId: String

    @Environment(DataService.self) private var data

    var body: some View {
        List {
            ForEach(problems) { problem in
                NavigationLink(value: HomeView.NavTarget.problem(problem.id)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(problem.title)
                            .font(TKType.subtitle)
                            .foregroundStyle(TKColor.textPrimary)
                        HStack(spacing: TKSpacing.sm) {
                            Text(problem.mode.rawValue)
                            Text("★\(problem.difficulty)")
                        }
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(TKColor.background.ignoresSafeArea())
        .navigationTitle(data.unit(id: unitId)?.title ?? "問題")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var problems: [Problem] {
        data.problems(in: unitId)
    }
}
