import AVFoundation
import FluidAudio
import Foundation

final class LocalParakeetService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private var asrManager: AsrManager?
    private var models: AsrModels?

    private var isInitializing = false
    private var initializationError: Error?

    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }

    var isAvailable: Bool {
        // Assume availability if selected; FluidAudio handles specific HW requirements
        return true
    }

    private func ensureInitialized() async throws {
        if asrManager != nil { return }
        if isInitializing {
            while isInitializing {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            if asrManager != nil { return }
        }

        isInitializing = true
        defer { isInitializing = false }

        do {
            let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId)

            // downloadAndLoad handles lazy loading and caching internally
            let loadedModels = try await AsrModels.downloadAndLoad(version: selectedId == "parakeet-tdt-v3" ? .v3 : .v2)
            self.models = loadedModels

            let manager = AsrManager(config: .default)
            try await manager.initialize(models: loadedModels)

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

        guard let file = try? AVAudioFile(forReading: audioURL),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw LocalModelError.audioConversionFailed
        }

        try file.read(into: buffer)

        let result = try await manager.transcribe(buffer)
        return result.text
    }
}
