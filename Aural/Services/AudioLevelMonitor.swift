import AVFoundation
import Foundation

@Observable
final class AudioLevelMonitor {
    // Current audio levels (0.0 to 1.0)
    private(set) var currentLevel: Float = 0.0
    private(set) var averageLevel: Float = 0.0
    private(set) var peakLevel: Float = 0.0

    // Rolling buffer of recent levels for waveform visualization
    private(set) var recentLevels: [Float] = []
    private let maxSamples: Int

    // Smoothing factor for visual stability (0.0 = no smoothing, 1.0 = max smoothing)
    // Almost zero for maximum responsiveness like Super Whisper
    private let smoothingFactor: Float = 0.0
    private var previousLevel: Float = 0.0

    // Minimum threshold to avoid showing noise (reduced for better sensitivity)
    private let noiseFloor: Float = 0.005

    init(maxSamples: Int = 10) {  // Small buffer, we only need current level
        self.maxSamples = maxSamples
        self.recentLevels = Array(repeating: 0.0, count: maxSamples)
    }

    /// Process an audio buffer and update levels
    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)

        // Calculate RMS (Root Mean Square) amplitude
        var sum: Float = 0.0
        for frame in 0..<frameLength {
            let sample = channelDataValue[frame]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))

        // Normalize to 0.0-1.0 range (typical speech is around 0.1-0.3 RMS)
        // We amplify it significantly for better visualization (like Super Whisper)
        // Higher gain = more sensitive and reactive waveforms
        let normalizedLevel = min(rms * 10.0, 1.0)

        // Apply noise floor (reduced for better sensitivity to quiet speech)
        let level = normalizedLevel > noiseFloor ? normalizedLevel : 0.0

        // Apply smoothing for more stable visualization
        let smoothedLevel = (level * (1.0 - smoothingFactor)) + (previousLevel * smoothingFactor)
        previousLevel = smoothedLevel

        // Update current level
        currentLevel = smoothedLevel

        // Update peak level
        if smoothedLevel > peakLevel {
            peakLevel = smoothedLevel
        }

        // Update average level (exponential moving average)
        if averageLevel == 0.0 {
            averageLevel = smoothedLevel
        } else {
            averageLevel = (averageLevel * 0.9) + (smoothedLevel * 0.1)
        }

        // Add to rolling buffer for waveform display
        recentLevels.removeFirst()
        recentLevels.append(smoothedLevel)
    }

    /// Reset all levels to zero
    func reset() {
        currentLevel = 0.0
        averageLevel = 0.0
        peakLevel = 0.0
        previousLevel = 0.0
        recentLevels = Array(repeating: 0.0, count: maxSamples)
    }

    /// Get a subset of levels for visualization (useful for different bar counts)
    func getLevels(count: Int) -> [Float] {
        guard count > 0, count <= recentLevels.count else {
            return recentLevels
        }

        // Sample evenly from the recent levels
        let step = recentLevels.count / count
        var result: [Float] = []

        for i in 0..<count {
            let index = i * step
            result.append(recentLevels[index])
        }

        return result
    }
}
