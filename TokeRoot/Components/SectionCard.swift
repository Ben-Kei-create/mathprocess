import SwiftUI

/// Generic card container used by Home sections, Settings rows, etc.
struct SectionCard<Content: View>: View {
    let title: String?
    let content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TKSpacing.sm) {
            if let title {
                Text(title)
                    .font(TKType.caption)
                    .foregroundStyle(TKColor.textSecondary)
            }
            content
                .padding(TKSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TKColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: TKRadius.medium)
                        .stroke(TKColor.divider, lineWidth: 1)
                )
        }
    }
}
