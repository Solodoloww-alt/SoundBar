import SwiftUI

// MARK: - App Storage Keys (all in one place)
// Visual
// barColorMode: "preset" | "solid" | "gradient"
// presetTheme: String
// solidColor: Color (stored as hex string)
// gradientColor1, gradientColor2, gradientColor3: hex strings
// gradientUseThreeColors: Bool
// gradientAngle: Double (0-360)
// glowMode: Bool
// glowRadius: Double
// glowColorMode: "match" | "white" | "custom"
// glowCustomColor: hex
// capsuleMode: Bool
// mirrorMode: Bool
// beatPulseEnabled: Bool
// barOpacity: Double
// peakHold: Bool
// peakDecay: Double
// peakColorMode: "white" | "match" | "custom"
// peakCustomColor: hex
// Bars
// barCount: Double
// barSpacing: Double
// cornerRadius: Double
// minBarHeight: Double
// Audio
// sensitivity: Double
// smoothing: Double
// bassBoost: Double
// freqOffset: Double
// Background
// showBackground: Bool
// backgroundColor: hex
// backgroundOpacity: Double

struct SettingsView: View {
    @ObservedObject var audioMonitor: SystemAudioMonitor
    @State private var selectedSection: Section = .capture

    enum Section: String, CaseIterable {
        case capture  = "Capture"
        case colours  = "Colours"
        case bars     = "Bars"
        case audio    = "Audio"
        case advanced = "Advanced"

