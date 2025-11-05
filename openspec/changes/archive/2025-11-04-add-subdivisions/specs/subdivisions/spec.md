# subdivisions Specification

## Purpose
Enable musicians to hear and see rhythmic divisions within each beat (eighth notes, sixteenth notes, triplets) with precise timing and customizable audio/visual feedback for advanced practice and rhythm development.

## ADDED Requirements

### Requirement: Subdivision Mode Selection
The system SHALL support four subdivision modes: None, Eighth Notes, Sixteenth Notes, and Triplets.

#### Scenario: No subdivisions enabled (default)
- **WHEN** subdivision mode is "None"
- **THEN** play only main beats (current behavior)
- **AND** display no subdivision indicators
- **AND** emit only beat_occurred signals

#### Scenario: Eighth notes enabled
- **WHEN** subdivision mode is "Eighth Notes"
- **AND** metronome is running at 120 BPM
- **THEN** play 2 clicks per beat (1 main beat + 1 subdivision)
- **AND** main beat at beat position 0
- **AND** subdivision at beat position 0.5
- **AND** total clicks per measure in 4/4 time: 8

#### Scenario: Sixteenth notes enabled
- **WHEN** subdivision mode is "Sixteenth Notes"
- **AND** metronome is running at 120 BPM
- **THEN** play 4 clicks per beat (1 main beat + 3 subdivisions)
- **AND** clicks at beat positions 0, 0.25, 0.5, 0.75
- **AND** total clicks per measure in 4/4 time: 16

#### Scenario: Triplets enabled
- **WHEN** subdivision mode is "Triplets"
- **AND** metronome is running at 120 BPM
- **THEN** play 3 clicks per beat (1 main beat + 2 subdivisions)
- **AND** clicks at beat positions 0, 0.333, 0.667
- **AND** total clicks per measure in 4/4 time: 12
- **AND** spacing creates swing/shuffle feel

### Requirement: Subdivision Timing Precision
The system SHALL maintain sub-millisecond timing accuracy for all subdivisions across all tempos.

#### Scenario: Subdivision timing at slow tempo (40 BPM)
- **WHEN** tempo is 40 BPM (1.5 second beats)
- **AND** subdivision mode is "Eighth Notes"
- **THEN** main beat at 0.0 seconds
- **AND** subdivision at 0.75 seconds
- **AND** timing accuracy within ±1ms
- **AND** no drift over 10 minutes

#### Scenario: Subdivision timing at fast tempo (240 BPM)
- **WHEN** tempo is 240 BPM (0.25 second beats)
- **AND** subdivision mode is "Sixteenth Notes"
- **THEN** clicks every 62.5 milliseconds
- **AND** timing accuracy within ±1ms
- **AND** no audio overlap or jitter
- **AND** visual indicators synchronized with audio

#### Scenario: Triplet timing precision
- **WHEN** subdivision mode is "Triplets"
- **AND** tempo is 120 BPM (0.5 second beats)
- **THEN** first subdivision at 0.1667 seconds (1/3 of beat)
- **AND** second subdivision at 0.3333 seconds (2/3 of beat)
- **AND** next main beat at 0.5000 seconds
- **AND** ratios maintain exact 1:1:1 spacing

### Requirement: Subdivision Audio Playback
The system SHALL play subdivision clicks with distinct audio characteristics from main beats.

#### Scenario: Subdivision volume quieter than main beats
- **WHEN** subdivision mode enabled (any mode)
- **AND** main beat volume is 0.8 (click-volume setting)
- **AND** subdivision volume setting is 0.5
- **THEN** play main beat at 0.8 volume
- **AND** play subdivisions at 0.5 volume
- **AND** subdivision clicks audibly lighter than main beats

#### Scenario: Subdivision sound selection
- **WHEN** subdivision-sound-type is "default"
- **THEN** use low.wav sound file for subdivisions
- **WHEN** subdivision-sound-type is "woodblock"
- **THEN** use woodblock-low.wav for subdivisions
- **AND** respect sound type setting for consistent timbre

