import SwiftUI

struct TouchBarVisualizerView: View {

    @ObservedObject var audioMonitor: SystemAudioMonitor

    @AppStorage("barCount")           private var barCount        = 30.0
    @AppStorage("barSpacing")         private var barSpacing      = 2.0
    @AppStorage("cornerRadius")       private var cornerRadius    = 1.5
    @AppStorage("minBarHeight")       private var minBarHeight    = 2.0
    @AppStorage("barOpacity")         private var barOpacity      = 1.0
    @AppStorage("capsuleMode")        private var capsuleMode     = false
    @AppStorage("mirrorMode")         private var mirrorMode      = false
    @AppStorage("glowMode")           private var glowMode        = true
    @AppStorage("glowRadius")         private var glowRadius      = 4.0
    @AppStorage("glowColorMode")      private var glowColorMode   = "match"
    @AppStorage("glowCustomColorHex") private var glowCustomHex   = "#00FFFF"
    @AppStorage("peakHold")           private var peakHold        = true
    @AppStorage("peakColorMode")      private var peakColorMode   = "white"
    @AppStorage("peakCustomColorHex") private var peakCustomHex   = "#FFFFFF"
    @AppStorage("barColorMode")       private var colorMode       = "preset"
    @AppStorage("presetTheme")        private var presetTheme     = "Cyan/Purple"
    @AppStorage("solidColorHex")      private var solidColorHex   = "#00FFFF"
    @AppStorage("gradientColor1Hex")  private var grad1Hex        = "#00FFFF"
    @AppStorage("gradientColor2Hex")  private var grad2Hex        = "#FF00FF"
    @AppStorage("gradientColor3Hex")  private var grad3Hex        = "#FF6600"
    @AppStorage("gradientUse3Colors") private var gradientUse3    = false
    @AppStorage("showBackground")     private var showBackground  = false
    @AppStorage("bgColorHex")         private var bgColorHex      = "#000000"
    @AppStorage("bgOpacity")          private var bgOpacity       = 0.6
    @AppStorage("beatPulseEnabled")   private var beatPulse       = true
    @AppStorage("barWidthScale")      private var barWidthScale   = 1.0

    private var visibleBars: Int {
        min(max(1, Int(barCount)), audioMonitor.amplitudes.count)
    }

    // Resolve bar colour for a given bar index
    private func barColor(index: Int, total: Int) -> Color {
        let t = Double(index) / Double(max(total - 1, 1))
        switch colorMode {
        case "solid":
            return colorFromHex(solidColorHex).opacity(barOpacity)
        case "gradient":
            let colors: [Color] = gradientUse3
                ? [colorFromHex(grad1Hex), colorFromHex(grad2Hex), colorFromHex(grad3Hex)]
                : [colorFromHex(grad1Hex), colorFromHex(grad2Hex)]
            return interpolateColors(colors, at: t).opacity(barOpacity)
        default: // preset
            return presetColor(t: t).opacity(barOpacity)
        }
    }

    private func presetColor(t: Double) -> Color {
        switch presetTheme {
        case "Fire":        return Color(hue: 0.08 - t * 0.08, saturation: 1, brightness: 1)
        case "Neon Green":  return Color(hue: 0.35 - t * 0.05, saturation: 1, brightness: 1)
        case "Cyan/Purple": return Color(hue: 0.5 + t * 0.35, saturation: 1, brightness: 1)
        case "Ocean":       return Color(hue: 0.55 + t * 0.1,  saturation: 0.9, brightness: 1)
        case "Sunset":      return Color(hue: 0.07 + t * 0.25, saturation: 1, brightness: 1)
        case "Monochrome":  return Color(white: 1 - t * 0.5)
        case "Rose":        return Color(hue: 0.95 - t * 0.05, saturation: 0.8, brightness: 1)
        case "Gold":        return Color(hue: 0.13 - t * 0.05, saturation: 1, brightness: 1)
        case "Rainbow":     return Color(hue: t, saturation: 1, brightness: 1)
        default:            return Color(hue: 0.5 + t * 0.25,  saturation: 1, brightness: 1)
        }
    }

