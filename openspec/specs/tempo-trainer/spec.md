# tempo-trainer Specification

## Purpose
TBD - created by archiving change add-tempo-trainer. Update Purpose after archive.
## Requirements
### Requirement: Tempo Trainer Configuration
The system SHALL allow configuration of tempo progression parameters: start tempo, target tempo, increment, and interval.

#### Scenario: Configure ascending progression
- **WHEN** user sets start tempo to 60 BPM
- **AND** sets target tempo to 120 BPM
- **AND** sets increment to +5 BPM
- **AND** sets interval to 8 bars
- **THEN** trainer configured for 60→120 BPM progression
- **AND** tempo increases by 5 BPM every 8 bars
- **AND** configuration saved to settings

#### Scenario: Configure descending progression
- **WHEN** user sets start tempo to 140 BPM
- **AND** sets target tempo to 60 BPM
- **AND** sets increment to -10 BPM
- **AND** sets interval to 4 bars
- **THEN** trainer configured for descending progression
- **AND** tempo decreases by 10 BPM every 4 bars

#### Scenario: Enable trainer with valid configuration
- **WHEN** trainer configured with start=60, target=120, increment=+5
- **AND** user enables tempo trainer
- **THEN** trainer becomes active
- **AND** metronome tempo set to start tempo (60 BPM)
- **AND** progression tracking begins
- **AND** UI shows "Tempo Trainer Active"

### Requirement: Bar-Based Tempo Progression
The system SHALL increase tempo after completing specified number of bars (measures).

#### Scenario: First tempo increase after N bars
- **WHEN** trainer active with 60→120 BPM, +5 every 8 bars
- **AND** metronome in 4/4 time
- **AND** 32 beats played (8 complete bars)
- **WHEN** beat 33 plays (downbeat of bar 9)
- **THEN** increase tempo to 65 BPM
- **AND** emit tempo_should_change signal
- **AND** apply tempo change on this downbeat
- **AND** reset bar counter to 0

#### Scenario: Multiple tempo increases
- **WHEN** trainer active with 60→120 BPM, +5 every 8 bars
- **AND** 8 bars complete at 60 BPM
- **THEN** increase to 65 BPM
- **WHEN** 8 more bars complete at 65 BPM
- **THEN** increase to 70 BPM
- **WHEN** 8 more bars complete at 70 BPM
- **THEN** increase to 75 BPM
- **AND** progression continues until target reached

#### Scenario: Bar counting across different time signatures
- **WHEN** trainer set to increase every 4 bars
- **AND** metronome in 3/4 time (3 beats per bar)
- **AND** 12 beats played (4 complete bars)
- **WHEN** beat 13 plays (downbeat of bar 5)
- **THEN** increase tempo
- **AND** bar counting works correctly for 3/4 time

#### Scenario: Bar counting only on downbeats
- **WHEN** trainer set to increase every 8 bars
- **AND** currently at beat 2 of bar 7
- **THEN** bars_completed = 6 (only 6 complete bars)
- **WHEN** beat 4 of bar 7 plays
- **THEN** bars_completed still = 6 (bar 7 not complete)
- **WHEN** beat 1 of bar 8 plays (downbeat)
- **THEN** bars_completed = 7

### Requirement: Time-Based Tempo Progression
The system SHALL increase tempo after specified number of seconds of playing time.

#### Scenario: First tempo increase after N seconds
- **WHEN** trainer active with 80→140 BPM, +2 every 30 seconds
- **AND** metronome plays for 30 seconds
- **THEN** increase tempo to 82 BPM
- **AND** reset seconds counter to 0
- **AND** continue playing at 82 BPM

#### Scenario: Multiple tempo increases over time
- **WHEN** trainer active with 80→140 BPM, +2 every 30 seconds
- **AND** 30 seconds elapsed at 80 BPM → increase to 82 BPM
- **AND** 30 seconds elapsed at 82 BPM → increase to 84 BPM
- **AND** 30 seconds elapsed at 84 BPM → increase to 86 BPM
- **THEN** progression continues every 30 seconds

#### Scenario: Time counting only when metronome running
- **WHEN** trainer active with time-based intervals
- **AND** metronome plays for 15 seconds
- **AND** user pauses metronome for 10 seconds
- **AND** user resumes metronome
- **AND** metronome plays for 15 more seconds
- **THEN** total elapsed time = 30 seconds (pause time excluded)
- **AND** tempo increase triggers after 30s of active playing

### Requirement: Target Tempo Handling
The system SHALL stop progression when target tempo is reached and not overshoot target.

