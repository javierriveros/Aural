import AppKit
import SwiftUI

final class WaveformWindowController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<StatusPillView>?
    private var levelMonitor: AudioLevelMonitor?
    var onTap: (() -> Void)?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init() {
        setupPanel()
    }

    private func setupPanel() {
        let contentView = StatusPillView(state: .idle, audioLevel: 0) { [weak self] in
            self?.onTap?()
        }
        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 64),
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

    func show(state: WidgetState, levelMonitor: AudioLevelMonitor) {
        guard let panel = panel else { return }

        self.levelMonitor = levelMonitor

        updateState(state)

        if !panel.isVisible {
            positionPanelAtBottom()
        }

        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
        levelMonitor = nil
    }

    private func updateState(_ state: WidgetState) {
        guard let hostingView = hostingView else { return }

        hostingView.rootView = StatusPillView(
            state: state,
            audioLevel: levelMonitor?.currentLevel ?? 0.0
        ) { [weak self] in
            self?.onTap?()
        }
    }

    private func positionPanelAtBottom() {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        let xPos = screenFrame.midX - (panelSize.width / 2)
        let yPos = screenFrame.minY + 24

        panel.setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
}
