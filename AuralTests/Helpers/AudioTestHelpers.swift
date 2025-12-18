import AVFoundation
import Foundation

enum AudioTestHelper {
    static func createTemporaryAudioFile(duration: TimeInterval = 1.0) throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let audioFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        guard let writer = try? AVAssetWriter(outputURL: audioFileURL, fileType: .wav),
              let input = try? AVAssetWriterInput(mediaType: .audio, outputSettings: settings) else {
            throw NSError(domain: "AudioTestHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create asset writer"])
        }

        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let samplesPerSecond = 44100
        let totalSamples = Int(duration * Double(samplesPerSecond))
        let bufferSize = 1024

        let format = AVAudioFormat(settings: settings)!

        input.requestMediaDataWhenReady(on: DispatchQueue(label: "AudioGeneration")) {
            var currentSample = 0

            while input.isReadyForMoreMediaData && currentSample < totalSamples {
                let samplesToRead = min(bufferSize, totalSamples - currentSample)

                if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samplesToRead)) {
                    buffer.frameLength = AVAudioFrameCount(samplesToRead)

                    if let channelData = buffer.int16ChannelData {
                        let channelPointer = channelData[0]
                        for index in 0..<Int(buffer.frameLength) {
                            // Generate a simple silent buffer (all zeros) for testing
                            channelPointer[index] = 0
                        }
                    }

                    input.append(buffer.toCMSampleBuffer(presentationTime: CMTime(value: CMTimeValue(currentSample), timescale: 44100))!)
                    currentSample += samplesToRead
                }
            }

            input.markAsFinished()
            writer.finishWriting {}
        }

        // Wait for file to establish
        var attempts = 0
        while !FileManager.default.fileExists(atPath: audioFileURL.path) && attempts < 10 {
            Thread.sleep(forTimeInterval: 0.1)
            attempts += 1
        }

        return audioFileURL
    }
}

extension AVAudioPCMBuffer {
    func toCMSampleBuffer(presentationTime: CMTime) -> CMSampleBuffer? {
        var status: OSStatus = noErr
        var sampleBuffer: CMSampleBuffer?

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 44100),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )

        status = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: format.formatDescription,
            sampleCount: CMItemCount(frameLength),
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )

        guard status == noErr, let buffer = sampleBuffer else { return nil }

        let status2 = CMSampleBufferSetDataBufferFromAudioBufferList(
            buffer,
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: 0,
            bufferList: audioBufferList
        )

        return status2 == noErr ? buffer : nil
    }
}
