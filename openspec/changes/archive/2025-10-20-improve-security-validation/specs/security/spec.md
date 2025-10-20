# Security Capability

## ADDED Requirements

### Requirement: File Size Validation
The system SHALL enforce a maximum file size limit of 10MB for custom audio files to prevent denial-of-service attacks.

#### Scenario: Large file rejected
- **WHEN** user selects audio file larger than 10MB
- **THEN** display error toast "File too large: [size] exceeds 10MB limit"
- **AND** do not save path to settings
- **AND** maintain previous custom sound selection

#### Scenario: Valid size accepted
- **WHEN** user selects audio file 10MB or smaller
- **THEN** proceed with format validation
- **AND** allow file to be loaded

### Requirement: Audio Format Validation
The system SHALL validate custom audio files against an allowlist of supported formats (WAV, MP3, OGG, FLAC) using MIME type detection.

#### Scenario: Unsupported format rejected
- **WHEN** user selects file with unsupported MIME type
- **THEN** display error toast "Unsupported audio format: [mime-type]"
- **AND** suggest supported formats "Please use WAV, MP3, OGG, or FLAC"
- **AND** do not save path to settings

#### Scenario: Supported format accepted
- **WHEN** user selects file with MIME type in allowlist
- **THEN** proceed with remaining validation
- **AND** allow file to be loaded

#### Scenario: Format spoofing prevented
- **WHEN** user renames non-audio file to .wav extension
- **THEN** MIME type detection identifies actual content type
- **AND** reject file based on content, not extension

### Requirement: Symlink Validation
The system SHALL resolve symbolic links to their final target and validate the target is a regular file before accepting custom audio paths.

#### Scenario: Symlink to valid file accepted
- **WHEN** user selects symbolic link pointing to valid audio file
- **THEN** resolve symlink to final target path
- **AND** validate target file per size/format requirements
- **AND** save resolved path to settings

#### Scenario: Symlink to directory rejected
- **WHEN** user selects symbolic link pointing to directory
- **THEN** display error "Path is not a regular file"
- **AND** do not save to settings

#### Scenario: Broken symlink rejected
- **WHEN** user selects symbolic link with missing target
- **THEN** display error "File does not exist"
- **AND** do not save to settings

### Requirement: Safe URI Construction
The system SHALL use `GLib.File.get_uri()` for all GStreamer URI construction to prevent path injection vulnerabilities.

#### Scenario: Special characters handled
- **WHEN** custom audio path contains special characters (spaces, unicode)
- **THEN** URI is properly encoded via GLib.File.get_uri()
- **AND** GStreamer loads file successfully

#### Scenario: No string concatenation
- **WHEN** setting GStreamer playbin URI property
- **THEN** system uses File.get_uri() method
- **AND** never concatenates "file://" + path strings

### Requirement: Resource Limits - Tap History
The system SHALL limit tap tempo history to maximum 100 entries to prevent memory exhaustion.

#### Scenario: Tap history capped
- **WHEN** user taps more than 100 times without timeout
- **THEN** oldest entries are removed to maintain 100 entry limit
- **AND** BPM calculation uses most recent 8 taps per algorithm
- **AND** memory usage remains bounded

### Requirement: Resource Limits - Drawing Rate
The system SHALL limit beat indicator redraw rate to 60 frames per second to prevent excessive CPU usage.

#### Scenario: Rapid beats throttled
- **WHEN** metronome runs at maximum 240 BPM (4 beats/second)
- **THEN** each beat triggers at most one redraw
- **AND** any additional redraws within frame period (16.67ms) are coalesced
- **AND** CPU usage remains reasonable

#### Scenario: Multiple rapid redraws coalesced
- **WHEN** multiple events trigger redraws within 16.67ms window
- **THEN** only one redraw executes per frame period
- **AND** latest state is rendered

### Requirement: Settings Debouncing
The system SHALL debounce rapid settings changes with 100ms delay to prevent update storms.

#### Scenario: Rapid slider movement
- **WHEN** user rapidly drags volume slider
- **THEN** settings write is delayed by 100ms
- **AND** only final value is written to GSettings
- **AND** intermediate values are discarded

