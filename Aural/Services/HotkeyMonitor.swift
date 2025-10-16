import AppKit
import Carbon

@Observable
final class HotkeyMonitor {
    enum MonitoringState {
        case inactive
        case active
        case permissionDenied
    }

    private(set) var state: MonitoringState = .inactive
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    private let targetKeyCode: CGKeyCode = 0x3F

    init() {}

    func startMonitoring() -> Bool {
        guard checkAccessibilityPermission() else {
            state = .permissionDenied
            return false
        }

        let eventMask = (1 << CGEventType.flagsChanged.rawValue) |
                       (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor: HotkeyMonitor = Unsafely.fromOpaque(refcon)
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unsafely.toOpaque(self)
        ) else {
            state = .permissionDenied
            return false
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = runLoopSource
        self.state = .active

        return true
    }

    func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        state = .inactive
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent> {
        if type == .flagsChanged {
            let flags = event.flags
            let fnKeyPressed = flags.contains(.maskSecondaryFn)

            if fnKeyPressed {
                onKeyDown?()
            } else {
                onKeyUp?()
            }
        }

        return Unmanaged.passUnretained(event)
    }

    private func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }

    deinit {
        stopMonitoring()
    }
}

private enum Unsafely {
    static func toOpaque<T: AnyObject>(_ object: T) -> UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(object).toOpaque()
    }

    static func fromOpaque<T: AnyObject>(_ pointer: UnsafeMutableRawPointer) -> T {
        return Unmanaged<T>.fromOpaque(pointer).takeUnretainedValue()
    }
}
