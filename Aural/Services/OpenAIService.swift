import Foundation

final class OpenAIService: TranscriptionProvider {
    private let apiURL = URL(string: APIConstants.whisperAPIURL)!
    private let apiKeyIdentifier = UserDefaultsKeys.openAIAPIKey

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

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let audioData = try Data(contentsOf: audioURL)
        let mimeType = MultipartFormDataBuilder.mimeType(for: audioURL)

        var builder = MultipartFormDataBuilder()
        builder.addFile(name: "file", filename: audioURL.lastPathComponent, mimeType: mimeType, data: audioData)
        builder.addField(name: "model", value: APIConstants.whisperModel)
        builder.addField(name: "response_format", value: "json")
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
                return whisperResponse.text
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
}
