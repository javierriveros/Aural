import Foundation

struct ModelRegistry {
    static let models: [TranscriptionModel] = [
        // Whisper Models (English only)
        TranscriptionModel(
            id: "whisper-tiny-en",
            family: .whisper,
            name: "Whisper Tiny (English)",
            size: "75 MB",
            sizeBytes: 78_000_000,
            downloadURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin")!,
            languages: ["en"],
            description: "Fastest Whisper model, lowest accuracy."
        ),
        TranscriptionModel(
            id: "whisper-base-en",
            family: .whisper,
            name: "Whisper Base (English)",
            size: "142 MB",
            sizeBytes: 148_000_000,
            downloadURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin")!,
            languages: ["en"],
            description: "Good balance of speed and accuracy for English."
        ),
        TranscriptionModel(
            id: "whisper-small-en",
            family: .whisper,
            name: "Whisper Small (English)",
            size: "466 MB",
            sizeBytes: 488_000_000,
            downloadURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin")!,
            languages: ["en"],
            description: "High accuracy English model."
        ),

        // Whisper Models (Multilingual)
        TranscriptionModel(
            id: "whisper-tiny",
            family: .whisper,
            name: "Whisper Tiny (Multi)",
            size: "75 MB",
            sizeBytes: 78_000_000,
            downloadURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin")!,
            languages: ["all"],
            description: "Fastest multilingual model."
        ),
        TranscriptionModel(
            id: "whisper-base",
            family: .whisper,
            name: "Whisper Base (Multi)",
            size: "142 MB",
            sizeBytes: 148_000_000,
            downloadURL: URL(string: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin")!,
            languages: ["all"],
            description: "Good balance for multiple languages."
        ),

        // Parakeet Models (NVIDIA) - Using CoreML versions from Fluid Inference
        TranscriptionModel(
            id: "parakeet-tdt-0.6b-v2",
            family: .parakeet,
            name: "Parakeet TDT 0.6B v2",
            size: "1.1 GB",
            sizeBytes: 1_100_000_000,
            downloadURL: URL(string: "https://huggingface.co/fluid-inference/parakeet-tdt-0.6b-v2-coreml/resolve/main/parakeet-tdt-0.6b-v2.mlmodelc.zip")!,
            languages: ["en"],
            description: "State-of-the-art accuracy and ultra-fast (English).",
            coreMLIdentifier: "parakeet_tdt_0.6b_v2",
            managedBySDK: true
        ),
        TranscriptionModel(
            id: "parakeet-tdt-v3",
            family: .parakeet,
            name: "Parakeet TDT v3 (Multi)",
            size: "1.2 GB",
            sizeBytes: 1_200_000_000,
            downloadURL: URL(string: "https://huggingface.co/fluid-inference/parakeet-tdt-v3-coreml/resolve/main/parakeet-tdt-v3.mlmodelc.zip")!,
            languages: ["en", "es", "fr", "de", "it", "nl", "pt"],
            description: "Latest multilingual Parakeet model.",
            coreMLIdentifier: "parakeet_tdt_v3",
            managedBySDK: true
        )
    ]

    static func model(forId id: String) -> TranscriptionModel? {
        models.first { $0.id == id }
    }
}
