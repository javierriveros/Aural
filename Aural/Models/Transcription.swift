import Foundation
import SwiftData

@Model
final class Transcription {
    var id: UUID
    var text: String
    var timestamp: Date
    var duration: TimeInterval
    var cost: Double
    var providerType: String?   // "cloud" or "local"
    var providerName: String?   // "OpenAI", "Groq", "Whisper Base", etc.

    init(text: String, duration: TimeInterval, cost: Double = 0.0, providerType: String? = nil, providerName: String? = nil) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.duration = duration
        self.cost = cost
        self.providerType = providerType
        self.providerName = providerName
    }
}
