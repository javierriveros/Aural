import Foundation

@Observable
final class ModelDownloadManager: NSObject {
    private var session: URLSession!
    private var downloadTasks: [String: URLSessionDownloadTask] = [:]
    private(set) var downloadProgress: [String: Double] = [:]
    private var modelIdForTask: [Int: String] = [:] // Task identifier to model ID mapping

    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
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

        let task = session.downloadTask(with: model.downloadURL)
        modelIdForTask[task.taskIdentifier] = model.id
        downloadTasks[model.id] = task
        downloadProgress[model.id] = 0.0
        task.resume()
    }

    func cancelDownload(for model: TranscriptionModel) {
        guard let task = downloadTasks[model.id] else { return }
        task.cancel()
        downloadTasks.removeValue(forKey: model.id)
        downloadProgress.removeValue(forKey: model.id)
        modelIdForTask.removeValue(forKey: task.taskIdentifier)
    }

    func deleteModel(_ model: TranscriptionModel) {
        let path = downloadPath(for: model)
        try? FileManager.default.removeItem(at: path)
        downloadProgress.removeValue(forKey: model.id)
    }

    private func handleDownloadCompletion(for modelId: String, location: URL?, error: Error?) {
        defer {
            downloadTasks.removeValue(forKey: modelId)
        }

        if let error = error {
            print("Failed to download model \(modelId): \(error)")
            downloadProgress.removeValue(forKey: modelId)
            return
        }

        guard let location = location,
              let model = ModelRegistry.model(forId: modelId) else {
            downloadProgress.removeValue(forKey: modelId)
            return
        }

        let destination = downloadPath(for: model)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            downloadProgress[modelId] = 1.0
        } catch {
            print("Failed to move downloaded model: \(error)")
            downloadProgress.removeValue(forKey: modelId)
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let modelId = modelIdForTask[downloadTask.taskIdentifier] else { return }
        modelIdForTask.removeValue(forKey: downloadTask.taskIdentifier)
        handleDownloadCompletion(for: modelId, location: location, error: nil)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let modelId = modelIdForTask[downloadTask.taskIdentifier],
              totalBytesExpectedToWrite > 0 else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        downloadProgress[modelId] = progress
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let modelId = modelIdForTask[downloadTask.taskIdentifier] else { return }

        if let error = error {
            modelIdForTask.removeValue(forKey: downloadTask.taskIdentifier)
            handleDownloadCompletion(for: modelId, location: nil, error: error)
        }
    }
}