#### Scenario: Exact target reached
- **WHEN** current tempo is 115 BPM
- **AND** target tempo is 120 BPM
- **AND** increment is +5 BPM
- **AND** interval completed
- **THEN** increase tempo to exactly 120 BPM
- **AND** emit target_reached signal
- **AND** stop further tempo increases
- **AND** show notification "Target 120 BPM reached"

#### Scenario: Increment would overshoot target
- **WHEN** current tempo is 115 BPM
- **AND** target tempo is 120 BPM
- **AND** increment is +10 BPM
- **AND** interval completed
- **THEN** increase tempo to 120 BPM (not 125 BPM)
- **AND** clamp to target
- **AND** emit target_reached signal

#### Scenario: Descending target reached
- **WHEN** current tempo is 65 BPM (descending from 140)
- **AND** target tempo is 60 BPM
- **AND** increment is -10 BPM
- **THEN** decrease tempo to 60 BPM (not 55 BPM)
- **AND** emit target_reached signal
- **AND** stop further decreases

#### Scenario: Auto-stop at target enabled
- **WHEN** target tempo reached
- **AND** auto-stop-at-target setting enabled
- **THEN** emit target_reached signal
- **AND** stop metronome immediately
- **AND** show notification "Target reached, metronome stopped"

#### Scenario: Continue playing at target when auto-stop disabled
- **WHEN** target tempo reached
- **AND** auto-stop-at-target setting disabled
- **THEN** emit target_reached signal
- **AND** metronome continues at target tempo
- **AND** no further tempo changes
- **AND** show notification "Target 120 BPM reached"

### Requirement: Tempo Change Application Timing
The system SHALL apply tempo changes at musically appropriate boundaries to avoid disrupting timing.

#### Scenario: Tempo change applied on downbeat
- **WHEN** bar-based interval completed
- **AND** currently at beat 3 of measure
- **THEN** delay tempo change until next downbeat
- **WHEN** next beat 1 plays
- **THEN** apply new tempo starting this beat

#### Scenario: No mid-measure tempo changes
- **WHEN** 8th bar completes (downbeat of bar 9 triggers change)
- **THEN** tempo change applies starting bar 9 beat 1
- **AND** entire bar 9 played at new tempo
- **AND** no beats split between old and new tempo

### Requirement: Progression State Tracking
The system SHALL track progression state and provide progress visibility to users.

#### Scenario: Progress display during bar-based progression
- **WHEN** trainer active with 60→120 BPM, +5 every 8 bars
- **AND** current tempo is 75 BPM
- **AND** 5 bars completed toward next increment
- **THEN** display "75/120 BPM, next +5 in 3 bars"
- **AND** progress bar shows (75-60)/(120-60) = 25% complete

#### Scenario: Progress display during time-based progression
- **WHEN** trainer active with 80→140 BPM, +2 every 30 seconds
- **AND** current tempo is 90 BPM
- **AND** 22 seconds elapsed toward next increment
- **THEN** display "90/140 BPM, next +2 in 8 seconds"
- **AND** progress bar shows (90-80)/(140-80) = 17% complete

#### Scenario: Calculate remaining increments
- **WHEN** current tempo is 85 BPM
- **AND** target tempo is 120 BPM
- **AND** increment is +5 BPM
- **THEN** remaining increments = (120-85)/5 = 7
- **AND** display "7 increments remaining"

### Requirement: Pause and Resume Behavior
The system SHALL preserve trainer state when metronome is paused and resume correctly.

#### Scenario: Pause preserves bar count
- **WHEN** trainer active with bar-based intervals
- **AND** 5 of 8 bars completed toward next increment
- **AND** user pauses metronome
- **THEN** preserve bars_completed = 5
- **AND** preserve current_tempo
- **WHEN** user resumes metronome
- **THEN** continue from 5 bars, need 3 more for increment

#### Scenario: Pause preserves time count
- **WHEN** trainer active with time-based intervals (every 30s)
- **AND** 18 seconds elapsed toward next increment
- **AND** user pauses metronome
- **THEN** preserve seconds_elapsed = 18
- **WHEN** user resumes metronome
- **THEN** continue from 18 seconds, need 12 more for increment

#### Scenario: Stop resets progression state
- **WHEN** trainer active with progression in progress
- **AND** user stops metronome (not just pause)
- **THEN** reset bars_completed = 0
- **AND** reset seconds_elapsed = 0
- **WHEN** user starts metronome again
- **THEN** progression starts fresh from beginning

### Requirement: Manual Tempo Change Handling
The system SHALL detect and handle manual tempo changes during trainer session.

#### Scenario: Manual tempo change disables trainer
- **WHEN** trainer active at 75 BPM
- **AND** user manually changes tempo to 100 BPM via slider
- **THEN** detect tempo change not from trainer
- **AND** pause trainer automatically
- **AND** set trainer to inactive state
- **AND** show toast "Tempo Trainer paused (manual change detected)"

