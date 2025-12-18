import SwiftUI

struct ModelManagerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    let whisperModels = ModelRegistry.models.filter { $0.family == .whisper }
                    ForEach(whisperModels) { model in
                        ModelRow(model: model)
                    }
                } header: {
                    Text("Whisper Models")
                } footer: {
                    Text("OpenAI Whisper models for speech-to-text. English-only models are faster and more accurate for English.")
                        .font(.caption2)
                }
                
                Section {
                    let parakeetModels = ModelRegistry.models.filter { $0.family == .parakeet }
                    ForEach(parakeetModels) { model in
                        ModelRow(model: model)
                    }
                } header: {
                    Text("Parakeet Models")
                } footer: {
                    Text("NVIDIA Parakeet models powered by FluidAudio for high-speed local transcription.")
                        .font(.caption2)
                }
            }
            .navigationTitle("Manage Models")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// MARK: - Model Row

struct ModelRow: View {
    @Environment(AppState.self) private var appState
    let model: TranscriptionModel
    
    private var isDownloaded: Bool {
        appState.modelDownloadManager.isModelDownloaded(model)
    }
    
    private var isDownloading: Bool {
        appState.modelDownloadManager.downloadProgress[model.id] != nil && !isDownloaded
    }
    
    private var progress: Double {
        appState.modelDownloadManager.downloadProgress[model.id] ?? 0
    }
    
    private var isSelected: Bool {
        appState.selectedModelId == model.id
    }
    
    private var isAvailable: Bool {
        true
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                        .foregroundStyle(isAvailable ? .primary : .secondary)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(model.size)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(languageDisplayText)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            actionButton
        }
        .padding(.vertical, 4)
    }
    
    private var languageDisplayText: String {
        if model.languages.contains("all") {
            return "Multilingual"
        } else if model.languages.count == 1 && model.languages.first == "en" {
            return "English"
        } else {
            return model.languages.joined(separator: ", ")
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if model.managedBySDK {
            // SDK managed models (like Parakeet via FluidAudio) handle their own downloading
            // lazily when initialized.
            HStack(spacing: 8) {
                Label("Auto-Managed", systemImage: "bolt.badge.automatic")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Button(isSelected ? "Selected" : "Select") {
                    appState.selectedModelId = model.id
                }
                .buttonStyle(.bordered)
                .disabled(isSelected)
            }
        } else if isDownloading {
            // Show progress with cancel button
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 2) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 80)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    appState.modelDownloadManager.cancelDownload(for: model)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel download")
            }
        } else if isDownloaded {
            // Show menu for downloaded models
            Menu {
                Button(isSelected ? "Selected" : "Select as Default") {
                    appState.selectedModelId = model.id
                }
                .disabled(isSelected)
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    appState.modelDownloadManager.deleteModel(model)
                    if isSelected {
                        appState.selectedModelId = nil
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Downloaded")
                        .font(.caption)
                }
            }
            .menuStyle(.button)
        } else {
            Button {
                appState.modelDownloadManager.downloadModel(model)
            } label: {
                Label("Download", systemImage: "icloud.and.arrow.down")
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    ModelManagerView()
        .environment(AppState())
}