        var icon: String {
            switch self {
            case .capture:  return "waveform"
            case .colours:  return "paintpalette"
            case .bars:     return "slider.horizontal.3"
            case .audio:    return "music.note"
            case .advanced: return "gearshape"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // ── Sidebar ──────────────────────────────────────────────
            List(Section.allCases, id: \.self, selection: $selectedSection) { sec in
                Label(sec.rawValue, systemImage: sec.icon)
                    .tag(sec)
            }
            .navigationSplitViewColumnWidth(200)
            .listStyle(.sidebar)

            // App info at bottom of sidebar
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                Text("SoundBar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)

        } detail: {
            // ── Detail ───────────────────────────────────────────────
            Group {
                switch selectedSection {
                case .capture:  CaptureSection(audioMonitor: audioMonitor)
                case .colours:  ColoursSection()
                case .bars:     BarsSection()
                case .audio:    AudioSection()
                case .advanced: AdvancedSection()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(selectedSection.rawValue)
        }
        .frame(width: 640, height: 520)
    }
}

// MARK: - Capture Section

struct CaptureSection: View {
    @ObservedObject var audioMonitor: SystemAudioMonitor

    var body: some View {
        Form {
            Section {
                // Live preview of the Touch Bar
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black)
                        .frame(height: 44)
                    TouchBarVisualizerView(audioMonitor: audioMonitor)
                        .frame(height: 30)
                        .padding(.horizontal, 8)
                }
                .padding(.vertical, 4)
                Text("Live Touch Bar Preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } header: { Text("Preview") }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(audioMonitor.isCapturing ? "Capturing System Audio" : "Not Capturing")
                            .font(.system(size: 13, weight: .medium))
                        Text(audioMonitor.isCapturing
                             ? "Visualizer is active on Touch Bar"
                             : "Press Start to begin visualization")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if audioMonitor.isCapturing {
                        // Animated live indicator
                        HStack(spacing: 3) {
                            ForEach(0..<3) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(.green)
                                    .frame(width: 3, height: CGFloat([8,12,6][i]))
                            }
                        }
                    }
                }

                Button {
                    audioMonitor.isCapturing
                        ? audioMonitor.stopMonitoring()
                        : audioMonitor.startMonitoring()
                } label: {
                    Label(
                        audioMonitor.isCapturing ? "Stop Visualizing" : "Start Visualizing",
                        systemImage: audioMonitor.isCapturing ? "stop.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(audioMonitor.isCapturing ? .red : .accentColor)
                .controlSize(.large)
            } header: { Text("Status") }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Colours Section

struct ColoursSection: View {
    @AppStorage("barColorMode")        private var colorMode         = "preset"
    @AppStorage("presetTheme")         private var presetTheme       = "Cyan/Purple"
    @AppStorage("solidColorHex")       private var solidColorHex     = "#00FFFF"
    @AppStorage("gradientColor1Hex")   private var grad1Hex          = "#00FFFF"
    @AppStorage("gradientColor2Hex")   private var grad2Hex          = "#FF00FF"
    @AppStorage("gradientColor3Hex")   private var grad3Hex          = "#FF6600"
    @AppStorage("gradientUse3Colors")  private var gradientUse3      = false
    @AppStorage("glowMode")            private var glowMode          = true
    @AppStorage("glowRadius")          private var glowRadius        = 4.0
    @AppStorage("glowColorMode")       private var glowColorMode     = "match"
    @AppStorage("glowCustomColorHex")  private var glowCustomHex     = "#00FFFF"
    @AppStorage("peakHold")            private var peakHold          = true
    @AppStorage("peakColorMode")       private var peakColorMode     = "white"
    @AppStorage("peakCustomColorHex")  private var peakCustomHex     = "#FFFFFF"
    @AppStorage("barOpacity")          private var barOpacity        = 1.0
    @AppStorage("showBackground")      private var showBackground    = false
    @AppStorage("bgColorHex")          private var bgColorHex        = "#000000"
    @AppStorage("bgOpacity")           private var bgOpacity         = 0.6

    private var solidColor: Binding<Color> { hexBinding($solidColorHex) }
    private var grad1Color: Binding<Color> { hexBinding($grad1Hex) }
    private var grad2Color: Binding<Color> { hexBinding($grad2Hex) }
    private var grad3Color: Binding<Color> { hexBinding($grad3Hex) }
    private var glowCustomColor: Binding<Color> { hexBinding($glowCustomHex) }
    private var peakCustomColor: Binding<Color> { hexBinding($peakCustomHex) }
    private var bgColor: Binding<Color> { hexBinding($bgColorHex) }

    let presets = ["Cyan/Purple", "Fire", "Neon Green", "Ocean",
                   "Sunset", "Monochrome", "Rose", "Gold", "Rainbow"]

    var body: some View {
        Form {
            // ── Bar Colour Mode ───────────────────────────────────
            Section {
                Picker("Mode", selection: $colorMode) {
                    Text("Preset").tag("preset")
                    Text("Solid").tag("solid")
                    Text("Gradient").tag("gradient")
                }
                .pickerStyle(.segmented)

                switch colorMode {
                case "solid":
                    ColorPicker("Bar Colour", selection: solidColor, supportsOpacity: false)

                case "gradient":
                    ColorPicker("Colour 1", selection: grad1Color, supportsOpacity: false)
                    ColorPicker("Colour 2", selection: grad2Color, supportsOpacity: false)
                    Toggle("Use Three Colours", isOn: $gradientUse3)
                    if gradientUse3 {
                        ColorPicker("Colour 3", selection: grad3Color, supportsOpacity: false)
                    }
                    // Gradient preview
                    gradientPreview
                        .frame(height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                default: // preset
                    Picker("Theme", selection: $presetTheme) {
                        ForEach(presets, id: \.self) { Text($0) }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(barOpacity * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $barOpacity, in: 0.2...1.0)
                }
            } header: { Text("Bar Colour") }

            // ── Glow ─────────────────────────────────────────────
            Section {
                Toggle("Enable Glow", isOn: $glowMode)
                if glowMode {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text(String(format: "%.1f", glowRadius))
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: $glowRadius, in: 1...16)
                    }
                    Picker("Glow Colour", selection: $glowColorMode) {
                        Text("Match Bars").tag("match")
                        Text("White").tag("white")
                        Text("Custom").tag("custom")
                    }
                    if glowColorMode == "custom" {
                        ColorPicker("Custom Glow Colour",
                                    selection: glowCustomColor,
                                    supportsOpacity: false)
                    }
                }
            } header: { Text("Glow") }

            // ── Peak Hold ─────────────────────────────────────────
            Section {
                Toggle("Show Peak Lines", isOn: $peakHold)
                if peakHold {
                    Picker("Peak Colour", selection: $peakColorMode) {
                        Text("White").tag("white")
                        Text("Match Bars").tag("match")
                        Text("Custom").tag("custom")
                    }
                    if peakColorMode == "custom" {
                        ColorPicker("Custom Peak Colour",
                                    selection: peakCustomColor,
                                    supportsOpacity: false)
                    }
                }
            } header: { Text("Peak Hold") }

            // ── Background ────────────────────────────────────────
            Section {
                Toggle("Custom Background", isOn: $showBackground)
                if showBackground {
                    ColorPicker("Background Colour", selection: bgColor, supportsOpacity: false)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Opacity")
                            Spacer()
                            Text("\(Int(bgOpacity * 100))%")
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: $bgOpacity, in: 0.1...1.0)
                    }
                }
            } header: { Text("Background") }
        }
        .formStyle(.grouped)
    }

    var gradientPreview: some View {
        let colors: [Color] = gradientUse3
            ? [colorFromHex(grad1Hex), colorFromHex(grad2Hex), colorFromHex(grad3Hex)]
            : [colorFromHex(grad1Hex), colorFromHex(grad2Hex)]
        return LinearGradient(colors: colors,
                              startPoint: .leading,
                              endPoint: .trailing)
    }

    private func hexBinding(_ storage: Binding<String>) -> Binding<Color> {
        Binding(
            get: { colorFromHex(storage.wrappedValue) },
            set: { storage.wrappedValue = hexFromColor($0) }
        )
    }
}

// MARK: - Bars Section

struct BarsSection: View {
    @AppStorage("barCount")      private var barCount      = 30.0
    @AppStorage("barSpacing")    private var barSpacing    = 2.0
    @AppStorage("cornerRadius")  private var cornerRadius  = 1.5
    @AppStorage("minBarHeight")  private var minBarHeight  = 2.0
    @AppStorage("capsuleMode")   private var capsuleMode   = false
    @AppStorage("mirrorMode")    private var mirrorMode    = false
    @AppStorage("beatPulseEnabled") private var beatPulse  = true
    @AppStorage("barWidthScale") private var barWidthScale = 1.0

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Bar Count")
                        Spacer()
                        Text("\(Int(barCount))")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $barCount, in: 5...100, step: 1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Spacing")
                        Spacer()
                        Text(String(format: "%.1f", barSpacing))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $barSpacing, in: 0...8, step: 0.5)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Min Height")
                        Spacer()
                        Text(String(format: "%.1f", minBarHeight))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $minBarHeight, in: 0...10, step: 0.5)
                }
            } header: { Text("Size") }

