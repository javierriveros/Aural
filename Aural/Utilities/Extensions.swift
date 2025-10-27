import AppKit
import Foundation

// MARK: - TimeInterval Extensions

extension TimeInterval {
    /// Formats the time interval as MM:SS for recording duration display
    func formattedAsRecordingDuration() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formats the time interval as seconds with 's' suffix
    func formattedAsSeconds() -> String {
        return "\(Int(self))s"
    }
}

// MARK: - FileManager Extensions

extension FileManager {
    /// Safely removes a file at the given URL, logging errors if they occur
    func safelyRemoveItem(at url: URL, logErrors: Bool = true) {
        do {
            try removeItem(at: url)
        } catch {
            if logErrors {
                print("Failed to remove file at \(url.path): \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Clipboard Service

enum ClipboardService {
    /// Copies the given text to the system clipboard
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
