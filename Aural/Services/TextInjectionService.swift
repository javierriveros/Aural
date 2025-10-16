import Foundation
import AppKit
import ApplicationServices

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

        if tryAccessibilityInsertion(text) {
            return
        }

        if tryKeyboardSimulation(text) {
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

    private func tryKeyboardSimulation(_ text: String) -> Bool {
        let source = CGEventSource(stateID: .hidSystemState)

        for character in text {
            let unicodeScalars = String(character).unicodeScalars
            guard let unicodeScalar = unicodeScalars.first else { continue }

            let keyCode = UniChar(truncatingIfNeeded: unicodeScalar.value)

            if let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                keyDownEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: [keyCode])
                keyDownEvent.post(tap: .cghidEventTap)
            }

            if let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                keyUpEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: [keyCode])
                keyUpEvent.post(tap: .cghidEventTap)
            }

            usleep(1000)
        }

        return true
    }

    private func getFocusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: AnyObject?

        let appError = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appError == .success, let focusedAppElement = focusedApp else {
            return nil
        }

        var focusedElement: AnyObject?
        let elementError = AXUIElementCopyAttributeValue(focusedAppElement as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard elementError == .success else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    func canInjectText() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
