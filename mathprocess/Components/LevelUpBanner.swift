import SwiftUI

/// Quiet celebration shown after a clear that advanced the user's max
/// difficulty in the current unit. One sentence, one new idea — by
/// design, never more.
struct LevelUpBanner: View {
    let level: Int
    let concept: String?

    var body: some View {
        HStack(alignment: .top, spacing: TKSpacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(TKColor.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lv.\(level) に進めました")
                    .font(TKType.subtitle)
                    .foregroundStyle(TKColor.success)
                if let concept {
                    Text("新しい考え方を1つ覚えました：\(concept)")
                        .font(TKType.body)
                        .foregroundStyle(TKColor.textPrimary)
                }
            }
            Spacer()
        }
        .padding(TKSpacing.md)
        .frame(maxWidth: .infinity)
        .background(TKColor.successSoft)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.success.opacity(0.4), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }
}
