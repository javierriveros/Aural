import SwiftUI

struct WaveformVisualizerView: View {
    let audioLevels: [Float]
    let barCount: Int
    let isLocked: Bool

    init(audioLevels: [Float], barCount: Int = 50, isLocked: Bool = false) {
        self.audioLevels = audioLevels
        self.barCount = barCount
        self.isLocked = isLocked
    }

    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount)
            let barSpacing: CGFloat = 4  // Increased spacing for thinner bars
            let effectiveBarWidth = max(barWidth - barSpacing, 2)  // Thinner bars
            let minBarHeight: CGFloat = 6

            // Use darker colors - black/dark gray for better contrast
            let baseColor: Color = isLocked ?
                Color(red: 0.2, green: 0.2, blue: 0.2) :  // Dark gray for locked
                Color(red: 0.15, green: 0.15, blue: 0.15)  // Almost black for unlocked

            for i in 0..<barCount {
                // Get level for this bar (with bounds checking)
                let levelIndex = min(i * audioLevels.count / barCount, audioLevels.count - 1)
                let level = audioLevels[levelIndex]

                // Calculate bar height - Much taller! Use more of the available height
                let maxHeight = size.height * 1.8  // Increased from 0.9 to 1.8 for much taller bars
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

                // Use solid dark color with high opacity for strong contrast
                let opacity = 0.85 + (Double(level) * 0.15)  // Higher base opacity
                context.fill(path, with: .color(baseColor.opacity(opacity)))
            }
        }
        .drawingGroup()  // Enable Metal acceleration for smoother rendering
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