#### Scenario: Downbeat remains accented with subdivisions
- **WHEN** subdivision mode is "Sixteenth Notes"
- **AND** time signature is 4/4
- **AND** beat 1 of measure plays
- **THEN** play high sound at accent volume (downbeat)
- **AND** following 3 subdivisions play at subdivision volume
- **AND** beat 2 plays low sound at click volume
- **AND** downbeat remains clearly accented

### Requirement: Subdivision Visual Indicators
The system SHALL display visual indicators for active subdivisions synchronized with audio.

#### Scenario: No subdivision indicators when mode is None
- **WHEN** subdivision mode is "None"
- **THEN** display only main beat circle indicator
- **AND** no subdivision dots or markers visible

#### Scenario: Eighth note indicators displayed
- **WHEN** subdivision mode is "Eighth Notes"
- **AND** show-subdivision-indicators setting enabled
- **THEN** display 1 dot between beat positions
- **AND** dot positioned at 180° from main beat (opposite side of circle)
- **AND** dot size 3px when inactive, 6px when active
- **AND** dot pulses/highlights on subdivision click

#### Scenario: Sixteenth note indicators displayed
- **WHEN** subdivision mode is "Sixteenth Notes"
- **AND** show-subdivision-indicators setting enabled
- **THEN** display 3 dots at 90°, 180°, 270° positions
- **AND** dots represent subdivisions 1, 2, 3 respectively
- **AND** active subdivision highlighted with larger size and accent color

#### Scenario: Triplet indicators displayed
- **WHEN** subdivision mode is "Triplets"
- **THEN** display 2 dots at 120° and 240° positions (uneven spacing)
- **AND** dots represent first and second subdivisions
- **AND** visual spacing reflects triplet timing (not evenly spaced like 16ths)

#### Scenario: Subdivision indicators toggle off
- **WHEN** user disables "show-subdivision-indicators" setting
- **THEN** hide all subdivision dots
- **AND** main beat indicator continues normally
- **AND** audio subdivisions continue playing (visual only disabled)

### Requirement: Subdivision Signal Emission
The system SHALL emit signals for subdivision events to enable UI updates and future features.

#### Scenario: Subdivision signal emitted with metadata
- **WHEN** subdivision mode is "Sixteenth Notes"
- **AND** metronome plays subdivision 2 of beat 5
- **THEN** emit subdivision_occurred signal with parameters:
  - beat_number = 5
  - subdivision_index = 2
  - subdivisions_per_beat = 4
- **AND** signal emitted before visual update
- **AND** UI can use signal to update indicators

#### Scenario: Beat signal still emitted for main beats
- **WHEN** subdivision mode is "Eighth Notes"
- **AND** main beat plays (subdivision_index = 0)
- **THEN** emit beat_occurred signal (existing behavior)
- **AND** do NOT emit subdivision_occurred for main beats
- **AND** maintain backward compatibility with existing signal handlers

### Requirement: Subdivision Mode Changes
The system SHALL handle subdivision mode changes gracefully without timing disruption.

#### Scenario: Change subdivision mode while stopped
- **WHEN** metronome is stopped
- **AND** user changes from "Eighth Notes" to "Sixteenth Notes"
- **THEN** update subdivision mode immediately
- **WHEN** metronome starts
- **THEN** play with new subdivision mode (sixteenth notes)
- **AND** no transition artifacts

#### Scenario: Change subdivision mode while running
- **WHEN** metronome is running with "Eighth Notes"
- **AND** currently at beat 3, subdivision 1
- **AND** user changes to "Triplets"
- **THEN** complete current beat with eighths
- **WHEN** next beat starts
- **THEN** switch to triplets mode
- **AND** display toast "Subdivision mode changed to Triplets"
- **AND** no timing glitches or skipped beats

