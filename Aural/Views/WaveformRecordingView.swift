import SwiftUI

struct WaveformRecordingView: View {
    let duration: TimeInterval
    let isLocked: Bool
    let audioLevels: [Float]
    let onTap: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Waveform visualizer with more height
            WaveformVisualizerView(
                audioLevels: audioLevels,
                barCount: 50,
                isLocked: isLocked
            )
            .frame(height: 120)  // Increased height for taller bars
            .padding(.horizontal, Spacing.lg)

            // Recording info
            HStack(spacing: Spacing.sm) {
                // Mic/Lock icon
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: isLocked ? "lock.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(stateColor)
                }

                // Duration
                Text(formatDuration(duration))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                // Recording indicator dot
                Circle()
                    .fill(BrandColors.error)
                    .frame(width: 8, height: 8)
                    .opacity(pulseAnimation ? 0.3 : 1.0)
            }

            // Tap to stop hint
            Text(instructionText)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.lg)
        .padding(.horizontal, Spacing.xl)
        .background(
            // Clean white background with material
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color.white)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(
                    Color.black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
        .onTapGesture {
            onTap()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }

    private var stateColor: Color {
        isLocked ? BrandColors.warning : BrandColors.primaryBlue
    }

    private var instructionText: String {
        if isLocked {
            return "Tap anywhere to stop"
        } else {
            return "Hold key to continue recording"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        return duration.formattedAsRecordingDuration()
    }
}

#Preview("Unlocked Recording") {
    WaveformRecordingView(
        duration: 12.5,
        isLocked: false,
        audioLevels: (0..<60).map { i in
            Float(sin(Double(i) * 0.3) * 0.5 + 0.5)
        },
        onTap: {}
    )
    .padding(40)
    .frame(width: 500, height: 250)
}

#Preview("Locked Recording") {
    WaveformRecordingView(
        duration: 45.8,
        isLocked: true,
        audioLevels: (0..<60).map { i in
            Float(sin(Double(i) * 0.2) * 0.4 + 0.6)
        },
        onTap: {}
    )
    .padding(40)
    .frame(width: 500, height: 250)
}
