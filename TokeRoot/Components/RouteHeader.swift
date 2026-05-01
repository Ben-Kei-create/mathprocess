import SwiftUI

/// Top breadcrumb shown on the problem screen — e.g.
/// 「中1 > 一次方程式　3/10」
struct RouteHeader: View {
    let path: String           // "中1 > 一次方程式"
    let progress: String?      // "3/10" — optional

    var body: some View {
        HStack {
            Text(path)
                .font(TKType.caption)
                .foregroundStyle(TKColor.textSecondary)
            if let progress {
                Text(progress)
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, TKSpacing.md)
        .padding(.top, TKSpacing.sm)
    }
}
