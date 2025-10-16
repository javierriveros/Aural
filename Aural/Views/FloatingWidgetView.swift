import SwiftUI

enum WidgetState {
    case idle
    case recording(duration: TimeInterval, isLocked: Bool)
    case transcribing
}

struct FloatingWidgetView: View {
    let state: WidgetState
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            stateIcon
                .font(.title2)
                .foregroundStyle(stateColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(stateTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle = stateSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if case .recording = state {
                Spacer()
                recordingIndicator
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
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
            return .gray
        case .recording(_, let isLocked):
            return isLocked ? .orange : .red
        case .transcribing:
            return .blue
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
            .fill(.red)
            .frame(width: 8, height: 8)
            .opacity(0.8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        FloatingWidgetView(state: .idle, onTap: {})
        FloatingWidgetView(state: .recording(duration: 5.3, isLocked: false), onTap: {})
        FloatingWidgetView(state: .recording(duration: 65.5, isLocked: true), onTap: {})
        FloatingWidgetView(state: .transcribing, onTap: {})
    }
    .padding()
    .frame(width: 300)
}
