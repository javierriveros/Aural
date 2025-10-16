import SwiftUI

struct RecordingIndicatorView: View {
    let isRecording: Bool
    let duration: TimeInterval

    @State private var pulseAnimation = false

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(pulseAnimation ? 0.6 : 1.0)
                .animation(
                    isRecording ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                    value: pulseAnimation
                )

            Text(isRecording ? "Recording" : "Ready")
                .font(.headline)

            if isRecording {
                Text(formatDuration(duration))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .onChange(of: isRecording) { _, newValue in
            pulseAnimation = newValue
        }
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
        RecordingIndicatorView(isRecording: false, duration: 0)
        RecordingIndicatorView(isRecording: true, duration: 45.3)
    }
    .padding()
}
