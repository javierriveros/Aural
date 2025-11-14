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

        // Create panel with larger size for waveform display
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 240),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true  // Allow dragging
        panel.backgroundColor = .clear
        panel.hasShadow = true  // Enable shadow
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.contentView = hostingView

        // Configure shadow for better visibility
        if let shadowView = panel.contentView?.superview {
            shadowView.shadow = NSShadow()
            shadowView.wantsLayer = true
            shadowView.layer?.shadowOpacity = 0.3
            shadowView.layer?.shadowRadius = 24
            shadowView.layer?.shadowOffset = CGSize(width: 0, height: 8)
            shadowView.layer?.shadowColor = NSColor.black.cgColor
        }

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
