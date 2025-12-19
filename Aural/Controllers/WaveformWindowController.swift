import AppKit
import SwiftUI

final class WaveformWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<OrbRecordingView>?
    private var levelMonitor: AudioLevelMonitor?
    var onTap: (() -> Void)?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init() {
        setupPanel()
    }

    private func setupPanel() {
        let contentView = OrbRecordingView(
            duration: 0,
            isLocked: false,
            audioLevel: 0.0
        ) { [weak self] in
            self?.onTap?()
        }
        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 460),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = false
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

        updateState(duration: duration, isLocked: isLocked)

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

        let audioLevel = levelMonitor?.currentLevel ?? 0.0

        hostingView.rootView = OrbRecordingView(
            duration: duration,
            isLocked: isLocked,
            audioLevel: audioLevel
        ) { [weak self] in
            self?.onTap?()
        }
    }

    private func positionPanelAtCenter() {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        let xPos = screenFrame.midX - (panelSize.width / 2)
        let yPos = screenFrame.midY - (panelSize.height / 2)

        panel.setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
}
