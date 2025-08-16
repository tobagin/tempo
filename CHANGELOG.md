# Changelog

All notable changes to Tempo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4] - 2025-01-14

### Changed
- Streamlined AppData description for better Flathub presentation
- Enhanced readability following Flathub quality guidelines
- Removed redundant technical details for improved clarity
- Made description more user-focused and concise

## [1.0.3] - 2025-01-14

### Fixed
- AppStream validation warning about redefined relation items
- Removed duplicate keyboard control from recommends section

## [1.0.2] - 2025-01-14

### Fixed
- AppStream metadata validation errors for Flathub submission
- Developer information and contact details in metadata
- Removed inapplicable metadata fields (notifications kudo, donation URL)
- Added proper branding colors for better app store presentation

### Changed
- Simplified system requirements in AppData
- Updated help URL to point to GitHub Discussions

## [1.0.1] - 2025-01-14

### Added
- Application screenshots showing main window, preferences, and about dialog
- Enhanced README.md with visual preview gallery
- Comprehensive AppStream metadata with screenshot URLs

### Changed
- Moved screenshots to dedicated `/screenshots` directory
- Updated metadata descriptions for better software center presentation
- Enhanced visual documentation for users and distributors

## [1.0.0] - 2025-01-14

### Initial Release

This is the first stable release of Tempo, a modern metronome application for musicians built with GTK4 and Libadwaita.

### Features

#### Core Metronome Functionality
- **High-precision timing engine** with sub-millisecond accuracy using drift compensation
- **Tempo control** from 40 to 240 BPM with multiple input methods:
  - Adjustable slider for quick changes
  - Spin button for precise values
  - Tap tempo functionality with intelligent BPM calculation
- **Time signature support** for various musical meters:
  - Configurable beats per measure (1-16)
  - Support for common note values (2, 4, 8, 16)
  - Visual indication of downbeats vs regular beats

#### Audio System
- **Low-latency audio playback** optimized for rapid tempos (>126 BPM)
- **GStreamer-based audio engine** with minimal buffering for real-time performance
- **Distinct audio cues** for downbeats and regular beats
- **Robust audio handling** with fallback mechanisms for different audio systems
- **Flatpak-optimized** audio pipeline supporting PulseAudio and PipeWire

#### User Interface
- **Modern GTK4/Libadwaita design** following GNOME design principles
- **Adaptive UI** that works well on different screen sizes
- **Visual beat indicator** with:
  - Color-coded beat visualization (red for downbeats, blue for regular beats)
  - Beat counter showing position within measure
  - Smooth visual feedback synchronized with audio
- **Clean HeaderBar** with proper WindowTitle structure
- **Responsive controls** with immediate visual feedback

#### User Experience
- **Keyboard shortcuts** for efficient control:
  - `Spacebar`: Start/stop metronome
  - `T`: Tap tempo
  - `↑/↓`: Adjust tempo by 1 BPM
  - `Ctrl+Q`: Quit application
- **Settings persistence** automatically saves user preferences
- **Intuitive controls** with clear visual hierarchy
- **Professional-grade timing** suitable for music practice and performance

#### Technical Implementation
- **Multi-threaded architecture** prevents GUI blocking during precise timing
- **Absolute time references** eliminate cumulative timing drift
- **Resource-efficient** design with minimal CPU and memory usage
- **Blueprint UI markup** for maintainable and clean interface definitions
- **Comprehensive error handling** with graceful degradation

#### Packaging & Distribution
- **Flatpak packaging** for universal Linux distribution
- **Complete app metadata** with AppStream integration
- **Desktop integration** with proper icon theming and categorization
- **Translation infrastructure** ready for internationalization

### Technical Details

#### Architecture
- Built with **Python 3.8+** using modern async patterns
- **GTK4** and **Libadwaita** for native Linux integration
- **GStreamer 1.18+** for professional audio handling
- **Meson build system** for cross-platform compatibility
- **Blueprint compiler** for clean UI definitions

#### Audio Engine
- **Preloaded audio samples** for instant playback at high tempos
- **Seek-and-play strategy** eliminates player recreation overhead
- **10ms audio buffering** with 1ms latency targeting
- **Automatic audio sink detection** (PulseAudio/PipeWire/ALSA)
- **Proper resource cleanup** prevents memory leaks

#### Timing System
- **High-resolution performance counter** (time.perf_counter)
- **Compensation algorithms** for system sleep and interruptions  
- **Thread-safe GUI updates** via GLib.idle_add
- **Drift-free timing** maintains accuracy over long sessions

### Known Issues
- PreferencesDialog uses deprecated Adw.PreferencesWindow (cosmetic warning only)
- MESA-INTEL graphics warnings on some systems (driver-related, does not affect functionality)

### System Requirements
- **Operating System**: Linux with GTK4 support
- **Memory**: 256MB RAM minimum, 400MB recommended
- **Display**: 360px minimum width, 400px recommended
- **Audio**: PulseAudio, PipeWire, or ALSA-compatible audio system
- **Dependencies**: GTK4 4.10+, Libadwaita 1.5+, GStreamer 1.18+

### Installation
Available through Flatpak for universal Linux compatibility:
```bash
flatpak install flathub io.github.tobagin.tempo
```

### Contributing
This release establishes the foundation for future development. Contributions are welcome for:
- Additional time signatures and rhythmic patterns
- Enhanced visual themes and customization
- Improved accessibility features
- Performance optimizations
- Bug fixes and stability improvements

---

**Full Changelog**: [Initial Release](https://github.com/tobagin/tempo/releases/tag/v1.0.0)