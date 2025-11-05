# Changelog

All notable changes to Tempo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Rhythm Patterns**
  - Play authentic rhythm patterns for genre-specific practice (Latin, jazz, and more)
  - Six built-in patterns included:
    - **Son Clave (3-2)**: Traditional Cuban clave pattern in 3-2 orientation
    - **Son Clave (2-3)**: Traditional Cuban clave pattern in 2-3 orientation (reversed)
    - **Rumba Clave**: Afro-Cuban rumba clave with displaced third note
    - **Bossa Nova**: Classic Brazilian bossa nova pattern with ghost notes
    - **Swing Ride**: Jazz swing ride cymbal pattern with triplet feel
    - **Backbeat**: Simple rock/pop backbeat emphasizing beats 2 and 4
  - Three accent levels per step (strong, regular, ghost) with automatic volume adjustment
  - High-precision timing engine with sub-millisecond accuracy maintains perfect rhythm
  - Pattern selector dropdown in main window for easy pattern switching
  - "None" option returns to standard metronome mode
  - Pattern selection persists across app restarts
  - Patterns support variable lengths (4-8 beats typical, up to 64 beats possible)
  - Full BPM control - patterns play at any tempo from 40-240 BPM
  - Patterns use current sound type selection (default, woodblock, metal, digital)
  - Visual beat indicator shows pattern playback with accent-level colors
  - User patterns directory for future custom pattern support
- **Visual Metronome Modes**
  - Multiple visual indicator styles to suit different preferences and use cases
  - Five visual modes available:
    - **Circle**: Traditional pulsing circle (default, maintains original Tempo design)
    - **Pendulum**: Swinging animation mimicking mechanical metronomes with realistic pendulum motion
    - **Bar Graph**: Vertical bars showing beat positions within the measure
    - **Progress Ring**: Circular progress indicator filling clockwise over each measure
    - **Minimalist Flash**: Simple full-area color flash with fade effect for minimal distraction
  - All modes support beat number display (when enabled)
  - Downbeat highlighting with distinct colors (red) when configured
  - Muted beat indicators showing dimmed visuals with "M" marker
  - Smooth 60fps animations for natural motion
  - Mode selection in Preferences > Visual > "Visual Mode" dropdown
  - Settings persist across app restarts
  - Real-time mode switching applies immediately without restart
  - Theme-responsive colors adapting to light/dark mode
  - Maintained timing accuracy across all visual modes
- **Silent/Muted Beats Feature**
  - Train internal timing by selectively muting beats while maintaining visual feedback
  - Four mute patterns available:
    - **Every Nth Beat**: Mute every 2nd, 3rd, 4th, etc. beat for regular practice intervals
    - **Random Percentage**: Mute 25%, 50%, or 75% of beats randomly for unpredictable training
    - **Specific Beats**: Mute only certain beats in each bar (e.g., beats 2 & 4 for backbeat training)
    - **Progressive**: Gradually increase mute percentage over time to build confidence
  - Visual indicators show all beats including muted ones (dimmed gray outline with "M" marker)
  - Muted beats skip audio playback while maintaining precise timing
  - Comprehensive preferences page: "Silent Beats" in settings
  - Pattern-specific parameters with dynamic UI visibility
  - Settings persist across app restarts
  - Real-time pattern changes apply immediately during playback
  - Mute logic integrated before audio playback to avoid glitches
- **Tempo Trainer Feature**
  - Progressive tempo change for gradual speed building during practice
  - Configure start tempo, target tempo, and increment size (±1 to ±50 BPM)
  - Two progression modes: bar-based (every N bars) and time-based (every N seconds)
  - Real-time progress display showing current tempo, target, and countdown to next increment
  - Automatic tempo changes applied at measure boundaries for smooth transitions
  - Optional auto-stop when target tempo reached
  - Target completion notifications via toast messages
  - Works with both ascending (build speed) and descending (cool down) progressions
  - Settings persist across app restarts
  - Toggle trainer visibility via menu: "Show Tempo Trainer"
  - Integrated with metronome beat tracking for precise bar counting
