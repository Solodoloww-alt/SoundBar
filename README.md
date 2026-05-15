# SoundBar

A macOS audio visualizer for the MacBook Pro Touch Bar. Captures system audio and displays real-time frequency bars on the Touch Bar.

## Features

- Real-time FFT audio visualization on the Touch Bar
- Always-visible mode (system-wide Touch Bar overlay)
- Multiple color presets (Cyan/Purple, Fire, Neon Green, Ocean, Sunset, etc.)
- Custom gradients and solid colors
- Glow effects, mirror mode, capsule shapes
- Peak hold with configurable decay
- Beat pulse animation
- Adjustable bar count, spacing, sensitivity, smoothing, bass boost
- Launch at Login support
- Menu bar quick access

## Screenshots

```
None, check it out for yourself <3
```

## Requirements

- macOS 15.0+
- MacBook Pro with Touch Bar
- Screen Recording permission (System Settings > Privacy & Security > Screen Recording)

## Installation

Download the latest release from [Releases](https://github.com/Solodoloww-alt/SoundBar/releases).

Or build from source:

```bash
git clone https://github.com/Solodoloww-alt/SoundBar.git
cd SoundBar
xcodebuild -project SoundBar.xcodeproj -scheme SoundBar -configuration Release build
cp -R build/Release/SoundBar.app /Applications/
```

## Usage

1. Launch SoundBar
2. Click **Start Visualizing** in the settings window
3. Grant Screen Recording permission when prompted
4. The Touch Bar now shows the audio visualizer
5. Open Settings from the menu bar icon to customize

### Always Visible

Enable **Always Visible on Touch Bar** in Settings → Advanced to keep the visualizer on the Touch Bar even when switching to other apps.

### Control Strip Toggle

Press **⌥⇧C** or use the menu bar item to toggle between Control Strip modes.

## Settings

| Section  | Options |
|----------|---------|
| Capture  | Start/Stop, preview |
| Colours  | Presets, solid, gradient, glow, peak, background |
| Bars     | Count, spacing, shape, mirror mode, beat pulse |
| Audio    | Sensitivity, smoothing, bass boost, frequency offset, peak decay |
| Advanced | Launch at Login, Always Visible |

## Technical Details

- Audio capture via `ScreenCaptureKit` (`SCStream` with `capturesAudio`)
- FFT processing via `Accelerate` (vDSP), 512-bin window with pre-allocated buffers
- Always-visible Touch Bar via private API `presentSystemModalTouchBar:placement:systemTrayItemIdentifier:`
- SwiftUI rendering with `Canvas` for efficient bar drawing
- No sandbox, no third-party dependencies

## License

MIT
