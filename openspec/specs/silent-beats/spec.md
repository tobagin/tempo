# silent-beats Specification

## Purpose
TBD - created by archiving change add-silent-beats. Update Purpose after archive.
## Requirements
### Requirement: Mute Pattern Interface
The system SHALL provide multiple mute patterns to determine which beats are silenced: Every Nth, Random Percentage, Specific Beats, and Progressive.

#### Scenario: Every Nth pattern mutes regularly
- **WHEN** mute pattern set to "Every 2nd beat"
- **THEN** beats 2, 4, 6, 8, etc. are muted
- **AND** beats 1, 3, 5, 7, etc. are audible
- **AND** visual indicator shows all beats, muted ones dimmed

#### Scenario: Every 3rd pattern
- **WHEN** mute pattern set to "Every 3rd beat"
- **THEN** beats 3, 6, 9, 12, etc. are muted
- **AND** two audible beats followed by one muted beat

#### Scenario: Random pattern mutes unpredictably
- **WHEN** mute pattern set to "Random 50%"
- **THEN** approximately 50% of beats over 100 beats are muted
- **AND** mute distribution is pseudo-random
- **AND** same seed produces same mute sequence

#### Scenario: Specific beats pattern
- **WHEN** mute pattern set to "Beats 2 and 4"
- **THEN** only beats 2 and 4 of each bar are muted
- **AND** beat 1, 3 (in 4/4) are audible
- **AND** pattern respects time signature

### Requirement: Visual Feedback for Muted Beats
The system SHALL display visual indication for muted beats using dimmed styling, maintaining beat indicator for timing reference.

#### Scenario: Muted beat shows dimmed
- **WHEN** beat is muted (no audio)
- **THEN** beat indicator displays with 40% opacity
- **AND** outline-only circle instead of filled
- **AND** uses gray color instead of normal color

#### Scenario: Muted beat displays "M" indicator
- **WHEN** beat is muted
- **THEN** small "M" text or icon shown in indicator
- **AND** indicator size/position unchanged
- **AND** mute indicator visible but not distracting

#### Scenario: Audible beat shows normally
- **WHEN** beat is not muted
- **THEN** indicator displays with standard styling
- **AND** normal color (blue/red for downbeat)
- **AND** filled circle

### Requirement: Mute Toggle Control
The system SHALL provide UI toggle to enable/disable mute mode without changing pattern configuration.

#### Scenario: Mute enabled
- **WHEN** user toggles "Mute beats" switch on
- **THEN** mute_enabled property set to true
- **AND** current mute pattern applied immediately
- **AND** setting persisted to GSettings

#### Scenario: Mute disabled
- **WHEN** user toggles "Mute beats" switch off
- **THEN** mute_enabled property set to false
- **AND** all beats audible
- **AND** visual indicators return to normal styling

#### Scenario: Mute toggled during playback
- **WHEN** metronome running and user toggles mute
- **THEN** change applies on next beat
- **AND** no audio glitches or timing disruption
- **AND** visual updates immediately

### Requirement: Mute Pattern Selection UI
The system SHALL provide dropdown or radio buttons to select mute pattern type with dynamic parameter controls.

#### Scenario: Pattern dropdown populated
- **WHEN** user views mute settings
- **THEN** dropdown shows: None, Every Nth, Random, Specific Beats, Progressive
- **AND** current selection highlighted
- **AND** pattern description displayed

#### Scenario: Every Nth selected shows interval parameter
- **WHEN** user selects "Every Nth" pattern
- **THEN** display interval spinner (range 2-16)
- **AND** default value 2
- **AND** hide parameters for other patterns

#### Scenario: Random selected shows percentage parameter
- **WHEN** user selects "Random" pattern
- **THEN** display percentage slider (0-100%)
- **AND** default value 50%
- **AND** hide parameters for other patterns

#### Scenario: Specific Beats selected shows beat entry
- **WHEN** user selects "Specific Beats" pattern
- **THEN** display comma-separated beat entry field
- **AND** default value "2,4"
- **AND** validate input is comma-separated integers

