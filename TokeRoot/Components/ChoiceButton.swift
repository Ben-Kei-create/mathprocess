import SwiftUI

/// One of the 「次に何をする？」 choices. Soft, large, with state-aware
/// fills:
/// - default: pale surface
/// - correct (after tap): success green
/// - wrong (after tap): warm amber, never red
struct ChoiceButton: View {
    let label: String
    let state: State
    let action: () -> Void

    enum State { case idle, correct, wrong, dimmed }

    var body: some View {
        let style = labelStyle
        Button(action: action) {
            HStack(alignment: .center, spacing: TKSpacing.sm) {
                MathText(
                    text: label,
                    font: style.font,
                    scriptFont: style.scriptFont,
                    scriptOffset: style.scriptOffset,
                    lowerScriptOffset: -4
                )
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(style.lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailingAccessory
            }
            .padding(.horizontal, TKSpacing.md + 2)
            .padding(.vertical, TKSpacing.md + 2)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(stroke, lineWidth: 1.2)
            )
            .shadow(color: state == .idle ? TKColor.accent.opacity(0.07) : .clear,
                    radius: 5,
                    y: 2)
            .opacity(state == .dimmed ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MathDisplayFormatter.plain(label))
        .animation(.easeInOut(duration: 0.18), value: state)
    }

    private var labelStyle: LabelStyle {
        let count = MathDisplayFormatter.plain(label).count
        if count >= 34 {
            return LabelStyle(
                font: TKType.caption,
                scriptFont: .system(size: 9, weight: .semibold, design: .rounded),
                scriptOffset: 4,
                lineSpacing: 3
            )
        }
        if count >= 20 {
            return LabelStyle(
                font: TKType.body,
                scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                scriptOffset: 5,
                lineSpacing: 2
            )
        }
        return LabelStyle(
            font: TKType.subtitle,
            scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
            scriptOffset: 6,
            lineSpacing: 2
        )
    }

    private var background: Color {
        switch state {
        case .idle:    return TKColor.surface
        case .correct: return TKColor.successSoft
        case .wrong:   return TKColor.warmSoft
        case .dimmed:  return TKColor.surface
        }
    }
    private var foreground: Color {
        switch state {
        case .correct: return TKColor.success
        case .wrong:   return TKColor.warm
        default:       return TKColor.textPrimary
        }
    }
    private var stroke: Color {
        switch state {
        case .correct: return TKColor.success.opacity(0.6)
        case .wrong:   return TKColor.warm.opacity(0.6)
        default:       return TKColor.divider
        }
    }
    private var trailingIcon: String? {
        switch state {
        case .correct: return "checkmark"
        case .wrong:   return "arrow.uturn.left"
        default:       return nil
        }
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        switch state {
        case .idle:
            HStack(spacing: 5) {
                Text("えらぶ")
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
            }
            .font(TKType.caption)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, TKSpacing.sm)
            .padding(.vertical, 7)
            .background(TKColor.accent)
            .clipShape(Capsule())
        case .correct, .wrong:
            if let icon = trailingIcon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(foreground)
            }
        case .dimmed:
            EmptyView()
        }
    }
}

private struct LabelStyle {
    let font: Font
    let scriptFont: Font
    let scriptOffset: CGFloat
    let lineSpacing: CGFloat
}