- **Tempo Presets Feature**
  - Save complete metronome configurations as named presets for quick recall
  - Preset Manager dialog with full CRUD operations (Create, Read, Update, Delete)
  - Search and filter presets by name or description
  - Sort presets by name, creation date, last used date, or tempo
  - Import and export presets as JSON files for backup and sharing
  - Duplicate presets for creating variations
  - Presets save all settings: tempo, time signature, subdivisions, trainer config, and audio/visual preferences
  - Graceful handling of optional features (presets work even if subdivisions/trainer not configured)
  - Preset data stored in `~/.config/tempo/presets.json`
  - Maximum 100 presets with warning at 50
  - Keyboard shortcut: Ctrl+P to open Preset Manager
  - Accessible via main menu: "Manage Presets..."
- **Practice Timer Feature**
  - Session timer with count-up and countdown modes
  - Auto-stop functionality based on beats, bars, or time duration
  - Timer display below beat indicator (toggleable visibility)
  - Timer synchronization with metronome playback (configurable)
  - Countdown duration configurable from 1-180 minutes
  - Toast notifications for countdown completion and auto-stop events
  - Auto-stop progress indicator showing remaining beats/bars/time
  - New Practice Timer preferences page with comprehensive settings
  - Timer settings persist across application restarts
  - Sub-millisecond timing accuracy using GLib monotonic time
- **Subdivision Support**
  - Comprehensive subdivision modes: Eighth Notes (2 per beat), Sixteenth Notes (4 per beat), and Triplets (3 per beat)
  - Separate audio playback for subdivisions with adjustable volume
  - Configurable subdivision sound types (default, woodblock, metal, digital)
- **Mobile-Responsive Design**
  - Adaptive layout with three responsive breakpoints:
    - Phone (≤550px): Compact layout with 200x200px beat indicator, vertical time signature controls
    - Tablet (551-900px): Balanced layout with 250x250px beat indicator
    - Desktop (900px+): Full layout with 300x300px beat indicator (unchanged)
  - Minimum window size constraints (360x600px) supporting smallest phone screens
  - Touch-friendly controls meeting 44px minimum touch target requirements:
    - Enhanced spinbutton heights and increment/decrement buttons
    - Larger slider thumbs (24x24px) and taller troughs (12px) on touch devices
    - All buttons meet minimum 44x44px size on touch devices
  - Scrollable content on constrained screens (vertical scrolling only)
  - Adaptive margins and spacing for better mobile space utilization
  - Tempo trainer adaptive layout:
    - Start/Target/Increment controls stack vertically on phone screens
    - Interval controls (Every X bars/seconds) stack vertically on phone
    - Arrow (→) hidden on phone screens
    - Prevents horizontal scrollbar on narrow screens
  - Responsive preset manager dialog:
    - Redesigned with mobile-first UX
    - Adw.SplitButton in headerbar for new preset with dropdown menu (Import, Export, Export All)
    - Bottom toolbar with icon-only action buttons (Load, Rename, Duplicate, Delete) in title-widget
    - Icon buttons: Load (checkmark), Rename (edit), Duplicate (copy), Delete (trash)
    - Removed redundant close button (dialog X button is sufficient, show-end-title-buttons: false)
    - Fixed horizontal scrollbar in preset details (vertical scrolling only)
    - Vertical pane orientation on phones (preset list stacks above details)
  - Automatic adaptation of Adw.PreferencesDialog and Adw.AlertDialog for mobile screens
  - CSS media queries for touch device detection (@media pointer: coarse)
  - Optimized for mobile Linux devices (PinePhone, Librem 5, etc.)
  - Subdivision dropdown selector in main window for quick mode switching
  - Dedicated subdivisions section in Audio preferences
  - Visual indicator toggle for subdivision markers (configurable)
  - Smart audio overlap prevention at high tempos
  - Precise subdivision timing using same absolute time reference as main beats
  - Settings persistence across app restarts
  - Maintains sub-millisecond timing accuracy with subdivisions enabled

