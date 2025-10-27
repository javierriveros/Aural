import AppKit
import ApplicationServices
import Foundation

final class TextInjectionService {
    enum InjectionError: LocalizedError {
        case accessibilityPermissionDenied
        case noFocusedElement
        case injectionFailed
        case fallbackToClipboard

        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionDenied:
                return "Accessibility permission required for text injection"
            case .noFocusedElement:
                return "No focused text field found"
            case .injectionFailed:
                return "Failed to inject text"
            case .fallbackToClipboard:
                return "Text copied to clipboard (injection not available)"
            }
        }
    }

    func injectText(_ text: String) throws {
        guard AXIsProcessTrusted() else {
            throw InjectionError.accessibilityPermissionDenied
        }

        if isOwnAppFocused() {
            throw InjectionError.fallbackToClipboard
        }

        usleep(50000)

        if tryClipboardPaste(text) {
            return
        }

        if tryKeyboardSimulation(text) {
            return
        }

        if tryAccessibilityInsertion(text) {
            return
        }

        throw InjectionError.injectionFailed
    }

    private func tryAccessibilityInsertion(_ text: String) -> Bool {
        guard let focusedElement = getFocusedElement() else {
            return false
        }

        var value: AnyObject?
        let error = AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &value)

        guard error == .success else {
            return false
        }

        let currentText = (value as? String) ?? ""
        let newText = currentText + text

        let setValue = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, newText as CFTypeRef)

        if setValue == .success {
            let newLength = newText.count
            AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextRangeAttribute as CFString, CFRangeMake(newLength, 0) as CFTypeRef)
            return true
        }

        return false
    }

    private func tryClipboardPaste(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        let previousContents = pasteboard.string(forType: .string)

        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        usleep(50000)

        let success = simulateCommandV()

        usleep(50000)

        if let previousContents = previousContents {
            pasteboard.clearContents()
            pasteboard.setString(previousContents, forType: .string)
        }

        return success
    }

    private func simulateCommandV() -> Bool {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return false
        }

        let vKeyCode: CGKeyCode = 0x09

        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return false
        }

        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand

        keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
        usleep(10000)
        keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)

        return true
    }

    private func tryKeyboardSimulation(_ text: String) -> Bool {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return false
        }

        for character in text {
            let unicodeScalars = String(character).unicodeScalars
            guard let unicodeScalar = unicodeScalars.first else { continue }

            let keyCode = UniChar(truncatingIfNeeded: unicodeScalar.value)

            guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }

            keyDownEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: [keyCode])
            keyUpEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: [keyCode])

            keyDownEvent.post(tap: .cgAnnotatedSessionEventTap)
            usleep(1000)
            keyUpEvent.post(tap: .cgAnnotatedSessionEventTap)
            usleep(1000)
        }

        return true
    }

    private func isOwnAppFocused() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        let currentApp = NSRunningApplication.current
        return frontmostApp.processIdentifier == currentApp.processIdentifier
    }

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?

        let appError = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appError == .success, let focusedAppElement = focusedApp else {
            return nil
        }

        var focusedElement: CFTypeRef?
        let elementError = AXUIElementCopyAttributeValue(focusedAppElement as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard elementError == .success, let element = focusedElement else {
            return nil
        }

        return (element as! AXUIElement)
    }

    func canInjectText() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
