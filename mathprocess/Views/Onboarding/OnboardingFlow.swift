import SwiftUI

/// Two-question onboarding. Kept short by design — each step has one
/// clear ask and one continue button.
struct OnboardingFlow: View {
    @Environment(ProgressStore.self) private var store
    @State private var step: Step = .welcome
    @State private var time: DailyTime = .t5
    @State private var lifestyle: Lifestyle = .unsure

    enum Step { case welcome, time, lifestyle, ready }

    var body: some View {
        VStack {
            Spacer(minLength: TKSpacing.xl)
            content
                .frame(maxWidth: .infinity)
                .padding(.horizontal, TKSpacing.lg)
            Spacer()
            footer
                .padding(.horizontal, TKSpacing.lg)
                .padding(.bottom, TKSpacing.lg)
        }
        .background(TKColor.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:   welcome
        case .time:      timeQuestion
        case .lifestyle: lifestyleQuestion
        case .ready:     ready
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: TKSpacing.md) {
            Text("解け√ルート")
                .font(TKType.display)
                .foregroundStyle(TKColor.textPrimary)
            Text("解けないを、\n解けるルートに変える。")
                .font(TKType.title)
                .foregroundStyle(TKColor.textSecondary)
            Text("つまずいた場所からやり直せる、\nやさしい中学数学アプリ。")
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
                .padding(.top, TKSpacing.md)
        }
    }

    private var timeQuestion: some View {
        VStack(alignment: .leading, spacing: TKSpacing.md) {
            Text("1日に数学に使えそうな時間は？")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text("あとで変えられます。")
                .font(TKType.caption)
                .foregroundStyle(TKColor.textTertiary)
            VStack(spacing: TKSpacing.sm) {
                ForEach(DailyTime.allCases) { t in
                    optionRow(text: t.label, selected: time == t) { time = t }
                }
            }
            .padding(.top, TKSpacing.sm)
        }
    }

    private var lifestyleQuestion: some View {
        VStack(alignment: .leading, spacing: TKSpacing.md) {
            Text("今の生活に近いものは？")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            VStack(spacing: TKSpacing.sm) {
                ForEach(Lifestyle.allCases) { l in
                    optionRow(text: l.rawValue, selected: lifestyle == l) { lifestyle = l }
                }
            }
            .padding(.top, TKSpacing.sm)
        }
    }

    private var ready: some View {
        VStack(alignment: .leading, spacing: TKSpacing.md) {
            Text("準備ができました。")
                .font(TKType.title)
                .foregroundStyle(TKColor.textPrimary)
            Text(supportiveLine)
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
            Text("これから「ルート診断テスト」を5問だけ受けてもらいます。\n点数を出すためではなく、どこから始めると一番楽かを決めるためです。")
                .font(TKType.body)
                .foregroundStyle(TKColor.textSecondary)
                .padding(.top, TKSpacing.sm)
        }
    }

    private var supportiveLine: String {
        if time == .t3 || time == .t5 {
            return "今日は\(time.rawValue)分だけで大丈夫です。"
        }
        switch lifestyle {
        case .sportsClub:  return "運動部の日でも、1問だけ戻れればOKです。"
        case .lessonsBusy: return "塾と並行でも、5分だけ戻れれば十分です。"
        default:           return "焦らず1問。それで今日は前に進めます。"
        }
    }

    private func optionRow(text: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(TKColor.accent)
                }
            }
            .padding(TKSpacing.md)
            .background(selected ? TKColor.accentSoft : TKColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(selected ? TKColor.accent.opacity(0.5) : TKColor.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: TKSpacing.sm) {
            PrimaryButton(primaryTitle) { advance() }
            if step != .welcome {
                Button("もどる") { back() }
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
        }
    }

    private var primaryTitle: String {
        switch step {
        case .welcome:   return "はじめる"
        case .time:      return "次へ"
        case .lifestyle: return "次へ"
        case .ready:     return "ルート診断テストへ"
        }
    }

    private func advance() {
        switch step {
        case .welcome:   step = .time
        case .time:      step = .lifestyle
        case .lifestyle: step = .ready
        case .ready:
            store.profile.dailyTime = time
            store.profile.lifestyle = lifestyle
            store.profile.hasCompletedOnboarding = true
            store.save()
        }
    }

    private func back() {
        switch step {
        case .welcome:   break
        case .time:      step = .welcome
        case .lifestyle: step = .time
        case .ready:     step = .lifestyle
        }
    }
}
