import SwiftUI

struct ModelManagerView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Whisper Models") {
                    let whisperModels = ModelRegistry.models.filter { $0.family == .whisper }
                    ForEach(whisperModels) { model in
                        ModelRow(model: model)
                    }
                }
                
                Section("Parakeet Models") {
                    let parakeetModels = ModelRegistry.models.filter { $0.family == .parakeet }
                    ForEach(parakeetModels) { model in
                        ModelRow(model: model)
                    }
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

struct ModelRow: View {
    @Environment(AppState.self) private var appState
    let model: TranscriptionModel
    
    var isDownloaded: Bool {
        appState.modelDownloadManager.isModelDownloaded(model)
    }
    
    var isDownloading: Bool {
        appState.modelDownloadManager.downloadProgress[model.id] != nil && !isDownloaded
    }
    
    var progress: Double {
        appState.modelDownloadManager.downloadProgress[model.id] ?? 0
    }
    
    var isSelected: Bool {
        appState.selectedModelId == model.id
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.name)
                        .font(.headline)
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
                    
                    Text(model.languages.joined(separator: ", "))
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            if isDownloading {
                VStack(alignment: .trailing) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 100)
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                }
            } else if isDownloaded {
                Menu {
                    Button(isSelected ? "Selected" : "Select as Default") {
                        appState.selectedModelId = model.id
                    }
                    .disabled(isSelected)
                    
                    Button("Delete", role: .destructive) {
                        appState.modelDownloadManager.deleteModel(model)
                        if isSelected {
                            appState.selectedModelId = nil
                        }
                    }
                } label: {
                    Text("Downloaded")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
        .padding(.vertical, 4)
    }
}
