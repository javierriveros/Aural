import AppKit
import ApplicationServices
import Foundation

final class TextInjectionService {
    enum InjectionError: LocalizedError {
        case accessibilityPermissionDenied
        case fallbackToClipboard

        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionDenied:
                return "Accessibility permission required for text injection"
            case .fallbackToClipboard:
                return "Text copied to clipboard (injection not available)"
            }
        }
    }

    private static let restoreDelay: TimeInterval = 0.5

    func injectText(_ text: String) throws {
        guard AXIsProcessTrusted() else {
            throw InjectionError.accessibilityPermissionDenied
        }

        if isOwnAppFocused() {
            throw InjectionError.fallbackToClipboard
        }

        paste(Self.adjust(text, precedingText: textBeforeCursor()))
    }

    static func adjust(_ text: String, precedingText: String?) -> String {
        guard let preceding = precedingText, let first = text.first, !first.isWhitespace else { return text }
        guard let last = preceding.last, !last.isNewline else { return capitalizingFirst(text) }

        let trailing = preceding.last { !$0.isWhitespace }
        let startsSentence = trailing.map { ".!?".contains($0) } ?? true
        var result = startsSentence ? capitalizingFirst(text) : text
        if !last.isWhitespace, !"([{".contains(last), !".,!?;:)".contains(first) {
            result = " " + result
        }
        return result
    }

    private static func capitalizingFirst(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    private static let contextLength = 8
    private static let axTimeout: Float = 0.25

    private func textBeforeCursor() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(systemWide, Self.axTimeout)
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
              let focusedRef, CFGetTypeID(focusedRef) == AXUIElementGetTypeID() else { return nil }
        let element = unsafeBitCast(focusedRef, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, Self.axTimeout)

        var selectionRef: CFTypeRef?
        var selection = CFRange()
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectionRef) == .success,
              let selectionRef, CFGetTypeID(selectionRef) == AXValueGetTypeID(),
              AXValueGetValue(unsafeBitCast(selectionRef, to: AXValue.self), .cfRange, &selection),
              selection.location >= 0 else { return nil }

        let start = max(0, selection.location - Self.contextLength)
        var window = CFRange(location: start, length: selection.location - start)
        guard window.length > 0 else { return "" }
        guard let windowValue = AXValueCreate(.cfRange, &window) else { return nil }

        var textRef: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, kAXStringForRangeParameterizedAttribute as CFString, windowValue, &textRef) == .success else { return nil }
        return textRef as? String
    }

    private func paste(_ text: String) {
        let pasteboard = NSPasteboard.general
        let sensitiveTypes: Set<NSPasteboard.PasteboardType> = [
            NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"),
            NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
        ]
        let isSensitive = !sensitiveTypes.isDisjoint(with: pasteboard.types ?? [])
        // ponytail: snapshotting forces lazy/promised types to render and drops types that fail to read; upgrade to a type allowlist if it shows up in practice
        let snapshot: [[(NSPasteboard.PasteboardType, Data)]] = isSensitive ? [] : (pasteboard.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let changeCount = pasteboard.changeCount

        postCommandV()

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.restoreDelay) {
            guard !isSensitive, pasteboard.changeCount == changeCount else { return }
            pasteboard.clearContents()
            let items = snapshot.map { entries -> NSPasteboardItem in
                let item = NSPasteboardItem()
                entries.forEach { item.setData($0.1, forType: $0.0) }
                return item
            }
            pasteboard.writeObjects(items)
        }
    }

    private func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 0x09

        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: keyDown)
            event?.flags = .maskCommand
            event?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    private func isOwnAppFocused() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        let currentApp = NSRunningApplication.current
        return frontmostApp.processIdentifier == currentApp.processIdentifier
    }

    func canInjectText() -> Bool {
        return AXIsProcessTrusted()
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
