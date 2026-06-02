import SwiftUI

/// First-run guided setup. The user must choose a transcription mode and
/// configure it (cloud API key, or a downloaded local model) before finishing,
/// so recording works immediately afterwards.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private enum Step {
        case mode
        case cloud
        case local
    }

    @State private var step: Step = .mode

    // Cloud configuration
    @State private var provider: CloudProvider = .openai
    @State private var apiKey: String = ""
    @State private var isTesting = false
    @State private var testResult: String?
    @State private var testSucceeded = false

    // Local configuration
    @State private var showModelManager = false

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Group {
                switch step {
                case .mode: modeStep
                case .cloud: cloudStep
                case .local: localStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Spacing.lg)
        }
        .frame(minWidth: 460, idealWidth: 480, minHeight: 540, idealHeight: 560)
        .sheet(isPresented: $showModelManager) {
            ModelManagerView()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(BrandColors.gradientPrimary)
                    .frame(width: 40, height: 40)
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome to Aural")
                    .font(Typography.title2)
                Text("Let's set up transcription")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Step 1: choose mode

    private var modeStep: some View {
        VStack(spacing: Spacing.lg) {
            Text("How would you like to transcribe?")
                .font(Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            modeCard(
                title: "Local",
                subtitle: "Private, free, on-device. Downloads a model once.",
                icon: "lock.laptopcomputer"
            ) { step = .local }

            modeCard(
                title: "Cloud",
                subtitle: "Fastest setup. Needs an API key (OpenAI or Groq).",
                icon: "cloud"
            ) { step = .cloud }

            Spacer()
        }
    }

    private func modeCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(BrandColors.primaryBlue)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.md)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(CornerRadius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2a: cloud

    private var cloudStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Picker("Provider", selection: $provider) {
                ForEach(CloudProvider.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: provider) { _, _ in
                testResult = nil
                testSucceeded = false
            }

            Text(provider.description)
                .font(Typography.caption)
                .foregroundStyle(.secondary)

            SecureField("\(provider.rawValue) API Key", text: $apiKey)
                .textFieldStyle(.roundedBorder)
                .onChange(of: apiKey) { _, _ in
                    testResult = nil
                    testSucceeded = false
                }

            HStack {
                Button("Test Key") { testKey() }
                    .disabled(apiKey.isEmpty || isTesting)
                if isTesting {
                    ProgressView().scaleEffect(0.7)
                }
            }

            if let testResult {
                Text(testResult)
                    .font(Typography.caption)
                    .foregroundStyle(testSucceeded ? BrandColors.success : BrandColors.error)
            }

            Spacer()

            HStack {
                Button("Back") { step = .mode }
                Spacer()
                Button("Finish") { finishCloud() }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty)
            }
        }
    }

    // MARK: - Step 2b: local

    private var localStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("On-device transcription is free and private. Choose a model to download.")
                .font(Typography.body)
                .foregroundStyle(.secondary)

            HStack {
                if let modelId = appState.selectedModelId,
                   let model = ModelRegistry.model(forId: modelId) {
                    Label(model.name, systemImage: "cube.box")
                } else {
                    Text("No model selected")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Choose Model") { showModelManager = true }
                    .buttonStyle(.bordered)
            }
            .padding(Spacing.md)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(CornerRadius.md)

            if appState.selectedModelId != nil && !localReady {
                Text("Download the selected model to finish setup.")
                    .font(Typography.caption)
                    .foregroundStyle(BrandColors.warning)
            }

            Spacer()

            HStack {
                Button("Back") { step = .mode }
                Spacer()
                Button("Finish") { finishLocal() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!localReady)
            }
        }
    }

    /// True when the selected local model is downloaded and ready to use.
    private var localReady: Bool {
        appState.transcriptionMode == .local
            ? appState.isTranscriptionConfigured
            : isSelectedLocalModelReady
    }

    private var isSelectedLocalModelReady: Bool {
        guard let modelId = appState.selectedModelId,
              let model = ModelRegistry.model(forId: modelId) else { return false }
        return model.managedBySDK
            ? appState.modelDownloadManager.isParakeetModelDownloaded(modelId)
            : appState.modelDownloadManager.isModelDownloaded(model)
    }

    // MARK: - Actions

    private func testKey() {
        isTesting = true
        testResult = nil
        testSucceeded = false

        Task {
            do {
                try await appState.validateCloudKey(provider: provider, key: apiKey)
                await MainActor.run {
                    testResult = "API key is valid!"
                    testSucceeded = true
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testResult = "Test failed: \(error.localizedDescription)"
                    testSucceeded = false
                    isTesting = false
                }
            }
        }
    }

    private func finishCloud() {
        switch provider {
        case .openai: try? appState.openAIService.setAPIKey(apiKey)
        case .groq: try? appState.groqService.setAPIKey(apiKey)
        }
        appState.selectedCloudProvider = provider
        appState.transcriptionMode = .cloud
        complete()
    }

    private func finishLocal() {
        appState.transcriptionMode = .local
        complete()
    }

    private func complete() {
        appState.hasCompletedSetup = true
        appState.requiresSetup = false
        dismiss()
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
