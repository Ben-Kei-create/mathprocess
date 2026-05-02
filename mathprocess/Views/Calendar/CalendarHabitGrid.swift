import SwiftUI

/// Month grid of daily habit symbols. Quiet, never punitive.
struct CalendarHabitGrid: View {
    @Environment(ProgressStore.self) private var store

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            HStack {
                ForEach(["日","月","火","水","木","金","土"], id: \.self) { d in
                    Text(d)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(daysInGrid, id: \.self) { day in
                    cell(for: day)
                }
            }
        }
    }

    private var daysInGrid: [Date?] {
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month], from: now)
        guard let firstOfMonth = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func cell(for day: Date?) -> some View {
        let goal = store.profile.dailyTime.goalSeconds
        guard let day else {
            return AnyView(Color.clear.frame(height: 36))
        }
        let mark = store.dailyMark(for: day, goalSeconds: goal)
        let dayNum = Calendar.current.component(.day, from: day)
        return AnyView(
            VStack(spacing: 1) {
                Text("\(dayNum)")
                    .font(.system(size: 10))
                    .foregroundStyle(TKColor.textTertiary)
                Text(mark.symbol.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color(mark.symbol))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(TKColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        )
    }

    private func color(_ s: DailyMark.Symbol) -> Color {
        switch s {
        case .exceeded: return TKColor.success
        case .reached:  return TKColor.accent
        case .some:     return TKColor.textSecondary
        case .none:     return TKColor.textTertiary
        }
    }
}
