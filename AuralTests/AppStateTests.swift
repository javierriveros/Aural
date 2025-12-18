@testable import Aural
import XCTest

final class AppStateTests: XCTestCase {
    var appState: AppState!
    var audioRecorderMock: AudioRecorderMock!
    var audioProcessorMock: AudioProcessorMock!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)

        audioRecorderMock = AudioRecorderMock()
        audioProcessorMock = AudioProcessorMock()

        appState = AppState(
            audioRecorder: audioRecorderMock,
            audioProcessor: audioProcessorMock
        )
    }

    override func tearDown() {
        appState = nil
        audioRecorderMock = nil
        audioProcessorMock = nil
        super.tearDown()
    }

    func testInitializationDefaults() {
        XCTAssertEqual(appState.transcriptionMode, .cloud)
        XCTAssertEqual(appState.selectedCloudProvider, .openai)
        XCTAssertTrue(appState.showFloatingWidget)
        XCTAssertEqual(appState.audioSpeedMultiplier, 1.0)
    }

    func testTranscriptionModePersistence() {
        appState.transcriptionMode = .local
        XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaultsKeys.transcriptionMode), "local")

        appState.transcriptionMode = .cloud
        XCTAssertEqual(UserDefaults.standard.string(forKey: UserDefaultsKeys.transcriptionMode), "cloud")
    }

    /*
    // This test requires handling MainActor isolation properly or making startRecording internal/accessible.
    // Since startRecording is private and triggered by hotkeyMonitor closures, 
    // we would need to invoke the closure.
    func testStartRecording() async {
        // Setup mock
        let tempURL = URL(fileURLWithPath: "/tmp/test.m4a")
        audioRecorderMock.startRecordingReturnValue = tempURL
        audioRecorderMock.requestPermissionReturnValue = true
        
        // Trigger recording somehow. 
        // We can expose a method just for testing or simulate the hotkey.
        // For now, let's assume we can trigger the closure if we had access, 
        // but hotkeyMonitor is internal.
        
        // This is a placeholder for when we refactor HotkeyMonitor or expose internal triggers.
    }
    */

    func testDependencyInjection() {
        // Verify that the appState is using our mocks
        XCTAssertIdentical(appState.audioRecorder, audioRecorderMock)
        XCTAssertIdentical(appState.audioProcessor, audioProcessorMock)
    }
}
