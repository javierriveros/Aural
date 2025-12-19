import SwiftUI

enum WidgetState {
    case idle
    case recording(duration: TimeInterval, isLocked: Bool)
    case transcribing
}

struct FloatingWidgetView: View {
    let state: WidgetState
    let onTap: () -> Void

    @State private var pulseAnimation = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                Circle()
                    .fill(stateColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 1.0)
                    .animation(
                        isRecording ? .easeOut(duration: 1.5).repeatForever(autoreverses: false) : .default,
                        value: pulseAnimation
                    )

                Circle()
                    .fill(stateColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                stateIcon
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(stateColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(stateTitle)
                    .font(Typography.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                if let subtitle = stateSubtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if case .recording = state {
                Spacer()
                recordingIndicator
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .strokeBorder(
                    LinearGradient(
                        colors: isRecording ? [BrandColors.primaryBlue.opacity(0.3), BrandColors.primaryCyan.opacity(0.3)] : [.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isRecording ? BrandColors.primaryBlue.opacity(0.15) : .black.opacity(0.1),
            radius: isRecording ? 8 : 4,
            x: 0,
            y: 2
        )
        .compositingGroup()
        .padding(20)
        .onTapGesture {
            onTap()
        }
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
    }

    private var isRecording: Bool {
        if case .recording = state {
            return true
        }
        return false
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "mic.slash")
        case .recording(_, let isLocked):
            if isLocked {
                Image(systemName: "lock.fill")
            } else {
                Image(systemName: "mic.fill")
            }
        case .transcribing:
            ProgressView()
                .scaleEffect(0.8)
        }
    }

    private var stateColor: Color {
        switch state {
        case .idle:
            return .secondary
        case .recording(_, let isLocked):
            return isLocked ? BrandColors.warning : BrandColors.error
        case .transcribing:
            return BrandColors.primaryBlue
        }
    }

    private var stateTitle: String {
        switch state {
        case .idle:
            return "Ready"
        case .recording(_, let isLocked):
            return isLocked ? "Recording (Locked)" : "Recording"
        case .transcribing:
            return "Transcribing"
        }
    }

    private var stateSubtitle: String? {
        switch state {
        case .idle:
            return "Hold Fn to record"
        case .recording(let duration, _):
            return formatDuration(duration)
        case .transcribing:
            return "Processing audio..."
        }
    }

    @ViewBuilder
    private var recordingIndicator: some View {
        Circle()
            .fill(BrandColors.error)
            .frame(width: 8, height: 8)
            .opacity(0.8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        return duration.formattedAsRecordingDuration()
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingWidgetView(state: .idle) {}
        FloatingWidgetView(state: .recording(duration: 5.3, isLocked: false)) {}
        FloatingWidgetView(state: .recording(duration: 65.5, isLocked: true)) {}
        FloatingWidgetView(state: .transcribing) {}
    }
    .padding()
    .frame(width: 300)
}
