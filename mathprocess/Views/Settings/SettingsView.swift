import SwiftUI

struct SettingsView: View {
    @Environment(ProgressStore.self) private var store
    @State private var showResetAlert = false
    @State private var showRemoveAdsAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: TKSpacing.lg) {
                    timeCard
                    lifestyleCard
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
        .alert("広告非表示購入", isPresented: $showRemoveAdsAlert) {
            Button("OK") {
                store.profile.adsRemoved = true
                store.save()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("（プロトタイプ）実際の購入処理は組み込まれていません。\nOK で広告非表示状態を有効化します。")
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
                    Button("購入") { showRemoveAdsAlert = true }
                        .buttonStyle(.borderedProminent)
                        .tint(TKColor.accent)
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
}
