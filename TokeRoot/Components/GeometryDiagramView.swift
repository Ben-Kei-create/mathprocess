import SwiftUI

struct GeometryDiagramView: View {
    let diagram: GeometryDiagram

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
                context.draw(
                    Text(point.label ?? point.id)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textPrimary),
                    at: CGPoint(x: position.x + 12, y: position.y - 12)
                )
            }

            for label in diagram.labels {
                context.draw(
                    Text(label.text)
                        .font(TKType.caption)
                        .foregroundStyle(TKColor.textSecondary),
                    at: CGPoint(x: label.x * size.width, y: label.y * size.height)
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
}
