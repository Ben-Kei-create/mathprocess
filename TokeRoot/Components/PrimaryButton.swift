import SwiftUI

/// Large, calm, full-width tap target. Used everywhere the user is being
/// invited forward — never to indicate urgency.
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    var style: Style = .filled
    let action: () -> Void

    enum Style { case filled, soft, outline }

    init(_ title: String,
         systemImage: String? = nil,
         style: Style = .filled,
         action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: TKSpacing.sm) {
                if let icon = systemImage {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(TKType.subtitle)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, TKSpacing.md + 2)
            .background(background)
            .foregroundStyle(foreground)
            .overlay(
                RoundedRectangle(cornerRadius: TKRadius.large)
                    .stroke(strokeColor, lineWidth: style == .outline ? 1.5 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: TKRadius.large))
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch style {
        case .filled:  return TKColor.accent
        case .soft:    return TKColor.accentSoft
        case .outline: return .clear
        }
    }
    private var foreground: Color {
        switch style {
        case .filled:  return .white
        case .soft:    return TKColor.accent
        case .outline: return TKColor.accent
        }
    }
    private var strokeColor: Color {
        style == .outline ? TKColor.accent : .clear
    }
}
