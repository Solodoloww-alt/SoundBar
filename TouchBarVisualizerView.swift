import SwiftUI

struct TouchBarVisualizerView: View {

    @ObservedObject var audioMonitor: SystemAudioMonitor

    @AppStorage("barCount")      private var barCount      = 30.0
    @AppStorage("glowMode")      private var glowMode      = true
    @AppStorage("glowRadius")    private var glowRadius    = 4.0
    @AppStorage("capsuleMode")   private var capsuleMode   = false
    @AppStorage("peakHold")      private var peakHold      = true
    @AppStorage("mirrorMode")    private var mirrorMode    = false
    @AppStorage("barColorTheme") private var colorTheme    = "Cyan/Purple"
    @AppStorage("barSpacing")    private var barSpacing    = 2.0
    @AppStorage("cornerRadius")  private var cornerRadius  = 1.5
    @AppStorage("minBarHeight")  private var minBarHeight  = 2.0
    @AppStorage("barOpacity")    private var barOpacity    = 1.0

    private var visibleBars: Int {
        min(max(1, Int(barCount)), audioMonitor.amplitudes.count)
    }

    private func barColor(index: Int, total: Int) -> Color {
        let t = Double(index) / Double(max(total - 1, 1))
        switch colorTheme {
        case "Fire":
            return Color(hue: 0.08 - t * 0.08, saturation: 1, brightness: 1)
        case "Neon Green":
            return Color(hue: 0.35 - t * 0.05, saturation: 1, brightness: 1)
        case "Ocean":
            return Color(hue: 0.55 + t * 0.1, saturation: 0.9, brightness: 1)
        case "Sunset":
            return Color(hue: 0.07 + t * 0.25, saturation: 1, brightness: 1)
        case "Monochrome":
            return Color(white: 1 - t * 0.4)
        case "Rose":
            return Color(hue: 0.95 - t * 0.05, saturation: 0.8, brightness: 1)
        case "Gold":
            return Color(hue: 0.13 - t * 0.05, saturation: 1, brightness: 1)
        default: // Cyan/Purple
            return Color(hue: 0.5 + t * 0.25, saturation: 1, brightness: 1)
        }
    }

    var body: some View {
        Canvas { context, size in

            let spacing  = CGFloat(barSpacing)
            let count    = visibleBars
            let totalGap = CGFloat(count - 1) * spacing
            let barWidth = (size.width - totalGap) / CGFloat(count)
            let cr       = CGFloat(cornerRadius)
            let minH     = CGFloat(minBarHeight)

            for i in 0..<count {
                let amp  = CGFloat(audioMonitor.amplitudes[i])
                let peak = CGFloat(audioMonitor.peakLevels[i])

                var height = min(max(minH, amp * size.height), size.height)

                let x = CGFloat(i) * (barWidth + spacing)

                let color = barColor(index: i, total: count).opacity(barOpacity)

                if mirrorMode {
                    // Draw from centre outward (symmetric)
                    height = height / 2
                    let centerY = size.height / 2

                    let topRect = CGRect(x: x, y: centerY - height,
                                        width: barWidth, height: height)
                    let botRect = CGRect(x: x, y: centerY,
                                        width: barWidth, height: height)

                    for rect in [topRect, botRect] {
                        let path: Path = capsuleMode
                            ? Path(roundedRect: rect, cornerRadius: barWidth / 2)
                            : Path(roundedRect: rect, cornerRadius: cr)
                        context.fill(path, with: .color(color))
                        if glowMode {
                            context.drawLayer { l in
                                l.addFilter(.blur(radius: CGFloat(glowRadius)))
                                l.fill(path, with: .color(color.opacity(0.6)))
                            }
                        }
                    }

                } else {
                    // Normal bottom-up
                    let rect = CGRect(x: x, y: size.height - height,
                                      width: barWidth, height: height)
                    let path: Path = capsuleMode
                        ? Path(roundedRect: rect, cornerRadius: barWidth / 2)
                        : Path(roundedRect: rect, cornerRadius: cr)

                    context.fill(path, with: .color(color))

                    if glowMode {
                        context.drawLayer { l in
                            l.addFilter(.blur(radius: CGFloat(glowRadius)))
                            l.fill(path, with: .color(color.opacity(0.6)))
                        }
                    }

                    // Peak hold line
                    if peakHold {
                        let peakH    = min(max(minH, peak * size.height), size.height)
                        let peakRect = CGRect(x: x, y: size.height - peakH,
                                              width: barWidth, height: 1.5)
                        context.fill(Path { p in p.addRect(peakRect) },
                                     with: .color(.white.opacity(0.8)))
                    }
                }
            }
        }
        .frame(height: 30)
        .scaleEffect(audioMonitor.beatPulse)
        .animation(.spring(response: 0.15, dampingFraction: 0.5),
                   value: audioMonitor.beatPulse)
    }
}
