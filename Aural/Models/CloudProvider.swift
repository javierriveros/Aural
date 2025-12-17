import Foundation

enum CloudProvider: String, Codable, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case groq = "Groq"
    
    var id: String { rawValue }
    
    var apiEndpoint: URL {
        switch self {
        case .openai:
            return URL(string: "https://api.openai.com/v1/audio/transcriptions")!
        case .groq:
            return URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
        }
    }
    
    var requiresAPIKey: Bool {
        return true
    }
    
    var description: String {
        switch self {
        case .openai:
            return "Standard AI transcription by OpenAI."
        case .groq:
            return "Ultrafast transcription using Groq LPU."
        }
    }
    
    var priceInfo: String {
        switch self {
        case .openai:
            return "$0.006 / min"
        case .groq:
            return "Free (Rate Limited)"
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openai:
            return "whisper-1"
        case .groq:
            return "whisper-large-v3-turbo"
        }
    }
}
