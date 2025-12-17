import Foundation

@Observable
final class ModelDownloadManager {
    private let session: URLSession
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private(set) var downloadProgress: [String: Double] = [:]
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    var localModelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("Aural").appendingPathComponent(LocalModelConstants.modelsDirectory)
        
        if !FileManager.default.fileExists(atPath: modelsDir.path) {
            try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        
        return modelsDir
    }
    
    func downloadPath(for model: TranscriptionModel) -> URL {
        return localModelsDirectory.appendingPathComponent(model.downloadURL.lastPathComponent)
    }
    
    func isModelDownloaded(_ model: TranscriptionModel) -> Bool {
        return FileManager.default.fileExists(atPath: downloadPath(for: model).path)
    }
    
    func downloadModel(_ model: TranscriptionModel) {
        guard downloadTasks[model.id] == nil else { return }
        
        let task = session.downloadTask(with: model.downloadURL) { [weak self] location, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to download model \(model.id): \(error)")
                Task { @MainActor in
                    self.downloadTasks.removeValue(forKey: model.id)
                    self.downloadProgress.removeValue(forKey: model.id)
                }
                return
            }
            
            guard let location = location else { return }
            
            let destination = self.downloadPath(for: model)
            
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                
                Task { @MainActor in
                    self.downloadTasks.removeValue(forKey: model.id)
                    self.downloadProgress[model.id] = 1.0
                }
            } catch {
                print("Failed to move downloaded model: \(error)")
                Task { @MainActor in
                    self.downloadTasks.removeValue(forKey: model.id)
                }
            }
        }
        
        downloadTasks[model.id] = task
        downloadProgress[model.id] = 0.0
        task.resume()
        
        // Track progress (simplified version for now)
        observeProgress(for: model, task: task)
    }
    
    private func observeProgress(for model: TranscriptionModel, task: URLSessionDownloadTask) {
        // In a real app, we'd use a delegate for progress, but for simplicity we'll poll
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, let task = self.downloadTasks[model.id] else {
                timer.invalidate()
                return
            }
            
            if task.state == .completed {
                timer.invalidate()
                return
            }
            
            if task.countOfBytesExpectedToReceive > 0 {
                let progress = Double(task.countOfBytesReceived) / Double(task.countOfBytesExpectedToReceive)
                Task { @MainActor in
                    self.downloadProgress[model.id] = progress
                }
            }
        }
    }
    
    func deleteModel(_ model: TranscriptionModel) {
        let path = downloadPath(for: model)
        try? FileManager.default.removeItem(at: path)
        downloadProgress.removeValue(forKey: model.id)
    }
}
