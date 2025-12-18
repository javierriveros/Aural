import Foundation

protocol TranscriptionProvider: AnyObject {
    func transcribe(audioURL: URL) async throws -> String
    var isAvailable: Bool { get }
    
    /// Optional: Pre-load the model into memory to avoid latency during first use
    func preload() async
}

extension TranscriptionProvider {
    func preload() async {
        // Default implementation does nothing
    }
}
