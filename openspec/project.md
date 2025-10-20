# Project Context

## Purpose
Tempo is a modern, precise metronome application for musicians built with GTK4 and Libadwaita. The project aims to provide:
- Sub-millisecond timing accuracy with drift-free timing engine
- Clean, adaptive interface following GNOME design principles
- Customizable tempo (40-240 BPM), time signatures, and visual feedback
- Low-latency audio with accented downbeats
- Keyboard shortcuts and tap tempo functionality
- Native Linux integration via Flatpak distribution on Flathub

## Tech Stack
- **Language**: Vala (primary application code)
- **UI Toolkit**: GTK4 (version >= 4.10.0)
- **Widget Library**: Libadwaita (version >= 1.5)
- **UI Definition**: Blueprint markup language (v0.18.0) compiled to GTK .ui XML
- **Audio Engine**: GStreamer 1.0 with audio plugins
- **Build System**: Meson (>= 0.59.0)
- **Packaging**: Flatpak targeting GNOME Platform runtime 48
- **Distribution**: Flathub
- **Version Control**: Git (GitHub: tobagin/tempo)

## Project Conventions

### Code Style
- **Vala Code**: Follow standard Vala conventions
  - `PascalCase` for classes (e.g., `MainWindow`, `MetronomeEngine`)
  - `PascalCase` for file names matching class names (e.g., `MainWindow.vala`, `TapTempo.vala`)
  - `snake_case` for methods and variables
  - Clear, descriptive names for all public APIs
- **UI Files (`.blp`)**: `snake_case` naming (e.g., `main_window.blp`, `preferences_dialog.blp`)
- **UI Widget IDs**: `kebab-case` (e.g., `main-action-button`, `tempo-slider`)
- **Meson Variables**: `snake_case`
- **Application ID**: Reverse domain notation: `io.github.tobagin.tempo` (production), `io.github.tobagin.tempo.Devel` (development)

### Code Organization
- **Source Directory Structure**:
  - `/src/Main.vala` - Application entry point (at root)
  - `/src/windows/` - Window classes (e.g., `MainWindow.vala`)
  - `/src/dialogs/` - Dialog classes (e.g., `PreferencesDialog.vala`, `KeyboardShortcutsDialog.vala`)
  - `/src/utils/` - Utility classes (e.g., `MetronomeEngine.vala`, `TapTempo.vala`)
  - `/src/Config.vala.in` - Generated configuration file template
- **UI Directory Structure**: Flat structure in `/data/ui/` (3 Blueprint files)
- **File-to-Class Correspondence**: Each `.vala` file name matches its primary class name

### Architecture Patterns
- **MVC-like Pattern**: Model-View-Controller adapted for GTK
  - **Model**: Business logic and state management (pure Vala, UI-independent)
  - **View**: Blueprint files (.blp) compiled to GTK UI definitions
  - **Controller**: Vala classes connecting Model and View, handling signals
- **Composite Templates**: Use `@Gtk.Template` to link Vala classes with UI definitions
- **GResource**: All assets (UI files, icons, sounds) compiled into binary gresource
- **GSettings**: Application settings managed via gschema.xml for persistence
- **Timing Architecture**:
  - High-precision threading with absolute time references to prevent drift
  - Separate timing thread to avoid GUI blocking
  - Compensation for system delays and sleep interruptions

### Testing Strategy
- **Unit Tests**: Located in `/tests` directory mirroring main structure
- **Test Framework**: Pytest (despite Vala codebase, tests can validate build/integration)
- **Coverage**: Test expected use, edge cases, and failure scenarios
- **Validation**: Run `./scripts/validate-automation.sh` before commits
- **Integration Tests**: Validate Flatpak builds and audio functionality
- **Manual Testing**: Test on real hardware for timing accuracy verification

### Git Workflow
- **Main Branch**: `main` (default and production branch)
- **Branching**: Feature branches for new development
- **Commits**: Clear, descriptive commit messages
- **Tags**: Semantic versioning (e.g., v1.2.4) for releases
- **Release Process**:
  1. Update version in meson.build
  2. Create git tag
  3. Update production manifest with tag and commit hash
  4. Submit to Flathub

## Domain Context
### Musical Terminology
- **BPM (Beats Per Minute)**: Tempo measurement (40-240 range supported)
- **Time Signature**: Beats per measure and note value (e.g., 4/4, 3/4, 6/8)
  - Numerator: Beats per measure
  - Denominator: Note value (2=half, 4=quarter, 8=eighth, 16=sixteenth)
- **Downbeat**: First beat of a measure (accented with distinct sound)
- **Metronome Accuracy**: Sub-millisecond precision required for professional use
- **Tap Tempo**: Calculate BPM by tapping rhythm repeatedly

### Audio Engineering
- **Low-latency Audio**: Critical for timing perception (< 10ms preferred)
- **Buffer Management**: Balance between latency and stability
- **GStreamer Pipeline**: Audio generation and playback chain
- **Sample Rates**: Standard audio sample rates (44.1kHz, 48kHz)

## Important Constraints
### Technical Constraints
- **File Size Limit**: No single file should exceed 500 lines of code (refactor into modules)
- **Performance**: Sub-millisecond timing accuracy requirement
- **Audio Latency**: Must maintain low latency for professional use
- **Platform**: Linux-only (GNOME ecosystem focus)
- **Runtime**: GNOME Platform runtime 48 (controls available GTK/Adwaita versions)

### Distribution Constraints
- **Flatpak Sandbox**: Limited system access (network, audio, graphics only)
- **Reproducible Builds**: Production builds must use git tags with verified commits
- **Flathub Guidelines**: Must meet Flathub quality and metadata requirements
- **License**: GPL3+ (open source requirement)

### Development Constraints
- **Blueprint Compilation**: UI files must compile cleanly with blueprint-compiler
- **GResource Bundling**: All assets must be bundled at build time
- **Meson Build**: All build steps must work through Meson
- **No Shortcuts**: Tasks must be fully completed (per user instructions)

## External Dependencies
### Build-time Dependencies
- **blueprint-compiler**: v0.18.0 from GNOME GitLab (jwestman/blueprint-compiler)
- **GTK4**: >= 4.10.0 (via GNOME runtime)
- **Libadwaita**: >= 1.5 (via GNOME runtime)
- **GLib/GObject**: >= 2.76 (via GNOME runtime)
- **Meson**: >= 0.59.0 (build system)

### Runtime Dependencies
- **GNOME Platform**: Runtime 48 (org.gnome.Platform)
- **GStreamer**: >= 1.18 with audio plugins
- **Audio System**: PulseAudio or PipeWire
- **Graphics**: Wayland or X11 with DRI support

### Development Dependencies
- **GNOME SDK**: org.gnome.Sdk runtime 48
- **flatpak-builder**: For local development builds
- **Git**: Version control
- **Pytest**: Test framework (optional, for validation scripts)

### External Services
- **GitHub**: Source code hosting (github.com/tobagin/tempo)
- **Flathub**: Application distribution platform
- **GNOME GitLab**: blueprint-compiler source
