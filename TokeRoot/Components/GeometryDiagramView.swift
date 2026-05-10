import SwiftUI

struct GeometryDiagramView: View {
    let diagram: GeometryDiagram
    var showPointLabels = true
    var showAngleNames = true
    var showMeasurements = true

    var body: some View {
        Canvas { context, size in
            let points = Dictionary(uniqueKeysWithValues: diagram.points.map {
                ($0.id, CGPoint(x: $0.x * size.width, y: $0.y * size.height))
            })

            for segment in diagram.segments {
                guard let start = points[segment.start],
                      let end = points[segment.end] else { continue }
                var path = Path()
                path.move(to: start)
                path.addLine(to: end)
                context.stroke(path, with: .color(TKColor.textSecondary), lineWidth: 2)
            }

            for angle in diagram.angles {
                guard let vertex = points[angle.vertex] else { continue }
                let radius = angle.radius <= 1
                    ? angle.radius * min(size.width, size.height)
                    : angle.radius
                var path = Path()
                path.addArc(
                    center: vertex,
                    radius: radius,
                    startAngle: .degrees(angle.startDegrees),
                    endAngle: .degrees(angle.endDegrees),
                    clockwise: false
                )
                context.stroke(path, with: .color(TKColor.accent), lineWidth: 2)
            }

            for point in diagram.points {
                guard let position = points[point.id] else { continue }
                let dot = Path(ellipseIn: CGRect(
                    x: position.x - 3,
                    y: position.y - 3,
                    width: 6,
                    height: 6
                ))
                context.fill(dot, with: .color(TKColor.textPrimary))
                if showPointLabels {
                    let text = point.label ?? point.id
                    let labelPoint = CGPoint(x: position.x + 12, y: position.y - 12)
                    drawLabel(text, at: labelPoint, in: &context, color: TKColor.textPrimary)
                }
            }

            for label in diagram.labels {
                guard shouldDraw(label.text) else { continue }
                drawLabel(
                    label.text,
                    at: CGPoint(x: label.x * size.width, y: label.y * size.height),
                    in: &context,
                    color: TKColor.textSecondary
                )
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(diagram.aspectRatio, contentMode: .fit)
        .padding(TKSpacing.md)
        .background(TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.divider, lineWidth: 1)
        )
    }

    private func shouldDraw(_ text: String) -> Bool {
        if isAngleName(text) {
            return showAngleNames
        }
        if isMeasurement(text) {
            return showMeasurements
        }
        return true
    }

    private func isAngleName(_ text: String) -> Bool {
        text.contains("∠") || text.contains("角")
    }

    private func isMeasurement(_ text: String) -> Bool {
        if text.contains("°") || text.contains("度") { return true }
        if text.lowercased() == "x" { return true }
        return text.range(of: #"^-?\d+(\.\d+)?$"#, options: .regularExpression) != nil
    }

    private func drawLabel(
        _ text: String,
        at point: CGPoint,
        in context: inout GraphicsContext,
        color: Color
    ) {
        let rect = labelBackgroundRect(for: text, centeredAt: point)
        let background = Path(
            roundedRect: rect,
            cornerRadius: TKRadius.small
        )
        context.fill(background, with: .color(TKColor.surface.opacity(0.92)))
        context.stroke(background, with: .color(TKColor.divider.opacity(0.8)), lineWidth: 0.6)
        context.draw(
            Text(text)
                .font(TKType.caption)
                .foregroundStyle(color),
            at: point
        )
    }

    private func labelBackgroundRect(for text: String, centeredAt point: CGPoint) -> CGRect {
        let width = max(24, CGFloat(text.count) * 9 + 12)
        let height: CGFloat = 22
        return CGRect(
            x: point.x - width / 2,
            y: point.y - height / 2,
            width: width,
            height: height
        )
    }
}