            Section {
                Toggle("Capsule Shape", isOn: $capsuleMode)
                if !capsuleMode {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Corner Radius")
                            Spacer()
                            Text(String(format: "%.1f", cornerRadius))
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: $cornerRadius, in: 0...10, step: 0.5)
                    }
                }
            } header: { Text("Shape") }

            Section {
                Toggle("Mirror Mode", isOn: $mirrorMode)
                Toggle("Beat Pulse", isOn: $beatPulse)
            } header: { Text("Animation") }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Audio Section

struct AudioSection: View {
    @AppStorage("sensitivity")  private var sensitivity  = 5.0
    @AppStorage("smoothing")    private var smoothing    = 0.6
    @AppStorage("bassBoost")    private var bassBoost    = 1.5
    @AppStorage("freqOffset")   private var freqOffset   = 2.0
    @AppStorage("peakDecay")    private var peakDecay    = 0.97

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        Text(String(format: "%.1f", sensitivity))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $sensitivity, in: 0.5...20, step: 0.5)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Smoothing")
                        Spacer()
                        Text(String(format: "%.2f", smoothing))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $smoothing, in: 0.05...0.98, step: 0.01)
                }
            } header: { Text("Response") }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Bass Boost")
                        Spacer()
                        Text(String(format: "%.1f×", bassBoost))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $bassBoost, in: 0.5...5.0, step: 0.1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Frequency Offset")
                        Spacer()
                        Text("\(Int(freqOffset))")
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $freqOffset, in: 0...15, step: 1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Peak Decay")
                        Spacer()
                        Text(String(format: "%.3f", peakDecay))
                            .foregroundStyle(.secondary).monospacedDigit()
                    }
                    Slider(value: $peakDecay, in: 0.90...0.999, step: 0.001)
                }
            } header: { Text("Frequency") }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Advanced Section

