import Foundation

final class OpenAIService: TranscriptionProvider {
    enum TranscriptionError: LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured"
            case .invalidURL:
                return "Invalid audio file URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from Whisper API"
            case .apiError(let message):
                return "API error: \(message)"
            }
        }
    }

    private let apiURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let apiKeyIdentifier = UserDefaultsKeys.openAIAPIKey

    var apiKey: String? {
        get {
            UserDefaults.standard.string(forKey: apiKeyIdentifier)
        }
    }

    var isAvailable: Bool {
        guard let key = apiKey, !key.isEmpty else { return false }
        return true
    }

    func setAPIKey(_ key: String) throws {
        UserDefaults.standard.set(key, forKey: apiKeyIdentifier)
    }

    func deleteAPIKey() throws {
        UserDefaults.standard.removeObject(forKey: apiKeyIdentifier)
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw TranscriptionError.noAPIKey
        }

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.invalidURL
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = try createMultipartBody(
            audioURL: audioURL,
            boundary: boundary
        )
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranscriptionError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let whisperResponse = try decoder.decode(WhisperResponse.self, from: data)
                return whisperResponse.text
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw TranscriptionError.apiError(errorMessage)
            }
        } catch let error as TranscriptionError {
            throw error
        } catch {
            throw TranscriptionError.networkError(error)
        }
    }

    private func createMultipartBody(audioURL: URL, boundary: String) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\(lineBreak)")
        body.append("Content-Type: audio/m4a\(lineBreak)\(lineBreak)")

        let audioData = try Data(contentsOf: audioURL)
        body.append(audioData)
        body.append(lineBreak)

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"model\"\(lineBreak)\(lineBreak)")
        body.append("whisper-1\(lineBreak)")

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"response_format\"\(lineBreak)\(lineBreak)")
        body.append("json\(lineBreak)")

        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
