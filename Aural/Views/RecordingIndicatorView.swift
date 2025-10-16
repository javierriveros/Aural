import SwiftUI

struct RecordingIndicatorView: View {
    let isRecording: Bool
    let isLocked: Bool
    let duration: TimeInterval

    @State private var pulseAnimation = false
    @State private var breathAnimation = false
    @State private var rotationAnimation = 0.0

    var body: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(BrandColors.gradientPrimary)
                    .frame(width: 120, height: 120)
                    .scaleEffect(breathAnimation ? 1.1 : 1.0)
                    .opacity(breathAnimation ? 0.3 : 0.6)
                    .blur(radius: 20)
                    .animation(
                        isRecording ? .easeInOut(duration: 2.0).repeatForever(autoreverses: true) : .default,
                        value: breathAnimation
                    )

                Circle()
                    .fill(isRecording ? BrandColors.gradientPrimary : BrandColors.gradientSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(lineWidth: 2)
                            .fill(.white.opacity(0.3))
                    )
                    .shadow(color: BrandColors.primaryBlue.opacity(0.3), radius: 20, x: 0, y: 10)

                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(rotationAnimation))
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                        value: pulseAnimation
                    )

                if isLocked && isRecording {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(BrandColors.warning)
                                .clipShape(Circle())
                                .shadow(color: BrandColors.warning.opacity(0.5), radius: 8, x: 0, y: 4)
                                .offset(x: 8, y: 8)
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            .frame(height: 120)

            VStack(spacing: Spacing.xs) {
                Text(recordingStatusText)
                    .font(Typography.title2)
                    .foregroundStyle(isRecording ? BrandColors.primaryBlue : .primary)

                if isRecording {
                    Text(formatDuration(duration))
                        .font(Typography.monoBody)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Ready to transcribe")
                        .font(Typography.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.lg)
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
            breathAnimation = newValue
            if newValue {
                withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                    rotationAnimation = 360
                }
            } else {
                rotationAnimation = 0
            }
        }
    }

    private var recordingStatusText: String {
        if isRecording {
            return isLocked ? "Recording (Locked)" : "Recording"
        }
        return "Ready"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        RecordingIndicatorView(isRecording: false, isLocked: false, duration: 0)
        RecordingIndicatorView(isRecording: true, isLocked: false, duration: 45.3)
        RecordingIndicatorView(isRecording: true, isLocked: true, duration: 102.7)
    }
    .padding()
}
