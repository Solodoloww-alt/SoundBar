import SwiftUI

struct SettingsView: View {
    @ObservedObject var audioMonitor: SystemAudioMonitor

    // Capture
    @AppStorage("barCount")          private var barCount          = 30.0
    @AppStorage("sensitivity")       private var sensitivity       = 5.0
    @AppStorage("smoothing")         private var smoothing         = 0.6

    // Visual style
    @AppStorage("barColorTheme")     private var colorTheme        = "Cyan/Purple"
    @AppStorage("glowMode")          private var glowMode          = true
    @AppStorage("glowRadius")        private var glowRadius        = 4.0
    @AppStorage("capsuleMode")       private var capsuleMode       = false
    @AppStorage("peakHold")          private var peakHold          = true
    @AppStorage("peakDecay")         private var peakDecay         = 0.97
    @AppStorage("mirrorMode")        private var mirrorMode        = false
    @AppStorage("barSpacing")        private var barSpacing        = 2.0
    @AppStorage("cornerRadius")      private var cornerRadius      = 1.5
    @AppStorage("minBarHeight")      private var minBarHeight      = 2.0
    @AppStorage("barOpacity")        private var barOpacity        = 1.0
    @AppStorage("bassBoost")         private var bassBoost         = 1.5
    @AppStorage("freqOffset")        private var freqOffset        = 2.0
    @AppStorage("beatPulseEnabled")  private var beatPulseEnabled  = true

