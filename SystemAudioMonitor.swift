import Foundation
import ScreenCaptureKit
import CoreMedia
import Accelerate
import Combine

class SystemAudioMonitor: NSObject, ObservableObject, SCStreamOutput {
    @Published var amplitudes: [Float]  = Array(repeating: 0, count: 100)
    @Published var peakLevels: [Float]  = Array(repeating: 0, count: 100)
    @Published var beatPulse: CGFloat   = 1.0
    @Published var isCapturing          = false

    private var stream: SCStream?
    private lazy var fftHelper = FFTHelper(size: 1024)

    // All settings read live from UserDefaults
    private var smoothing:   Float { Float(UserDefaults.standard.double(forKey: "smoothing")  .nonZero ?? 0.6)  }
    private var sensitivity: Float { Float(UserDefaults.standard.double(forKey: "sensitivity").nonZero ?? 5.0)  }
    private var bassBoost:   Float { Float(UserDefaults.standard.double(forKey: "bassBoost")  .nonZero ?? 1.5)  }
    private var freqOffset:  Int   { Int(UserDefaults.standard.double(forKey: "freqOffset"))  }
    private var peakDecay:   Float { Float(UserDefaults.standard.double(forKey: "peakDecay")  .nonZero ?? 0.97) }

    func startMonitoring() {
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                guard let display = content.displays.first else { return }
                let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
                let config  = SCStreamConfiguration()
                config.capturesAudio = true
                config.sampleRate    = 48000
                config.channelCount  = 1
                stream = SCStream(filter: filter, configuration: config, delegate: nil)
                try stream?.addStreamOutput(self, type: .audio,
                                            sampleHandlerQueue: DispatchQueue(label: "audio", qos: .userInteractive))
                try await stream?.startCapture()
                DispatchQueue.main.async { self.isCapturing = true }
            } catch {
                print("Capture failed: \(error)")
            }
        }
    }

    func stopMonitoring() {
        stream?.stopCapture()
        stream = nil
        DispatchQueue.main.async {
            self.isCapturing = false
            self.amplitudes  = Array(repeating: 0, count: 100)
            self.peakLevels  = Array(repeating: 0, count: 100)
        }
    }

    func stream(_ stream: SCStream,
                didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                of type: SCStreamOutputType) {
        guard type == .audio,
              let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        let length = CMBlockBufferGetDataLength(blockBuffer)
        var pointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0,
                                    lengthAtOffsetOut: nil, totalLengthOut: nil,
                                    dataPointerOut: &pointer)
        guard let data = pointer else { return }

        let floatCount  = length / 4
        let floatData   = data.withMemoryRebound(to: Float.self, capacity: floatCount) { $0 }
        let frequencies = fftHelper.analyze(buffer: floatData, count: floatCount)

        let smooth    = smoothing
        let sens      = sensitivity
        let bass      = bassBoost
        let offset    = max(0, min(freqOffset, 10))
        let decay     = peakDecay

        DispatchQueue.main.async {
            var energy: Float = 0

            for i in 0..<100 {
                let freqIndex = min(i + offset + 2, frequencies.count - 1)
                // Bass curve: stronger boost for lower bins, controlled by bassBoost setting
                let t     = Float(i) / 100.0
                let curve = bass - (bass - 1.0) * t   // goes from `bass` → 1.0 linearly
                let raw   = frequencies[freqIndex] * sens * curve
                let target = min(raw, 1.0)

                if target > self.amplitudes[i] {
                    // Fast attack
                    self.amplitudes[i] = self.amplitudes[i] * smooth * 0.4 + target * (1 - smooth * 0.4)
                } else {
                    // Slow decay
                    self.amplitudes[i] = self.amplitudes[i] * smooth + target * (1 - smooth)
                }

                if self.amplitudes[i] > self.peakLevels[i] {
                    self.peakLevels[i] = self.amplitudes[i]
                } else {
                    self.peakLevels[i] *= decay
                }
                energy += self.amplitudes[i]
            }

            let avgEnergy  = energy / 100
            let pulseEnabled = UserDefaults.standard.object(forKey: "beatPulseEnabled") as? Bool ?? true
            self.beatPulse = (pulseEnabled && avgEnergy > 0.3) ? 1.15 : 1.0
        }
    }
}

// MARK: - FFT Helper

class FFTHelper {
    let size: Int
    let log2size: vDSP_Length
    let fftSetup: FFTSetup

    init(size: Int) {
        self.size     = size
        self.log2size = vDSP_Length(log2f(Float(size)))
        self.fftSetup = vDSP_create_fftsetup(log2size, FFTRadix(kFFTRadix2))!
    }

    func analyze(buffer: UnsafePointer<Float>, count: Int) -> [Float] {
        let halfSize = size / 2
        var real = [Float](repeating: 0, count: halfSize)
        var imag = [Float](repeating: 0, count: halfSize)
        var splitComplex = DSPSplitComplex(realp: &real, imagp: &imag)

        var input = [Float](repeating: 0, count: size)
        let copyCount = min(count, size)
        for i in 0..<copyCount { input[i] = buffer[i] }

        input.withUnsafeBytes { ptr in
            guard let base = ptr.baseAddress else { return }
            vDSP_ctoz(base.assumingMemoryBound(to: DSPComplex.self),
                      2, &splitComplex, 1, vDSP_Length(halfSize))
        }

        vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2size, FFTDirection(FFT_FORWARD))

        var magnitudes = [Float](repeating: 0, count: halfSize)
        vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(halfSize))

        var scale: Float = 2.0 / Float(size)
        vDSP_vsmul(magnitudes, 1, &scale, &magnitudes, 1, vDSP_Length(halfSize))

        return magnitudes
    }

    deinit { vDSP_destroy_fftsetup(fftSetup) }
}

// MARK: - Helper

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
