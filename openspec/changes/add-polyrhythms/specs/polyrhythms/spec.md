# Polyrhythm Capability

## ADDED Requirements

### Requirement: Dual Rhythmic Stream Support
The system SHALL support two simultaneous independent rhythmic streams with configurable beat counts.

#### Scenario: 3 against 4 polyrhythm
- **WHEN** stream 1 set to 3 beats, stream 2 set to 4 beats
- **THEN** play 3 clicks in stream 1 per cycle
- **AND** play 4 clicks in stream 2 per cycle
- **AND** both streams complete cycle together (LCM = 12 ticks)

#### Scenario: Streams synchronized at cycle completion
- **WHEN** polyrhythm cycle completes
- **THEN** both streams align on first beat
- **AND** cycle repeats seamlessly

### Requirement: LCM-Based Tick Scheduling
The system SHALL calculate least common multiple (LCM) of stream beat counts to schedule ticks precisely.

#### Scenario: LCM calculated correctly
- **WHEN** stream 1 = 3, stream 2 = 4
- **THEN** LCM = 12 ticks per cycle
- **AND** stream 1 clicks at ticks 0, 4, 8
- **AND** stream 2 clicks at ticks 0, 3, 6, 9

#### Scenario: Large polyrhythms supported
- **WHEN** stream 1 = 5, stream 2 = 7
- **THEN** LCM = 35 ticks per cycle
- **AND** timing accuracy maintained despite high tick rate

### Requirement: Stereo Audio Panning
The system SHALL pan stream 1 audio to left channel and stream 2 audio to right channel for spatial distinction.

#### Scenario: Stereo panning enabled
- **WHEN** polyrhythm mode active with panning enabled
- **THEN** stream 1 sounds play from left speaker
- **AND** stream 2 sounds play from right speaker
- **AND** spatial separation clear

#### Scenario: Panning disabled
- **WHEN** user disables stereo panning
- **THEN** use different sound types for each stream (different timbres)
- **AND** both streams play center

### Requirement: Polyrhythm Presets
The system SHALL provide presets for common polyrhythms (2v3, 3v4, 3v5, 4v5, 5v7).

#### Scenario: Preset selected
- **WHEN** user selects "3 against 4" preset
- **THEN** set stream 1 to 3 beats
- **AND** set stream 2 to 4 beats
- **AND** apply immediately

### Requirement: Dual Visual Indicators
The system SHALL display two separate visual indicators showing current beat position for each stream.

#### Scenario: Dual indicators displayed
- **WHEN** polyrhythm mode active
- **THEN** show stream 1 indicator on left side
- **AND** show stream 2 indicator on right side
- **AND** both indicators pulse on respective beats

#### Scenario: Cycle progress displayed
- **WHEN** polyrhythm playing
- **THEN** show progress bar for current position in LCM cycle
- **AND** show tick count (e.g., "8/12")

### Requirement: Polyrhythm Mode Toggle
The system SHALL provide toggle to enable/disable polyrhythm mode.

#### Scenario: Polyrhythm enabled
- **WHEN** user enables polyrhythm mode
- **THEN** show dual stream configuration controls
- **AND** hide standard time signature controls
- **AND** switch to PolyrhythmEngine

#### Scenario: Polyrhythm disabled
- **WHEN** user disables polyrhythm mode
- **THEN** revert to standard metronome
- **AND** use single time signature
- **AND** hide polyrhythm controls

### Requirement: Timing Accuracy for Polyrhythms
The system SHALL maintain sub-millisecond timing accuracy for all tick events in polyrhythm mode.

#### Scenario: High tick rate accuracy
- **WHEN** polyrhythm 5 against 7 at 180 BPM (35 ticks per beat, 105 ticks/second)
- **THEN** each tick occurs within 1ms of scheduled time
- **AND** no accumulated drift over 100 cycles

### Requirement: Common BPM for Both Streams
The system SHALL apply same BPM tempo to both streams, varying only beat subdivision.

#### Scenario: BPM applies to both streams
- **WHEN** user sets BPM to 120
- **THEN** both streams use 120 BPM for timing calculations
- **AND** streams differ only in beat count per cycle

#### Scenario: BPM change updates both streams
- **WHEN** user changes BPM during polyrhythm playback
- **THEN** recalculate tick duration for both streams
- **AND** apply new tempo immediately to both

### Requirement: Polyrhythm Settings Persistence
The system SHALL persist polyrhythm configuration across application restarts.

#### Scenario: Polyrhythm settings saved
- **WHEN** user configures polyrhythm (enabled, stream beats, panning)
- **THEN** save to GSettings
- **AND** restore on next application start

### Requirement: Stream Beat Count Configuration
The system SHALL allow stream beat counts from 1 to 16.

#### Scenario: Beat count adjusted
- **WHEN** user changes stream 1 beat count to 5
- **THEN** recalculate LCM with new value
- **AND** update visual indicator
- **AND** apply immediately if playing

#### Scenario: Equal beat counts
- **WHEN** both streams set to same beat count (e.g., 4 and 4)
- **THEN** streams play in unison
- **AND** equivalent to standard metronome (no polyrhythm)

### Requirement: Polyrhythm Performance Overhead
The system SHALL maintain acceptable performance with polyrhythm mode (< 10% CPU increase vs standard mode).

#### Scenario: CPU usage acceptable
- **WHEN** polyrhythm 5 against 7 at 240 BPM
- **THEN** CPU usage increases less than 10% vs standard metronome
- **AND** audio latency remains < 10ms
- **AND** UI responsive
