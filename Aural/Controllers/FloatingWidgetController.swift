import AppKit
import SwiftUI

final class FloatingWidgetController {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<FloatingWidgetView>?
    var onTap: (() -> Void)?

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    init() {
        setupPanel()
    }

    private func setupPanel() {
        let contentView = FloatingWidgetView(state: .idle) { [weak self] in
            self?.onTap?()
        }
        let hostingView = NSHostingView(rootView: contentView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
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
        hostingView.rootView = FloatingWidgetView(state: state) { [weak self] in
            self?.onTap?()
        }
    }

    private func positionPanel() {
        guard let panel = panel, let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size

        let xPos = screenFrame.maxX - panelSize.width - 20
        let yPos = screenFrame.maxY - panelSize.height - 20

        panel.setFrameOrigin(NSPoint(x: xPos, y: yPos))
    }
}
