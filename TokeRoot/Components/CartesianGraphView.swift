import Foundation
import SwiftUI

struct CartesianGraphView: View {
    let graph: CartesianGraph

    private struct PlotLayout {
        let plot: CGRect
        let bounds: GraphBounds
    }

    private struct GraphBounds {
        let xMin: Double
        let xMax: Double
        let yMin: Double
        let yMax: Double

        var span: Double { max(xMax - xMin, yMax - yMin) }
    }

    var body: some View {
        Canvas { context, size in
            let layout = makeLayout(in: size)

            drawGrid(in: layout, context: &context)
            drawAxes(in: layout, context: &context)
            drawParabolas(in: layout, context: &context)
            drawLines(in: layout, context: &context)
            drawPoints(in: layout, context: &context)
        }
        .frame(maxWidth: .infinity)
        .frame(height: graph.parabolas.isEmpty ? 300 : 340)
        .background(TKColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: TKRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: TKRadius.medium)
                .stroke(TKColor.divider, lineWidth: 1)
        )
    }

    private func makeLayout(in size: CGSize) -> PlotLayout {
        let leftMargin: CGFloat = 38
        let rightMargin: CGFloat = 16
        let topMargin: CGFloat = 18
        let bottomMargin: CGFloat = 34
        let available = CGRect(
            x: leftMargin,
            y: topMargin,
            width: max(size.width - leftMargin - rightMargin, 1),
            height: max(size.height - topMargin - bottomMargin, 1)
        )
        let side = max(min(available.width, available.height), 1)
        let plot = CGRect(
            x: available.midX - side / 2,
            y: available.midY - side / 2,
            width: side,
            height: side
        )

        let xRange = max(graph.xMax - graph.xMin, 0.0001)
        let yRange = max(graph.yMax - graph.yMin, 0.0001)
        let span = max(xRange, yRange)
        let xCenter = (graph.xMin + graph.xMax) / 2
        let yCenter = (graph.yMin + graph.yMax) / 2
        let bounds = GraphBounds(
            xMin: xCenter - span / 2,
            xMax: xCenter + span / 2,
            yMin: yCenter - span / 2,
            yMax: yCenter + span / 2
        )

        return PlotLayout(plot: plot, bounds: bounds)
    }

    private func drawGrid(in layout: PlotLayout, context: inout GraphicsContext) {
        let plot = layout.plot
        let bounds = layout.bounds
        let labelStep = labelStep(for: bounds.span)

        for x in tickValues(min: bounds.xMin, max: bounds.xMax, step: 1) {
            let p = point(x: x, y: bounds.yMin, in: layout)
            var path = Path()
            path.move(to: CGPoint(x: p.x, y: plot.minY))
            path.addLine(to: CGPoint(x: p.x, y: plot.maxY))
            context.stroke(path, with: .color(TKColor.divider.opacity(0.55)), lineWidth: 1)

            if !isZero(x), isTickLabel(x, step: labelStep) {
                context.draw(
                    Text(tickText(x)).font(TKType.caption).foregroundStyle(TKColor.textTertiary),
                    at: CGPoint(x: p.x, y: plot.maxY + 14)
                )
            }
        }

        for y in tickValues(min: bounds.yMin, max: bounds.yMax, step: 1) {
            let p = point(x: bounds.xMin, y: y, in: layout)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: p.y))
            path.addLine(to: CGPoint(x: plot.maxX, y: p.y))
            context.stroke(path, with: .color(TKColor.divider.opacity(0.55)), lineWidth: 1)

            if !isZero(y), isTickLabel(y, step: labelStep) {
                context.draw(
                    Text(tickText(y)).font(TKType.caption).foregroundStyle(TKColor.textTertiary),
                    at: CGPoint(x: plot.minX - 16, y: p.y)
                )
            }
        }
    }

    private func drawAxes(in layout: PlotLayout, context: inout GraphicsContext) {
        let plot = layout.plot
        let bounds = layout.bounds

        if bounds.xMin <= 0 && bounds.xMax >= 0 {
            let p = point(x: 0, y: bounds.yMin, in: layout)
            var path = Path()
            path.move(to: CGPoint(x: p.x, y: plot.minY))
            path.addLine(to: CGPoint(x: p.x, y: plot.maxY))
            context.stroke(path, with: .color(TKColor.textSecondary), lineWidth: 1.5)
            context.draw(
                Text("y").font(TKType.caption).foregroundStyle(TKColor.textSecondary),
                at: CGPoint(x: p.x + 10, y: plot.minY + 8)
            )
        }

        if bounds.yMin <= 0 && bounds.yMax >= 0 {
            let p = point(x: bounds.xMin, y: 0, in: layout)
            var path = Path()
            path.move(to: CGPoint(x: plot.minX, y: p.y))
            path.addLine(to: CGPoint(x: plot.maxX, y: p.y))
            context.stroke(path, with: .color(TKColor.textSecondary), lineWidth: 1.5)
            context.draw(
                Text("x").font(TKType.caption).foregroundStyle(TKColor.textSecondary),
                at: CGPoint(x: plot.maxX - 8, y: p.y - 12)
            )
        }

        let origin = point(x: 0, y: 0, in: layout)
        if plot.contains(origin) {
            context.draw(
                Text("0").font(TKType.caption).foregroundStyle(TKColor.textSecondary),
                at: CGPoint(x: origin.x - 12, y: origin.y + 12)
            )
        }
    }

    private func drawParabolas(in layout: PlotLayout, context: inout GraphicsContext) {
        guard !graph.parabolas.isEmpty else { return }

        for (index, parabola) in graph.parabolas.enumerated() {
            let color = graphColor(at: index)
            let startX = max(min(parabola.xStart, parabola.xEnd), layout.bounds.xMin)
            let endX = min(max(parabola.xStart, parabola.xEnd), layout.bounds.xMax)
            guard startX < endX else { continue }

            var path = Path()
            let sampleCount = 120
            for index in 0...sampleCount {
                let t = Double(index) / Double(sampleCount)
                let x = startX + (endX - startX) * t
                let y = parabola.a * pow(x - parabola.h, 2) + parabola.k
                let p = point(x: x, y: y, in: layout)
                if index == 0 {
                    path.move(to: p)
                } else {
                    path.addLine(to: p)
                }
            }

            var clipped = context
            clipped.clip(to: Path(layout.plot))
            clipped.stroke(path, with: .color(color), lineWidth: 3)

            if let label = parabola.label {
                let labelX = endX - (endX - startX) * 0.18
                let labelY = parabola.a * pow(labelX - parabola.h, 2) + parabola.k
                let labelPoint = point(x: labelX, y: labelY, in: layout)
                drawLabel(
                    label,
                    at: CGPoint(x: labelPoint.x - 22, y: labelPoint.y - 20),
                    in: layout.plot,
                    foreground: color,
                    context: &context
                )
            }
        }
    }

    private func drawLines(in layout: PlotLayout, context: inout GraphicsContext) {
        let plot = layout.plot

        for (index, line) in graph.lines.enumerated() {
            let color = graphColor(at: index)
            let start = point(x: line.x1, y: line.y1, in: layout)
            let end = point(x: line.x2, y: line.y2, in: layout)
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)

            var clipped = context
            clipped.clip(to: Path(plot))
            clipped.stroke(path, with: .color(color), lineWidth: 3)

            if let label = line.label {
                drawLabel(
                    label,
                    at: CGPoint(x: end.x - 42, y: end.y - 22),
                    in: plot,
                    foreground: color,
                    context: &context
                )
            }
        }
    }

    private func drawPoints(in layout: PlotLayout, context: inout GraphicsContext) {
        let plot = layout.plot

        for graphPoint in graph.points {
            let p = point(x: graphPoint.x, y: graphPoint.y, in: layout)
            guard plot.insetBy(dx: -8, dy: -8).contains(p) else { continue }

            let rect = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: rect), with: .color(TKColor.warm))

            if let label = graphPoint.label {
                drawLabel(
                    label,
                    at: CGPoint(x: p.x + 30, y: p.y - 16),
                    in: plot,
                    foreground: TKColor.textPrimary,
                    context: &context
                )
            }
        }
    }

    private func point(x: Double, y: Double, in layout: PlotLayout) -> CGPoint {
        let bounds = layout.bounds
        let plot = layout.plot
        let xRange = max(bounds.xMax - bounds.xMin, 0.0001)
        let yRange = max(bounds.yMax - bounds.yMin, 0.0001)
        let px = plot.minX + ((x - bounds.xMin) / xRange) * plot.width
        let py = plot.maxY - ((y - bounds.yMin) / yRange) * plot.height
        return CGPoint(x: px, y: py)
    }

    private func tickValues(min: Double, max: Double, step: Double) -> [Double] {
        let start = ceil(min / step) * step
        let end = floor(max / step) * step
        var values: [Double] = []
        var current = start
        while current <= end + 0.0001 {
            values.append(current)
            current += step
        }
        return values
    }

    private func labelStep(for span: Double) -> Double {
        if span <= 12 { return 1 }
        if span <= 24 { return 2 }
        return 5
    }

    private func isTickLabel(_ value: Double, step: Double) -> Bool {
        let divided = value / step
        return abs(divided - divided.rounded()) < 0.0001
    }

    private func tickText(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.0001 {
            return "\(Int(rounded))"
        }
        return String(format: "%.1f", value)
    }

    private func isZero(_ value: Double) -> Bool {
        abs(value) < 0.0001
    }

    private func graphColor(at index: Int) -> Color {
        let colors = [
            TKColor.accent,
            TKColor.warm,
            TKColor.success,
            TKColor.textSecondary
        ]
        return colors[index % colors.count]
    }

    private func drawLabel(
        _ label: String,
        at proposedCenter: CGPoint,
        in plot: CGRect,
        foreground: Color,
        context: inout GraphicsContext
    ) {
        let displayLabel = MathDisplayFormatter.plain(label)
        let width = CGFloat(max(displayLabel.count, 1)) * 7.2 + 12
        let height: CGFloat = 20
        let center = CGPoint(
            x: min(max(proposedCenter.x, plot.minX + width / 2 + 4), plot.maxX - width / 2 - 4),
            y: min(max(proposedCenter.y, plot.minY + height / 2 + 4), plot.maxY - height / 2 - 4)
        )
        let rect = CGRect(
            x: center.x - width / 2,
            y: center.y - height / 2,
            width: width,
            height: height
        )
        let bubble = Path(roundedRect: rect, cornerRadius: 6)
        context.fill(bubble, with: .color(TKColor.surface.opacity(0.94)))
        context.stroke(bubble, with: .color(TKColor.divider.opacity(0.8)), lineWidth: 0.7)
        context.draw(
            Text(displayLabel).font(TKType.caption).foregroundStyle(foreground),
            at: center
        )
    }
}
