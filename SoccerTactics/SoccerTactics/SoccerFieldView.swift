import SwiftUI

/// Draws a top-down soccer pitch, scaled to fill whatever rect it's given.
struct SoccerFieldView: View {
    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .color(Color(red: 0.06, green: 0.35, blue: 0.14)))

            // Alternating mow stripes for a realistic pitch look.
            let stripeCount = 12
            let stripeWidth = size.width / CGFloat(stripeCount)
            for i in 0..<stripeCount where i % 2 == 0 {
                let stripeRect = CGRect(x: CGFloat(i) * stripeWidth, y: 0, width: stripeWidth, height: size.height)
                context.fill(Path(stripeRect), with: .color(.white.opacity(0.04)))
            }

            let lineStyle = StrokeStyle(lineWidth: max(2, size.width * 0.003), lineCap: .round)
            let line = GraphicsContext.Shading.color(.white.opacity(0.9))
            let margin = size.width * 0.02

            let playRect = rect.insetBy(dx: margin, dy: margin)
            context.stroke(Path(playRect), with: line, style: lineStyle)

            // Halfway line.
            var half = Path()
            half.move(to: CGPoint(x: playRect.midX, y: playRect.minY))
            half.addLine(to: CGPoint(x: playRect.midX, y: playRect.maxY))
            context.stroke(half, with: line, style: lineStyle)

            // Center circle + spot.
            let centerRadius = playRect.height * 0.16
            let centerCircle = Path(ellipseIn: CGRect(
                x: playRect.midX - centerRadius, y: playRect.midY - centerRadius,
                width: centerRadius * 2, height: centerRadius * 2))
            context.stroke(centerCircle, with: line, style: lineStyle)
            context.fill(Path(ellipseIn: CGRect(x: playRect.midX - 2, y: playRect.midY - 2, width: 4, height: 4)), with: line)

            // Penalty areas + goal areas + arcs, on left and right.
            let boxHeight = playRect.height * 0.62
            let boxWidth = playRect.width * 0.16
            let goalBoxHeight = playRect.height * 0.32
            let goalBoxWidth = playRect.width * 0.06
            let arcRadius = playRect.height * 0.16

            for side in [-1.0, 1.0] {
                let isLeft = side < 0
                let originX = isLeft ? playRect.minX : playRect.maxX

                let box = CGRect(
                    x: isLeft ? originX : originX - boxWidth,
                    y: playRect.midY - boxHeight / 2,
                    width: boxWidth, height: boxHeight)
                context.stroke(Path(box), with: line, style: lineStyle)

                let goalBox = CGRect(
                    x: isLeft ? originX : originX - goalBoxWidth,
                    y: playRect.midY - goalBoxHeight / 2,
                    width: goalBoxWidth, height: goalBoxHeight)
                context.stroke(Path(goalBox), with: line, style: lineStyle)

                let spotX = isLeft ? originX + boxWidth * 0.62 : originX - boxWidth * 0.62
                context.fill(Path(ellipseIn: CGRect(x: spotX - 2, y: playRect.midY - 2, width: 4, height: 4)), with: line)

                var arc = Path()
                let arcCenter = CGPoint(x: spotX, y: playRect.midY)
                let startAngle: Angle = isLeft ? .degrees(-53) : .degrees(127)
                let endAngle: Angle = isLeft ? .degrees(53) : .degrees(233)
                arc.addArc(center: arcCenter, radius: arcRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                context.stroke(arc, with: line, style: lineStyle)

                // Corner arcs.
                let cornerRadius = playRect.width * 0.02
                for corner in [playRect.minY, playRect.maxY] {
                    var cornerArc = Path()
                    let cStart: Angle = isLeft
                        ? (corner == playRect.minY ? .degrees(0) : .degrees(270))
                        : (corner == playRect.minY ? .degrees(90) : .degrees(180))
                    let cEnd: Angle = isLeft
                        ? (corner == playRect.minY ? .degrees(90) : .degrees(360))
                        : (corner == playRect.minY ? .degrees(180) : .degrees(270))
                    cornerArc.addArc(center: CGPoint(x: originX, y: corner), radius: cornerRadius, startAngle: cStart, endAngle: cEnd, clockwise: false)
                    context.stroke(cornerArc, with: line, style: lineStyle)
                }
            }
        }
    }
}

#Preview {
    SoccerFieldView()
        .frame(width: 700, height: 440)
}
