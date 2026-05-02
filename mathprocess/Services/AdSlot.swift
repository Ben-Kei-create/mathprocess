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
        if ProgressStore.shared.profile.adsRemoved {
            EmptyView()
        } else {
            HStack {
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
            .background(TKColor.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(TKColor.divider, lineWidth: 1)
            )
            .padding(.horizontal, TKSpacing.md)
        }
    }
}
