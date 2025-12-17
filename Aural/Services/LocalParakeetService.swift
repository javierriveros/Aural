import AVFoundation
import CoreML
import Foundation

final class LocalParakeetService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private let audioConverter = AudioFormatConverter()
    
    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }
    
    var isAvailable: Bool {
        // Parakeet CoreML integration is not yet complete
        // Return false to prevent selection of Parakeet models
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId),
              model.family == .parakeet else {
            return false
        }
        
        // Currently disabled until CoreML inference is implemented
        return false
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        // Parakeet CoreML integration requires:
        // 1. Loading compiled CoreML model (.mlmodelc) from the download path
        // 2. Extracting Mel Spectrogram features from PCM audio using Accelerate
        // 3. Running inference using MLModel
        // 4. Decoding output tokens using Greedy or Beam Search
        //
        // This is a complex implementation that requires additional dependencies
        // and native Swift ML processing. For now, we throw an error indicating
        // the feature is not yet available.
        
        throw LocalModelError.notImplemented
    }
}
