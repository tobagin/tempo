# MIDI Output Capability

## ADDED Requirements

### Requirement: MIDI Clock Output
The system SHALL send MIDI clock messages at 24 pulses per quarter note (24 PPQN) synchronized with metronome tempo.

#### Scenario: Clock sent at correct intervals
- **WHEN** metronome running at 120 BPM with MIDI clock enabled
- **THEN** send 24 clock messages per beat
- **AND** interval between clocks is 20.83ms (0.5s / 24)
- **AND** clock timing maintains < 1ms jitter

#### Scenario: Clock synchronizes with tempo changes
- **WHEN** user changes BPM from 120 to 180 during playback
- **THEN** recalculate clock interval for new tempo
- **AND** next clock sent at new interval (13.89ms for 180 BPM)
- **AND** no timing discontinuity

### Requirement: MIDI Transport Messages
The system SHALL send MIDI Start message when metronome starts and Stop message when metronome stops.

#### Scenario: Start message on playback
- **WHEN** user presses play button
- **THEN** send MIDI Start (0xFA) message before first clock
- **AND** begin sending clock messages

#### Scenario: Stop message on pause
- **WHEN** user presses pause/stop button
- **THEN** send MIDI Stop (0xFC) message
- **AND** cease sending clock messages
- **AND** MIDI devices stop playback

### Requirement: MIDI Note Messages
The system SHALL optionally send MIDI Note On/Off messages for beats and downbeats with configurable note numbers.

#### Scenario: Note on downbeat
- **WHEN** downbeat occurs with MIDI notes enabled
- **THEN** send Note On message with downbeat note number and velocity 127
- **AND** send Note Off message 50ms later
- **AND** note aligns with audio click

#### Scenario: Note on regular beat
- **WHEN** regular beat occurs with MIDI notes enabled
- **THEN** send Note On message with regular beat note number and velocity 100
- **AND** send Note Off message 50ms later

#### Scenario: MIDI notes disabled
- **WHEN** MIDI clock enabled but notes disabled
- **THEN** send only clock and transport messages
- **AND** no Note On/Off messages sent

### Requirement: MIDI Device Selection
The system SHALL enumerate available MIDI devices and allow user to select output device in preferences.

#### Scenario: Device list populated
- **WHEN** user opens MIDI preferences
- **THEN** display list of available MIDI output devices
- **AND** include "Virtual Port" option for software connections
- **AND** show current connection status

#### Scenario: Device selected
- **WHEN** user selects MIDI device from list
- **THEN** attempt connection to device
- **AND** display "Connected" if successful
- **AND** save device selection to settings

#### Scenario: Device unavailable
- **WHEN** selected device not available
- **THEN** display error "MIDI device unavailable"
- **AND** continue audio-only operation
- **AND** provide retry/reconnect button

### Requirement: MIDI Channel Configuration
The system SHALL allow user to configure MIDI channel (1-16) for note messages.

#### Scenario: Channel selected
- **WHEN** user sets MIDI channel to 10
- **THEN** all Note On/Off messages sent on channel 10 (0x99/0x89)
- **AND** channel persisted to settings

### Requirement: MIDI Note Number Configuration
The system SHALL allow user to configure MIDI note numbers for downbeat and regular beats.

#### Scenario: Note numbers configured
- **WHEN** user sets downbeat note to 60 (C4) and regular to 62 (D4)
- **THEN** downbeats trigger MIDI note 60
- **AND** regular beats trigger MIDI note 62
- **AND** settings persisted

#### Scenario: Note name displayed
- **WHEN** user adjusts note number spinner
- **THEN** display note name alongside number (e.g., "60 - C4", "76 - E5")
- **AND** update name in real-time

### Requirement: MIDI Initialization and Error Handling
The system SHALL gracefully handle MIDI initialization failures and continue audio-only operation.

#### Scenario: MIDI initialization succeeds
- **WHEN** application starts with MIDI enabled
- **THEN** initialize ALSA sequencer
- **AND** create MIDI output port "Tempo MIDI Out"
- **AND** mark as connected

#### Scenario: MIDI initialization fails
- **WHEN** ALSA sequencer unavailable or permission denied
- **THEN** log warning with error details
- **AND** continue audio metronome operation
- **AND** display toast "MIDI unavailable, using audio only"
- **AND** do not crash application

#### Scenario: MIDI device disconnected during playback
- **WHEN** MIDI device unplugged or connection lost mid-session
- **THEN** detect disconnect via ALSA error
- **AND** stop MIDI output gracefully
- **AND** continue audio playback
- **AND** show notification "MIDI disconnected"

### Requirement: MIDI Settings Persistence
The system SHALL persist MIDI configuration across application restarts.

#### Scenario: MIDI settings saved
- **WHEN** user configures MIDI device, channel, and note numbers
- **THEN** save to GSettings immediately
- **AND** settings include: enabled, device, channel, send-clock, send-notes, note numbers

#### Scenario: MIDI settings restored
- **WHEN** application starts
- **THEN** load MIDI settings from GSettings
- **AND** attempt to initialize MIDI with saved configuration
- **AND** reconnect to last-used device if available

### Requirement: MIDI Test Functionality
The system SHALL provide test button to verify MIDI output without starting metronome.

#### Scenario: Test MIDI notes
- **WHEN** user clicks "Test MIDI" button in preferences
- **THEN** send Note On message with configured downbeat note
- **AND** send Note Off after 50ms
- **AND** wait 200ms
- **AND** send Note On message with regular beat note
- **AND** send Note Off after 50ms
- **AND** display "Test sent" confirmation

### Requirement: MIDI Timing Accuracy
The system SHALL maintain MIDI clock timing with < 1ms jitter to ensure stable synchronization.

#### Scenario: Clock jitter measured
- **WHEN** MIDI clock sent over 1000 beats
- **THEN** timing variance between clocks < 1ms
- **AND** no accumulated drift over duration
- **AND** clock intervals consistent

### Requirement: MIDI Performance Overhead
The system SHALL add negligible performance overhead (< 5% CPU increase) when MIDI enabled.

#### Scenario: CPU usage with MIDI
- **WHEN** metronome running at 240 BPM with MIDI clock enabled
- **THEN** CPU usage increases by less than 5% compared to audio-only
- **AND** no impact on audio timing precision
- **AND** UI remains responsive

### Requirement: Flatpak MIDI Permissions
The system SHALL document required Flatpak permissions for MIDI device access and handle permission denial gracefully.

#### Scenario: Permissions granted
- **WHEN** Flatpak has device permissions (--device=all)
- **THEN** MIDI initialization succeeds
- **AND** devices enumerated correctly

#### Scenario: Permissions denied
- **WHEN** Flatpak lacks device permissions
- **THEN** MIDI initialization fails with permission error
- **AND** display helpful error: "MIDI requires device permissions. Grant via Flatseal or manually."
- **AND** provide documentation link

### Requirement: MIDI Output Synchronization
The system SHALL synchronize MIDI clock and note messages with audio playback to prevent drift.

#### Scenario: MIDI and audio aligned
- **WHEN** metronome running with both audio and MIDI
- **THEN** MIDI note messages sent within 1ms of audio click
- **AND** MIDI clocks maintain consistent timing
- **AND** no noticeable offset between audio and MIDI

### Requirement: MIDI Cleanup on Exit
The system SHALL properly close MIDI connections and free resources on application exit.

#### Scenario: Clean shutdown
- **WHEN** application closes with MIDI active
- **THEN** send MIDI Stop message
- **AND** close ALSA sequencer
- **AND** delete MIDI port
- **AND** free all MIDI resources
