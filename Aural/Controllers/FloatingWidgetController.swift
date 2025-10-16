import AppKit
import SwiftUI

final class FloatingWidgetController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<FloatingWidgetView>?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init() {
        setupPanel()
    }

    private func setupPanel() {
        let contentView = FloatingWidgetView(state: .idle)
        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 80),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isOpaque = false
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView

        positionPanel()
    }

    func show() {
        guard let panel = panel else { return }
        if !panel.isVisible {
            positionPanel()
        }
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func updateState(_ state: WidgetState) {
        guard let hostingView = hostingView else { return }
        hostingView.rootView = FloatingWidgetView(state: state)
    }

    private func positionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        let x = screenFrame.maxX - panelSize.width - 20
        let y = screenFrame.maxY - panelSize.height - 20

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
