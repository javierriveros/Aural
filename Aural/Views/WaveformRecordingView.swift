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
            Text(isLocked ? "Tap to stop recording" : "Release to stop")
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.lg)
        .padding(.horizontal, Spacing.xl)
        .background(
            ZStack {
                // Darker background with gradient for depth
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Subtle material overlay
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .fill(.thinMaterial)
                    .opacity(0.5)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(
                    Color.black.opacity(0.08),
                    lineWidth: 1
                )
        )
        // Multiple shadow layers for depth
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 2
        )
        .shadow(
            color: Color.black.opacity(0.12),
            radius: 12,
            x: 0,
            y: 6
        )
        .shadow(
            color: Color.black.opacity(0.16),
            radius: 32,
            x: 0,
            y: 12
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
