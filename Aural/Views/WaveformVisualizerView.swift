import SwiftUI

struct WaveformVisualizerView: View {
    let audioLevels: [Float]
    let barCount: Int
    let isLocked: Bool

    // Use a consistent seed per bar for variation
    private let barSeeds: [Float]

    init(audioLevels: [Float], barCount: Int = 50, isLocked: Bool = false) {
        self.audioLevels = audioLevels
        self.barCount = barCount
        self.isLocked = isLocked

        // Generate consistent variation factors for each bar (0.6 to 1.4)
        self.barSeeds = (0..<barCount).map { i in
            let normalized = Float(i) / Float(barCount)
            // Create a wave pattern for variation
            return 0.7 + sin(normalized * .pi * 4) * 0.3 + cos(normalized * .pi * 6) * 0.2
        }
    }

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount)
            let barSpacing: CGFloat = 4
            let effectiveBarWidth = max(barWidth - barSpacing, 2)
            let minBarHeight: CGFloat = 6

            // Use darker colors for better contrast
            let baseColor: Color = isLocked ?
                Color(red: 0.2, green: 0.2, blue: 0.2) :
                Color(red: 0.15, green: 0.15, blue: 0.15)

            // Get current audio level (use the most recent value)
            let currentLevel = audioLevels.last ?? 0.0

            for i in 0..<barCount {
                // Apply variation to current level for this bar
                let barVariation = barSeeds[i]
                let level = currentLevel * barVariation

                // Calculate bar height
                let maxHeight = size.height * 1.8
                let barHeight = max(CGFloat(level) * maxHeight, minBarHeight)

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

                let path = RoundedRectangle(cornerRadius: min(effectiveBarWidth / 2, 1.5))
                    .path(in: rect)

                // Use solid dark color with high opacity
                let opacity = 0.85 + (Double(level) * 0.15)
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
