import SwiftUI

/// Combined Study Log + Calendar habit view. Shows what became
/// possible — never what's missing.
struct LogView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(DataService.self) private var data

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: TKSpacing.lg) {
                    summaryCard
                    monthCalendar
                    achievementsCard
                    AdSlot(placement: .logBottom)
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
            .navigationTitle("記録")
        }
    }

    private var summaryCard: some View {
        SectionCard("これまで") {
            HStack(spacing: TKSpacing.lg) {
                stat("問題", "\(store.events.count)")
                stat("分", "\(totalMinutes)")
                stat("日", "\(uniqueDays)")
            }
        }
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text(label)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var totalMinutes: Int {
        store.events.map(\.durationSeconds).reduce(0, +) / 60
    }
    private var uniqueDays: Int {
        let cal = Calendar.current
        return Set(store.events.map { cal.startOfDay(for: $0.date) }).count
    }

    private var monthCalendar: some View {
        SectionCard("カレンダー") {
            CalendarHabitGrid()
        }
    }

    private var achievementsCard: some View {
        SectionCard("できるようになったこと") {
            if earnedAchievements.isEmpty {
                Text("これからここに、できるようになったことが増えていきます。")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: TKSpacing.sm) {
                    ForEach(earnedAchievements) { achievement in
                        HStack(alignment: .top, spacing: TKSpacing.sm) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(TKColor.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(achievement.title)
                                    .font(TKType.body)
                                    .foregroundStyle(TKColor.textPrimary)
                                Text(achievement.description)
                                    .font(TKType.caption)
                                    .foregroundStyle(TKColor.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var earnedAchievements: [Achievement] {
        store.achievements
            .filter { $0.earnedAt != nil }
            .sorted {
                ($0.earnedAt ?? .distantPast) > ($1.earnedAt ?? .distantPast)
            }
    }
}
