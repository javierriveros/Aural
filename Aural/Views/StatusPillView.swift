import SwiftUI

struct StatusPillView: View {
    let state: WidgetState
    let audioLevel: Float
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            icon
            label
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Capsule().fill(.regularMaterial))
        .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 2)
        .contentShape(Capsule())
        .onTapGesture { onTap() }
        .frame(width: 280, height: 64)
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .recording(_, let isLocked):
            Image(systemName: isLocked ? "lock.fill" : "mic.fill")
                .foregroundStyle(tint)
        case .transcribing:
            ProgressView().controlSize(.small)
        case .notice(_, let isError):
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "doc.on.clipboard")
                .foregroundStyle(tint)
        case .idle:
            EmptyView()
        }
    }

    @ViewBuilder
    private var label: some View {
        switch state {
        case .recording(let duration, _):
            HStack(spacing: Spacing.xs) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(tint)
                            .frame(width: 3, height: barHeight(index))
                    }
                }
                .frame(height: 18)
                .animation(.easeOut(duration: 0.1), value: audioLevel)
                Text(duration.formattedAsRecordingDuration())
                    .font(Typography.monoCaption)
                    .foregroundStyle(.primary)
            }
        case .transcribing:
            Text("Transcribing…").font(Typography.caption).foregroundStyle(.primary)
        case .notice(let message, _):
            Text(message).font(Typography.caption).foregroundStyle(.primary).lineLimit(1)
        case .idle:
            EmptyView()
        }
    }

    private var tint: Color {
        switch state {
        case .recording(_, let isLocked): return isLocked ? BrandColors.warning : BrandColors.primaryBlue
        case .transcribing, .idle: return BrandColors.primaryBlue
        case .notice(_, let isError): return isError ? BrandColors.error : BrandColors.success
        }
    }

    private func barHeight(_ index: Int) -> CGFloat {
        let weights: [CGFloat] = [0.5, 0.8, 1.0, 0.8, 0.5]
        return 4 + 14 * CGFloat(min(max(audioLevel, 0), 1)) * weights[index]
    }
}

#Preview {
    VStack {
        StatusPillView(state: .recording(duration: 4.2, isLocked: false), audioLevel: 0.6) {}
        StatusPillView(state: .transcribing, audioLevel: 0) {}
        StatusPillView(state: .notice("Copied — press ⌘V", isError: false), audioLevel: 0) {}
        StatusPillView(state: .notice("Transcription failed", isError: true), audioLevel: 0) {}
    }
    .padding()
}
