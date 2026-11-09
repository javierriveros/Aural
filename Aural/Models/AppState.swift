import AppKit
import AVFoundation
import Foundation
import ServiceManagement
import SwiftData

@Observable
final class AppState {
    let audioRecorder: AudioRecorderProtocol
    let shortcutManager = ShortcutManager()
    let modelDownloadManager = ModelDownloadManager()

    let soundPlayer = SoundPlayer.shared
    let audioLevelMonitor = AudioLevelMonitor()
    let hotkeyMonitor = HotkeyMonitor()
    let voiceCommandProcessor = VoiceCommandProcessor()
    let textInjectionService = TextInjectionService()
    let vocabularyService = VocabularyService()
    let textCleanupService = TextCleanupService()

    private let floatingWidget = FloatingWidgetController()
    private let waveformWindow = WaveformWindowController()
    private(set) var openAIService: CloudTranscriptionService
    private(set) var groqService: CloudTranscriptionService
    private var localWhisperService: LocalWhisperService?
    private(set) var localParakeetService: LocalParakeetService?

    var modelContext: ModelContext?

    private(set) var isRecording = false
    private(set) var isRecordingLocked = false
    private(set) var isTranscribing = false
    private(set) var lastTranscription: String?
    private(set) var lastError: String?

    /// Set when the user attempts to record before transcription is configured.
    /// The UI observes this to prompt the user to (re)run setup.
    var requiresSetup = false

    /// Drives the Settings sheet. Lives here so menu commands (⌘,) and
    /// keyboard shortcuts can open Settings, not just the in-window button.
    var showSettings = false
    var openMainWindow: (() -> Void)?

