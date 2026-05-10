import SwiftUI

/// Centerpiece of the problem screen. The equation animates between
/// states; the optional `highlight` substring is rendered with a soft
/// yellow underline so the eye finds the changed piece without strain.
struct EquationCard: View {
    let text: String
    let highlight: String?

    var body: some View {
        let style = displayStyle
        ZStack {
            RoundedRectangle(cornerRadius: TKRadius.large)
                .fill(TKColor.surface)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)

            renderedText(style: style)
                .foregroundStyle(TKColor.textPrimary)
                .multilineTextAlignment(style.alignment)
                .lineSpacing(style.lineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .frame(maxWidth: .infinity, alignment: style.frameAlignment)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: style.minHeight)
        .id(text)                         // forces transition between values
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal:   .opacity.combined(with: .move(edge: .top))
        ))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MathDisplayFormatter.plain(text))
    }

    @ViewBuilder
    private func renderedText(style: DisplayStyle) -> some View {
        if let rows = tableRows {
            ValueTableView(rows: rows)
        } else if let h = highlight,
           !h.isEmpty,
           let range = text.range(of: h) {
            let before = String(text[..<range.lowerBound])
            let mid    = String(text[range])
            let after  = String(text[range.upperBound...])
            (MathText.render(
                before,
                font: style.font,
                scriptFont: style.scriptFont,
                scriptOffset: style.scriptOffset
            )
             + MathText.render(
                mid,
                font: style.font,
                scriptFont: style.scriptFont,
                scriptOffset: style.scriptOffset
             )
                .foregroundStyle(TKColor.textPrimary)
                .underline(true, color: TKColor.highlight)
             + MathText.render(
                after,
                font: style.font,
                scriptFont: style.scriptFont,
                scriptOffset: style.scriptOffset
             ))
        } else {
            MathText(
                text: text,
                font: style.font,
                scriptFont: style.scriptFont,
                scriptOffset: style.scriptOffset
            )
        }
    }

    private var displayStyle: DisplayStyle {
        let displayText = MathDisplayFormatter.plain(text)
        let count = displayText.count
        let hasSentence = displayText.contains("。") || displayText.contains("、")
        let hasLineBreak = displayText.contains("\n")

        if hasLineBreak || hasSentence || count >= 54 {
            return DisplayStyle(
                font: TKType.body,
                scriptFont: .system(size: 11, weight: .semibold, design: .rounded),
                scriptOffset: 5,
                minHeight: 160,
                horizontalPadding: TKSpacing.md,
                verticalPadding: TKSpacing.lg,
                alignment: .leading,
                frameAlignment: .leading,
                lineSpacing: 5
            )
        }

        if count >= 30 {
            return DisplayStyle(
                font: TKType.subtitle,
                scriptFont: .system(size: 12, weight: .semibold, design: .rounded),
                scriptOffset: 6,
                minHeight: 145,
                horizontalPadding: TKSpacing.md,
                verticalPadding: TKSpacing.lg,
                alignment: .center,
                frameAlignment: .center,
                lineSpacing: 3
            )
        }

        return DisplayStyle(
            font: TKType.equation,
            scriptFont: .system(size: 18, weight: .semibold, design: .rounded),
            scriptOffset: 10,
            minHeight: 140,
            horizontalPadding: TKSpacing.lg,
            verticalPadding: TKSpacing.xl,
            alignment: .center,
            frameAlignment: .center,
            lineSpacing: 2
        )
    }

    private var tableRows: [[String]]? {
        let rawRows: [String]
        if text.contains("/") && text.contains(":") {
            rawRows = text.components(separatedBy: " / ")
        } else if text.contains("\n") {
            rawRows = text.components(separatedBy: .newlines)
        } else {
            return nil
        }

        let parsedRows = rawRows.compactMap { row -> [String]? in
            let trimmed = row.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }

            if trimmed.contains("|") {
                let cells = trimmed
                    .split(separator: "|")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                return cells.count >= 2 ? cells : nil
            }

            let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }
            let label = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let values = parts[1]
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard !label.isEmpty, !values.isEmpty else { return nil }
            return [label] + values
        }

        guard parsedRows.count >= 2 else { return nil }
        return parsedRows
    }
}

private struct DisplayStyle {
    let font: Font
    let scriptFont: Font
    let scriptOffset: CGFloat
    let minHeight: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let alignment: TextAlignment
    let frameAlignment: Alignment
    let lineSpacing: CGFloat
}

private struct ValueTableView: View {
    let rows: [[String]]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                        MathText(
                            text: rows[rowIndex][columnIndex],
                            font: columnIndex == 0 ? TKType.subtitle : TKType.body,
                            scriptFont: .system(size: columnIndex == 0 ? 12 : 11,
                                                weight: .semibold,
                                                design: .rounded),
                            scriptOffset: 6
                        )
                            .foregroundStyle(columnIndex == 0 ? TKColor.accent : TKColor.textPrimary)
                            .frame(minWidth: columnIndex == 0 ? 42 : 58,
                                   minHeight: 42)
                            .padding(.horizontal, TKSpacing.xs)
                            .background(columnIndex == 0 ? TKColor.accentSoft : TKColor.surface)
                            .overlay(
                                Rectangle()
                                    .stroke(TKColor.divider, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.small))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.small)
                .stroke(TKColor.divider, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
