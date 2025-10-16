import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var apiKey: String = ""
    @State private var isTestingAPI = false
    @State private var testResult: String?
    @State private var showSuccess = false
    @State private var recordingMode: RecordingMode = .hybrid
    @State private var soundsEnabled = true
    @State private var showFloatingWidget = true
    @State private var audioSpeedMultiplier: Float = 1.0
    @State private var textInjectionEnabled = false
    @State private var hotkeyConfig = HotkeyConfiguration.default
    @State private var customVocabulary = CustomVocabulary()
    @State private var showVocabularyManager = false

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
                    Picker("Recording Mode", selection: $recordingMode) {
                        ForEach(RecordingMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(recordingMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle("Enable Sounds", isOn: $soundsEnabled)
                        .toggleStyle(.switch)

                    Toggle("Show Floating Widget", isOn: $showFloatingWidget)
                        .toggleStyle(.switch)
                } header: {
                    Text("Recording")
                        .font(.headline)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Audio Speed:")
                            Spacer()
                            Text("\(String(format: "%.1fx", audioSpeedMultiplier))")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $audioSpeedMultiplier, in: 1.0...2.0, step: 0.1)

                        Text("Speed up audio before transcription to reduce API costs. 1.5x-2.0x recommended.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if audioSpeedMultiplier > 1.0 {
                            Text("Estimated savings: ~\(Int((audioSpeedMultiplier - 1.0) / audioSpeedMultiplier * 100))%")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                } header: {
                    Text("Audio Processing")
                        .font(.headline)
                }

                Section {
                    Toggle("Enable Text Injection", isOn: $textInjectionEnabled)
                        .toggleStyle(.switch)

                    Text("When enabled, transcribed text will be typed at the cursor position. Requires Accessibility permission. Falls back to clipboard if injection fails.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if textInjectionEnabled {
                        Text("⚠️ Make sure to grant Accessibility permissions in System Settings")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Text Injection")
                        .font(.headline)
                }

                Section {
                    HotkeyRecorderView(configuration: $hotkeyConfig)
                } header: {
                    Text("Hotkey Configuration")
                        .font(.headline)
                }

                Section {
                    Toggle("Enable Custom Vocabulary", isOn: $customVocabulary.isEnabled)
                        .toggleStyle(.switch)

                    Text("Replace specific words and phrases in transcriptions with custom alternatives.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("\(customVocabulary.entries.count) entries")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Manage Vocabulary") {
                            showVocabularyManager = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } header: {
                    Text("Custom Vocabulary")
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
        .frame(width: 500, height: 650)
        .onAppear {
            loadSettings()
        }
        .sheet(isPresented: $showVocabularyManager) {
            VStack {
                VocabularyManagementView(vocabulary: $customVocabulary)
                    .frame(minWidth: 700, minHeight: 500)

                HStack {
                    Spacer()
                    Button("Done") {
                        showVocabularyManager = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }

    private func loadSettings() {
        apiKey = UserDefaults.standard.string(forKey: UserDefaultsKeys.openAIAPIKey) ?? ""
        recordingMode = RecordingModePreferences.mode
        soundsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundsEnabled)
        showFloatingWidget = appState.showFloatingWidget
        audioSpeedMultiplier = appState.audioSpeedMultiplier
        textInjectionEnabled = appState.textInjectionEnabled
        hotkeyConfig = HotkeyRepository().load()
        customVocabulary = VocabularyRepository().load()
    }

    private func saveSettings() {
        UserDefaults.standard.set(apiKey, forKey: UserDefaultsKeys.openAIAPIKey)
        RecordingModePreferences.mode = recordingMode
        UserDefaults.standard.set(soundsEnabled, forKey: UserDefaultsKeys.soundsEnabled)
        UserDefaults.standard.set(audioSpeedMultiplier, forKey: UserDefaultsKeys.audioSpeedMultiplier)
        UserDefaults.standard.set(textInjectionEnabled, forKey: UserDefaultsKeys.textInjectionEnabled)

        appState.showFloatingWidget = showFloatingWidget
        appState.audioSpeedMultiplier = audioSpeedMultiplier
        appState.textInjectionEnabled = textInjectionEnabled
        appState.hotkeyMonitor.updateHotkey(hotkeyConfig)

        VocabularyRepository().save(customVocabulary)
        appState.vocabularyService.reload()
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

                UserDefaults.standard.set(apiKey, forKey: UserDefaultsKeys.openAIAPIKey)

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
