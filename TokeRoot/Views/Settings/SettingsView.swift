import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(NotificationService.self) private var notifications
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TKSpacing.lg) {
                    timeCard
                    lifestyleCard
                    reminderCard
                    aboutCard
                    dangerCard
                    AdSlot(placement: .settingsBottom)
                }
                .padding(.horizontal, TKSpacing.md)
                .padding(.top, TKSpacing.md)
                .padding(.bottom, TKSpacing.xl)
            }
            .background(TKColor.background.ignoresSafeArea())
            .navigationTitle("設定")
        }
        .alert("最初からやり直しますか？", isPresented: $showResetAlert) {
            Button("やり直す", role: .destructive) { store.resetAll() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("学習記録とふくしゅう箱もリセットされます。")
        }
    }

    private var timeCard: some View {
        SectionCard("1日に使えそうな時間") {
            Picker("", selection: bind(\.dailyTime)) {
                ForEach(DailyTime.allCases) { t in
                    Text(t.label).tag(t)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var lifestyleCard: some View {
        SectionCard("生活スタイル") {
            VStack(spacing: TKSpacing.xs) {
                ForEach(Lifestyle.allCases) { l in
                    Button {
                        store.profile.lifestyle = l
                        store.save()
                    } label: {
                        let isSelected = store.profile.lifestyle == l
                        HStack {
                            Text(l.rawValue)
                                .foregroundStyle(TKColor.textPrimary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)
                                    .background(TKColor.accent)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(TKColor.textTertiary)
                            }
                        }
                        .padding(.horizontal, TKSpacing.sm)
                        .padding(.vertical, 8)
                        .background(isSelected ? TKColor.accentSoft : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var reminderCard: some View {
        SectionCard("リマインド") {
            VStack(alignment: .leading, spacing: TKSpacing.sm) {
                Toggle("毎日のリマインド", isOn: reminderEnabled)
                    .tint(TKColor.accent)

                if store.profile.reminderHour != nil {
                    DatePicker("時刻",
                               selection: reminderTime,
                               displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                }
            }
        }
    }

    private var aboutCard: some View {
        SectionCard("このアプリについて") {
            VStack(alignment: .leading, spacing: TKSpacing.xs) {
                Text("解け√ルート v0.1 (MVP)")
                    .foregroundStyle(TKColor.textPrimary)
                Text("解けないを、解けるルートに変える。")
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
        }
    }

    private var dangerCard: some View {
        SectionCard {
            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("最初からやり直す")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(TKColor.warm)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }

    private func bind<T>(_ keyPath: WritableKeyPath<UserProfile, T>) -> Binding<T> {
        Binding(
            get: { store.profile[keyPath: keyPath] },
            set: { newValue in
                store.profile[keyPath: keyPath] = newValue
                store.save()
            }
        )
    }

    private var reminderEnabled: Binding<Bool> {
        Binding(
            get: { store.profile.reminderHour != nil },
            set: { enabled in
                if enabled {
                    let date = defaultReminderDate
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                    store.profile.reminderHour = comps.hour
                    store.profile.reminderMinute = comps.minute
                    store.save()
                    scheduleReminder(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                } else {
                    store.profile.reminderHour = nil
                    store.profile.reminderMinute = nil
                    store.save()
                    notifications.cancelDailyReminder()
                }
            }
        )
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var comps = DateComponents()
                comps.hour = store.profile.reminderHour ?? 20
                comps.minute = store.profile.reminderMinute ?? 0
                return Calendar.current.date(from: comps) ?? defaultReminderDate
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                store.profile.reminderHour = comps.hour
                store.profile.reminderMinute = comps.minute
                store.save()
                scheduleReminder(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
            }
        )
    }

    private var defaultReminderDate: Date {
        var comps = DateComponents()
        comps.hour = 20
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? .now
    }

    private func scheduleReminder(hour: Int, minute: Int) {
        Task {
            let scheduled = await notifications.scheduleDailyReminder(hour: hour, minute: minute)
            if !scheduled {
                store.profile.reminderHour = nil
                store.profile.reminderMinute = nil
                store.save()
            }
        }
    }

}
