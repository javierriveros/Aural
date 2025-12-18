import Foundation

/// Mode of transcription: cloud-based API or local on-device model
enum TranscriptionMode: String, Codable, CaseIterable {
    case cloud = "Cloud"
    case local = "Local"
}

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
    
    // Whether the model is managed by an external SDK (e.g. FluidAudio)
    var managedBySDK: Bool = false
}
