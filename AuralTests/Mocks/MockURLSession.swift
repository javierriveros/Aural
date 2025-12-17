import Foundation

class MockURLSessionDownloadTask: URLSessionDownloadTask {
    private let resumeAction: () -> Void
    var _state: URLSessionTask.State = .suspended
    
    override var state: URLSessionTask.State { _state }
    
    init(resumeAction: @escaping () -> Void) {
        self.resumeAction = resumeAction
        super.init()
    }
    
    override func resume() {
        _state = .running
        resumeAction()
    }
    
    override func cancel() {
        _state = .canceling
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
