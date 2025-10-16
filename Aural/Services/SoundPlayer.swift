import AppKit
import AVFoundation

final class SoundPlayer {
    static let shared = SoundPlayer()

    private var soundsEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.soundsEnabled)
    }

    private init() {
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.soundsEnabled: true])
    }

    func playRecordingStart() {
        guard soundsEnabled else { return }
        NSSound(named: "Pop")?.play()
    }

    func playRecordingStop() {
        guard soundsEnabled else { return }
        NSSound(named: "Tink")?.play()
    }

    func playTranscriptionComplete() {
        guard soundsEnabled else { return }
        NSSound(named: "Glass")?.play()
    }

    func playError() {
        guard soundsEnabled else { return }
        NSSound(named: "Sosumi")?.play()
    }

    func playLockEngaged() {
        guard soundsEnabled else { return }
        NSSound(named: "Morse")?.play()
    }
}