### Changed
- MetronomeEngine now supports optional PracticeTimer integration
- Main window layout updated to include timer display area and subdivision controls
- MetronomeEngine timing loop refactored to handle both beats and subdivisions
- Audio system extended with third GStreamer player for subdivision sounds

## [1.4.0] - 2025-11-03

### Added
- **Sound Type Selection**
  - Multiple built-in sound types: Default, Woodblock, Metal, and Digital
  - Independent high/low sound type selection for maximum flexibility
  - Sound type dropdowns in Audio preferences above custom sound pickers
  - Automatic fallback to default sounds when sound type files are missing
  - Smart precedence: custom sounds override sound types when enabled
  - Sound type dropdowns disabled when custom sounds are set for clarity
  - All sound files bundled in application resources (no external downloads)

### Changed
- Preferences dialog "Custom Sounds" section renamed to "Sound Selection"
- Custom sounds switch subtitle updated to clarify it replaces built-in sounds

## [1.3.0] - 2025-10-20

### Added
- **Comprehensive File Validation System**
  - 10MB file size limit enforcement for custom audio files
  - MIME type validation (WAV, MP3, OGG, FLAC) with extensive format support
  - Symlink resolution and validation to regular files
  - Path length validation (4096 character limit)
  - GStreamer pre-validation before saving files to settings

- **Audio System Error Handling**
  - Visual-only mode for graceful degradation when audio fails
  - Modal alert dialogs for audio initialization failures
  - Option to continue without audio or exit application
  - Audio controls automatically disabled in visual-only mode

- **Enhanced Security Features**
  - Safe URI construction using `File.get_uri()` preventing path injection
  - Version string sanitization preventing malicious input
  - Runtime path validation with automatic fallback to defaults
  - Resource limiting: tap history capped at 100 entries
  - Frame rate limiting: beat indicator capped at 60 FPS
  - Settings debouncing (100ms) preventing update storms
  - 5-second timeout for audio file loading

- **Improved User Experience**
  - Detailed alert dialogs explaining file rejection reasons
  - Thread-safe dialog presentation from GStreamer callbacks
  - User-friendly error messages with actionable suggestions
  - Enhanced MIME type support (`audio/vnd.wave`, `audio/x-vorbis+ogg`, etc.)

### Fixed
- Custom sounds now properly reset to defaults when toggle disabled
- Invalid audio files no longer saved to settings
- File validation now occurs before playback attempt
- MIME type detection works correctly across different systems
- GStreamer errors properly caught and displayed to user

### Security
- All 14 security requirements from OpenSpec specification implemented
- File handling hardened against DoS attacks and malicious files
- Input validation comprehensive across all user inputs
- Graceful error handling prevents crashes from invalid data

## [1.2.4] - 2025-09-18

### Changed
- Updated blueprint-compiler source to official GNOME repository
- Fixed dependency URLs for better long-term reliability
- Ensures compatibility with official upstream sources

## [1.2.3] - 2025-09-18

### Changed
- Updated runtime version to GNOME 49 for latest platform features
- Enhanced metainfo with additional application metadata items
- Improved compatibility with latest GNOME runtime environment

## [1.2.2] - 2025-08-25

### Fixed
- Fixed manifest update to only target tempo module, preventing blueprint compiler issues
- Corrected translation file references for new metainfo filename

### Changed
- Migrated from appdata.xml to metainfo.xml following modern AppStream standards
- Updated build system references to use metainfo naming convention

## [1.2.1] - 2025-08-25

### Added
- Implemented fully automated Flatpak releases with zero manual intervention
- GitHub Actions now push directly to Flathub main branch
- Integrated about dialog for "What's New" feature
- Added automatic about dialog navigation with tab+enter simulation
- GSettings-based version tracking to prevent repeated notifications

### Changed
- Replaced alert dialog with integrated about dialog for release notes
- Simplified keyboard shortcuts dialog by removing blue card styling
- Enhanced release workflow with comprehensive error handling
- Removed unnecessary x-checker-data configuration for cleaner manifests
- Streamlined development workflow with automated tag-based deployments

