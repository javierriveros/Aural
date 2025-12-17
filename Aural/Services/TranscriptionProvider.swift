import Foundation

protocol TranscriptionProvider: AnyObject {
    func transcribe(audioURL: URL) async throws -> String
    var isAvailable: Bool { get }
}
