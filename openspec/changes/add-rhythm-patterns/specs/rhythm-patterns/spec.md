# Rhythm Patterns Capability

## ADDED Requirements

### Requirement: Pattern Data Structure
The system SHALL support rhythm patterns defined as sequences of timed steps with accent levels and sound assignments.

#### Scenario: Pattern with multiple steps
- **WHEN** pattern contains 7 steps over 8 beats
- **THEN** each step has beat position, subdivision, accent level, and sound type
- **AND** steps can occur on beat (subdivision 0) or between beats
- **AND** pattern cycles when reaching length_beats

#### Scenario: Variable pattern lengths
- **WHEN** pattern length is between 1 and 64 beats
- **THEN** pattern playback repeats after length_beats
- **AND** timing accuracy maintained regardless of length
- **AND** beat counter displays position within pattern

### Requirement: Pattern JSON Serialization
The system SHALL load and save patterns in JSON format with required fields: name, description, length_beats, time_signature, and steps array.

#### Scenario: Valid JSON pattern loaded
- **WHEN** JSON file contains all required fields with valid values
- **THEN** pattern loads successfully into RhythmPattern object
- **AND** all steps are accessible
- **AND** pattern available for selection

#### Scenario: Invalid JSON rejected
- **WHEN** JSON file is malformed or missing required fields
- **THEN** display error toast "Failed to load pattern: [reason]"
- **AND** skip pattern during library loading
- **AND** continue loading remaining patterns

#### Scenario: Pattern saved to JSON
- **WHEN** user creates or edits pattern in editor
- **THEN** save to JSON with formatted indentation
- **AND** include all pattern metadata and steps
- **AND** validate JSON is parseable before saving

### Requirement: Built-in Pattern Library
The system SHALL include minimum 6 built-in rhythm patterns covering common musical genres (clave, bossa, swing).

#### Scenario: Built-in patterns loaded on startup
- **WHEN** application starts
- **THEN** load all patterns from gresource data/patterns/
- **AND** display patterns in selection UI
- **AND** patterns sorted alphabetically by name

#### Scenario: Built-in pattern immutable
- **WHEN** user attempts to edit built-in pattern
- **THEN** create copy as user pattern with "(Custom)" suffix
- **AND** save to user patterns directory
- **AND** original built-in remains unchanged

### Requirement: User Custom Patterns
The system SHALL allow users to create, edit, and delete custom patterns stored in config directory.

#### Scenario: User creates new pattern
- **WHEN** user opens pattern editor and clicks "New Pattern"
- **THEN** initialize empty pattern with default values
- **AND** allow editing name, length, time signature, steps
- **AND** save to ~/.var/app/io.github.tobagin.tempo/config/tempo/patterns/

#### Scenario: User edits existing pattern
- **WHEN** user selects user pattern and clicks "Edit"
- **THEN** load pattern into editor with all current values
- **AND** allow modifications
- **AND** overwrite JSON file on save

#### Scenario: User deletes pattern
- **WHEN** user selects user pattern and clicks "Delete"
- **THEN** show confirmation dialog "Delete pattern '[name]'?"
- **AND** remove JSON file on confirm
- **AND** remove from pattern library
- **AND** deactivate if currently active

### Requirement: Pattern Selection UI
The system SHALL provide UI control in main window to select and activate patterns.

#### Scenario: Pattern dropdown displayed
- **WHEN** user views main window
- **THEN** pattern selector shows "None" (default) and all available patterns
- **AND** dropdown sorted: None, then built-in patterns, then user patterns
- **AND** current selection highlighted

#### Scenario: Pattern activated
- **WHEN** user selects pattern from dropdown
- **THEN** switch metronome mode to pattern mode
- **AND** load pattern into PatternEngine
- **AND** display pattern name in UI
- **AND** save selection to settings as last-used-pattern

#### Scenario: Pattern deactivated
- **WHEN** user selects "None" from pattern dropdown
- **THEN** switch back to simple beat mode
- **AND** display standard beat indicator
- **AND** clear active-pattern setting

### Requirement: Pattern Playback Engine
The system SHALL schedule and play pattern steps according to pattern definition with sub-millisecond timing accuracy.

#### Scenario: Pattern plays at 120 BPM
- **WHEN** pattern active and metronome started at 120 BPM
- **THEN** schedule each step at absolute time based on beat + subdivision
- **AND** play sound with volume scaled by accent level
- **AND** emit step_occurred signal for UI updates
- **AND** loop pattern after length_beats

#### Scenario: Pattern timing precision
- **WHEN** pattern plays over 100 loops at any BPM (40-240)
- **THEN** timing drift is less than 5ms over entire duration
- **AND** each step occurs at mathematically correct time
- **AND** no accumulated timing error

#### Scenario: BPM changed during pattern playback
- **WHEN** user adjusts BPM slider while pattern playing
- **THEN** recalculate step times for new BPM
- **AND** next step occurs at new tempo
- **AND** no timing discontinuity or audio glitch

### Requirement: Accent Level Volume Mapping
The system SHALL apply volume scaling based on accent level: ghost (0.3), regular (0.7), strong (1.0).

#### Scenario: Strong accent played
- **WHEN** pattern step has accent level "strong"
- **THEN** play sound at 100% volume (1.0 multiplier)
- **AND** visual indicator shows bright color

#### Scenario: Regular accent played
- **WHEN** pattern step has accent level "regular"
- **THEN** play sound at 70% volume (0.7 multiplier)
- **AND** visual indicator shows standard color

#### Scenario: Ghost accent played
- **WHEN** pattern step has accent level "ghost"
- **THEN** play sound at 30% volume (0.3 multiplier)
- **AND** visual indicator shows dimmed color