    let themes = ["Cyan/Purple", "Fire", "Neon Green", "Ocean", "Sunset", "Monochrome", "Rose", "Gold"]

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    Divider().padding(.horizontal)
                    VStack(spacing: 12) {
                        captureSection
                        visualSection
                        barsSection
                        audioSection
                        dangerSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 840)
    }

    // MARK: - Header

    var headerSection: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 52, height: 52)
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("SoundBar")
                    .font(.system(size: 20, weight: .bold))
                Text("Touch Bar Audio Visualizer")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if audioMonitor.isCapturing {
                HStack(spacing: 5) {
                    Circle().fill(.green).frame(width: 7, height: 7)
                    Text("Live")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.green.opacity(0.12), in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Capture

    var captureSection: some View {
        SettingsGroup(title: "Capture", icon: "waveform", iconColor: .cyan) {
            Button {
                audioMonitor.isCapturing
                    ? audioMonitor.stopMonitoring()
                    : audioMonitor.startMonitoring()
            } label: {
                HStack {
                    Image(systemName: audioMonitor.isCapturing
                          ? "stop.circle.fill" : "play.circle.fill")
                    Text(audioMonitor.isCapturing
                         ? "Stop Visualizing" : "Start Visualizing")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(audioMonitor.isCapturing ? .red : .cyan)
            .controlSize(.large)
        }
    }

    // MARK: - Visual Style

    var visualSection: some View {
        SettingsGroup(title: "Visual Style", icon: "sparkles", iconColor: .purple) {
            VStack(spacing: 0) {
                PickerRow(label: "Color Theme", selection: $colorTheme, options: themes)
                Divider().padding(.leading, 16)
                ToggleRow(label: "Glow Effect",  icon: "light.max",                     isOn: $glowMode)
                if glowMode {
                    Divider().padding(.leading, 16)
                    SliderRow(label: "Glow Radius", value: $glowRadius, range: 1...12, step: 0.5,
                              format: { String(format: "%.1f", $0) })
                }
                Divider().padding(.leading, 16)
                ToggleRow(label: "Capsule Bars",  icon: "capsule.fill",                 isOn: $capsuleMode)
                Divider().padding(.leading, 16)
                ToggleRow(label: "Mirror Mode",   icon: "rectangle.on.rectangle.angled",isOn: $mirrorMode)
                Divider().padding(.leading, 16)
                ToggleRow(label: "Beat Pulse",    icon: "heart.fill",                   isOn: $beatPulseEnabled)
                Divider().padding(.leading, 16)
                SliderRow(label: "Bar Opacity", value: $barOpacity, range: 0.2...1.0,
                          format: { "\(Int($0 * 100))%" })
            }
        }
    }

    // MARK: - Bar Shape

    var barsSection: some View {
        SettingsGroup(title: "Bar Shape", icon: "slider.horizontal.3", iconColor: .orange) {
            VStack(spacing: 0) {
                SliderRow(label: "Bar Count", value: $barCount, range: 10...100, step: 1,
                          format: { "\(Int($0))" })
                Divider().padding(.leading, 16)
                SliderRow(label: "Bar Spacing", value: $barSpacing, range: 0...6, step: 0.5,
                          format: { String(format: "%.1f", $0) })
                Divider().padding(.leading, 16)
                SliderRow(label: "Corner Radius", value: $cornerRadius, range: 0...8, step: 0.5,
                          format: { String(format: "%.1f", $0) })
                Divider().padding(.leading, 16)
                SliderRow(label: "Min Bar Height", value: $minBarHeight, range: 0...8, step: 0.5,
                          format: { String(format: "%.1f", $0) })
            }
        }
    }

    // MARK: - Audio

    var audioSection: some View {
        SettingsGroup(title: "Audio Processing", icon: "waveform.path.ecg", iconColor: .green) {
            VStack(spacing: 0) {
                SliderRow(label: "Sensitivity", value: $sensitivity, range: 0.5...20, step: 0.5,
                          format: { String(format: "%.1f", $0) })
                Divider().padding(.leading, 16)
                SliderRow(label: "Smoothing", value: $smoothing, range: 0.1...0.98, step: 0.01,
                          format: { String(format: "%.2f", $0) })
                Divider().padding(.leading, 16)
                SliderRow(label: "Bass Boost", value: $bassBoost, range: 0.5...4.0, step: 0.1,
                          format: { String(format: "%.1f×", $0) })
                Divider().padding(.leading, 16)
                SliderRow(label: "Freq Offset", value: $freqOffset, range: 0...10, step: 1,
                          format: { "\(Int($0))" })
                Divider().padding(.leading, 16)
                ToggleRow(label: "Peak Hold", icon: "line.horizontal.3.decrease", isOn: $peakHold)
                if peakHold {
                    Divider().padding(.leading, 16)
                    SliderRow(label: "Peak Decay", value: $peakDecay, range: 0.90...0.999, step: 0.001,
                              format: { String(format: "%.3f", $0) })
                }
            }
        }
    }

    // MARK: - Danger

    var dangerSection: some View {
        SettingsGroup(title: "Reset", icon: "arrow.counterclockwise", iconColor: .red) {
            VStack(spacing: 0) {
                Button("Reset All Settings to Defaults") {
                    colorTheme = "Cyan/Purple"; barCount = 30; sensitivity = 5.0
                    smoothing = 0.6; glowMode = true; glowRadius = 4.0
                    capsuleMode = false; peakHold = true; peakDecay = 0.97
                    mirrorMode = false; barSpacing = 2.0; cornerRadius = 1.5
                    minBarHeight = 2.0; barOpacity = 1.0; bassBoost = 1.5
                    freqOffset = 2.0; beatPulseEnabled = true
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider().padding(.leading, 16)

                Button {
                    NSApp.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit SoundBar")
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }
}

// MARK: - Reusable Components

struct SettingsGroup<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(.background.opacity(0.6), in:
                RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.separator.opacity(0.6), lineWidth: 0.5)
            )
            .padding(.bottom, 4)
        }
    }
}

struct ToggleRow: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon).frame(width: 18).foregroundStyle(.secondary)
                Text(label)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct SliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    let format: (Double) -> String

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(.system(size: 13))
                Spacer()
                Text(format(value))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            if let step {
                Slider(value: $value, in: range, step: step).tint(.cyan)
            } else {
                Slider(value: $value, in: range).tint(.cyan)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

struct PickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 13))
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