#### Scenario: Re-enable trainer after manual change
- **WHEN** trainer paused due to manual tempo change
- **AND** user re-enables trainer
- **THEN** reset progression: current_tempo = start_tempo
- **AND** set metronome to start_tempo
- **AND** reset bars_completed / seconds_elapsed to 0
- **AND** begin fresh progression

#### Scenario: Tempo change from trainer not treated as manual
- **WHEN** trainer applies increment (75 BPM → 80 BPM)
- **THEN** track this as trainer-initiated change
- **AND** do not pause trainer
- **AND** trainer remains active

### Requirement: Trainer Settings Persistence
The system SHALL persist trainer configuration and restore on application restart.

#### Scenario: Trainer configuration saved
- **WHEN** user configures start=60, target=120, increment=+5
- **AND** sets interval to 8 bars
- **AND** enables auto-stop at target
- **AND** closes application
- **WHEN** user reopens application
- **THEN** start tempo is 60 BPM
- **AND** target tempo is 120 BPM
- **AND** increment is +5 BPM
- **AND** interval is 8 bars
- **AND** auto-stop enabled

#### Scenario: Trainer state not persisted
- **WHEN** trainer active with progress at 85 BPM (5 bars completed)
- **AND** application closes or crashes
- **WHEN** user reopens application
- **THEN** trainer is disabled (not active)
- **AND** progression state reset (bars_completed = 0)
- **AND** configuration preserved for easy restart

### Requirement: Trainer Input Validation
The system SHALL validate all trainer configuration inputs and reject invalid values.

#### Scenario: Start and target must differ
- **WHEN** user sets start tempo to 120 BPM
- **AND** sets target tempo to 120 BPM
- **AND** attempts to enable trainer
- **THEN** show error "Start and target tempo must differ"
- **AND** prevent trainer activation
- **AND** trainer remains disabled

#### Scenario: Increment must not be zero
- **WHEN** user sets increment to 0 BPM
- **AND** attempts to enable trainer
- **THEN** show error "Increment must be non-zero"
- **AND** suggest range: -50 to +50 (excluding 0)
- **AND** prevent trainer activation

#### Scenario: Increment direction must match target direction
- **WHEN** user sets start=60, target=120 (ascending)
- **AND** sets increment to -5 BPM (negative)
- **AND** attempts to enable trainer
- **THEN** show error "For ascending progression, increment must be positive"
- **AND** suggest: "Use +5 instead of -5"

#### Scenario: Start and target within valid BPM range
- **WHEN** user sets start tempo to 30 BPM (below 40 minimum)
- **THEN** clamp to minimum 40 BPM
- **AND** show warning "Minimum tempo is 40 BPM"
- **WHEN** user sets target tempo to 300 BPM (above 240 maximum)
- **THEN** clamp to maximum 240 BPM
- **AND** show warning "Maximum tempo is 240 BPM"

#### Scenario: Interval value must be positive
- **WHEN** user sets interval to 0 bars or 0 seconds
- **THEN** reject with error "Interval must be at least 1"
- **AND** enforce minimum value of 1

#### Scenario: Warning for large increments
- **WHEN** user sets increment to +25 BPM or greater
- **THEN** show warning "Large increments (>20 BPM) may be difficult"
- **AND** suggest "Smaller increments (5-10 BPM) recommended"
- **AND** allow user to proceed or adjust

### Requirement: Trainer UI Integration
The system SHALL integrate trainer controls into main window and preferences without cluttering interface.

#### Scenario: Trainer section collapsible
- **WHEN** user opens main window
- **THEN** show "Tempo Trainer" section below tempo controls
- **AND** section collapsed by default (minimizes clutter)
- **WHEN** user clicks to expand
- **THEN** reveal trainer configuration controls
- **AND** show progress display if trainer active

#### Scenario: Trainer controls in preferences
- **WHEN** user opens Preferences dialog
- **THEN** show "Tempo Trainer" section with:
  - Start tempo spinner (40-240 BPM)
  - Target tempo spinner (40-240 BPM)
  - Increment spinner (-50 to +50, excluding 0)
  - Interval type dropdown (Bars / Seconds)
  - Interval value spinner (1-999)
  - "Auto-stop at target" checkbox
- **AND** all controls bound to GSettings

#### Scenario: Progress display format clarity
- **WHEN** trainer active
- **THEN** show clear progress: "Current/Target BPM"
- **AND** show next increment timing: "next +5 in X bars/seconds"
- **AND** show progress bar with percentage complete
- **AND** update progress every beat (bars) or second (time)

