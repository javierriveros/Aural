@testable import Aural
import XCTest

final class TextCleanupServiceTests: XCTestCase {
  var service: TextCleanupService!
  var userDefaults: UserDefaults!
  var repository: FillerWordsRepository!

  override func setUp() {
    super.setUp()
    // Use a unique suite for each test run to ensure isolation
    userDefaults = UserDefaults(suiteName: "TextCleanupTests-\(UUID().uuidString)")!
    repository = FillerWordsRepository(userDefaults: userDefaults)
    service = TextCleanupService(fillerRepository: repository)

    // Setup initial clean state
    let config = FillerWordsConfiguration(isEnabled: true)
    repository.save(config)
    // Stutter uses standard user defaults in service (logic not refactored yet)
    // For now we test stutter logic using standard defaults (less critical to isolate as it is simple bool)
    UserDefaults.standard.set(true, forKey: UserDefaultsKeys.removeStuttering)
  }

  override func tearDown() {
    userDefaults.removePersistentDomain(forName: "TextCleanupTests")
    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.removeStuttering)
    service = nil
    repository = nil
    userDefaults = nil
    super.tearDown()
  }

  // MARK: - Filler Word Removal

  func testRemoveSimpleFillers() {
    let input = "So um I want to uh test this"
    let result = service.removeFillerWords(from: input)
    XCTAssertFalse(result.contains("um"))
    XCTAssertFalse(result.contains("uh"))
  }

  func testRemoveFillerWithTrailingComma() {
    let input = "Well, um, I think we should"
    let result = service.removeFillerWords(from: input)
    XCTAssertFalse(result.contains("um"))
  }

  func testRemoveMultipleFillers() {
    let input = "Uh um er I mean uhh"
    let result = service.removeFillerWords(from: input)
    XCTAssertFalse(result.lowercased().contains("uh"))
    XCTAssertFalse(result.lowercased().contains("um"))
    XCTAssertFalse(result.lowercased().contains("er"))
  }

  func testFillersCaseInsensitive() {
    let input = "UM is here and Uh is there"
    let result = service.removeFillerWords(from: input)
    XCTAssertFalse(result.contains("UM"))
    XCTAssertFalse(result.contains("Uh"))
  }

  func testPreservesLegitimateWords() {
    let input = "The umbrella is humming"
    let result = service.removeFillerWords(from: input)
    XCTAssertTrue(result.contains("umbrella"))
    XCTAssertTrue(result.contains("humming"))
  }

  // MARK: - Stuttering Removal

  func testRemoveSimpleStutter() {
    let input = "I I want to test this"
    let expected = "I want to test this"
    XCTAssertEqual(service.removeStuttering(from: input), expected)
  }

  func testRemoveTripleStutter() {
    let input = "The the the cat sat"
    let expected = "The cat sat"
    XCTAssertEqual(service.removeStuttering(from: input), expected)
  }

  func testRemoveMultipleStutterInstances() {
    let input = "I I want to to see the the cat"
    let expected = "I want to see the cat"
    XCTAssertEqual(service.removeStuttering(from: input), expected)
  }

  func testStutterCaseInsensitive() {
    let input = "The THE cat"
    let expected = "The cat"
    XCTAssertEqual(service.removeStuttering(from: input), expected)
  }

  // MARK: - Disabled Features

  func testDisabledFillerRemoval() {
    let config = FillerWordsConfiguration(isEnabled: false)
    repository.save(config)
    
    // Create new service to pick up changes if necessary, though repository reference is same
    // With our DI, repository.load() calls userDefaults directly so it should pick it up immediately
    
    let input = "I um want to test"
    let result = service.removeFillerWords(from: input)
    XCTAssertTrue(result.contains("um"))
  }
}
