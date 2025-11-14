import Foundation
import SwiftData

@Model
final class Transcription {
    var id: UUID
    var text: String
    var timestamp: Date
    var duration: TimeInterval
    var cost: Double

    init(text: String, duration: TimeInterval, cost: Double = 0.0) {
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
        self.duration = duration
        self.cost = cost
    }
}
