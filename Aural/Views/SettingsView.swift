import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var isTestingAPI = false
    @State private var testResult: String?
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title)
                .frame(maxWidth: .infinity, alignment: .leading)

            Form {
                Section {
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button("Test API Key") {
                            testAPIKey()
                        }
                        .disabled(apiKey.isEmpty || isTestingAPI)

                        if isTestingAPI {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    if let result = testResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(showSuccess ? .green : .red)
                    }
                } header: {
                    Text("OpenAI Configuration")
                        .font(.headline)
                }

                Section {
                    HStack {
                        Text("Global Hotkey:")
                        Spacer()
                        Text("Fn")
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                    }
                    Text("Hold the Fn key to record audio")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Hotkey Configuration")
                        .font(.headline)
                }

                Section {
                    HStack {
                        Text("Version:")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
        .onAppear {
            loadSettings()
        }
    }

    private func loadSettings() {
        apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    }

    private func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: "openai_api_key")
    }

    private func testAPIKey() {
        isTestingAPI = true
        testResult = nil
        showSuccess = false

        Task {
            do {
                let testURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("test.txt")
                try "test".write(to: testURL, atomically: true, encoding: .utf8)

                UserDefaults.standard.set(apiKey, forKey: "openai_api_key")

                let service = WhisperService()
                _ = try await service.transcribe(audioURL: testURL)

                try? FileManager.default.removeItem(at: testURL)

                await MainActor.run {
                    testResult = "API key is valid!"
                    showSuccess = true
                    isTestingAPI = false
                }
            } catch {
                await MainActor.run {
                    testResult = "API key test failed: \(error.localizedDescription)"
                    showSuccess = false
                    isTestingAPI = false
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
