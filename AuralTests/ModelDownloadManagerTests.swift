import XCTest
@testable import Aural

final class ModelDownloadManagerTests: XCTestCase {
    var manager: ModelDownloadManager!
    
    override func setUp() {
        super.setUp()
        manager = ModelDownloadManager()
    }
    
    func testDownloadPathConstruction() {
        let model = ModelRegistry.models.first!
        let path = manager.downloadPath(for: model)
        XCTAssertTrue(path.path.contains(LocalModelConstants.modelsDirectory))
        XCTAssertEqual(path.lastPathComponent, model.downloadURL.lastPathComponent)
    }
    
    func testLocalModelsDirectoryExists() {
        let dir = manager.localModelsDirectory
        XCTAssertTrue(FileManager.default.fileExists(atPath: dir.path))
    }
}
