import AVFoundation
import FluidAudio
import Foundation

final class LocalParakeetService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private var asrManager: AsrManager?
    private var models: AsrModels?
    
    // Track initialization state
    private var isInitializing = false
    private var initializationError: Error?
    
    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }
    
    var isAvailable: Bool {
        // Parakeet is supported on macOS 14+ and Apple Silicon ideally,
        // but let's assume availability if the user selected it.
        // We could verify architecture here if needed.
        return true
    }
    
    private func ensureInitialized() async throws {
        if asrManager != nil { return }
        if isInitializing {
            // Simple busy-wait for demo purposes, or just let strict concurrency handle it
            // In a real app, we'd use an Actor or Task for shared initialization
            // For now, we'll re-attempt or wait (simplified)
        }
        
        isInitializing = true
        defer { isInitializing = false }
        
        do {
            // Determine version from selected model ID
            let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId)
            
            // This downloads/loads models using FluidAudio's internal mechanics
            // Using type inference (.v2, .v3) as the exact enum path seems to differ
            self.models = try await AsrModels.downloadAndLoad(version: selectedId == "parakeet-tdt-v3" ? .v3 : .v2)
            
            // Use type inference for configuration as per SDK examples
            let manager = AsrManager(config: .default)
            try await manager.initialize(models: self.models!)
            
            self.asrManager = manager
        } catch {
            self.initializationError = error
            throw error
        }
    }
    
    func preload() async {
        _ = try? await ensureInitialized()
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        try await ensureInitialized()
        
        guard let manager = asrManager else {
            throw LocalModelError.modelLoadFailed
        }
        
        // FluidAudio expects audio buffer or specific format
        // We'll read the file into a buffer
        guard let file = try? AVAudioFile(forReading: audioURL),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw LocalModelError.audioConversionFailed
        }
        
        try file.read(into: buffer)
        
        // Transcribe
        let result = try await manager.transcribe(buffer)
        return result.text
    }
}
