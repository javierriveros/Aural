import SwiftUI

struct OrbRecordingView: View {
    let duration: TimeInterval
    let isLocked: Bool
    let audioLevel: Float
    let onTap: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            OrbVisualizerView(
                audioLevel: audioLevel,
                isLocked: isLocked
            )
            .frame(width: 260, height: 260)

            HStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: isLocked ? "lock.fill" : "mic.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(stateColor)
                }

                Text(formatDuration(duration))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Circle()
                    .fill(BrandColors.error)
                    .frame(width: 8, height: 8)
                    .opacity(pulseAnimation ? 0.3 : 1.0)
            }

            Text(instructionText)
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.xl)
        .padding(.horizontal, Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(.regularMaterial)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .fill(Color(nsColor: .windowBackgroundColor))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .strokeBorder(
                    LinearGradient(
                        colors: [stateColor.opacity(0.3), stateColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: stateColor.opacity(0.15), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(40)
        .onTapGesture { onTap() }
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
            return "Press shortcut to stop"
        } else {
            return "Release shortcut to stop"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        return duration.formattedAsRecordingDuration()
    }
}

#Preview("Unlocked Recording") {
    OrbRecordingView(
        duration: 12.5,
        isLocked: false,
        audioLevel: 0.4
    ) {}
    .frame(width: 400, height: 380)
}

#Preview("Locked Recording") {
    OrbRecordingView(
        duration: 45.8,
        isLocked: true,
        audioLevel: 0.6
    ) {}
    .frame(width: 400, height: 380)
}

#Preview("Idle State") {
    OrbRecordingView(
        duration: 0,
        isLocked: false,
        audioLevel: 0.0
    ) {}
    .frame(width: 400, height: 380)
}