## [1.2.0] - 2025-08-25

### Added
- Comprehensive keyboard shortcuts dialog with all available shortcuts
- Updated menu structure with proper keyboard accelerators
- Implemented configuration system with development mode support
- Enhanced about dialog with release notes, acknowledgments, and credits
- Dynamic resource naming for development builds

### Changed
- Improved build system with proper app ID handling
- Updated version management system as single source of truth
- Added development flag consistency across all build tools

## [1.1.8] - 2025-08-17

### Fixed
- Time signature denominators now properly affect beat timing
- 4/4, 4/8, 4/2, and 4/16 now have different beat speeds as expected
- Improved beat duration calculation using both numerator and denominator
- Enhanced musical accuracy for practice sessions

## [1.1.7] - 2025-08-17

### Fixed
- Removed problematic translation keys from desktop file
- Ensured clean desktop file validation for Flathub submission
- Maintained all functionality while fixing translation issues

## [1.1.6] - 2025-08-17

### Fixed
- Fixed AppStream metadata validation errors in release descriptions
- Fixed desktop file validation by adding required non-translated keys
- Corrected release description format to use proper p and ul tags
- Enhanced desktop actions with proper Name entries
- Ensured compliance with desktop file specification

## [1.1.5] - 2025-08-17

### Fixed
- Fixed GTK4 API compatibility issues for proper Flatpak building
- Replaced deprecated `FileFilter.set_name()` with `.name` property
- Fixed FileDialog parent window reference for proper portal integration
- Replaced non-working `surface.set_keep_above()` with proper warning
- Fixed window signal connections (realize → map signal)
- Corrected metronome engine property references (is_playing → is_running)

### Changed
- Implemented secure file picking using desktop portals
- Enhanced build system compatibility with GNOME runtime 48
- Improved sandbox security with portal-based file access

## [1.1.4] - 2025-08-17

### Added
- Implemented full custom sounds functionality with file chooser
- Added GTK4 FileDialog with support for multiple audio formats
- Added test playback of selected custom sounds
- Implemented right-click context menu to clear custom sounds
- Implemented keep-on-top window functionality using GTK4 surface API
- Added start-on-launch functionality

### Fixed
- Fixed tap sensitivity range mismatch between UI and settings schema
- Enhanced file validation and error handling for audio files

### Changed
- Custom sounds toggle now properly shows/hides file picker rows
- All preferences now properly connected to real-time UI updates
- External settings changes are synchronized across application instances

## [1.1.3] - 2025-08-17

### Added
- Comprehensive translations for Portuguese (Brazil and Portugal)
- Spanish translation with proper musical terminology
- Irish (Gaelic) translation
- Māori translation
- Completed Italian translation coverage
- Enhanced Turkish translation completeness
- Updated translation infrastructure and build system
- All UI elements, preferences, and help text now fully translatable

## [1.1.2] - 2025-08-17

### Changed
- Merged comprehensive improvements from feature branches
- Consolidated Blueprint UI template enhancements
- Integrated custom sound support capabilities
- Improved code organization and maintainability
- Enhanced build system stability

## [1.1.1] - 2025-08-16

### Added
- Complete Python to Vala conversion for better performance and integration
- GStreamer audio integration with distinct beat and downbeat sounds
- Blueprint UI templates with modern GTK4/Libadwaita design
- Animated beat indicator with Cairo-based pulse effects and perfect sync
- Comprehensive keyboard shortcuts for full application control
- Enhanced preferences dialog with Audio, Behavior, and Visual settings
- Multi-language support with Italian and Turkish translations
- Improved timing engine with microsecond precision

### Changed
- Larger beat indicator with dramatic glow effects
- Fixed beat sequence to proper 1-2-3-4 display
- Proper translator credits in about dialog

## [1.0.8] - 2025-01-15

### Changed
- Updated file chooser to use modern `Gtk.FileDialog` API
- File picker now properly uses desktop environment portals
- Improved security through sandboxed file access
- Removed redundant portal permissions from Flatpak manifest

