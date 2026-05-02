import SwiftUI

/// Seven-day strip of habit symbols. Quiet — never red, never shaming.
struct WeeklyCalendarStrip: View {
    let marks: [DailyMark]   // exactly 7, oldest -> newest

    var body: some View {
        HStack(spacing: TKSpacing.sm) {
            ForEach(marks, id: \.day) { mark in
                VStack(spacing: 4) {
                    Text(weekday(for: mark.day))
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textTertiary)
                    Text(mark.symbol.rawValue)
                        .font(TKType.subtitle)
                        .foregroundStyle(symbolColor(mark.symbol))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(TKColor.surfaceElevated)
                        )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekday(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "E"
        return f.string(from: date)
    }

    private func symbolColor(_ s: DailyMark.Symbol) -> Color {
        switch s {
        case .exceeded: return TKColor.success
        case .reached:  return TKColor.accent
        case .some:     return TKColor.textSecondary
        case .none:     return TKColor.textTertiary
        }
    }
}
