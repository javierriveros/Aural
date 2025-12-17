import Foundation

// Note: SwiftWhisper integration requires adding the package to the Xcode project:
// https://github.com/exPHAT/SwiftWhisper.git
//
// Until SwiftWhisper is added, this service will throw an error indicating setup is required.

final class LocalWhisperService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private let audioConverter = AudioFormatConverter()
    
    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }
    
    var isAvailable: Bool {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId),
              model.family == .whisper else {
            return false
        }
        
        // Check if model is downloaded
        guard modelDownloadManager.isModelDownloaded(model) else {
            return false
        }
        
        // SwiftWhisper package is not yet integrated
        // Return false until the dependency is properly set up
        #if canImport(SwiftWhisper)
        return true
        #else
        return false
        #endif
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId) else {
            throw LocalModelError.noModelSelected
        }
        
        let modelPath = modelDownloadManager.downloadPath(for: model)
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw LocalModelError.modelNotDownloaded
        }
        
        // SwiftWhisper integration
        // To enable local Whisper transcription:
        // 1. Add SwiftWhisper package to Xcode: https://github.com/exPHAT/SwiftWhisper.git
        // 2. Import SwiftWhisper at the top of this file
        // 3. Implement the transcription logic below
        
        #if canImport(SwiftWhisper)
        // Convert audio to 16kHz PCM WAV (required by Whisper)
        let pcmURL = try await audioConverter.convertToPCM(url: audioURL)
        defer { try? FileManager.default.removeItem(at: pcmURL) }
        
        // TODO: Implement when SwiftWhisper is added
        // let whisper = Whisper(modelURL: modelPath)
        // let segments = try await whisper.transcribe(audioURL: pcmURL)
        // return segments.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        
        throw LocalModelError.notImplemented
        #else
        throw LocalModelError.notImplemented
        #endif
    }
}
