import Foundation

class MockURLSessionDownloadTask: URLSessionDownloadTask {
    private let resumeAction: () -> Void
    var internalState: URLSessionTask.State = .suspended
    
    override var state: URLSessionTask.State { internalState }
    
    init(resumeAction: @escaping () -> Void) {
        self.resumeAction = resumeAction
        super.init()
    }
    
    override func resume() {
        internalState = .running
        resumeAction()
    }
    
    override func cancel() {
        internalState = .canceling
    }
}

// Simplified mock session - in real tests we'd use a more robust URLProtocol or delegate mock
class MockURLSession: URLSession {
    var lastURL: URL?
    
    override func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        lastURL = url
        return MockURLSessionDownloadTask {
            // No-op or simulate callback
        }
    }
}
