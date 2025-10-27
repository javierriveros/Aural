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
    @State private var voiceCommandsEnabled = false
    @State private var keyboardShortcuts = KeyboardShortcutsConfiguration.default

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .fill(BrandColors.gradientPrimary)
                        .frame(width: 40, height: 40)

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text("Settings")
                    .font(Typography.title2)

                Spacer()
            }
            .padding(Spacing.lg)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

            Divider()

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
                            .font(Typography.caption)
                            .foregroundStyle(showSuccess ? BrandColors.success : BrandColors.error)
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
                        .buttonStyle(PrimaryButtonStyle())
                        .controlSize(.small)
                    }
                } header: {
                    Text("Custom Vocabulary")
                        .font(.headline)
                }

                Section {
                    Toggle("Enable Voice Commands", isOn: $voiceCommandsEnabled)
                        .toggleStyle(.switch)

                    Text("Process voice commands for punctuation, formatting, and editing. Say 'comma', 'period', 'new line', 'capitalize', etc.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if voiceCommandsEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Example commands:")
                                .font(.caption)
                                .fontWeight(.medium)

                            Text("• Punctuation: comma, period, question mark")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Formatting: new line, new paragraph")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Capitalization: capitalize, all caps, lowercase")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Editing: scratch that, delete sentence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 4)
                    }
                } header: {
                    Text("Voice Commands")
                        .font(.headline)
                }

                Section {
                    Toggle("Enable Keyboard Shortcuts", isOn: $keyboardShortcuts.isEnabled)
                        .toggleStyle(.switch)

                    Text("Quick keyboard shortcuts for common actions")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if keyboardShortcuts.isEnabled {
                        ForEach(ShortcutAction.allCases) { action in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(action.rawValue)
                                        .font(.body)
                                    Text(action.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let shortcut = keyboardShortcuts.shortcut(for: action) {
                                    Text(shortcut.displayString)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .cornerRadius(6)
                                } else {
                                    Text("Not Set")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Keyboard Shortcuts")
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

            HStack(spacing: Spacing.md) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save Settings") {
                    saveSettings()
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(apiKey.isEmpty)
            }
            .padding(Spacing.lg)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 600, height: 850)
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
        migrateAPIKeyFromUserDefaults()

        apiKey = appState.whisperService.apiKey ?? ""
        recordingMode = RecordingModePreferences.mode
        soundsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundsEnabled)
        showFloatingWidget = appState.showFloatingWidget
        audioSpeedMultiplier = appState.audioSpeedMultiplier
        textInjectionEnabled = appState.textInjectionEnabled
        hotkeyConfig = HotkeyRepository().load()
        customVocabulary = VocabularyRepository().load()
        voiceCommandsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.voiceCommandsEnabled)
        keyboardShortcuts = KeyboardShortcutsRepository().load()
    }

    private func migrateAPIKeyFromUserDefaults() {
        if let oldKey = UserDefaults.standard.string(forKey: UserDefaultsKeys.openAIAPIKey),
           !oldKey.isEmpty,
           appState.whisperService.apiKey == nil {
            try? appState.whisperService.setAPIKey(oldKey)
            UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.openAIAPIKey)
        }
    }

    private func saveSettings() {
        try? appState.whisperService.setAPIKey(apiKey)

        RecordingModePreferences.mode = recordingMode
        UserDefaults.standard.set(soundsEnabled, forKey: UserDefaultsKeys.soundsEnabled)
        UserDefaults.standard.set(audioSpeedMultiplier, forKey: UserDefaultsKeys.audioSpeedMultiplier)
        UserDefaults.standard.set(textInjectionEnabled, forKey: UserDefaultsKeys.textInjectionEnabled)
        UserDefaults.standard.set(voiceCommandsEnabled, forKey: UserDefaultsKeys.voiceCommandsEnabled)

        appState.showFloatingWidget = showFloatingWidget
        appState.audioSpeedMultiplier = audioSpeedMultiplier
        appState.textInjectionEnabled = textInjectionEnabled
        appState.hotkeyMonitor.updateHotkey(hotkeyConfig)

        VocabularyRepository().save(customVocabulary)
        appState.vocabularyService.reload()

        KeyboardShortcutsRepository().save(keyboardShortcuts)
        appState.shortcutManager.updateConfiguration(keyboardShortcuts)
    }

    func testAPIKey() {
        isTestingAPI = true
        testResult = nil
        showSuccess = false

        Task {
            do {
                try appState.whisperService.setAPIKey(apiKey)

                let testAudioURL = try await createTestAudioFile()

                _ = try await appState.whisperService.transcribe(audioURL: testAudioURL)

                try? FileManager.default.removeItem(at: testAudioURL)

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

    private func createTestAudioFile() async throws -> URL {
        let testURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let audioRecorder = AudioRecorder()
        try await audioRecorder.startRecording()
        try await Task.sleep(nanoseconds: 500_000_000)

        if let recordedURL = audioRecorder.stopRecording() {
            try FileManager.default.moveItem(at: recordedURL, to: testURL)
            return testURL
        } else {
            throw NSError(domain: "SettingsView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test audio"])
        }
    }
}

#Preview {
    SettingsView()
}
