import AppKit

@Observable
final class ShortcutManager {
    private(set) var configuration: KeyboardShortcutsConfiguration
    private let repository = KeyboardShortcutsRepository()
    private var eventMonitor: Any?

    var onShortcutTriggered: ((ShortcutAction) -> Void)?

    init() {
        self.configuration = repository.load()
        setupEventMonitor()
    }

    func updateConfiguration(_ configuration: KeyboardShortcutsConfiguration) {
        self.configuration = configuration
        repository.save(configuration)
        restartMonitoring()
    }

    func setShortcut(_ definition: KeyboardShortcutDefinition?, for action: ShortcutAction) {
        configuration.setShortcut(definition, for: action)
        repository.save(configuration)
        restartMonitoring()
    }

    func reset() {
        repository.reset()
        self.configuration = .default
        restartMonitoring()
    }

    private func setupEventMonitor() {
        stopMonitoring()

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.configuration.isEnabled else { return event }

            for action in ShortcutAction.allCases {
                if let shortcut = self.configuration.shortcut(for: action),
                   shortcut.matches(keyCode: CGKeyCode(event.keyCode), modifiers: event.modifierFlags) {
                    self.onShortcutTriggered?(action)
                    return nil
                }
            }

            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func restartMonitoring() {
        setupEventMonitor()
    }

    deinit {
        stopMonitoring()
    }
}
