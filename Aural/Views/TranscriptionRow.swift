import SwiftUI
import SwiftData

struct TranscriptionRow: View {
    let transcription: Transcription
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transcription.timestamp, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(formatDuration(transcription.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(transcription.text)
                .font(.body)
                .textSelection(.enabled)
                .lineLimit(3)

            HStack {
                Button {
                    onCopy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return "\(seconds)s"
    }
}
