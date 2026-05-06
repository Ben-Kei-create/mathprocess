import SwiftUI

struct MathText: View {
    let text: String

    var body: some View {
        parsedText
            .font(TKType.equation)
    }

    private var parsedText: Text {
        parse(text).reduce(Text("")) { partial, segment in
            partial + rendered(segment)
        }
    }

    private func rendered(_ segment: Segment) -> Text {
        switch segment.kind {
        case .normal:
            return Text(segment.value)
        case .superscript:
            return Text(segment.value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .baselineOffset(10)
        case .lowerScript:
            return Text(segment.value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .baselineOffset(-6)
        }
    }

    private func parse(_ value: String) -> [Segment] {
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

    private func extractScript(from value: String, index: inout String.Index) -> String {
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

private struct Segment {
    enum Kind {
        case normal
        case superscript
        case lowerScript
    }

    let value: String
    let kind: Kind
}