#### Scenario: Progressive selected shows start/end/interval parameters
- **WHEN** user selects "Progressive" pattern
- **THEN** display start percentage slider (0-100%)
- **AND** display end percentage slider (0-100%)
- **AND** display bars interval spinner (1-64)
- **AND** defaults: start=0%, end=75%, interval=16 bars

### Requirement: Mute Audio Suppression
The system SHALL prevent audio playback for muted beats while maintaining timing loop and visual feedback.

#### Scenario: Muted beat has no audio
- **WHEN** beat is determined to be muted by pattern
- **THEN** skip play_sound() call
- **AND** beat_occurred signal still emitted with is_muted=true
- **AND** timing loop continues normally
- **AND** no audio glitch or pop

#### Scenario: Audible beat plays normally
- **WHEN** beat is not muted
- **THEN** play appropriate sound (high for downbeat, low for regular)
- **AND** beat_occurred signal emitted with is_muted=false

#### Scenario: Downbeat can be muted
- **WHEN** downbeat (beat 1) determined to be muted
- **THEN** no high sound plays
- **AND** visual indicator still shows downbeat (dimmed)
- **AND** beat counter increments normally

### Requirement: Progressive Pattern Behavior
The system SHALL gradually increase mute percentage over time for progressive pattern, starting from start_percentage and reaching end_percentage.

#### Scenario: Progressive starts at 0%
- **WHEN** progressive pattern active with start=0%, end=75%, interval=16 bars
- **THEN** first 16 bars have 0% muted (all audible)
- **AND** after 16 bars, mute percentage increases
- **AND** continues increasing every 16 bars

#### Scenario: Progressive reaches target
- **WHEN** sufficient bars elapsed to reach end_percentage
- **THEN** mute percentage caps at end_percentage
- **AND** does not exceed end_percentage
- **AND** remains at end_percentage for remainder of session

#### Scenario: Progressive resets on stop
- **WHEN** metronome stopped and restarted
- **THEN** progressive pattern resets to start_percentage
- **AND** progression starts from beginning
- **AND** bars_elapsed counter reset to 0

### Requirement: Random Pattern Reproducibility
The system SHALL use pseudo-random generation with seed for random pattern, allowing reproducible mute sequences.

#### Scenario: Same seed produces same sequence
- **WHEN** random pattern initialized with seed 12345
- **THEN** first 100 beats produce specific mute sequence
- **AND** resetting pattern with same seed produces identical sequence
- **AND** reproducible across sessions

#### Scenario: Different seed produces different sequence
- **WHEN** random pattern initialized with seed 67890
- **THEN** mute sequence differs from seed 12345
- **AND** distribution still matches target percentage

#### Scenario: Random pattern reset
- **WHEN** user resets metronome or restarts playback
- **THEN** random pattern re-seeds
- **AND** mute sequence starts from beginning
- **AND** reproducible if seed unchanged

### Requirement: Specific Beats Pattern Validation
The system SHALL validate specific beats input and handle beat numbers relative to time signature.

#### Scenario: Valid beats accepted
- **WHEN** user enters "2,4" for specific beats in 4/4 time
- **THEN** beats 2 and 4 of each bar are muted
- **AND** pattern cycles with time signature

#### Scenario: Beats beyond time signature wrapped
- **WHEN** user enters "5" for specific beats in 4/4 time (4 beats per bar)
- **THEN** treat beat 5 as beat 1 of next bar (wrap)
- **AND** display warning "Beat 5 exceeds time signature, using beat 1"

#### Scenario: Invalid input rejected
- **WHEN** user enters non-numeric or invalid input
- **THEN** display error "Invalid beat numbers"
- **AND** fall back to previous valid pattern
- **AND** do not save invalid input

#### Scenario: Empty beats list
- **WHEN** user enters empty string for specific beats
- **THEN** treat as no beats muted (all audible)
- **AND** equivalent to mute disabled

### Requirement: Mute Settings Persistence
The system SHALL persist mute configuration (enabled, pattern type, parameters) across application restarts.

