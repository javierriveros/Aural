import AVFoundation
import Foundation

@Observable
final class AudioLevelMonitor {
    private(set) var currentLevel: Float = 0.0
    private(set) var averageLevel: Float = 0.0
    private(set) var peakLevel: Float = 0.0
    private(set) var velocity: Float = 0.0
    private(set) var energy: Float = 0.0
    private(set) var recentLevels: [Float] = []
    private let maxSamples: Int

    private let smoothingFactor: Float = 0.0
    private var previousLevel: Float = 0.0
    private let energyDecay: Float = 0.95
    private let noiseFloor: Float = 0.005

    init(maxSamples: Int = 30) {
        self.maxSamples = maxSamples
        self.recentLevels = Array(repeating: 0.0, count: maxSamples)
    }

    func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let frameLength = Int(buffer.frameLength)

        var sum: Float = 0.0
        for frame in 0..<frameLength {
            let sample = channelDataValue[frame]
            sum += sample * sample
        }

        let rms = sqrt(sum / Float(frameLength))
        let normalizedLevel = min(rms * 10.0, 1.0)
        let level = normalizedLevel > noiseFloor ? normalizedLevel : 0.0

        let smoothedLevel = (level * (1.0 - smoothingFactor)) + (previousLevel * smoothingFactor)
        previousLevel = smoothedLevel
        currentLevel = smoothedLevel

        velocity = abs(smoothedLevel - previousLevel) * 20.0
        velocity = min(velocity, 1.0)

        if smoothedLevel > 0.1 {
            energy = min(energy + smoothedLevel * 0.1, 1.0)
        } else {
            energy *= energyDecay
        }

        if smoothedLevel > peakLevel {
            peakLevel = smoothedLevel
        }

        if averageLevel == 0.0 {
            averageLevel = smoothedLevel
        } else {
            averageLevel = (averageLevel * 0.9) + (smoothedLevel * 0.1)
        }

        recentLevels.removeFirst()
        recentLevels.append(smoothedLevel)
    }

    func reset() {
        currentLevel = 0.0
        averageLevel = 0.0
        peakLevel = 0.0
        velocity = 0.0
        energy = 0.0
        previousLevel = 0.0
        recentLevels = Array(repeating: 0.0, count: maxSamples)
    }

    func getLevels(count: Int) -> [Float] {
        guard count > 0, count <= recentLevels.count else {
            return recentLevels
        }

        let step = recentLevels.count / count
        var result: [Float] = []

        for stepIndex in 0..<count {
            let index = stepIndex * step
            result.append(recentLevels[index])
        }

        return result
    }
}
