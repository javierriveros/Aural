import SwiftData
import SwiftUI

struct TranscriptionRow: View {
    let transcription: Transcription
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var showCopiedFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BrandColors.primaryBlue.opacity(0.6))
                    Text(transcription.timestamp, style: .time)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: Spacing.xs) {
                    Text(formatDuration(transcription.duration))
                        .font(Typography.monoCaption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 4)
                        .background(BrandColors.primaryBlue.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)

                    Text("\(wordCount(transcription.text)) words")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 4)
                        .background(BrandColors.primaryCyan.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)

                    Text(formatCost(transcription.cost))
                        .font(Typography.monoCaption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, 4)
                        .background(BrandColors.success.opacity(0.1))
                        .cornerRadius(CornerRadius.sm)
                }
            }

            Text(transcription.text)
                .font(Typography.body)
                .textSelection(.enabled)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            if transcription.text.count > 150 {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(Typography.caption)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(BrandColors.primaryBlue)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: Spacing.sm) {
                Button {
                    onCopy()
                    showCopiedFeedback = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopiedFeedback = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        Text(showCopiedFeedback ? "Copied!" : "Copy")
                            .font(Typography.caption)
                    }
                    .foregroundStyle(showCopiedFeedback ? BrandColors.success : BrandColors.primaryBlue)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        (showCopiedFeedback ? BrandColors.success : BrandColors.primaryBlue)
                            .opacity(0.1)
                    )
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCopiedFeedback)

                Spacer()

                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onDelete()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                        Text("Delete")
                            .font(Typography.caption)
                    }
                    .foregroundStyle(BrandColors.error)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(BrandColors.error.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                }
                .buttonStyle(.plain)
                .opacity(isHovered ? 1.0 : 0.6)
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .strokeBorder(
                            LinearGradient(
                                colors: isHovered ? [BrandColors.primaryBlue.opacity(0.3), BrandColors.primaryCyan.opacity(0.3)] : [.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isHovered ? BrandColors.primaryBlue.opacity(0.15) : .black.opacity(0.05),
            radius: isHovered ? 12 : 4,
            x: 0,
            y: isHovered ? 6 : 2
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return "\(seconds)s"
    }

    private func wordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    private func formatCost(_ cost: Double) -> String {
        // Always show actual cost, even if very small
        // Use 4 decimal places for precise tracking of small costs
        if cost < 0.01 {
            return String(format: "$%.4f", cost)
        }
        return String(format: "$%.3f", cost)
    }
}
