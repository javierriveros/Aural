import Foundation
import SwiftData

@Model
final class Transcription {
    var id: UUID
    var text: String
    var timestamp: Date
    var duration: TimeInterval

    init(text: String, duration: TimeInterval) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.duration = duration
    }
}