    private func interpolateColors(_ colors: [Color], at t: Double) -> Color {
        guard colors.count >= 2 else { return colors.first ?? .cyan }
        let scaled   = t * Double(colors.count - 1)
        let index    = min(Int(scaled), colors.count - 2)
        let local    = scaled - Double(index)
        let c1 = colors[index].resolve(in: EnvironmentValues())
        let c2 = colors[index + 1].resolve(in: EnvironmentValues())
        return Color(
            red:   Double(c1.red)   + (Double(c2.red)   - Double(c1.red))   * local,
            green: Double(c1.green) + (Double(c2.green) - Double(c1.green)) * local,
            blue:  Double(c1.blue)  + (Double(c2.blue)  - Double(c1.blue))  * local
        )
    }

    private func glowColor(barColor: Color) -> Color {
        switch glowColorMode {
        case "white":  return .white
        case "custom": return colorFromHex(glowCustomHex)
        default:       return barColor
        }
    }

    private func peakColor(barColor: Color) -> Color {
        switch peakColorMode {
        case "match":  return barColor
        case "custom": return colorFromHex(peakCustomHex)
        default:       return .white
        }
    }

    var body: some View {
        Canvas { context, size in

            // Optional background
            if showBackground {
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(colorFromHex(bgColorHex).opacity(bgOpacity))
                )
            }

            let spacing  = CGFloat(barSpacing)
            let count    = visibleBars
            let totalGap = CGFloat(count - 1) * spacing
            let barWidth = (size.width - totalGap) / CGFloat(count) * CGFloat(barWidthScale)
            let cr       = CGFloat(cornerRadius)
            let minH     = CGFloat(minBarHeight)

            for i in 0..<count {
                let amp  = CGFloat(audioMonitor.amplitudes[i])
                let peak = CGFloat(audioMonitor.peakLevels[i])
                let color = barColor(index: i, total: count)
                let x = CGFloat(i) * (barWidth + spacing)

                if mirrorMode {
                    let height = min(max(minH / 2, amp * size.height / 2), size.height / 2)
                    let centerY = size.height / 2
                    for rect in [
                        CGRect(x: x, y: centerY - height, width: barWidth, height: height),
                        CGRect(x: x, y: centerY,          width: barWidth, height: height)
                    ] {
                        let path: Path = capsuleMode
                            ? Path(roundedRect: rect, cornerRadius: barWidth / 2)
                            : Path(roundedRect: rect, cornerRadius: cr)
                        context.fill(path, with: .color(color))
                        if glowMode {
                            context.drawLayer { l in
                                l.addFilter(.blur(radius: CGFloat(glowRadius)))
                                l.fill(path, with: .color(glowColor(barColor: color).opacity(0.7)))
                            }
                        }
                    }

                    if peakHold {
                        let peakH    = min(max(minH, peak * size.height / 2), size.height / 2)
                        let peakRect = CGRect(x: x, y: centerY - peakH,
                                              width: barWidth, height: 1.5)
                        context.fill(Path { p in p.addRect(peakRect) },
                                     with: .color(peakColor(barColor: color).opacity(0.9)))
                        let peakRect2 = CGRect(x: x, y: centerY,
                                               width: barWidth, height: 1.5)
                        context.fill(Path { p in p.addRect(peakRect2) },
                                     with: .color(peakColor(barColor: color).opacity(0.9)))
                    }
                } else {
                    let height = min(max(minH, amp * size.height), size.height)
                    let rect   = CGRect(x: x, y: size.height - height,
                                        width: barWidth, height: height)
                    let path: Path = capsuleMode
                        ? Path(roundedRect: rect, cornerRadius: barWidth / 2)
                        : Path(roundedRect: rect, cornerRadius: cr)

                    context.fill(path, with: .color(color))

                    if glowMode {
                        context.drawLayer { l in
                            l.addFilter(.blur(radius: CGFloat(glowRadius)))
                            l.fill(path, with: .color(glowColor(barColor: color).opacity(0.7)))
                        }
                    }

                    if peakHold {
                        let peakH    = min(max(minH, peak * size.height), size.height)
                        let peakRect = CGRect(x: x, y: size.height - peakH,
                                              width: barWidth, height: 1.5)
                        context.fill(Path { p in p.addRect(peakRect) },
                                     with: .color(peakColor(barColor: color).opacity(0.9)))
                    }
                }
            }
        }
        .frame(height: 30)
        .scaleEffect(beatPulse ? audioMonitor.beatPulse : 1.0, anchor: mirrorMode ? .center : .bottom)
        .animation(.spring(response: 0.15, dampingFraction: 0.5),
                   value: audioMonitor.beatPulse)
    }
}