## [1.0.7] - 2025-01-15

### Changed
- Updated all version references to use current version consistently
- Fixed author information to use correct name throughout codebase
- Ensured only metainfo retains version history as intended

## [1.0.6] - 2025-01-15

### Added
- Added proper file picker portal permissions to Flatpak manifest
- Improved security by using sandboxed file access
- Enhanced compatibility with desktop file managers

## [1.0.5] - 2025-01-15

### Fixed
- Fixed desktop file to use correct executable name 'tempo' instead of application ID
- Resolved application launch issues from desktop environment
- Improved desktop integration and launcher compatibility

## [1.0.4] - 2025-01-14

### Changed
- Streamlined description to be more concise and user-focused
- Enhanced readability following Flathub quality guidelines
- Removed redundant technical details for better clarity

## [1.0.3] - 2025-01-14

### Fixed
- Removed duplicate keyboard control from recommends section
- Fixed AppStream validation warning about redefined relation items

## [1.0.2] - 2025-01-14

### Fixed
- Fixed AppStream validation errors for Flathub submission
- Updated developer information and contact details
- Removed inapplicable metadata fields
- Added proper branding colors

## [1.0.1] - 2025-01-14

### Added
- Application screenshots for better visibility
- Updated metadata with comprehensive visual previews
- Enhanced AppStream information for software centers

## [1.0.0] - 2025-01-14

### Initial Release

First stable release of Tempo, a modern metronome application for musicians built with GTK4 and Libadwaita.

#### Features
- High-precision timing engine with drift compensation
- Tempo control from 40 to 240 BPM
- Time signature support for various musical meters
- Low-latency GStreamer audio playback
- Visual beat indicator with downbeat accents
- Tap tempo functionality
- Keyboard shortcuts for efficient control
- Settings persistence
- Modern GTK4/Libadwaita design
- Flatpak packaging for universal Linux distribution

[1.3.0]: https://github.com/tobagin/tempo/releases/tag/1.3.0
[1.2.4]: https://github.com/tobagin/tempo/releases/tag/1.2.4
[1.2.3]: https://github.com/tobagin/tempo/releases/tag/1.2.3
[1.2.2]: https://github.com/tobagin/tempo/releases/tag/1.2.2
[1.2.1]: https://github.com/tobagin/tempo/releases/tag/1.2.1
[1.2.0]: https://github.com/tobagin/tempo/releases/tag/1.2.0
[1.1.8]: https://github.com/tobagin/tempo/releases/tag/1.1.8
[1.1.7]: https://github.com/tobagin/tempo/releases/tag/1.1.7
[1.1.6]: https://github.com/tobagin/tempo/releases/tag/1.1.6
[1.1.5]: https://github.com/tobagin/tempo/releases/tag/1.1.5
[1.1.4]: https://github.com/tobagin/tempo/releases/tag/1.1.4
[1.1.3]: https://github.com/tobagin/tempo/releases/tag/1.1.3
[1.1.2]: https://github.com/tobagin/tempo/releases/tag/1.1.2
[1.1.1]: https://github.com/tobagin/tempo/releases/tag/1.1.1
[1.0.8]: https://github.com/tobagin/tempo/releases/tag/1.0.8
[1.0.7]: https://github.com/tobagin/tempo/releases/tag/1.0.7
[1.0.6]: https://github.com/tobagin/tempo/releases/tag/1.0.6
[1.0.5]: https://github.com/tobagin/tempo/releases/tag/1.0.5
[1.0.4]: https://github.com/tobagin/tempo/releases/tag/1.0.4
[1.0.3]: https://github.com/tobagin/tempo/releases/tag/1.0.3
[1.0.2]: https://github.com/tobagin/tempo/releases/tag/1.0.2
[1.0.1]: https://github.com/tobagin/tempo/releases/tag/1.0.1
[1.0.0]: https://github.com/tobagin/tempo/releases/tag/1.0.0
