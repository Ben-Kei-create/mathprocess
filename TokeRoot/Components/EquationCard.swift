import SwiftUI

/// Centerpiece of the problem screen. The equation animates between
/// states; the optional `highlight` substring is rendered with a soft
/// yellow underline so the eye finds the changed piece without strain.
struct EquationCard: View {
    let text: String
    let highlight: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TKRadius.large)
                .fill(TKColor.surface)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

            renderedText
                .font(TKType.equation)
                .foregroundStyle(TKColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, TKSpacing.lg)
                .padding(.vertical, TKSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 140)
        .id(text)                         // forces transition between values
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal:   .opacity.combined(with: .move(edge: .top))
        ))
    }

    @ViewBuilder
    private var renderedText: some View {
        if let h = highlight,
           !h.isEmpty,
           let range = text.range(of: h) {
            let before = String(text[..<range.lowerBound])
            let mid    = String(text[range])
            let after  = String(text[range.upperBound...])
            (Text(before)
             + Text(mid)
                .foregroundStyle(TKColor.textPrimary)
                .underline(true, color: TKColor.highlight)
             + Text(after))
        } else {
            Text(text)
        }
    }
}
