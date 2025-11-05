# audio-playback Specification

## Purpose
TBD - created by archiving change add-sound-type-selection. Update Purpose after archive.
## Requirements
### Requirement: Built-in Sound Type Selection
The system SHALL provide multiple built-in sound type presets for metronome clicks, each containing a high (accent/downbeat) and low (regular beat) sound pair.

#### Scenario: Sound type presets available
- **WHEN** user opens preferences audio settings
- **THEN** display dropdown with at least 4 sound type options
- **AND** include: Default, Woodblock, Metal, Digital

#### Scenario: Sound type changes playback
- **WHEN** user selects different sound type preset
- **THEN** system uses corresponding high/low audio files from preset
- **AND** change takes effect on next beat
- **AND** metronome does not need to be restarted

#### Scenario: Sound type persists across sessions
- **WHEN** user selects sound type and closes application
- **THEN** selected sound type is saved to GSettings
- **AND** restored when application reopens

### Requirement: Independent High/Low Sound Type Selection
The system SHALL allow users to independently select different sound types for high (accent) and low (regular) sounds.

#### Scenario: Different types per beat
- **WHEN** user selects Woodblock for high sound
- **AND** user selects Metal for low sound
- **THEN** downbeats play woodblock sound
- **AND** regular beats play metal sound
- **AND** both selections are saved independently

#### Scenario: Mix built-in and custom sounds
- **WHEN** user enables custom sounds
- **AND** sets custom high sound path
- **AND** selects Woodblock type for low sound
- **THEN** downbeats use custom high sound file
- **AND** regular beats use built-in woodblock low sound

### Requirement: Sound Type Resource Management
The system SHALL bundle all sound type audio files as GResource assets compiled into the application binary.

#### Scenario: Sound files bundled at build time
- **WHEN** application is built with Meson
- **THEN** all sound type audio files are compiled into gresource bundle
- **AND** files are accessible via GResource URIs at runtime
- **AND** no external file dependencies required

#### Scenario: Sound file naming convention
- **WHEN** loading sound type preset files
- **THEN** files follow pattern: `data/sounds/{type}-high.wav` and `data/sounds/{type}-low.wav`
- **AND** default type uses `high.wav` and `low.wav` for backward compatibility

### Requirement: Sound Type UI Controls
The system SHALL provide dropdowns in preferences to select sound types for high and low sounds separately.

#### Scenario: Sound type dropdowns in preferences
- **WHEN** user opens Audio settings in preferences
- **THEN** display "High Sound Type" dropdown
- **AND** display "Low Sound Type" dropdown
- **AND** each dropdown contains all available sound type options
- **AND** dropdowns are positioned above custom sound file selectors

#### Scenario: Custom sounds disable type selection
- **WHEN** user enables "Use Custom Sounds" switch
- **AND** sets custom high sound path
- **THEN** "High Sound Type" dropdown becomes disabled/grayed out
- **AND** "Low Sound Type" dropdown remains enabled if low sound path is empty

#### Scenario: Clearing custom sound re-enables type selection
- **WHEN** user has custom sound enabled
- **AND** clears custom sound path via right-click menu
- **THEN** corresponding sound type dropdown becomes enabled
- **AND** reverts to using selected built-in sound type

### Requirement: Sound Type Validation and Fallback
The system SHALL validate bundled sound type files exist at startup and fall back to default sounds if missing.

#### Scenario: Missing sound type file handled
- **WHEN** system attempts to load sound type with missing audio file
- **THEN** log warning with missing file details
- **AND** fall back to default sound type (high.wav/low.wav)
- **AND** do not crash or show error dialog to user
- **AND** continue normal operation

#### Scenario: All sound type files validated at startup
- **WHEN** MetronomeEngine initializes
- **THEN** validate all bundled sound type files are accessible via GResource
- **AND** log any missing files as warnings
- **AND** initialize with valid sound type or default

### Requirement: Sound Type GSettings Schema
The system SHALL store sound type selections in GSettings with string keys representing the selected type.

#### Scenario: Sound type saved to settings
- **WHEN** user selects "Woodblock" sound type for high sound
- **THEN** save "woodblock" to "high-sound-type" GSettings key
- **AND** value persists across application restarts

#### Scenario: Invalid sound type in settings handled
- **WHEN** GSettings contains invalid sound type value
- **THEN** log warning about invalid type
- **AND** fall back to "default" sound type
- **AND** update settings with fallback value

#### Scenario: Sound type priority over custom when custom disabled
- **WHEN** "use-custom-sounds" is false
- **THEN** system uses sound type from "high-sound-type" setting
- **AND** ignores any value in "high-sound-path"
- **AND** applies same logic for low sound

### Requirement: Sound Type Audio Quality Standards
The system SHALL ensure all bundled sound type audio files meet quality and performance standards.

#### Scenario: Audio file specifications
- **WHEN** adding new sound type audio files
- **THEN** files MUST be WAV format, 16-bit, 44.1kHz or 48kHz sample rate
- **AND** files MUST be under 200KB per sound
- **AND** files MUST be between 50ms and 500ms duration
- **AND** files MUST have normalized peak levels to prevent clipping

#### Scenario: Sound type audio consistency
- **WHEN** testing all sound types
- **THEN** high/low sounds within same type have similar volume levels
- **AND** accented (high) sound is audibly distinct from regular (low) sound
- **AND** sound pairs work together musically

### Requirement: Backward Compatibility with Existing Settings
The system SHALL maintain backward compatibility with existing installations that lack sound type settings.

#### Scenario: First launch with new version
- **WHEN** user upgrades from version without sound types
- **AND** launches application for first time
- **THEN** "high-sound-type" defaults to "default"
- **AND** "low-sound-type" defaults to "default"
- **AND** existing custom sound paths remain intact
- **AND** custom sounds continue to work if enabled

#### Scenario: Custom sounds take precedence
- **WHEN** "use-custom-sounds" is true
- **AND** custom sound path is set
- **THEN** system uses custom sound file
- **AND** ignores sound type setting for that sound
- **AND** sound type dropdown is disabled in UI

