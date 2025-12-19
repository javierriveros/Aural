import SwiftUI

struct OrbVisualizerView: View {
    let audioLevel: Float
    let isLocked: Bool

    private let controlPointCount = 8
    private let baseRadius: CGFloat = 50
    private let maxMorphAmount: CGFloat = 25
    private let glowRadius: CGFloat = 30

    @State private var animationTime: Double = 0
    @State private var displayedLevel: Float = 0
    @State private var displayedVelocity: Float = 0
    @State private var previousLevel: Float = 0

    private let springResponse: Double = 0.3
    private let springDamping: Double = 0.7

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let currentTime = timeline.date.timeIntervalSinceReferenceDate
                let targetLevel = CGFloat(audioLevel)
                let velocity = abs(audioLevel - previousLevel) * 10

                drawGlowLayers(context: context, center: center, level: targetLevel)

                let blobPath = createBlobPath(
                    center: center,
                    time: currentTime,
                    level: targetLevel,
                    velocity: CGFloat(velocity)
                )

                let gradient = Gradient(colors: gradientColors)
                context.fill(
                    blobPath,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: center.x - baseRadius, y: center.y - baseRadius),
                        endPoint: CGPoint(x: center.x + baseRadius, y: center.y + baseRadius)
                    )
                )

                drawInnerHighlight(context: context, center: center, level: targetLevel, time: currentTime)
            }
            .onChange(of: timeline.date) { _, _ in
                withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                    displayedLevel = audioLevel
                    displayedVelocity = abs(audioLevel - previousLevel) * 10
                    previousLevel = audioLevel
                }
            }
        }
        .drawingGroup()
    }

    private var gradientColors: [Color] {
        if isLocked {
            return [
                BrandColors.warning.opacity(0.9),
                BrandColors.warning.opacity(0.7)
            ]
        } else {
            return [
                BrandColors.primaryBlue.opacity(0.9),
                BrandColors.primaryCyan.opacity(0.8)
            ]
        }
    }

    private var glowColor: Color {
        isLocked ? BrandColors.warning : BrandColors.primaryCyan
    }

    private func drawGlowLayers(context: GraphicsContext, center: CGPoint, level: CGFloat) {
        let glowIntensity = 0.15 + (level * 0.25)
        let glowScale = 1.0 + (level * 0.25)

        let outerGlowRadius = baseRadius * glowScale * 1.5
        let outerGlowRect = CGRect(
            x: center.x - outerGlowRadius,
            y: center.y - outerGlowRadius,
            width: outerGlowRadius * 2,
            height: outerGlowRadius * 2
        )
        context.fill(
            Circle().path(in: outerGlowRect),
            with: .color(glowColor.opacity(glowIntensity * 0.3))
        )

        let midGlowRadius = baseRadius * glowScale * 1.4
        let midGlowRect = CGRect(
            x: center.x - midGlowRadius,
            y: center.y - midGlowRadius,
            width: midGlowRadius * 2,
            height: midGlowRadius * 2
        )
        context.fill(
            Circle().path(in: midGlowRect),
            with: .color(glowColor.opacity(glowIntensity * 0.5))
        )

        let innerGlowRadius = baseRadius * glowScale * 1.15
        let innerGlowRect = CGRect(
            x: center.x - innerGlowRadius,
            y: center.y - innerGlowRadius,
            width: innerGlowRadius * 2,
            height: innerGlowRadius * 2
        )
        context.fill(
            Circle().path(in: innerGlowRect),
            with: .color(glowColor.opacity(glowIntensity * 0.7))
        )
    }

    private func createBlobPath(
        center: CGPoint,
        time: Double,
        level: CGFloat,
        velocity: CGFloat
    ) -> Path {
        let scaleFactor = 1.0 + (level * 0.5)
        let morphAmount = maxMorphAmount * (0.2 + level * 0.8) * (1.0 + velocity * 0.3)
        var points: [CGPoint] = []

        for controlPointIndex in 0..<controlPointCount {
            let angle = (Double(controlPointIndex) / Double(controlPointCount)) * 2 * .pi
            let noiseX = cos(angle) * 0.5 + time * 0.8
            let noiseY = sin(angle) * 0.5 + time * 0.8
            let noise = SimplexNoise.fbm(x: noiseX, y: noiseY, octaves: 2, persistence: 0.5)

            let radiusOffset = CGFloat(noise) * morphAmount
            let radius = (baseRadius + radiusOffset) * scaleFactor

            let xCoord = center.x + cos(angle) * radius
            let yCoord = center.y + sin(angle) * radius
            points.append(CGPoint(x: xCoord, y: yCoord))
        }

        return createSmoothPath(through: points)
    }

    private func createSmoothPath(through points: [CGPoint]) -> Path {
        guard points.count >= 3 else { return Path() }

        var path = Path()
        let pointCount = points.count
        path.move(to: points[0])

        for currentIndex in 0..<pointCount {
            let previousPoint = points[(currentIndex - 1 + pointCount) % pointCount]
            let currentPoint = points[currentIndex]
            let nextPoint = points[(currentIndex + 1) % pointCount]
            let nextNextPoint = points[(currentIndex + 2) % pointCount]

            let controlPoint1 = CGPoint(
                x: currentPoint.x + (nextPoint.x - previousPoint.x) / 6,
                y: currentPoint.y + (nextPoint.y - previousPoint.y) / 6
            )

            let controlPoint2 = CGPoint(
                x: nextPoint.x - (nextNextPoint.x - currentPoint.x) / 6,
                y: nextPoint.y - (nextNextPoint.y - currentPoint.y) / 6
            )

            path.addCurve(to: nextPoint, control1: controlPoint1, control2: controlPoint2)
        }

        path.closeSubpath()
        return path
    }

    private func drawInnerHighlight(
        context: GraphicsContext,
        center: CGPoint,
        level: CGFloat,
        time: Double
    ) {
        let highlightRadius = baseRadius * 0.4 * (1.0 + level * 0.3)
        let highlightOffset = baseRadius * 0.25
        let highlightCenter = CGPoint(
            x: center.x - highlightOffset * 0.5,
            y: center.y - highlightOffset * 0.7
        )

        let highlightRect = CGRect(
            x: highlightCenter.x - highlightRadius,
            y: highlightCenter.y - highlightRadius,
            width: highlightRadius * 2,
            height: highlightRadius * 2
        )

        context.fill(
            Ellipse().path(in: highlightRect),
            with: .color(.white.opacity(0.15 + level * 0.1))
        )
    }
}

#Preview("Orb Visualizer") {
    VStack(spacing: 40) {
        HStack(spacing: 40) {
            VStack {
                OrbVisualizerView(audioLevel: 0.0, isLocked: false)
                    .frame(width: 150, height: 150)
                Text("Idle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                OrbVisualizerView(audioLevel: 0.3, isLocked: false)
                    .frame(width: 150, height: 150)
                Text("Soft Speech")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack {
                OrbVisualizerView(audioLevel: 0.8, isLocked: false)
                    .frame(width: 150, height: 150)
                Text("Loud Speech")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        HStack(spacing: 40) {
            VStack {
                OrbVisualizerView(audioLevel: 0.5, isLocked: true)
                    .frame(width: 150, height: 150)
                Text("Locked Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding(40)
    .background(Color(nsColor: .windowBackgroundColor))
}

#Preview("Orb Dark Background") {
    OrbVisualizerView(audioLevel: 0.5, isLocked: false)
        .frame(width: 200, height: 200)
        .background(.black)
}
