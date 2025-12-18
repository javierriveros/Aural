@testable import Aural
import XCTest

final class ModelRegistryTests: XCTestCase {
    func testModelRegistryContainsWhisperModels() {
        let whisperModels = ModelRegistry.models.filter { $0.family == .whisper }
        XCTAssertFalse(whisperModels.isEmpty, "Registry should contain Whisper models")
    }

    func testModelRegistryContainsParakeetModels() {
        let parakeetModels = ModelRegistry.models.filter { $0.family == .parakeet }
        XCTAssertFalse(parakeetModels.isEmpty, "Registry should contain Parakeet models")
    }

    func testModelLookupById() {
        let firstModel = ModelRegistry.models.first!
        let foundModel = ModelRegistry.model(forId: firstModel.id)
        XCTAssertEqual(firstModel.id, foundModel?.id)
    }

    func testModelLookupWithInvalidIdReturnsNil() {
        let foundModel = ModelRegistry.model(forId: "invalid-id")
        XCTAssertNil(foundModel)
    }
}
