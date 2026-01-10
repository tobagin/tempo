# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