#### Scenario: Disable subdivisions while running
- **WHEN** metronome running with "Sixteenth Notes"
- **AND** user sets mode to "None"
- **THEN** stop playing subdivisions immediately
- **AND** continue playing only main beats
- **AND** remove subdivision visual indicators
- **AND** maintain correct beat timing

### Requirement: Tempo Changes with Subdivisions
The system SHALL recalculate subdivision timing when tempo changes during playback.

#### Scenario: Tempo increase with subdivisions active
- **WHEN** metronome running at 120 BPM with "Eighth Notes"
- **AND** eighth note interval is 250ms
- **AND** user changes tempo to 140 BPM
- **THEN** recalculate eighth note interval to 214ms
- **AND** apply new timing starting next beat
- **AND** maintain subdivision precision at new tempo

#### Scenario: Tempo change during subdivision
- **WHEN** tempo is 100 BPM with "Sixteenth Notes"
- **AND** currently playing subdivision 2 of 4
- **AND** user changes tempo to 120 BPM
- **THEN** complete remaining subdivisions (3 and 4) at old tempo
- **WHEN** next main beat arrives
- **THEN** apply new tempo for all subsequent clicks
- **AND** no timing discontinuity

### Requirement: Time Signature Changes with Subdivisions
The system SHALL maintain subdivision behavior when time signature changes.

#### Scenario: Time signature change preserves subdivision mode
- **WHEN** playing 4/4 time with "Triplets"
- **AND** user changes to 3/4 time
- **THEN** continue playing triplets (3 clicks per beat)
- **AND** measure now contains 9 clicks (3 beats × 3 subdivisions)
- **AND** downbeat accent on beat 1 of each 3/4 measure

#### Scenario: Subdivisions work in compound time signatures
- **WHEN** time signature is 6/8 (compound duple)
- **AND** subdivision mode is "Triplets"
- **THEN** each dotted quarter beat divided into 3 subdivisions
- **AND** total clicks per measure: 6 (2 beats × 3 subdivisions)
- **AND** subdivisions correctly interpret beat as dotted quarter

### Requirement: Subdivision Settings Persistence
The system SHALL persist subdivision configuration and restore on application restart.

#### Scenario: Subdivision settings saved on change
- **WHEN** user enables "Sixteenth Notes" mode
- **AND** sets subdivision volume to 0.3
- **AND** sets subdivision sound type to "woodblock"
- **AND** closes application
- **WHEN** user reopens application
- **THEN** subdivision mode is "Sixteenth Notes"
- **AND** subdivision volume is 0.3
- **AND** subdivision sound type is "woodblock"

#### Scenario: Subdivision state not persisted
- **WHEN** metronome running with subdivisions at beat 15
- **AND** application closes or crashes
- **WHEN** user reopens application
- **THEN** metronome is stopped (state not persisted)
- **AND** subdivision settings preserved
- **AND** beat counter reset to 0

### Requirement: Subdivision Performance
The system SHALL maintain application performance with subdivisions enabled.

#### Scenario: CPU overhead within acceptable range
- **WHEN** metronome runs at 240 BPM with "Sixteenth Notes"
- **AND** produces 16 clicks per second
- **AND** visual indicators updating
- **THEN** CPU usage increase < 2% compared to no subdivisions
- **AND** no impact on UI responsiveness
- **AND** timing accuracy maintained (< 1ms drift)

#### Scenario: Memory footprint minimal
- **WHEN** subdivision mode enabled
- **THEN** memory increase < 2KB
- **AND** no memory leaks over extended sessions (60+ minutes)

#### Scenario: Audio latency unchanged
- **WHEN** subdivisions enabled
- **THEN** audio latency remains < 10ms
- **AND** no buffering delays
- **AND** click sounds play without perceptible lag

### Requirement: Subdivision Audio Overlap Prevention
The system SHALL prevent or handle audio overlap at fast tempos with dense subdivisions.

