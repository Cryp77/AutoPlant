import SwiftUI

/// Transparent drawing surface layered over the pitch. Handles freehand pen
/// strokes and two-point arrows, and renders everything already committed.
struct WhiteboardView: View {
    @Binding var strokes: [Stroke]
    var tool: DrawTool
    var color: Color
    var lineWidth: CGFloat
    /// When false, drag gestures are ignored so tokens underneath/above can be dragged instead.
    var isDrawingEnabled: Bool

    @State private var activeStroke: Stroke?

    var body: some View {
        Canvas { context, _ in
            for stroke in strokes {
                draw(stroke, in: &context)
            }
            if let activeStroke {
                draw(activeStroke, in: &context)
            }
        }
        .contentShape(Rectangle())
        .allowsHitTesting(isDrawingEnabled)
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isDrawingEnabled else { return }
                switch tool {
                case .pen:
                    if activeStroke == nil {
                        activeStroke = Stroke(points: [value.location], color: color, lineWidth: lineWidth, isArrow: false)
                    } else {
                        activeStroke?.points.append(value.location)
                    }
                case .arrow:
                    activeStroke = Stroke(points: [value.startLocation, value.location], color: color, lineWidth: lineWidth, isArrow: true)
                }
            }
            .onEnded { _ in
                guard isDrawingEnabled else { return }
                if let activeStroke, activeStroke.points.count > 1 {
                    strokes.append(activeStroke)
                }
                activeStroke = nil
            }
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard stroke.points.count > 1 else { return }
        var path = Path()
        path.move(to: stroke.points[0])
        for point in stroke.points.dropFirst() {
            path.addLine(to: point)
        }
        let style = StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
        context.stroke(path, with: .color(stroke.color), style: style)

        if stroke.isArrow, let start = stroke.points.first, let end = stroke.points.last {
            context.stroke(arrowHead(from: start, to: end, lineWidth: stroke.lineWidth), with: .color(stroke.color), style: style)
        }
    }

    private func arrowHead(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat) -> Path {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength = max(14, lineWidth * 3)
        let headAngle = CGFloat.pi / 7

        let p1 = CGPoint(x: end.x - headLength * cos(angle - headAngle), y: end.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: end.x - headLength * cos(angle + headAngle), y: end.y - headLength * sin(angle + headAngle))

        var path = Path()
        path.move(to: p1)
        path.addLine(to: end)
        path.addLine(to: p2)
        return path
    }
}