    /// Whether the user has finished the first-run setup flow.
    var hasCompletedSetup: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.hasCompletedSetup) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.hasCompletedSetup) }
    }

    /// Whether the currently selected transcription mode is usable right now:
    /// a cloud provider with a non-empty key, or a downloaded+selected local model.
    var isTranscriptionConfigured: Bool {
        switch transcriptionMode {
        case .cloud:
            let key: String?
            switch selectedCloudProvider {
            case .openai: key = openAIService.apiKey
            case .groq: key = groqService.apiKey
            }
            return !(key ?? "").isEmpty
        case .local:
            guard let modelId = selectedModelId,
                  let model = ModelRegistry.model(forId: modelId) else {
                return false
            }
            if model.managedBySDK {
                return modelDownloadManager.isParakeetModelDownloaded(modelId)
            }
            return modelDownloadManager.isModelDownloaded(model)
        }
    }
    private var recordingStartTime: Date?
    private var notice: WidgetState?
    private var noticeTask: Task<Void, Never>?

    var launchAtLogin: Bool {
        get {
            access(keyPath: \.launchAtLogin)
            return SMAppService.mainApp.status == .enabled
        }
        set {
            withMutation(keyPath: \.launchAtLogin) {
                do {
                    if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                    if newValue, SMAppService.mainApp.status == .requiresApproval {
                        SMAppService.openSystemSettingsLoginItems()
                        lastError = "Launch at Login: approve Aural in System Settings"
                    }
                } catch {
                    lastError = "Launch at Login: \(error.localizedDescription)"
                }
            }
        }
    }
    private var widgetUpdateTimer: Timer?

    var recordingMode: RecordingMode {
        RecordingModePreferences.mode
    }

    var widgetDisplayMode: WidgetDisplayMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: UserDefaultsKeys.widgetDisplayMode),
               let mode = WidgetDisplayMode(rawValue: rawValue) {
                return mode
            }
            return .waveform  // Default to waveform mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.widgetDisplayMode)
            updateFloatingWidgetVisibility()
        }
    }

    // Legacy support - maps to widgetDisplayMode
    var showFloatingWidget: Bool {
        get { widgetDisplayMode != .none }
        set {
            // When set to false, use .none, otherwise use current mode or default
            widgetDisplayMode = newValue ? (widgetDisplayMode == .none ? .waveform : widgetDisplayMode) : .none
        }
    }

    var textInjectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.textInjectionEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.textInjectionEnabled) }
    }

    // Stored properties for observability, synced with UserDefaults
    var transcriptionMode: TranscriptionMode = .cloud {
        didSet {
            UserDefaults.standard.set(transcriptionMode.rawValue, forKey: UserDefaultsKeys.transcriptionMode)
            preloadCurrentProvider()
        }
    }

    var selectedCloudProvider: CloudProvider = .openai {
        didSet { UserDefaults.standard.set(selectedCloudProvider.rawValue, forKey: UserDefaultsKeys.selectedCloudProvider) }
    }

    var selectedModelId: String? {
        didSet {
            UserDefaults.standard.set(selectedModelId, forKey: UserDefaultsKeys.selectedModelId)
            preloadCurrentProvider()
        }
    }

    init(audioRecorder: AudioRecorderProtocol = AudioRecorder()) {
        self.audioRecorder = audioRecorder
        let vocabulary = vocabularyService
        openAIService = CloudTranscriptionService(provider: .openai) { vocabulary.transcriptionPrompt }
        groqService = CloudTranscriptionService(provider: .groq) { vocabulary.transcriptionPrompt }

        // Load initial values from UserDefaults
        let modeRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.transcriptionMode) ?? ""
        self.transcriptionMode = TranscriptionMode(rawValue: modeRaw) ?? .cloud

        let providerRaw = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedCloudProvider) ?? ""
        self.selectedCloudProvider = CloudProvider(rawValue: providerRaw) ?? .openai

        self.selectedModelId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId)

        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.showFloatingWidget: true,
            UserDefaultsKeys.textInjectionEnabled: true,
            UserDefaultsKeys.transcriptionMode: TranscriptionMode.cloud.rawValue,
            UserDefaultsKeys.selectedCloudProvider: CloudProvider.openai.rawValue,
            UserDefaultsKeys.removeStuttering: false
        ])

        self.localWhisperService = LocalWhisperService(modelDownloadManager: modelDownloadManager)
        self.localParakeetService = LocalParakeetService(modelDownloadManager: modelDownloadManager)

        setupHotkeyCallbacks()
        setupFloatingWidgetCallbacks()
        setupWaveformWindowCallbacks()
        setupShortcutCallbacks()
        setupAudioLevelMonitor()
        if !hotkeyMonitor.startMonitoring() {
            print("Warning: Failed to start hotkey monitoring")
        }
        updateFloatingWidgetVisibility()
        preloadCurrentProvider()
        refreshParakeetModelStatuses()
    }

    private func setupFloatingWidgetCallbacks() {
        floatingWidget.onTap = { [weak self] in
            self?.handleWidgetTap()
        }
    }

    private func setupWaveformWindowCallbacks() {
        waveformWindow.onTap = { [weak self] in
            guard let self, isRecordingLocked else { return }
            stopRecording()
        }
    }

    private func setupAudioLevelMonitor() {
        audioRecorder.setLevelMonitor(audioLevelMonitor)

        if hasCompletedSetup, AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            Task { [audioRecorder] in _ = await audioRecorder.requestPermission() }
        }
    }

    private func handleWidgetTap() {
        if isRecording {
            if isRecordingLocked { stopRecording() }
        } else {
            startRecording(locked: true)
        }
    }

    private func setupHotkeyCallbacks() {
        hotkeyMonitor.onKeyDown = { [weak self] in
            self?.handleKeyDown()
        }

        hotkeyMonitor.onKeyUp = { [weak self] in
            self?.handleKeyUp()
        }

        hotkeyMonitor.onQuickTap = { [weak self] in
            self?.handleQuickTap()
        }
    }

    private func setupShortcutCallbacks() {
        shortcutManager.onShortcutTriggered = { [weak self] action in
            self?.handleShortcut(action)
        }
    }

    private func handleShortcut(_ action: ShortcutAction) {
        Task { @MainActor in
            switch action {
            case .copyLastTranscription:
                if let transcription = lastTranscription {
                    ClipboardService.copy(transcription)
                }
            case .showHideWindow:
                openMainWindow?()
            case .openSettings:
                showSettings = true
            case .clearHistory:
                guard let context = modelContext else { return }
                do {
                    try context.delete(model: Transcription.self)
                    try context.save()
                } catch {
                    print("Failed to clear history: \(error)")
                }
            }
        }
    }

    private func handleKeyDown() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly, .hybrid:
            if !isRecording {
                startRecording()
            }
        case .tapToLock:
            break
        }
    }

    private func handleKeyUp() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly, .hybrid:
            if isRecording {
                stopRecording()
            }
        case .tapToLock:
            break
        }
    }

    private func handleQuickTap() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .tapToLock, .hybrid:
            toggleLockedRecording()
        case .holdOnly:
            handleKeyUp()
        }
    }

    private func toggleLockedRecording() {
        if isRecording && isRecordingLocked {
            stopRecording()
        } else if isRecording && !isRecordingLocked {
            isRecordingLocked = true
            updateFloatingWidget()
        } else if !isRecording {
            startRecording(locked: true)
        }
    }

    /// Returns false and flags `requiresSetup` if transcription can't run yet.
    private func ensureTranscriptionConfigured() -> Bool {
        guard isTranscriptionConfigured else {
            requiresSetup = true
            if !hasCompletedSetup { openMainWindow?() }
            showNotice("Finish setup in Aural", isError: true)
            return false
        }
        return true
    }

    private func startRecording(locked: Bool = false) {
        guard !isRecording, !isTranscribing else { return }
        guard ensureTranscriptionConfigured() else { return }

        audioLevelMonitor.reset()
        recordingStartTime = Date()
        notice = nil
        noticeTask?.cancel()

        do {
            _ = try audioRecorder.startRecording()
        } catch {
            soundPlayer.playError()
            showNotice("Couldn't start recording", isError: true)
            return
        }

        if locked { soundPlayer.playLockEngaged() } else { soundPlayer.playRecordingStart() }
        isRecording = true
        isRecordingLocked = locked
        updateFloatingWidgetVisibility()
        startWidgetUpdateTimer()
        updateFloatingWidget()
    }

    private func stopRecording() {
        guard isRecording else { return }

        soundPlayer.playRecordingStop()
        stopWidgetUpdateTimer()
        isRecording = false
        isRecordingLocked = false

        let url = audioRecorder.stopRecording()
        isTranscribing = url != nil
        updateFloatingWidgetVisibility()

        guard let url else { return }
        Task { @MainActor in
            await handleRecordingComplete(url: url)
        }
    }

    private func handleRecordingComplete(url: URL) async {
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        if duration < 0.25 {
            FileManager.default.safelyRemoveItem(at: url)
            isTranscribing = false
            updateFloatingWidget()
            return
        }

        lastError = nil
        updateFloatingWidget()

        do {
            let provider = try getTranscriptionProvider()
            let rawTranscription = try await provider.transcribe(audioURL: url)
            let cleanedText = textCleanupService.cleanup(rawTranscription)
            let withVocabulary = vocabularyService.applyWordBoundaryReplacements(to: cleanedText)
            let transcriptionText = voiceCommandProcessor.process(withVocabulary)

            if transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                FileManager.default.safelyRemoveItem(at: url)
                isTranscribing = false
                updateFloatingWidget()
                return
            }

            lastTranscription = transcriptionText

            if textInjectionEnabled {
                do {
                    try textInjectionService.injectText(transcriptionText)
                } catch {
                    ClipboardService.copy(transcriptionText)
                    showNotice("Copied — press ⌘V", isError: false)
                }
            } else {
                ClipboardService.copy(transcriptionText)
                showNotice("Copied — press ⌘V", isError: false)
            }

            // Calculate cost using provider-specific logic
            let cost = calculateCost(duration: duration)
            let providerType = transcriptionMode.rawValue.lowercased()
            let providerName = getProviderName()

            saveTranscription(text: transcriptionText, duration: duration, cost: cost, providerType: providerType, providerName: providerName)

            FileManager.default.safelyRemoveItem(at: url)

            soundPlayer.playTranscriptionComplete()
        } catch {
            lastError = error.localizedDescription
            showNotice("Transcription failed", isError: true)
            soundPlayer.playError()
            FileManager.default.safelyRemoveItem(at: url)
        }

        isTranscribing = false
        updateFloatingWidget()
    }

    private func saveTranscription(text: String, duration: TimeInterval, cost: Double, providerType: String? = nil, providerName: String? = nil) {
        guard let context = modelContext else { return }

        let transcription = Transcription(text: text, duration: duration, cost: cost, providerType: providerType, providerName: providerName)
        context.insert(transcription)

        do {
            try context.save()
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }

    private func updateFloatingWidgetVisibility() {
        switch widgetDisplayMode {
        case .none:
            floatingWidget.hide()
            waveformWindow.hide()
        case .simple:
            floatingWidget.show()
            waveformWindow.hide()
        case .waveform:
            floatingWidget.hide()
        }
        updateFloatingWidget()
    }

    private func showNotice(_ message: String, isError: Bool) {
        notice = .notice(message, isError: isError)
        noticeTask?.cancel()
        noticeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self else { return }
            self.notice = nil
            self.updateFloatingWidget()
        }
        updateFloatingWidget()
    }

    private func updateFloatingWidget() {
        let state: WidgetState
        if isTranscribing {
            state = .transcribing
        } else if isRecording {
            state = .recording(duration: audioRecorder.recordingDuration, isLocked: isRecordingLocked)
        } else {
            state = notice ?? .idle
        }

        switch widgetDisplayMode {
        case .none:
            break
        case .simple:
            floatingWidget.updateState(state)
        case .waveform:
            if case .idle = state {
                waveformWindow.hide()
            } else {
                waveformWindow.show(state: state, levelMonitor: audioLevelMonitor)
            }
        }
    }

    private func startWidgetUpdateTimer() {
        stopWidgetUpdateTimer()

        // Use different update rates for waveform vs simple widget
        // Waveform needs 60 FPS for smooth animation, simple widget only needs 10 FPS
        let updateInterval: TimeInterval = (widgetDisplayMode == .waveform && isRecording) ? 1.0/60.0 : 0.1

        // Create timer and add to run loop with common mode for better performance
        let timer = Timer(timeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateFloatingWidget()
        }

        RunLoop.current.add(timer, forMode: .common)
        widgetUpdateTimer = timer
    }

    private func stopWidgetUpdateTimer() {
        widgetUpdateTimer?.invalidate()
        widgetUpdateTimer = nil
    }

    private func getTranscriptionProvider() throws -> TranscriptionProvider {
        switch transcriptionMode {
        case .cloud:
            switch selectedCloudProvider {
            case .openai:
                return openAIService
            case .groq:
                return groqService
            }
        case .local:
            guard let modelId = selectedModelId,
                  let model = ModelRegistry.model(forId: modelId) else {
                throw NSError(domain: "AppState", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local model selected"])
            }

            switch model.family {
            case .whisper:
                guard let service = localWhisperService else {
                    throw NSError(domain: "AppState", code: -2, userInfo: [NSLocalizedDescriptionKey: "Local Whisper service not initialized"])
                }
                return service
            case .parakeet:
                guard let service = localParakeetService else {
                    throw NSError(domain: "AppState", code: -3, userInfo: [NSLocalizedDescriptionKey: "Local Parakeet service not initialized"])
                }
                return service
            }
        }
    }

    private func getProviderName() -> String {
        switch transcriptionMode {
        case .cloud:
            return selectedCloudProvider.rawValue
        case .local:
            if let modelId = selectedModelId, let model = ModelRegistry.model(forId: modelId) {
                return model.name
            }
            return "Local"
        }
    }

    private func calculateCost(duration: TimeInterval) -> Double {
        if transcriptionMode == .local { return 0.0 }

        switch selectedCloudProvider {
        case .openai:
            return (duration / 60.0) * APIConstants.openAIPricePerMinute
        case .groq:
            return 0.0 // Currently free
        }
    }

    private func preloadCurrentProvider() {
        Task {
            if let provider = try? getTranscriptionProvider() {
                await provider.preload()
            }

            // Pre-download Parakeet models when selected
            if transcriptionMode == .local,
               let modelId = selectedModelId,
               let model = ModelRegistry.model(forId: modelId),
               model.family == .parakeet,
               let parakeetService = localParakeetService {
                modelDownloadManager.downloadParakeetModel(modelId, using: parakeetService)
            }
        }
    }

    func refreshParakeetModelStatuses() {
        guard let parakeetService = localParakeetService else { return }
        for model in ModelRegistry.models where model.family == .parakeet {
            modelDownloadManager.refreshParakeetModelStatus(model.id, using: parakeetService)
        }
    }

    deinit {
        hotkeyMonitor.stopMonitoring()
        stopWidgetUpdateTimer()
    }
}

// MARK: - Cloud key validation

extension AppState {
    /// Validates a cloud API key by saving it on the provider's service and
    /// running a short test transcription. Throws if the key is rejected.
    func validateCloudKey(provider: CloudProvider, key: String) async throws {
        guard await audioRecorder.requestPermission() else { throw RecordingError.permissionDenied }
        let service: TranscriptionProvider
        switch provider {
        case .openai:
            try openAIService.setAPIKey(key)
            service = openAIService
        case .groq:
            try groqService.setAPIKey(key)
            service = groqService
        }

        let testAudioURL = try await createTestAudioFile()
        defer { FileManager.default.safelyRemoveItem(at: testAudioURL) }
        _ = try await service.transcribe(audioURL: testAudioURL)
    }

    private func createTestAudioFile() async throws -> URL {
        let testURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let recorder = AudioRecorder()
        _ = try recorder.startRecording()
        try await Task.sleep(nanoseconds: 500_000_000)

        guard let recordedURL = recorder.stopRecording() else {
            throw NSError(domain: "AppState", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create test audio"])
        }
        try FileManager.default.moveItem(at: recordedURL, to: testURL)
        return testURL
    }
}