#### Scenario: Sound duration check at fast tempo
- **WHEN** tempo is 240 BPM with "Sixteenth Notes"
- **AND** click interval is 62.5ms
- **AND** sound file duration is < 50ms
- **THEN** play subdivisions without overlap
- **AND** each click completes before next begins

#### Scenario: Volume reduction for overlap prevention
- **WHEN** tempo very fast (>200 BPM with sixteenths)
- **AND** clicks sound dense
- **THEN** automatically reduce subdivision volume by additional 10%
- **AND** maintain rhythm clarity
- **AND** prevent auditory fatigue

### Requirement: Subdivision UI Integration
The system SHALL integrate subdivision controls into main window and preferences without cluttering interface.

#### Scenario: Subdivision mode selector in main window
- **WHEN** user opens main window
- **THEN** show subdivision mode dropdown below tempo controls
- **AND** options: "None", "Eighth Notes", "Sixteenth Notes", "Triplets"
- **AND** current mode selected
- **AND** dropdown takes < 30px vertical space

#### Scenario: Subdivision preferences section
- **WHEN** user opens Preferences dialog
- **THEN** show "Subdivisions" section with:
  - Subdivision mode dropdown
  - Subdivision volume slider (0-100%)
  - Subdivision sound type dropdown
  - "Show subdivision indicators" checkbox
- **AND** section collapsed by default to reduce clutter

### Requirement: Subdivision Input Validation
The system SHALL validate all subdivision-related settings and inputs.

#### Scenario: Subdivision volume clamped to valid range
- **WHEN** user enters subdivision volume
- **THEN** enforce minimum 0.0 (silent)
- **AND** enforce maximum 1.0 (full volume)
- **AND** reject values outside range
- **AND** revert to previous valid value on invalid input

#### Scenario: Subdivision mode validated on load
- **WHEN** loading subdivision-mode from GSettings
- **AND** value is corrupted (e.g., -1 or 99)
- **THEN** log warning with g_warning()
- **AND** fallback to default (0 = None)
- **AND** reset setting to default value
- **AND** application continues normally

### Requirement: Subdivision Error Handling
The system SHALL handle subdivision-related errors gracefully without crashing.

#### Scenario: Subdivision audio player initialization fails
- **WHEN** GStreamer fails to create subdivision_sound_player
- **THEN** log error with warning()
- **AND** continue with visual-only subdivision mode
- **AND** main beat audio continues normally
- **AND** display toast "Subdivision audio unavailable, visual indicators only"

#### Scenario: Subdivision sound file missing
- **WHEN** subdivision sound type is "woodblock"
- **AND** woodblock-low.wav file not found
- **THEN** fallback to default low.wav sound
- **AND** log warning about missing file
- **AND** subdivisions continue playing with fallback sound

### Requirement: Subdivision Accessibility
The system SHALL ensure subdivision features are accessible to all users.

#### Scenario: Subdivision mode labels clear
- **WHEN** user views subdivision mode dropdown
- **THEN** show descriptive labels:
  - "None" - no subdivisions
  - "Eighth Notes (2 per beat)"
  - "Sixteenth Notes (4 per beat)"
  - "Triplets (3 per beat)"
- **AND** tooltips explain each mode

#### Scenario: Subdivision volume independent control
- **WHEN** user has hearing sensitivity
- **AND** sets subdivision volume to 0.2 (very quiet)
- **AND** main beat volume remains 0.8
- **THEN** subdivisions barely audible for reference
- **AND** main beats clearly heard
- **AND** allows customization for individual needs

#### Scenario: Visual indicators respect theme
- **WHEN** user enables dark theme
- **THEN** subdivision indicators use high contrast colors
- **AND** active indicators visible against dark background
- **WHEN** user enables light theme
- **THEN** indicators adapt to light background
- **AND** maintain visibility in all themes