#### Scenario: Debounce timer reset
- **WHEN** user changes setting before 100ms debounce expires
- **THEN** previous timer is cancelled
- **AND** new 100ms timer starts
- **AND** only latest value is eventually written

### Requirement: GSettings Path Validation
The system SHALL validate file paths read from GSettings before attempting to use them for audio playback.

#### Scenario: Valid stored path loaded
- **WHEN** application loads custom sound path from GSettings
- **THEN** validate path points to existing regular file
- **AND** validate file size and format per requirements
- **AND** load audio file if valid

#### Scenario: Invalid stored path handled
- **WHEN** stored path does not exist or is invalid
- **THEN** log warning with reason
- **AND** fall back to default sound
- **AND** clear invalid path from settings
- **AND** do not crash or show modal error

#### Scenario: Empty path handled
- **WHEN** stored path is empty string
- **THEN** treat as "use default sound"
- **AND** do not show error

### Requirement: GSettings String Length Limits
The system SHALL enforce maximum length of 4096 characters for file path settings at schema level.

#### Scenario: Normal path stored
- **WHEN** user selects file with path under 4096 characters
- **THEN** path is stored successfully in GSettings

#### Scenario: Excessively long path rejected
- **WHEN** external process attempts to write path over 4096 characters
- **THEN** GSettings schema validation rejects the value
- **AND** previous valid value is retained

### Requirement: Version String Validation
The system SHALL validate and sanitize version strings from GSettings before comparison operations.

#### Scenario: Valid version string
- **WHEN** last-version-shown contains valid semver "1.2.3"
- **THEN** version comparison succeeds
- **AND** release notes display logic works correctly

#### Scenario: Invalid version string sanitized
- **WHEN** last-version-shown contains invalid characters
- **THEN** sanitize to valid semver format or empty string
- **AND** treat as "never shown" to display release notes
- **AND** do not crash on comparison

### Requirement: Audio System Error Handling
The system SHALL display user-visible error dialog when audio system fails to initialize and offer visual-only mode.

#### Scenario: Audio initialization failure
- **WHEN** GStreamer or audio backend fails to initialize
- **THEN** display modal dialog "Audio system unavailable"
- **AND** offer option "Continue in visual-only mode"
- **AND** offer option "Exit application"

#### Scenario: Visual-only mode operation
- **WHEN** user chooses visual-only mode after audio failure
- **THEN** beat indicator continues to function normally
- **AND** volume controls are disabled/grayed out
- **AND** custom sound selection is disabled
- **AND** tempo and time signature controls remain functional
- **AND** visual beat synchronization works

#### Scenario: Audio system recovery
- **WHEN** running in visual-only mode
- **THEN** do not attempt to reinitialize audio automatically
- **AND** require app restart for audio recovery

### Requirement: User-Friendly File Error Messages
The system SHALL replace silent warnings with actionable toast notifications for file selection errors.

#### Scenario: File selection error toast
- **WHEN** user selects invalid audio file
- **THEN** display toast notification with specific reason
- **AND** include file size/format in message where applicable
- **AND** auto-dismiss after 5 seconds
- **AND** do not block UI with modal dialog

#### Scenario: Multiple validation failures
- **WHEN** file fails multiple validations (size AND format)
- **THEN** display error for first validation that failed
- **AND** do not overwhelm user with multiple toasts

### Requirement: Audio Loading Timeout
The system SHALL enforce 5-second timeout for audio file loading operations to prevent hang on corrupted files.

#### Scenario: Normal file loads quickly
- **WHEN** loading valid audio file
- **THEN** GStreamer loads within 5 seconds
- **AND** playback proceeds normally

#### Scenario: Corrupted file times out
- **WHEN** GStreamer takes longer than 5 seconds to load file
- **THEN** cancel loading operation
- **AND** display toast "Failed to load audio file: timeout"
- **AND** fall back to default sound
- **AND** clear custom path from settings

#### Scenario: Timeout does not block UI
- **WHEN** audio loading timeout occurs
- **THEN** UI remains responsive during timeout period
- **AND** user can interact with other controls
