import SwiftUI

/// Architectural placeholder for ads. The MVP renders a quiet, non-blocking
/// placeholder banner — no actual ad SDK is integrated. Crucially, this view
/// is only rendered on non-learning surfaces (Home / Log / Settings tabs).
///
/// **Never** place this view inside the problem-solving flow.
struct AdSlot: View {
    enum Placement {
        case homeBottom
        case logBottom
        case settingsBottom
    }

    let placement: Placement

    var body: some View {
        HStack {
            Text("PR")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(TKColor.textTertiary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(TKColor.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 5))
            Image(systemName: "rectangle.dashed")
                .foregroundStyle(.secondary)
            Text("広告スペース")
                .font(TKType.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, TKSpacing.md)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(TKColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TKColor.textTertiary.opacity(0.45),
                        style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
        )
        .padding(.horizontal, TKSpacing.md)
    }
}
