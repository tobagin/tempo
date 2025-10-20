# Implementation Tasks

## 1. File Handling Security (HIGH PRIORITY)
- [x] 1.1 Add file size validation (10MB limit) in PreferencesDialog.vala
- [x] 1.2 Implement audio format validation (wav, mp3, ogg, flac only) in PreferencesDialog.vala
- [x] 1.3 Add symlink resolution and validation in PreferencesDialog.vala
- [x] 1.4 Add audio file header validation before GStreamer loading in PreferencesDialog.vala
- [x] 1.5 Implement proper error dialogs for invalid file selections in PreferencesDialog.vala

## 2. URI Construction Security (HIGH PRIORITY)
- [x] 2.1 Replace string concatenation with File.get_uri() in MetronomeEngine.vala
- [x] 2.2 Replace string concatenation with File.get_uri() in PreferencesDialog.vala
- [x] 2.3 Add timeout handling for audio file loading operations (Implemented in PreferencesDialog test_play_sound)
- [x] 2.4 Add proper error handlers for GStreamer operations in MetronomeEngine.vala

## 3. Resource Limits (MEDIUM PRIORITY)
- [x] 3.1 Cap TapTempo history at 100 entries in TapTempo.vala
- [x] 3.2 Implement frame rate limiting for beat indicator (60 FPS) in MainWindow.vala
- [x] 3.3 Add debouncing for rapid settings changes in PreferencesDialog.vala

## 4. Input Validation (MEDIUM PRIORITY)
- [x] 4.1 Validate file paths read from GSettings in PreferencesDialog.vala
- [x] 4.2 Validate file paths read from GSettings in MetronomeEngine.vala
- [x] 4.3 Add max length constraints for string settings in gschema.xml.in
- [x] 4.4 Add version string sanitization for last-version-shown in Main.vala

## 5. Error Reporting (MEDIUM PRIORITY)
- [x] 5.1 Add user-visible error dialogs for critical audio failures in MetronomeEngine.vala
- [x] 5.2 Replace silent warnings with actionable error messages in PreferencesDialog.vala
- [x] 5.3 Implement graceful degradation (visual-only mode if audio fails) in MainWindow.vala
- [x] 5.4 Add status indicator for audio system health in MainWindow.vala

## 6. Testing & Validation
- [x] 6.1 Test file size limits with large audio files
- [x] 6.2 Test invalid audio format rejection
- [x] 6.3 Test symlink handling
- [x] 6.4 Test resource limits under stress
- [x] 6.5 Test graceful degradation when audio system fails
- [x] 6.6 Validate schema constraints with gsettings

## Implementation Notes

All security improvements have been successfully implemented and tested:

### Completed Features:
1. **File Validation** - Comprehensive validation in PreferencesDialog.vala including size (10MB), format (MIME type), symlinks, and path length (4096 chars)
2. **Safe URI Construction** - All GStreamer URI operations now use File.get_uri() instead of string concatenation
3. **Resource Limits** - TapTempo capped at 100 entries, beat indicator limited to 60 FPS, volume settings debounced at 100ms
4. **Path Validation** - Runtime validation of file paths from GSettings with automatic fallback to defaults
5. **Version String Security** - Sanitization and validation in Main.vala prevents injection attacks
6. **Audio System Error Handling** - Modal dialog offers visual-only mode when audio fails, with proper UI state management
7. **Audio Loading Timeout** - 5-second timeout implemented in test_play_sound with user feedback
8. **User-Friendly Errors** - Toast notifications replace silent warnings, specific error messages guide users

### Build Status:
✅ All code compiles successfully
✅ OpenSpec validation passes
✅ No blocking errors, only minor warnings

## Bug Fixes (Post-Implementation)

### Critical Validation Issues Fixed:
1. **GStreamer Pre-Validation** - Files are now tested with GStreamer BEFORE saving to settings
   - Only saves path if GStreamer successfully loads the file
   - Prevents invalid files from being stored in settings
   - Shows specific error messages when files fail to load

2. **Default Sound Reset** - Custom sounds properly reset to defaults when disabled
   - `get_sound_uri()` method always returns default URI when custom sounds toggle is OFF
   - Fixes issue where invalid custom sounds would cause no audio playback

3. **Runtime Path Validation** - Paths loaded from GSettings are validated on every beat
   - Invalid paths automatically cleared from settings
   - Automatic fallback to default sounds if custom path becomes invalid

### Implementation Details:
- [PreferencesDialog.vala:494-592](src/dialogs/PreferencesDialog.vala#L494-L592) - `test_and_save_sound()` validates with GStreamer before saving
- [PreferencesDialog.vala:404-412](src/dialogs/PreferencesDialog.vala#L404-L412) - `show_error_dialog()` displays clear rejection reasons
- [MetronomeEngine.vala:354-398](src/utils/MetronomeEngine.vala#L354-L398) - `get_sound_uri()` handles all URI resolution with validation
- Both methods use `validate_audio_path()` for consistent file validation

### User Experience Improvements:
- **Alert Dialogs** instead of dismissible toasts for file rejection
- **Detailed Error Messages** include filename and specific reason for rejection
- **Main Thread Safety** - All dialogs presented via `Idle.add()` from GStreamer bus callbacks
- **Guided Suggestions** - Error messages suggest valid formats (WAV, MP3, OGG, FLAC)

### MIME Type Support (Complete List):
- **WAV**: `audio/wav`, `audio/x-wav`, `audio/vnd.wave`
- **MP3**: `audio/mpeg`, `audio/mp3`, `audio/x-mpeg`
- **OGG**: `audio/ogg`, `audio/x-vorbis+ogg`, `audio/x-ogg`
- **FLAC**: `audio/flac`, `audio/x-flac`

Note: Different systems/libraries may report different MIME types for the same format. Our allowlist covers all common variants detected by GLib's `g_file_query_info()`.
