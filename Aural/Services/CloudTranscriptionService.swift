import Foundation

final class CloudTranscriptionService: TranscriptionProvider {
    private let provider: CloudProvider
    private let prompt: () -> String

    init(provider: CloudProvider, prompt: @escaping () -> String = { "" }) {
        self.provider = provider
        self.prompt = prompt
    }

    private var apiKeyIdentifier: String {
        switch provider {
        case .openai: return UserDefaultsKeys.openAIAPIKey
        case .groq: return UserDefaultsKeys.groqAPIKey
        }
    }

    var apiKey: String? {
        UserDefaults.standard.string(forKey: apiKeyIdentifier)
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
            throw CloudTranscriptionError.noAPIKey
        }

        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            throw CloudTranscriptionError.invalidURL
        }

        var request = URLRequest(url: provider.apiEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let audioData = try Data(contentsOf: audioURL)
        let mimeType = MultipartFormDataBuilder.mimeType(for: audioURL)

        var builder = MultipartFormDataBuilder()
        builder.addFile(name: "file", filename: audioURL.lastPathComponent, mimeType: mimeType, data: audioData)
        builder.addField(name: "model", value: provider.defaultModel)
        builder.addField(name: "response_format", value: "json")
        let hint = prompt()
        if !hint.isEmpty {
            builder.addField(name: "prompt", value: hint)
        }
        builder.finalize()

        request.setValue(builder.contentTypeHeader, forHTTPHeaderField: "Content-Type")
        request.httpBody = builder.data

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CloudTranscriptionError.invalidResponse
            }

            if httpResponse.statusCode == 200 {
                let decoder = JSONDecoder()
                let whisperResponse = try decoder.decode(WhisperResponse.self, from: data)
                return Self.isPromptEcho(whisperResponse.text, prompt: hint) ? "" : whisperResponse.text
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CloudTranscriptionError.apiError(errorMessage)
            }
        } catch let error as CloudTranscriptionError {
            throw error
        } catch {
            throw CloudTranscriptionError.networkError(error)
        }
    }

    // Whisper-family models can return the prompt verbatim when the audio has no speech.
    // Requiring a separator keeps a genuine one-word dictation of the first term.
    static func isPromptEcho(_ text: String, prompt: String) -> Bool {
        let punctuation = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let normalize = { (value: String) in value.trimmingCharacters(in: punctuation).lowercased() }
        let result = normalize(text)
        let hint = normalize(prompt)
        return result.contains(",") && hint.hasPrefix(result)
    }
}
