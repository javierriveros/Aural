import Foundation
import SwiftWhisper

final class LocalWhisperService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private let audioConverter = AudioFormatConverter()
    private var whisper: Whisper?
    private var currentModelId: String?
    
    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }
    
    var isAvailable: Bool {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId) else {
            return false
        }
        return modelDownloadManager.isModelDownloaded(model)
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId) else {
            throw NSError(domain: "LocalWhisper", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local model selected"])
        }
        
        let modelPath = modelDownloadManager.downloadPath(for: model)
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw NSError(domain: "LocalWhisper", code: -2, userInfo: [NSLocalizedDescriptionKey: "Model not downloaded"])
        }
        
        // Load model if needed
        if whisper == nil || currentModelId != selectedId {
            whisper = Whisper(modelURL: modelPath)
            currentModelId = selectedId
        }
        
        guard let whisper = whisper else {
            throw NSError(domain: "LocalWhisper", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Whisper"])
        }
        
        // Convert audio to 16kHz PCM WAV
        let pcmURL = try await audioConverter.convertToPCM(url: audioURL)
        defer { try? FileManager.default.removeItem(at: pcmURL) }
        
        // Transcribe
        return try await withCheckedThrowingContinuation { continuation in
            whisper.transcribe(audioURL: pcmURL) { result in
                switch result {
                case .success(let segments):
                    let text = segments.map { $0.text }.joined(separator: " ")
                    continuation.resume(returning: text.trimmingCharacters(in: .whitespacesAndNewlines))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
