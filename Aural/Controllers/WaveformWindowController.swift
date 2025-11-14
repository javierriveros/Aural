import AppKit
import SwiftUI

final class WaveformWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<WaveformRecordingView>?
    private var levelMonitor: AudioLevelMonitor?
    var onTap: (() -> Void)?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init() {
        setupPanel()
    }

    private func setupPanel() {
        // Create initial content view (will be updated when shown)
        let contentView = WaveformRecordingView(
            duration: 0,
            isLocked: false,
            audioLevels: Array(repeating: 0.0, count: 60)
        ) { [weak self] in
            self?.onTap?()
        }
        let hostingView = NSHostingView(rootView: contentView)

        // Create panel with larger size for waveform display (includes padding for shadow)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 548, height: 288),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true  // Allow dragging
        panel.backgroundColor = .clear
        panel.hasShadow = false  // Disable NSPanel shadow, use SwiftUI shadow instead
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView
    }

    func show(duration: TimeInterval, isLocked: Bool, levelMonitor: AudioLevelMonitor) {
        guard let panel = panel else { return }

        self.levelMonitor = levelMonitor

        // Update content with current state
        updateState(duration: duration, isLocked: isLocked)

        // Position at center of screen
        if !panel.isVisible {
            positionPanelAtCenter()
        }

        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
        levelMonitor = nil
    }

    func updateState(duration: TimeInterval, isLocked: Bool) {
        guard let hostingView = hostingView else { return }

        // Get current audio levels from monitor
        let audioLevels = levelMonitor?.recentLevels ?? Array(repeating: 0.0, count: 60)

        hostingView.rootView = WaveformRecordingView(
            duration: duration,
            isLocked: isLocked,
            audioLevels: audioLevels
        ) { [weak self] in
            self?.onTap?()
        }
    }

    private func positionPanelAtCenter() {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        // Center horizontally and vertically
        let x = screenFrame.midX - (panelSize.width / 2)
        let y = screenFrame.midY - (panelSize.height / 2)

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
