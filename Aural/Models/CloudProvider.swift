import Foundation

enum CloudProvider: String, Codable, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case groq = "Groq"

    var id: String { rawValue }

    var apiEndpoint: URL {
        switch self {
        case .openai:
            return URL(string: APIConstants.openAIAPIURL)!
        case .groq:
            return URL(string: APIConstants.groqAPIURL)!
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
            return "$\(APIConstants.openAIPricePerMinute) / min"
        case .groq:
            return "Free (Rate Limited)"
        }
    }

    var defaultModel: String {
        switch self {
        case .openai:
            return APIConstants.openAIModel
        case .groq:
            return APIConstants.groqModel
        }
    }
}
