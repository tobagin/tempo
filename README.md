# Tempo
**A Modern Metronome for Musicians**

Tempo is a simple, reliable, and aesthetically pleasing metronome application built with GTK4 and Libadwaita. It provides precise timing, customizable settings, and a distraction-free user experience for musicians of all levels.

## Screenshots

<table>
  <tr>
    <td><img src="screenshots/main-window.png" alt="Main Window" width="400"/><br/><em>Main window with tempo controls</em></td>
    <td><img src="screenshots/preference-general.png" alt="General Preferences" width="400"/><br/><em>General preferences</em></td>
  </tr>
  <tr>
    <td><img src="screenshots/preferences-visual.png" alt="Visual Preferences" width="400"/><br/><em>Visual preferences with theme selection</em></td>
    <td><img src="screenshots/about-dialog.png" alt="About Dialog" width="400"/><br/><em>About dialog</em></td>
  </tr>
</table>

## Features

### Core Functionality
- **Precise Timing**: Sub-millisecond accuracy with drift-free timing engine
- **Customizable Tempo**: Set BPM from 40 to 240 using slider, stepper, or tap tempo
- **Time Signature Control**: Support for common time signatures (2/4, 3/4, 4/4, 6/8, etc.)
- **Visual Beat Indicator**: Animated beat indicator with Cairo-based pulse effects
- **Accented Downbeats**: Distinct sounds for regular beats and downbeats
- **Low-Latency Audio**: Optimized GStreamer pipeline for minimal audio delay

### User Interface
- **Modern UI**: Blueprint-based GTK4/Libadwaita design following GNOME HIG
- **Responsive Design**: Adaptive interface that works on different screen sizes
- **Beat Visualization**: Large, animated beat indicator with dramatic pulse glow effects
- **Synchronized Feedback**: Perfect sync between audio and visual beat indicators

### User Experience
- **Comprehensive Keyboard Shortcuts**: Full control via keyboard
  - Space/Enter: Start/Stop playback
  - Arrow keys: Tempo adjustment (±1 or ±10 BPM with Shift)
  - Number keys (2-9): Quick time signature changes
  - F1: Help dialog with all shortcuts
- **Preferences Dialog**: Comprehensive settings with three categories:
  - **Audio**: Volume control, sound selection
  - **Behavior**: Auto-start, keyboard shortcuts toggle
  - **Visual**: Beat indicator style, color themes
- **Settings Persistence**: All preferences saved automatically via GSettings

## Installation

### Flatpak (Recommended)

The easiest way to install Tempo is via Flatpak:

```bash
flatpak install flathub io.github.tobagin.tempo
```

### Building from Source

#### Prerequisites

- Vala compiler (valac 0.56 or newer)
- GTK4 development libraries (4.10+)
- Libadwaita development libraries (1.5+)
- GStreamer development libraries (1.18+)
- Meson build system (0.59+)
- Blueprint compiler (0.18+)

On Ubuntu/Debian:
```bash
sudo apt install valac libgtk-4-dev libadwaita-1-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libgstreamer-plugins-good1.0-dev libgstreamer-audio1.0-dev \
    meson blueprint-compiler
```

On Fedora:
```bash
sudo dnf install vala gtk4-devel libadwaita-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel \
    gstreamer1-plugins-good meson blueprint-compiler
```

#### Build Instructions

1. Clone the repository:
```bash
git clone https://github.com/tobagin/tempo.git
cd tempo
```

2. Build with Meson:
```bash
meson setup builddir
meson compile -C builddir
```

3. Install (optional):
```bash
meson install -C builddir
```

#### Development Build

For development, you can build and run locally:

```bash
./build.sh --dev --install
flatpak run io.github.tobagin.tempo
```

## Usage

### Basic Controls

- **Start/Stop**: Click the play button or press `Spacebar`
- **Adjust Tempo**: Use the slider, spin button, or arrow keys (`↑`/`↓`)
- **Tap Tempo**: Click "Tap Tempo" or press `T` repeatedly to set tempo
- **Time Signature**: Set beats per measure and note value

### Keyboard Shortcuts

**Playback Control:**
- `Spacebar` or `Enter`: Start/stop metronome
- `T`: Tap tempo (tap repeatedly to set tempo)

