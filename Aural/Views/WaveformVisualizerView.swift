import SwiftUI

struct WaveformVisualizerView: View {
    let audioLevels: [Float]
    let barCount: Int
    let isLocked: Bool

    // Use a consistent seed per bar for variation
    private let barSeeds: [Float]
    // Phase offsets for staggered animation
    private let phaseOffsets: [Float]

    @State private var previousBarHeights: [CGFloat]

    init(audioLevels: [Float], barCount: Int = 80, isLocked: Bool = false) {
        self.audioLevels = audioLevels
        self.barCount = barCount
        self.isLocked = isLocked

        // Generate consistent variation factors for each bar (0.5 to 1.5)
        self.barSeeds = (0..<barCount).map { i in
            let normalized = Float(i) / Float(barCount)
            // Create a wave pattern for variation with more dynamic range
            return 0.6 + sin(normalized * .pi * 3) * 0.4 + cos(normalized * .pi * 5) * 0.3
        }

        // Generate phase offsets for smoother, more organic animation
        self.phaseOffsets = (0..<barCount).map { i in
            Float(i) * 0.05  // Small offset per bar
        }

        // Initialize previous bar heights
        _previousBarHeights = State(initialValue: Array(repeating: 8.0, count: barCount))
    }

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount)
            let barSpacing: CGFloat = 3  // Slightly reduced spacing for more bars
            let effectiveBarWidth = max(barWidth - barSpacing, 1.5)  // Thinner bars
            let minBarHeight: CGFloat = 8

            // Use darker colors for better contrast
            let baseColor: Color = isLocked ?
                Color(red: 0.2, green: 0.2, blue: 0.2) :
                Color(red: 0.15, green: 0.15, blue: 0.15)

            // Calculate average of recent levels for smoother response
            let recentLevels = audioLevels.suffix(5)  // Last 5 samples
            let currentLevel = recentLevels.isEmpty ? 0.0 : recentLevels.reduce(0.0, +) / Float(recentLevels.count)

            for i in 0..<barCount {
                // Apply variation to current level for this bar
                let barVariation = barSeeds[i]
                let targetLevel = currentLevel * barVariation

                // Calculate target bar height - Much taller!
                let maxHeight = size.height * 2.5  // Increased from 1.8 to 2.5 for much taller bars
                let targetHeight = max(CGFloat(targetLevel) * maxHeight, minBarHeight)

                // Smooth transition from previous height to target height
                let smoothingFactor: CGFloat = 0.3  // Higher = slower, smoother
                let smoothedHeight = previousBarHeights[i] * smoothingFactor + targetHeight * (1.0 - smoothingFactor)
                previousBarHeights[i] = smoothedHeight

                let barHeight = smoothedHeight

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

                let path = RoundedRectangle(cornerRadius: min(effectiveBarWidth / 2, 1.0))
                    .path(in: rect)

                // Use solid dark color with high opacity
                let opacity = 0.85 + (Double(targetLevel) * 0.15)
                context.fill(path, with: .color(baseColor.opacity(opacity)))
            }
        }
        .drawingGroup()
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