#### Scenario: Mute settings saved
- **WHEN** user configures mute pattern and parameters
- **THEN** save to GSettings immediately
- **AND** settings include: mute-enabled, mute-pattern-type, pattern-specific parameters

#### Scenario: Mute settings restored
- **WHEN** application starts
- **THEN** load mute settings from GSettings
- **AND** reconstruct mute pattern with saved parameters
- **AND** apply pattern if mute_enabled is true

#### Scenario: Invalid saved settings handled
- **WHEN** saved mute settings are corrupted or invalid
- **THEN** log warning
- **AND** fall back to default (mute disabled)
- **AND** do not crash

### Requirement: Mute Pattern Change During Playback
The system SHALL allow changing mute pattern while metronome is running, applying change on next beat.

#### Scenario: Pattern changed mid-playback
- **WHEN** metronome running and user selects different mute pattern
- **THEN** new pattern applies starting next beat
- **AND** no timing disruption
- **AND** visual indicator updates immediately

#### Scenario: Pattern parameters adjusted mid-playback
- **WHEN** metronome running and user adjusts mute interval from 2 to 3
- **THEN** new interval applies starting next beat
- **AND** pattern recalculated with new parameter

#### Scenario: Pattern reset mid-playback
- **WHEN** user clicks "Reset pattern" while playing
- **THEN** pattern state resets (e.g., progressive back to start_percentage)
- **AND** beat counter continues from current position
- **AND** no audio glitch

### Requirement: Subdivision Muting Support
The system SHALL allow muting subdivisions independently from main beats when subdivision mode active.

#### Scenario: Mute applies to subdivisions
- **WHEN** subdivision mode active (e.g., eighth notes) and mute pattern set
- **THEN** mute pattern can silence subdivision clicks
- **AND** main beats remain audible if not muted by pattern
- **AND** visual indicator shows muted subdivisions dimmed

#### Scenario: Separate mute for subdivisions
- **WHEN** setting "Mute subdivisions only" enabled
- **THEN** mute pattern applies only to subdivision clicks (not main beats)
- **AND** main beats always audible
- **AND** subdivisions follow mute pattern

#### Scenario: Mute both beats and subdivisions
- **WHEN** mute pattern active for both beats and subdivisions
- **THEN** pattern applies to all clicks (beats + subdivisions)
- **AND** visual indicator shows all muted clicks dimmed

### Requirement: Mute Performance
The system SHALL determine mute status for each beat with negligible performance impact (< 0.1ms overhead).

#### Scenario: Mute decision is fast
- **WHEN** beat callback executes with mute pattern active
- **THEN** should_mute_beat() completes in under 0.1ms
- **AND** does not affect timing accuracy
- **AND** no measurable latency increase

#### Scenario: Complex pattern maintains performance
- **WHEN** progressive pattern with random component active
- **THEN** beat processing time remains consistent
- **AND** timing precision maintained
- **AND** no CPU spikes

### Requirement: Mute UI Accessibility
The system SHALL provide clear visual distinction between muted and audible beats for accessibility.

#### Scenario: High contrast mute indication
- **WHEN** beat is muted
- **THEN** visual contrast ratio > 4.5:1 between muted and audible beats
- **AND** distinct shape difference (outline vs filled)
- **AND** accessible to users with low vision

#### Scenario: Mute status announced
- **WHEN** screen reader active and beat muted
- **THEN** announce "Beat X muted" or similar
- **AND** audible beats announced normally
- **AND** pattern description available in accessibility tree

### Requirement: Mute Preview Mode
The system SHALL provide preview mode to test mute pattern before applying during practice.

#### Scenario: Preview pattern in preferences
- **WHEN** user clicks "Preview" button for mute pattern
- **THEN** temporarily activate pattern for 8 bars
- **AND** display preview indicator
- **AND** automatically stop after 8 bars
- **AND** restore previous settings

#### Scenario: Preview stopped early
- **WHEN** user clicks "Stop Preview" during preview
- **THEN** immediately stop preview playback
- **AND** restore previous settings
- **AND** hide preview indicator

