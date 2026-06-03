# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.3] - 2026-06-03

### 🔧 Changed

- **Dependencies**: Raised minimum build dependency versions to match the GNOME 50 runtime baseline (GTK ≥ 4.18, libadwaita ≥ 1.9, GLib/GObject ≥ 2.84, json-glib ≥ 1.10, GStreamer ≥ 1.24).

## [1.5.2] - 2026-03-23

### 🐛 Fixed

- **Keyboard Shortcuts**: Spacebar now starts/stops the metronome immediately on launch, regardless of which widget has focus (fixes #15).

### 🔧 Changed

- **Flatpak Runtime**: Updated runtime and SDK to GNOME Platform 50.
- **Build Script**: Updated to use a shared local Flatpak repo to avoid stale build artifacts.

## [1.5.1] - 2026-01-12

### Changed

- **Metadata**: Improved summary and description for better Flathub presentation.
- **Branding**: Updated primary branding colors to distinctive Teal theme.
- **Documentation**: Simplified README, added Flathub/Ko-Fi badges, and clarified build instructions.

## [1.5.0] - 2026-01-10

### Added

- **Setlists**: Added ability to organize presets into sequences.
- **✨ New Icons**: Fresh new application icons (Thanks to @oiimrosabel).
- **Setlist Manager**: New dialog to create, rename, and manage setlists and their presets.
- **Setlist Navigation**: Quick navigation buttons (Previous/Next) in the main UI when a setlist is active.
- **Rhythm Patterns**: New patterns for practice (Son Clave, Rumba Clave, Bossa Nova, etc.).
- **Visual Modes**: Five new styles for the beat indicator (Pendulum, Bar Graph, etc.).
- **Silent Beats**: Selective muting of beats for interval training.
- **Practice Timer**: Count-up and countdown modes with auto-stop.

### Changed

- **Mobile Layout**: Adaptive UI improvements for mobile Linux devices.
- **Sound Selection**: New built-in sound types (Woodblock, Metal, Digital).
- **Preset Manager**: Redesigned for better mobile and desktop experience.

### Fixed

- **Time Signatures**: Corrected timing for different note value denominators.
- **Audio Reliability**: Improved error handling and visual-only fallback mode.
- **Security**: Added comprehensive file validation for custom sounds.

## [1.4.0] - 2025-11-03

### Added
- **Sound Type Selection**: Multiple built-in sound types: Default, Woodblock, Metal, and Digital.
- **Independent Sounds**: Independent high/low sound type selection.

### Changed
- Refined "Custom Sounds" settings section.

## [1.3.0] - 2025-10-20

### Added
- **File Validation**: MIME type and size checks for custom audio files.
- **Error Handling**: Modal alerts for audio system failures.
- **Visual-Only Mode**: Graceful degradation when audio is unavailable.

## [1.1.1] - 2025-08-16

### Changed
- Ported the entire application from Python to Vala for performance.
- Migrated to GTK4 and Libadwaita.

## [1.0.0] - 2025-01-14

### Added
- Initial release with high-precision timing and basic metronome features.