**Tempo Adjustment:**
- `↑`: Increase tempo by 1 BPM
- `↓`: Decrease tempo by 1 BPM  
- `Shift+↑`: Increase tempo by 10 BPM
- `Shift+↓`: Decrease tempo by 10 BPM

**Time Signature:**
- `2`-`9`: Set beats per measure (2/4, 3/4, 4/4, etc.)

**Application:**
- `F1`: Show help dialog with all shortcuts
- `Ctrl+,`: Open preferences
- `Ctrl+Q`: Quit application

### Visual Feedback

The beat indicator shows:
- **Blue circle**: Regular beats
- **Red circle**: Downbeats (first beat of measure)
- **Beat numbers**: Current beat position in measure

## Technical Details

### Architecture

Tempo is built with modern technologies:

- **Language**: Vala - compiles to efficient C code with GObject integration
- **Frontend**: GTK4 with Libadwaita for native Linux integration
- **UI Definition**: Blueprint markup language for clean, maintainable UI
- **Audio Engine**: GStreamer with optimized low-latency pipeline
- **Timing Engine**: High-precision GLib timing with drift compensation
- **Build System**: Meson for cross-platform building
- **Packaging**: Flatpak for universal Linux distribution

### Precision Timing

The metronome engine uses several techniques to ensure accuracy:

- **Absolute time references** prevent cumulative drift using GLib.get_monotonic_time()
- **High-resolution timing** with microsecond precision
- **Compensation for system delays** and scheduling interruptions  
- **Separate timing thread** using GLib.Thread to avoid UI blocking
- **GStreamer audio buffer management** for consistent low-latency output

## Development

### Project Structure

```
tempo/
├── data/           # UI Blueprint files, GSettings schemas, sounds
│   ├── ui/         # Blueprint UI templates (.blp files)
│   ├── sounds/     # Audio files for beat sounds
│   └── style.css   # Custom GTK/CSS styling
├── src/            # Vala source code (.vala files)
│   ├── main.vala           # Application entry point
│   ├── main_window.vala    # Main window with beat indicator
│   ├── metronome_engine.vala   # Core timing and audio engine
│   └── preferences_dialog.vala # Settings UI
├── tests/          # Unit tests (currently minimal due to GStreamer deps)
├── packaging/      # Flatpak manifests for local/production builds
├── po/             # Translation files (Italian, Turkish, more welcome!)
├── meson.build     # Build configuration
└── build.sh        # Convenience build script for development
```

### Running Tests

```bash
# Build and run tests (note: limited due to GStreamer dependencies)
meson test -C builddir

# For manual testing, build and run the application:
./build.sh --dev --install
flatpak run io.github.tobagin.tempo
```

### Code Style

The project follows Vala coding conventions:
- **CamelCase** for class names and public methods
- **snake_case** for private methods and variables
- **4-space indentation** for consistency
- **Explicit type annotations** where helpful for clarity

```bash
# Format Vala code (if using vala-lint or similar)
uncrustify -c vala.cfg --replace src/*.vala

# Check build without installing
meson compile -C builddir
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## Troubleshooting

### Audio Issues

If you experience audio problems:

1. **Check audio permissions**: Ensure Flatpak has audio access
2. **Verify GStreamer**: Make sure GStreamer plugins are installed
3. **Audio system**: Try switching between PulseAudio and PipeWire
4. **Latency**: Check audio settings in system preferences

### Performance Issues

For timing accuracy problems:

1. **System load**: Close unnecessary applications
2. **Power management**: Disable CPU scaling if possible
3. **Audio buffer**: Adjust buffer sizes in audio settings
4. **Real-time priority**: Some systems may require RT permissions

### Common Solutions

```bash
# Reinstall Flatpak version
flatpak uninstall io.github.tobagin.tempo
flatpak install flathub io.github.tobagin.tempo

# Reset settings
rm -rf ~/.config/tempo

# Check GStreamer plugins
gst-inspect-1.0 | grep audio
```

## License

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Support

- **Bug Reports**: [GitHub Issues](https://github.com/tobagin/tempo/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/tobagin/tempo/discussions)
- **Documentation**: [Project Wiki](https://github.com/tobagin/tempo/wiki)
