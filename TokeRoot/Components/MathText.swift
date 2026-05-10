import SwiftUI

struct MathText: View {
    let text: String
    var font: Font = TKType.equation
    var scriptFont: Font = .system(size: 18, weight: .semibold, design: .rounded)
    var scriptOffset: CGFloat = 10
    var lowerScriptOffset: CGFloat = -6

    var body: some View {
        Self.render(
            text,
            font: font,
            scriptFont: scriptFont,
            scriptOffset: scriptOffset,
            lowerScriptOffset: lowerScriptOffset
        )
        .accessibilityLabel(MathDisplayFormatter.plain(text))
    }

    static func render(
        _ text: String,
        font: Font = TKType.equation,
        scriptFont: Font = .system(size: 18, weight: .semibold, design: .rounded),
        scriptOffset: CGFloat = 10,
        lowerScriptOffset: CGFloat = -6
    ) -> Text {
        parse(MathDisplayFormatter.inlineSource(text)).reduce(Text("")) { partial, segment in
            partial + rendered(segment)
                .fontForMathSegment(
                    segment.kind,
                    baseFont: font,
                    scriptFont: scriptFont,
                    scriptOffset: scriptOffset,
                    lowerScriptOffset: lowerScriptOffset
                )
        }
    }

    private static func rendered(_ segment: Segment) -> Text {
        Text(segment.value)
    }

    private static func parse(_ value: String) -> [Segment] {
        var result: [Segment] = []
        var index = value.startIndex
        var buffer = ""

        func flush() {
            guard !buffer.isEmpty else { return }
            result.append(Segment(value: buffer, kind: .normal))
            buffer = ""
        }

        while index < value.endIndex {
            let char = value[index]
            if char == "^" || char == "_" {
                flush()
                let kind: Segment.Kind = char == "^" ? .superscript : .lowerScript
                value.formIndex(after: &index)
                let extracted = extractScript(from: value, index: &index)
                if extracted.isEmpty {
                    buffer.append(char)
                } else {
                    result.append(Segment(value: extracted, kind: kind))
                }
            } else {
                buffer.append(char)
                value.formIndex(after: &index)
            }
        }
        flush()
        return result
    }

    private static func extractScript(from value: String, index: inout String.Index) -> String {
        guard index < value.endIndex else { return "" }
        if value[index] == "{" {
            value.formIndex(after: &index)
            var script = ""
            while index < value.endIndex, value[index] != "}" {
                script.append(value[index])
                value.formIndex(after: &index)
            }
            if index < value.endIndex {
                value.formIndex(after: &index)
            }
            return script
        }
        let script = String(value[index])
        value.formIndex(after: &index)
        return script
    }
}

enum MathDisplayFormatter {
    static func inlineSource(_ value: String) -> String {
        value
            .replacingOccurrences(of: "-1/2", with: "-½")
            .replacingOccurrences(of: "1/2", with: "½")
    }

    static func plain(_ value: String) -> String {
        var result = inlineSource(value)
        let replacements = [
            ("^{0}", "⁰"), ("^{1}", "¹"), ("^{2}", "²"), ("^{3}", "³"),
            ("^{4}", "⁴"), ("^{5}", "⁵"), ("^{6}", "⁶"), ("^{7}", "⁷"),
            ("^{8}", "⁸"), ("^{9}", "⁹"),
            ("^0", "⁰"), ("^1", "¹"), ("^2", "²"), ("^3", "³"),
            ("^4", "⁴"), ("^5", "⁵"), ("^6", "⁶"), ("^7", "⁷"),
            ("^8", "⁸"), ("^9", "⁹")
        ]
        for (raw, display) in replacements {
            result = result.replacingOccurrences(of: raw, with: display)
        }
        return result
    }
}

private extension Text {
    func fontForMathSegment(
        _ kind: Segment.Kind,
        baseFont: Font,
        scriptFont: Font,
        scriptOffset: CGFloat,
        lowerScriptOffset: CGFloat
    ) -> Text {
        switch kind {
        case .normal:
            return self.font(baseFont)
        case .superscript:
            return self
                .font(scriptFont)
                .baselineOffset(scriptOffset)
        case .lowerScript:
            return self
                .font(scriptFont)
                .baselineOffset(lowerScriptOffset)
        }
    }
}

private struct Segment {
    enum Kind {
        case normal
        case superscript
        case lowerScript
    }

    let value: String
    let kind: Kind
}