### Requirement: Trainer Performance
The system SHALL maintain application performance with trainer enabled.

#### Scenario: Bar-based trainer has zero overhead
- **WHEN** trainer enabled with bar-based intervals
- **AND** metronome running
- **THEN** no additional CPU usage (uses existing beat_occurred signal)
- **AND** no additional memory allocation per beat
- **AND** no impact on timing accuracy

#### Scenario: Time-based trainer minimal overhead
- **WHEN** trainer enabled with time-based intervals
- **THEN** CPU overhead < 0.1% (one timeout per second)
- **AND** memory overhead < 500 bytes
- **AND** no impact on metronome timing precision

#### Scenario: Tempo change operation fast
- **WHEN** trainer applies tempo change
- **THEN** tempo change completes in < 1ms
- **AND** no perceptible lag or glitch
- **AND** next beat plays at new tempo seamlessly

### Requirement: Trainer Error Handling
The system SHALL handle trainer errors gracefully without crashing application.

#### Scenario: Invalid configuration from settings
- **WHEN** loading trainer configuration from GSettings
- **AND** increment value is 0 (corrupted)
- **THEN** log warning with g_warning()
- **AND** fallback to default (+5 BPM)
- **AND** trainer remains disabled until user configures
- **AND** application continues normally

#### Scenario: Tempo set failure during progression
- **WHEN** trainer attempts to apply tempo change
- **AND** MetronomeEngine.set_tempo() throws exception
- **THEN** catch exception gracefully
- **AND** log error message
- **AND** pause trainer automatically
- **AND** show toast "Trainer paused due to tempo error"
- **AND** metronome continues at current tempo

### Requirement: Trainer Integration with Other Features
The system SHALL work correctly alongside subdivisions and practice timer features.

#### Scenario: Trainer with subdivisions enabled
- **WHEN** trainer active with tempo progression
- **AND** subdivisions enabled (e.g., eighth notes)
- **AND** tempo increases from 80 to 85 BPM
- **THEN** subdivisions continue playing
- **AND** subdivision timing adjusts to new tempo
- **AND** both features work correctly together

#### Scenario: Trainer with practice timer enabled
- **WHEN** trainer active (bar-based)
- **AND** practice timer enabled (count-up)
- **AND** tempo progresses from 60 to 120 BPM over 10 minutes
- **THEN** practice timer shows 10 minutes elapsed
- **AND** tempo trainer shows target reached
- **AND** both features independent and functional

#### Scenario: Trainer with practice timer auto-stop
- **WHEN** trainer active with auto-stop disabled
- **AND** practice timer auto-stop enabled (e.g., after 5 minutes)
- **AND** practice timer triggers auto-stop
- **THEN** metronome stops
- **AND** trainer pauses preserving state
- **AND** user can resume both features

### Requirement: Trainer Accessibility
The system SHALL ensure trainer feature is accessible to all users.

#### Scenario: Clear labels and descriptions
- **WHEN** user views trainer controls
- **THEN** all inputs have clear labels:
  - "Start Tempo" not just "Start"
  - "Target Tempo" not just "Target"
  - "Increase by" not just "Increment"
- **AND** tooltips explain each setting
- **AND** examples provided: "e.g., +5 BPM every 8 bars"

#### Scenario: Progress announcements for screen readers
- **WHEN** tempo increases via trainer
- **THEN** announce "Tempo increased to 85 beats per minute"
- **WHEN** target reached
- **THEN** announce "Target tempo 120 beats per minute reached"
- **WHEN** trainer paused
- **THEN** announce "Tempo Trainer paused"

#### Scenario: Keyboard navigation
- **WHEN** user navigates with keyboard
- **THEN** all trainer controls accessible via Tab
- **AND** Enter key enables/disables trainer
- **AND** spinners adjustable with arrow keys
- **AND** dropdowns openable with Space/Enter

### Requirement: Trainer Visual Feedback
The system SHALL provide clear visual indication of trainer state and progress.

#### Scenario: Active trainer visual indication
- **WHEN** trainer enabled and active
- **THEN** trainer section has accent color border
- **AND** "Trainer Active" badge displayed
- **AND** progress bar visible with percentage
- **AND** current tempo highlighted

#### Scenario: Inactive trainer appearance
- **WHEN** trainer disabled
- **THEN** trainer section greyed out
- **AND** no progress display shown
- **AND** "Enable Trainer" button prominent

#### Scenario: Tempo increment visual feedback
- **WHEN** tempo increases via trainer
- **THEN** tempo display briefly highlights/flashes
- **AND** show toast notification "Tempo increased to 85 BPM"
- **AND** progress bar updates to new percentage
- **AND** "next increment in" counter resets

