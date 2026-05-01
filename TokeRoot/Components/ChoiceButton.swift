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
        Button(action: action) {
            HStack(alignment: .center, spacing: TKSpacing.sm) {
                Text(label)
                    .font(TKType.subtitle)
                    .foregroundStyle(foreground)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let icon = trailingIcon {
                    Image(systemName: icon)
                        .foregroundStyle(foreground)
                }
            }
            .padding(.horizontal, TKSpacing.md + 2)
            .padding(.vertical, TKSpacing.md + 2)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.medium)
                    .stroke(stroke, lineWidth: 1.2)
            )
            .opacity(state == .dimmed ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: state)
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
}
