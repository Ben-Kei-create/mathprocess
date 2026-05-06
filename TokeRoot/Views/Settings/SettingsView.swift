import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var store
    @Environment(PurchaseService.self) private var purchase
    @Environment(NotificationService.self) private var notifications
    @State private var showResetAlert = false
    @State private var showPurchaseMessage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TKSpacing.lg) {
                    timeCard
                    lifestyleCard
                    reminderCard
                    purchaseCard
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
        .alert(purchaseAlertTitle, isPresented: $showPurchaseMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchase.errorMessage ?? purchase.statusMessage ?? "")
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
                        HStack {
                            Text(l.rawValue)
                                .foregroundStyle(TKColor.textPrimary)
                            Spacer()
                            if store.profile.lifestyle == l {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(TKColor.accent)
                            }
                        }
                        .padding(.vertical, 6)
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

    private var purchaseCard: some View {
        SectionCard("購入") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("広告を非表示にする")
                        .foregroundStyle(TKColor.textPrimary)
                    Text(store.profile.adsRemoved ? "購入済み" : "ホームと記録の広告枠を消します")
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary)
                }
                Spacer()
                if store.profile.adsRemoved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TKColor.success)
                } else {
                    Button {
                        buyRemoveAds()
                    } label: {
                        if purchase.isPurchasing {
                            ProgressView()
                        } else {
                            Text(purchase.removeAdsProduct?.displayPrice ?? "購入")
                        }
                    }
                    .disabled(purchase.isPurchasing || purchase.isLoading)
                        .buttonStyle(.borderedProminent)
                        .tint(TKColor.accent)
                }
            }
            if !store.profile.adsRemoved {
                Button("購入を復元") {
                    restorePurchases()
                }
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
                .buttonStyle(.plain)
            }
            if let status = purchase.statusMessage {
                Text(status)
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
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
                Text("最初からやり直す")
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

    private var purchaseAlertTitle: String {
        purchase.errorMessage == nil ? "購入の状態" : "購入できませんでした"
    }

    private func buyRemoveAds() {
        Task {
            let purchased = await purchase.purchaseRemoveAds()
            if purchased {
                store.profile.adsRemoved = true
                store.save()
            } else if purchase.errorMessage != nil || purchase.statusMessage != nil {
                showPurchaseMessage = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            let restored = await purchase.restorePurchases()
            if restored {
                store.profile.adsRemoved = true
                store.save()
            }
            if purchase.errorMessage != nil || purchase.statusMessage != nil {
                showPurchaseMessage = true
            }
        }
    }
}
