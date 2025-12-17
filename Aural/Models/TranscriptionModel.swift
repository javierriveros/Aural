import Foundation

enum ModelFamily: String, Codable, CaseIterable {
    case whisper = "Whisper"
    case parakeet = "Parakeet"
}

struct TranscriptionModel: Identifiable, Codable, Hashable {
    let id: String
    let family: ModelFamily
    let name: String
    let size: String
    let sizeBytes: Int64
    let downloadURL: URL
    let languages: [String]
    let description: String
    var isDownloaded: Bool = false
    
    // CoreML model identifier if applicable
    var coreMLIdentifier: String?
}