struct AdvancedSection: View {
    @AppStorage("barColorMode")       private var colorMode      = "preset"
    @AppStorage("presetTheme")        private var presetTheme    = "Cyan/Purple"
    @AppStorage("solidColorHex")      private var solidColorHex  = "#00FFFF"
    @AppStorage("gradientColor1Hex")  private var grad1Hex       = "#00FFFF"
    @AppStorage("gradientColor2Hex")  private var grad2Hex       = "#FF00FF"
    @AppStorage("gradientColor3Hex")  private var grad3Hex       = "#FF6600"
    @AppStorage("gradientUse3Colors") private var gradientUse3   = false
    @AppStorage("glowMode")           private var glowMode       = true
    @AppStorage("glowRadius")         private var glowRadius     = 4.0
    @AppStorage("glowColorMode")      private var glowColorMode  = "match"
    @AppStorage("glowCustomColorHex") private var glowCustomHex  = "#00FFFF"
    @AppStorage("capsuleMode")        private var capsuleMode    = false
    @AppStorage("peakHold")           private var peakHold       = true
    @AppStorage("peakDecay")          private var peakDecay      = 0.97
    @AppStorage("peakColorMode")      private var peakColorMode  = "white"
    @AppStorage("peakCustomColorHex") private var peakCustomHex  = "#FFFFFF"
    @AppStorage("mirrorMode")         private var mirrorMode     = false
    @AppStorage("barSpacing")         private var barSpacing     = 2.0
    @AppStorage("cornerRadius")       private var cornerRadius   = 1.5
    @AppStorage("minBarHeight")       private var minBarHeight   = 2.0
    @AppStorage("barOpacity")         private var barOpacity     = 1.0
    @AppStorage("bassBoost")          private var bassBoost      = 1.5
    @AppStorage("freqOffset")         private var freqOffset     = 2.0
    @AppStorage("beatPulseEnabled")   private var beatPulse      = true
    @AppStorage("sensitivity")        private var sensitivity    = 5.0
    @AppStorage("smoothing")          private var smoothing      = 0.6
    @AppStorage("barCount")           private var barCount       = 30.0
    @AppStorage("showBackground")     private var showBackground = false
    @AppStorage("bgColorHex")         private var bgColorHex     = "#000000"
    @AppStorage("bgOpacity")          private var bgOpacity      = 0.6

    var body: some View {
        Form {
            Section {
                Button("Reset All Settings") {
                    resetAll()
                }
                .foregroundStyle(.red)
            } header: { Text("Reset") }

            Section {
                Button("Quit SoundBar") {
                    NSApp.terminate(nil)
                }
                .foregroundStyle(.red)
            } header: { Text("App") }
        }
        .formStyle(.grouped)
    }

    func resetAll() {
        colorMode = "preset";      presetTheme = "Cyan/Purple"
        solidColorHex = "#00FFFF"; grad1Hex = "#00FFFF"
        grad2Hex = "#FF00FF";      grad3Hex = "#FF6600"
        gradientUse3 = false;      glowMode = true
        glowRadius = 4.0;          glowColorMode = "match"
        glowCustomHex = "#00FFFF"; capsuleMode = false
        peakHold = true;           peakDecay = 0.97
        peakColorMode = "white";   peakCustomHex = "#FFFFFF"
        mirrorMode = false;        barSpacing = 2.0
        cornerRadius = 1.5;        minBarHeight = 2.0
        barOpacity = 1.0;          bassBoost = 1.5
        freqOffset = 2.0;          beatPulse = true
        sensitivity = 5.0;         smoothing = 0.6
        barCount = 30.0;           showBackground = false
        bgColorHex = "#000000";    bgOpacity = 0.6
    }
}

// MARK: - Colour Helpers (shared across the file)

func colorFromHex(_ hex: String) -> Color {
    var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
    if h.count == 3 {
        h = h.map { "\($0)\($0)" }.joined()
    }
    guard h.count == 6, let val = UInt64(h, radix: 16) else { return .cyan }
    return Color(
        red:   Double((val >> 16) & 0xFF) / 255,
        green: Double((val >> 8)  & 0xFF) / 255,
        blue:  Double( val        & 0xFF) / 255
    )
}

func hexFromColor(_ color: Color) -> String {
    let resolved = color.resolve(in: EnvironmentValues())
    let r = Int(resolved.red   * 255)
    let g = Int(resolved.green * 255)
    let b = Int(resolved.blue  * 255)
    return String(format: "#%02X%02X%02X", r, g, b)
}
