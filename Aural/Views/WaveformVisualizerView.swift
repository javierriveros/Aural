import SwiftUI

struct WaveformVisualizerView: View {
    let audioLevels: [Float]
    let barCount: Int
    let isLocked: Bool

    @State private var animationPhase: CGFloat = 0

    init(audioLevels: [Float], barCount: Int = 50, isLocked: Bool = false) {
        self.audioLevels = audioLevels
        self.barCount = barCount
        self.isLocked = isLocked
    }

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount)
            let barSpacing: CGFloat = 2
            let effectiveBarWidth = barWidth - barSpacing
            let minBarHeight: CGFloat = 4

            // Determine color based on lock state
            let gradient = isLocked ?
                Gradient(colors: [BrandColors.warning, BrandColors.warning.opacity(0.7)]) :
                Gradient(colors: [BrandColors.primaryBlue, BrandColors.primaryCyan])

            for i in 0..<barCount {
                // Get level for this bar (with bounds checking)
                let levelIndex = min(i * audioLevels.count / barCount, audioLevels.count - 1)
                let level = audioLevels[levelIndex]

                // Calculate bar height (minimum height for visibility)
                let maxHeight = size.height * 0.9
                var barHeight = max(CGFloat(level) * maxHeight, minBarHeight)

                // Add slight random variation for more organic feel when quiet
                if level < 0.1 {
                    let variation = sin(animationPhase + CGFloat(i) * 0.3) * 2
                    barHeight = max(barHeight + variation, minBarHeight)
                }

                // Calculate position (centered vertically)
                let x = CGFloat(i) * barWidth + barSpacing / 2
                let y = (size.height - barHeight) / 2

                // Create rounded rectangle for bar
                let rect = CGRect(
                    x: x,
                    y: y,
                    width: effectiveBarWidth,
                    height: barHeight
                )

                let path = RoundedRectangle(cornerRadius: effectiveBarWidth / 2)
                    .path(in: rect)

                // Calculate gradient position for this bar
                let gradientPosition = CGFloat(i) / CGFloat(barCount)
                let barColor = gradient.stops.interpolate(at: gradientPosition)

                // Draw the bar with slight opacity variation
                let opacity = 0.7 + (Double(level) * 0.3)
                context.fill(path, with: .color(barColor.opacity(opacity)))
            }
        }
        .onAppear {
            // Subtle animation for idle state
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
        }
    }
}

// Helper extension for gradient interpolation
private extension Gradient {
    var stops: [Gradient.Stop] {
        // Create default stops from colors if not explicitly defined
        let colors = [BrandColors.primaryBlue, BrandColors.primaryCyan]
        return colors.enumerated().map { index, color in
            Gradient.Stop(
                color: color,
                location: CGFloat(index) / CGFloat(max(colors.count - 1, 1))
            )
        }
    }
}

private extension Array where Element == Gradient.Stop {
    func interpolate(at position: CGFloat) -> Color {
        guard !isEmpty else { return .blue }
        if count == 1 { return first!.color }

        // Find surrounding stops
        var lowerStop = first!
        var upperStop = last!

        for i in 0..<(count - 1) {
            if position >= self[i].location && position <= self[i + 1].location {
                lowerStop = self[i]
                upperStop = self[i + 1]
                break
            }
        }

        // Simple interpolation (just return one of the colors for now)
        let range = upperStop.location - lowerStop.location
        if range == 0 { return lowerStop.color }

        let normalizedPosition = (position - lowerStop.location) / range
        return normalizedPosition < 0.5 ? lowerStop.color : upperStop.color
    }
}

#Preview("Active Recording") {
    VStack(spacing: 20) {
        // Simulate active recording with varying levels
        WaveformVisualizerView(
            audioLevels: (0..<60).map { i in
                Float(sin(Double(i) * 0.3) * 0.5 + 0.5)
            },
            isLocked: false
        )
        .frame(height: 100)
        .background(.black.opacity(0.1))

        // Locked state
        WaveformVisualizerView(
            audioLevels: (0..<60).map { i in
                Float(sin(Double(i) * 0.2) * 0.4 + 0.4)
            },
            isLocked: true
        )
        .frame(height: 100)
        .background(.black.opacity(0.1))

        // Quiet/idle state
        WaveformVisualizerView(
            audioLevels: Array(repeating: 0.05, count: 60),
            isLocked: false
        )
        .frame(height: 100)
        .background(.black.opacity(0.1))
    }
    .padding()
    .frame(width: 400)
}