### Requirement: Pattern Editor Dialog
The system SHALL provide grid-based pattern editor for creating and modifying patterns.

#### Scenario: Editor opened for new pattern
- **WHEN** user clicks "New Pattern" action
- **THEN** open PatternEditorDialog with empty grid
- **AND** default to 4 beats, 4/4 time signature
- **AND** show name entry, description entry, length spinner

#### Scenario: Grid cell toggled
- **WHEN** user clicks grid cell at beat 2, regular accent row
- **THEN** toggle step at that position (add if absent, remove if present)
- **AND** update cell visual state (filled vs empty)
- **AND** cell shows sound type indicator

#### Scenario: Pattern length changed
- **WHEN** user changes length spinner from 4 to 8 beats
- **THEN** resize grid to show 8 columns
- **AND** preserve existing steps within new length
- **AND** remove steps beyond new length if decreased

#### Scenario: Pattern time signature changed
- **WHEN** user changes time signature to 3/4
- **THEN** update pattern time_signature fields
- **AND** adjust beat grouping visual in grid
- **AND** maintain existing step positions

#### Scenario: Pattern preview
- **WHEN** user clicks "Preview" button in editor
- **THEN** temporarily play pattern at current BPM
- **AND** highlight current step in grid
- **AND** stop preview when button clicked again

#### Scenario: Pattern saved from editor
- **WHEN** user clicks "Save" with valid pattern name
- **THEN** serialize pattern to JSON
- **AND** save to user patterns directory
- **AND** add to pattern library
- **AND** close editor dialog
- **AND** show success toast "Pattern '[name]' saved"

### Requirement: Pattern Mode Switching
The system SHALL switch between simple beat mode and pattern mode based on active pattern selection.

#### Scenario: Switch to pattern mode
- **WHEN** user selects pattern from dropdown
- **THEN** stop current playback if running
- **AND** switch internal engine to PatternEngine
- **AND** update UI to show pattern controls
- **AND** display pattern name

#### Scenario: Switch to simple mode
- **WHEN** user selects "None" or deactivates pattern
- **THEN** switch internal engine to MetronomeEngine
- **AND** update UI to show standard beat controls
- **AND** hide pattern-specific elements

#### Scenario: Mode switch during playback
- **WHEN** metronome running and user switches modes
- **THEN** stop current playback gracefully
- **AND** reset beat counter to 1
- **AND** user must press play to resume in new mode

### Requirement: Pattern Visual Feedback
The system SHALL display pattern name and current position when pattern active.

#### Scenario: Pattern name displayed
- **WHEN** pattern is active
- **THEN** show pattern name below or near tempo display
- **AND** truncate long names to fit UI
- **AND** tooltip shows full name on hover

#### Scenario: Pattern position indicator
- **WHEN** pattern playing
- **THEN** beat indicator shows current beat and pattern length (e.g., "3/8")
- **AND** indicator resets to 1 on pattern loop
- **AND** accent level reflected in indicator color

#### Scenario: Pattern step visualization
- **WHEN** pattern playing with multiple steps per beat
- **THEN** visual indicator pulses for each step
- **AND** pulse intensity matches accent level
- **AND** different color for strong/regular/ghost accents

### Requirement: Pattern Audio Quality
The system SHALL pre-load pattern sounds and maintain low-latency playback during pattern execution.

#### Scenario: Sounds pre-loaded on activation
- **WHEN** pattern selected and activated
- **THEN** load all sound types used in pattern
- **AND** initialize separate GStreamer players for each accent level
- **AND** ready for playback before first step

#### Scenario: No audio glitches during pattern
- **WHEN** pattern plays with rapid step sequences
- **THEN** each step plays cleanly without cuts or glitches
- **AND** latency remains under 10ms for each step
- **AND** no audio buffer underruns

### Requirement: Pattern Library Limits
The system SHALL limit user patterns to maximum 100 entries to prevent storage bloat and UI clutter.

#### Scenario: User pattern limit enforced
- **WHEN** user attempts to save 101st pattern
- **THEN** display error toast "Maximum 100 custom patterns reached"
- **AND** suggest deleting unused patterns
- **AND** do not save new pattern

#### Scenario: Pattern name uniqueness
- **WHEN** user saves pattern with name matching existing pattern
- **THEN** append number to make unique (e.g., "Pattern (2)")
- **AND** save with unique name
- **AND** show toast "Saved as '[unique-name]'"

### Requirement: Pattern Step Validation
The system SHALL validate pattern steps have valid beat positions, subdivisions, and accent levels before playback.

#### Scenario: Step beat out of range
- **WHEN** pattern step specifies beat >= length_beats
- **THEN** wrap beat to valid range (beat % length_beats)
- **AND** log warning about invalid step
- **AND** play step at wrapped position

#### Scenario: Invalid accent level
- **WHEN** pattern step has unknown accent level
- **THEN** default to "regular" accent level
- **AND** log warning
- **AND** continue playback

#### Scenario: Invalid sound type
- **WHEN** pattern step references non-existent sound type
- **THEN** fall back to "high" sound
- **AND** log warning
- **AND** play step with fallback sound

### Requirement: Pattern Performance
The system SHALL load and manage pattern library with minimal memory overhead and fast access times.

#### Scenario: Pattern library loads quickly
- **WHEN** application starts with 100+ patterns
- **THEN** all patterns load in under 500ms
- **AND** UI remains responsive during loading

#### Scenario: Pattern memory footprint
- **WHEN** 100 patterns loaded (built-in + user)
- **THEN** total memory usage for patterns under 500KB
- **AND** no memory leaks over extended use
