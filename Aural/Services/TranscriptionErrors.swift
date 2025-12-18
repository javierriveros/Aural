import Foundation

// MARK: - Cloud Transcription Error

/// Shared error types for cloud transcription services (OpenAI, Groq)
enum CloudTranscriptionError: LocalizedError {
    case noAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key not configured"
        case .invalidURL:
            return "Invalid audio file URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Local Model Error

/// Error types for local transcription models (Whisper, Parakeet)
enum LocalModelError: LocalizedError {
    case noModelSelected
    case modelNotDownloaded
    case initializationFailed
    case transcriptionFailed(String)
    case notImplemented
    case modelLoadFailed
    case audioConversionFailed

    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            return "No local model selected"
        case .modelNotDownloaded:
            return "Model not downloaded"
        case .initializationFailed:
            return "Failed to initialize local model"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .modelLoadFailed:
            return "Failed to load the model"
        case .audioConversionFailed:
            return "Failed to convert audio file"
        }
    }
}

// MARK: - Multipart Form Data Helper

/// Helper for creating multipart form data requests
struct MultipartFormDataBuilder {
    private var body = Data()
    private let boundary: String
    private let lineBreak = "\r\n"
    
    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }
    
    var contentTypeHeader: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    var data: Data { body }
    
    mutating func addFile(name: String, filename: String, mimeType: String, data: Data) {
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)")
        body.append(data)
        body.append(lineBreak)
    }
    
    mutating func addField(name: String, value: String) {
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(name)\"\(lineBreak)\(lineBreak)")
        body.append(value + lineBreak)
    }
    
    mutating func finalize() {
        body.append("--\(boundary)--\(lineBreak)")
    }
    
    /// Determines the MIME type based on file extension
    static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "wav":
            return "audio/wav"
        case "mp3":
            return "audio/mpeg"
        case "m4a":
            return "audio/m4a"
        case "flac":
            return "audio/flac"
        case "ogg":
            return "audio/ogg"
        default:
            return "audio/m4a"
        }
    }
}

// MARK: - Data Extension

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
