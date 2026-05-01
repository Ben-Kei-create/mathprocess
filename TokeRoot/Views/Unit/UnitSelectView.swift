import SwiftUI

struct UnitSelectView: View {
    @Environment(DataService.self) private var data

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TKSpacing.lg) {
                ForEach(Grade.allCases) { g in
                    section(for: g)
                }
            }
            .padding(.horizontal, TKSpacing.md)
            .padding(.top, TKSpacing.md)
            .padding(.bottom, TKSpacing.xl)
        }
        .background(TKColor.background.ignoresSafeArea())
        .navigationTitle("単元をえらぶ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(for grade: Grade) -> some View {
        let units = data.units
            .filter { $0.grade == grade }
            .sorted { $0.order < $1.order }
        return VStack(alignment: .leading, spacing: TKSpacing.sm) {
            Text("\(grade.rawValue) ルート")
                .font(TKType.subtitle)
                .foregroundStyle(TKColor.textPrimary)

            VStack(spacing: TKSpacing.sm) {
                ForEach(units) { unit in
                    row(for: unit)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for unit: MathUnit) -> some View {
        if unit.isAvailable {
            NavigationLink(value: HomeView.NavTarget.problem(firstProblemId(unit))) {
                rowBody(unit)
            }
            .buttonStyle(.plain)
        } else {
            rowBody(unit)
                .opacity(0.55)
        }
    }

    private func rowBody(_ unit: MathUnit) -> some View {
        HStack(alignment: .center, spacing: TKSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(unit.title)
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                if let sub = unit.subtitle {
                    Text(sub)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                }
            }
            Spacer()
            Text(unit.status.label)
                .font(TKType.caption)
                .foregroundStyle(unit.isAvailable ? TKColor.success : TKColor.textTertiary)
            if unit.isAvailable {
                Image(systemName: "chevron.right")
                    .foregroundStyle(TKColor.textTertiary)
            }
        }
        .padding(TKSpacing.md)
        .background(TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.divider, lineWidth: 1)
        )
    }

    private func firstProblemId(_ unit: MathUnit) -> String {
        DataService.shared.problems(in: unit.id).first?.id ?? ""
    }
}
