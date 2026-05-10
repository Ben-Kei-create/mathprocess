import SwiftUI

struct UnitSelectView: View {
    @Environment(DataService.self) private var data
    @Environment(ProgressStore.self) private var store

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
            NavigationLink(value: HomeView.NavTarget.unitProblems(unit.id)) {
                rowBody(unit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: unit))
        } else {
            rowBody(unit)
                .opacity(0.55)
                .accessibilityLabel(accessibilityLabel(for: unit))
        }
    }

    private func rowBody(_ unit: MathUnit) -> some View {
        let count = problemCount(for: unit)
        let mastered = masteredCount(for: unit)
        return HStack(spacing: 0) {
            Rectangle()
                .fill(unit.isAvailable ? TKColor.success : TKColor.divider)
                .frame(width: unit.isAvailable ? 5 : 0)

            HStack(alignment: .center, spacing: TKSpacing.md) {
                VStack(alignment: .leading, spacing: TKSpacing.xs) {
                    Text(unit.title)
                        .font(TKType.subtitle)
                        .foregroundStyle(unit.isAvailable ? TKColor.textPrimary : TKColor.textSecondary)
                    if let sub = unit.subtitle {
                        MathText(
                            text: sub,
                            font: TKType.caption,
                            scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                            scriptOffset: 4
                        )
                            .foregroundStyle(TKColor.textSecondary)
                    }
                    if unit.isAvailable {
                        unitProgress(mastered: mastered, total: count)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if unit.isAvailable {
                    VStack(alignment: .trailing, spacing: TKSpacing.xs) {
                        Text("\(count)問")
                            .font(TKType.caption)
                            .foregroundStyle(TKColor.textTertiary)
                        HStack(spacing: 5) {
                            Text(actionTitle(mastered: mastered, total: count))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .font(TKType.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, TKSpacing.sm)
                        .padding(.vertical, 7)
                        .background(TKColor.success)
                        .clipShape(Capsule())
                    }
                } else {
                    Text(unit.status.label)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                }
            }
            .padding(TKSpacing.md)
        }
        .background(unit.isAvailable ? TKColor.successSoft.opacity(0.40) : TKColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(unit.isAvailable ? TKColor.success.opacity(0.28) : TKColor.divider, lineWidth: 1.2)
        )
        .shadow(color: unit.isAvailable ? TKColor.success.opacity(0.08) : .clear, radius: 6, y: 2)
    }

    private func unitProgress(mastered: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: TKSpacing.xs) {
                progressLabel("\(max(total - mastered, 0))", caption: "練習中")
                progressLabel("\(mastered)", caption: "完了")
            }
            ProgressView(value: Double(mastered), total: Double(max(total, 1)))
                .tint(TKColor.success)
        }
    }

    private func progressLabel(_ value: String, caption: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textPrimary)
            Text(caption)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
        }
    }

    private func problemCount(for unit: MathUnit) -> Int {
        data.problems(in: unit.id).count
    }

    private func masteredCount(for unit: MathUnit) -> Int {
        store.masteredCount(in: unit.id, data: data)
    }

    private func actionTitle(mastered: Int, total: Int) -> String {
        if total > 0 && mastered >= total {
            return "見直す"
        }
        if mastered > 0 {
            return "つづける"
        }
        return "はじめる"
    }

    private func accessibilityLabel(for unit: MathUnit) -> String {
        let count = problemCount(for: unit)
        let mastered = masteredCount(for: unit)
        let subtitle = unit.subtitle.map { "、\(MathDisplayFormatter.plain($0))" } ?? ""

        if unit.isAvailable {
            return "\(unit.title)\(subtitle)、\(count)問、\(mastered)問完了、\(actionTitle(mastered: mastered, total: count))"
        }
        return "\(unit.title)\(subtitle)、\(unit.status.label)"
    }
}
