# Implementation Tasks

## Phase 1: Core Subdivision Engine (MetronomeEngine)

### Task 1: Add subdivision data structures and enums
- [x] Open `src/utils/MetronomeEngine.vala`
- [x] Add `SubdivisionMode` enum with values: NONE(0), EIGHTH(2), SIXTEENTH(4), TRIPLET(3)
- [x] Add public property: `subdivision_mode` (default: NONE)
- [x] Add public property: `subdivision_volume` (range 0.0-1.0, default: 0.5)
- [x] Add private property: `subdivisions_per_beat` (int, calculated from mode)
- [x] Add private property: `current_subdivision_index` (int, tracks position within beat)
- [x] Add private property: `next_subdivision_time` (int64, absolute time for next click)
- [x] Add signal: `subdivision_occurred(int beat_number, int subdivision_index, int subdivisions_per_beat)`

**Validation**: File compiles, new properties accessible, signal defined

**Dependencies**: None

---

### Task 2: Implement subdivision timing calculation
- [x] Add method: `calculate_subdivision_duration(int subdivision_index) -> double`
- [x] For NONE mode: return full `beat_duration`
- [x] For EIGHTH mode: return `beat_duration / 2.0`
- [x] For SIXTEENTH mode: return `beat_duration / 4.0`
- [x] For TRIPLET mode: return `beat_duration / 3.0`
- [x] Add method: `update_subdivisions_per_beat()` to sync with mode
- [x] Connect subdivision_mode property change to update method

**Validation**:
- At 120 BPM (0.5s beats): eighths = 0.25s, sixteenths = 0.125s, triplets = 0.167s
- Calculations precise to microsecond level

**Dependencies**: Task 1

---

### Task 3: Refactor timing loop for subdivisions
- [x] Rename `on_beat_timeout()` to `on_click_timeout()`
- [x] Rename `schedule_next_beat()` to `schedule_next_click()`
- [x] Rename `next_beat_time` to `next_subdivision_time` (or keep both)
- [x] Modify `on_click_timeout()` to check if `current_subdivision_index == 0`
- [x] If index == 0: main beat logic (increment beat, emit beat_occurred)
- [x] If index > 0: subdivision logic (emit subdivision_occurred)
- [x] Increment `current_subdivision_index` after each click
- [x] Reset index to 0 when reaching `subdivisions_per_beat`
- [x] Calculate next click time using `calculate_subdivision_duration()`

**Validation**:
- With NONE mode: behavior identical to current implementation
- With EIGHTH mode: 2 clicks per beat fired correctly
- Beat numbers increment only on main beats (index == 0)

**Dependencies**: Task 1, Task 2

---

### Task 4: Initialize subdivision state on start/stop
- [x] Modify `start()` method: initialize `current_subdivision_index = 0`
- [x] Set `subdivisions_per_beat` based on current `subdivision_mode`
- [x] Calculate first click time (always a main beat)
- [x] Modify `stop()` method: reset `current_subdivision_index = 0`
- [x] Modify `reset_beat_counter()`: reset subdivision index as well

**Validation**:
- Starting metronome always begins on main beat (index 0)
- Stopping and restarting resets subdivision state

**Dependencies**: Task 3

---

### Task 5: Handle subdivision mode changes during playback
- [x] Add property change handler for `subdivision_mode`
- [x] If metronome running: flag to apply change on next main beat
- [x] Reset `current_subdivision_index` to 0 on mode change
- [x] Update `subdivisions_per_beat` immediately
- [x] Emit signal for UI notification (mode change toast)

**Validation**:
- Mode change while stopped: applies immediately on next start
- Mode change while running: transitions cleanly at next beat boundary

**Dependencies**: Task 3, Task 4

---

## Phase 2: Subdivision Audio System

### Task 6: Create subdivision audio player
- [x] In `initialize_audio()`: create third playbin element `subdivision_sound_player`
- [x] Check for null and handle creation failure gracefully
- [x] Set default URI to low.wav sound file
- [x] Add to audio_initialized checks

**Validation**: Third GStreamer player initializes successfully alongside high/low players

**Dependencies**: None (parallelizable with Phase 1)

---

### Task 7: Implement subdivision sound playback
- [x] Add method: `play_subdivision_click()`
- [x] Load sound based on `subdivision-sound-type` setting (similar to `get_sound_uri()`)
- [x] Apply `subdivision_volume` setting to player
- [x] Set state to NULL then PLAYING (same as main beats)
- [x] Add timeout to stop after 200ms (prevent overlap)
- [x] Call `play_subdivision_click()` from `on_click_timeout()` when index > 0

**Validation**:
- Subdivision clicks audibly quieter than main beats
- Sounds play at correct timing (verified with audio analysis tool)

**Dependencies**: Task 3, Task 6

---

### Task 8: Implement subdivision sound selection
- [x] Extend `get_sound_uri()` to accept `is_subdivision` parameter
- [x] Add logic to check `subdivision-sound-type` setting when is_subdivision == true
- [x] Support same sound types as main beats: default, woodblock, metal, digital
- [x] Fallback to low.wav if subdivision sound file missing

**Validation**: Each sound type works for subdivisions, fallback behavior correct

**Dependencies**: Task 7

---

### Task 9: Handle audio overlap at fast tempos
- [x] Add method: `calculate_max_sound_duration()` based on tempo and subdivision mode
- [x] At 240 BPM with 16ths: max duration ~50ms
- [x] If sound file longer than safe duration: truncate playback earlier
- [x] Optionally reduce subdivision volume by additional 10% at fast tempos (>200 BPM)

**Validation**: No audible overlap at 240 BPM with 16th notes

**Dependencies**: Task 7

---

## Phase 3: Settings Integration

### Task 10: Add GSettings schema keys for subdivisions
- [x] Open `data/io.github.tobagin.tempo.gschema.xml.in`
- [x] Add `subdivision-mode` integer key (range 0-4, default 0)
- [x] Add `subdivision-volume` double key (range 0.0-1.0, default 0.5)
- [x] Add `subdivision-sound-type` string key (default "default")
- [x] Add `show-subdivision-indicators` boolean key (default true)
- [x] Add proper summaries and descriptions for each

**Validation**: Schema compiles, settings visible in dconf-editor

**Dependencies**: None (parallelizable)

---

### Task 11: Bind subdivision settings in MetronomeEngine
- [x] In MetronomeEngine constructor: bind `subdivision_mode` to setting
- [x] Bind `subdivision_volume` to setting
- [x] Read `subdivision-sound-type` in `get_sound_uri()` when needed
- [x] Add validation: if mode invalid (< 0 or > 4), fallback to 0 with warning
- [x] Add validation: if volume invalid, clamp to 0.0-1.0 range

**Validation**:
- Settings changes immediately reflect in metronome behavior
- Invalid settings handled gracefully

**Dependencies**: Task 1, Task 10

---

## Phase 4: Visual Indicators

### Task 12: Add subdivision indicator drawing to MainWindow
- [x] Open `src/windows/MainWindow.vala`
- [x] Add method: `draw_subdivision_indicators(Cairo.Context cr, int subdiv_index)`
- [x] Calculate dot positions based on `subdivision_mode`:
  - EIGHTH: 1 dot at 180° (opposite main beat)
  - SIXTEENTH: 3 dots at 90°, 180°, 270°
  - TRIPLET: 2 dots at 120°, 240° (uneven spacing)
- [x] Draw inactive dots at 3px radius, subtle color (0.5 opacity)
- [x] Draw active dot (matching subdiv_index) at 6px radius, accent color
- [x] Call drawing method from main beat indicator draw function

**Validation**:
- Dots appear at correct positions for each mode
- Active dot highlights match audio timing

**Dependencies**: None (parallelizable with Phase 1-3)

---

### Task 13: Connect subdivision signals to visual updates
- [x] Connect to MetronomeEngine's `subdivision_occurred` signal
- [x] Implement handler: `on_subdivision_occurred(int beat, int subdiv_index, int subdivs_per_beat)`
- [x] Store current `subdiv_index` in MainWindow state
- [x] Trigger redraw of beat indicator area
- [x] Connect to `beat_occurred` signal: reset subdiv_index to 0 on main beats

**Validation**:
- Subdivision indicators pulse in sync with audio
- Visual timing matches audio timing (no lag)

**Dependencies**: Task 12, Task 3 (for signal emission)

---

### Task 14: Implement subdivision indicator visibility toggle
- [x] Read `show-subdivision-indicators` setting in MainWindow
- [x] Skip drawing subdivision indicators when setting is false
- [x] Add property binding to automatically update on setting change
- [x] Ensure main beat indicator continues normally when indicators hidden

**Validation**:
- Toggle works in real-time
- Audio continues regardless of visual setting

**Dependencies**: Task 12, Task 10

---

## Phase 5: UI Controls

### Task 15: Add subdivision mode selector to main window Blueprint
- [x] Open `data/ui/main_window.blp`
- [x] Add `AdwComboRow` for subdivision mode after tempo controls
- [x] Set options:
  - "None" (value 0)
  - "Eighth Notes (2 per beat)" (value 2)
  - "Sixteenth Notes (4 per beat)" (value 4)
  - "Triplets (3 per beat)" (value 3)
- [x] Bind to `subdivision-mode` GSettings key
- [x] Add tooltip: "Hear subdivisions within each beat"

**Validation**: Dropdown appears, options selectable, changes saved to settings

**Dependencies**: Task 10

---

### Task 16: Connect main window subdivision selector
- [x] In `src/windows/MainWindow.vala`: add template child for subdivision combo
- [x] Connect combo change signal to settings
- [x] If metronome running: show toast "Subdivision mode changed to [mode]"
- [x] Ensure setting updates MetronomeEngine via binding

**Validation**:
- Selecting mode updates metronome behavior
- Toast appears on change during playback

**Dependencies**: Task 15, Task 11

---

### Task 17: Add subdivision preferences section
- [x] Open `data/ui/preferences_dialog.blp`
- [x] Add `AdwPreferencesGroup` titled "Subdivisions"
- [x] Add `AdwComboRow` for subdivision mode (same as main window)
- [x] Add `AdwSpinRow` for subdivision volume (0-100%, step 5%)
- [x] Add `AdwComboRow` for subdivision sound type (default, woodblock, metal, digital)
- [x] Add `AdwSwitchRow` for "Show subdivision indicators"
- [x] Bind all controls to GSettings keys

**Validation**: All controls functional, changes persist

**Dependencies**: Task 10

---

### Task 18: Add subdivision volume conversion
- [x] GSettings stores volume as 0.0-1.0 double
- [x] UI displays as 0-100% integer
- [x] Add conversion helpers in PreferencesDialog
- [x] Spin row adjustment factor: setting_value * 100 (display), value / 100 (save)

**Validation**: Volume shows as percentage, stores as decimal

**Dependencies**: Task 17

---

## Phase 6: Testing & Validation

### Task 19: Unit test subdivision timing calculations
- [x] Create test cases for `calculate_subdivision_duration()`
- [x] Test at 120 BPM: eighths=0.25s, sixteenths=0.125s, triplets=0.167s
- [x] Test at 40 BPM (slowest): verify spacing
- [x] Test at 240 BPM (fastest): verify no overflow
- [x] Test triplet precision: verify 1:1:1 ratio within 0.1ms

**Validation**: All timing calculations accurate to microsecond level

**Dependencies**: Task 2

---

### Task 20: Integration test audio synchronization
- [x] Enable subdivisions, start metronome
- [x] Record audio output to file
- [x] Analyze waveform: verify click spacing matches expected intervals
- [x] Test at multiple tempos: 60, 120, 180, 240 BPM
- [x] Test all subdivision modes
- [x] Verify no drift over 5-minute sessions

**Validation**: Audio timing matches specification within 1ms tolerance

**Dependencies**: Task 7, Task 9

---

### Task 21: Integration test visual synchronization
- [x] Enable subdivisions with visual indicators
- [x] Record screen with audio
- [x] Verify visual pulses match audio clicks (< 16ms lag for 60fps)
- [x] Test at fast tempo (200 BPM, 16ths): verify smooth animation

**Validation**: Visual feedback synchronized with audio

**Dependencies**: Task 13

---

### Task 22: Manual testing comprehensive checklist
- [x] Test NONE mode: verify unchanged behavior
- [x] Test EIGHTH mode at 60, 120, 180 BPM
- [x] Test SIXTEENTH mode at 60, 120, 180, 240 BPM
- [x] Test TRIPLET mode at 60, 120, 180 BPM
- [x] Change mode while stopped: verify applies on start
- [x] Change mode while running: verify smooth transition
- [x] Change tempo with subdivisions active: verify recalculation
- [x] Test in multiple time signatures: 4/4, 3/4, 6/8, 5/4, 7/8
- [x] Test subdivision volume slider: verify audible difference
- [x] Test subdivision sound types: verify each type plays
- [x] Toggle visual indicators: verify on/off behavior
- [x] Test at minimum tempo (40 BPM): verify no issues
- [x] Test at maximum tempo (240 BPM): verify no overlap/jitter
- [x] Restart app: verify subdivision settings persist

**Validation**: All manual tests pass, no regressions

**Dependencies**: All previous implementation tasks

---

### Task 23: Performance profiling
- [x] Run metronome at 240 BPM with 16th notes for 10 minutes
- [x] Profile CPU usage: verify < 2% overhead vs no subdivisions
- [x] Profile memory usage: verify < 2KB increase
- [x] Measure timing drift: verify < 1ms accumulated error
- [x] Verify audio latency unchanged (< 10ms)
- [x] Check for memory leaks using valgrind (if available)

**Validation**: Performance meets specification targets

**Dependencies**: Task 22

---

### Task 24: Edge case testing
- [x] Test triplets in 6/8 time (compound meter)
- [x] Test triplets in 4/4 time (simple meter)
- [x] Test mode change mid-subdivision (beat 2, subdiv 3)
- [x] Test very fast tempo change (120→240 BPM instantly)
- [x] Test very slow tempo change (240→40 BPM instantly)
- [x] Test corrupted settings (mode = 99, volume = -5.0)
- [x] Test missing subdivision sound file
- [x] Test audio system failure with subdivisions
- [x] Test rapid mode toggling (None→8ths→16ths→Triplets→None in 2 seconds)

**Validation**: All edge cases handled gracefully, no crashes

**Dependencies**: Task 22

---

### Task 25: Accessibility testing
- [x] Test with screen reader (Orca): verify labels announced
- [x] Test with high contrast theme: verify indicators visible
- [x] Test with very low subdivision volume (0.1): verify still audible
- [x] Test with very high subdivision volume (1.0): verify not distorted
- [x] Test keyboard navigation: verify all controls accessible
- [x] Test with large UI text size: verify layout not broken

**Validation**: Accessible to users with various needs

**Dependencies**: Task 22

---

## Phase 7: Documentation & Polish

### Task 26: Code review and cleanup
- [x] Review all code for project conventions (PascalCase, snake_case)
- [x] Verify no file exceeds 500 lines (split if needed)
- [x] Add comprehensive comments explaining subdivision logic
- [x] Document subdivision timing algorithm with examples
- [x] Verify error handling comprehensive (all edge cases covered)
- [x] Remove debug logging statements
- [x] Check all GSettings keys have proper descriptions

**Validation**: Code meets project style guidelines

**Dependencies**: All implementation tasks

---

### Task 27: Update CHANGELOG.md
- [x] Add entry under "## [Unreleased]" section
- [x] Document major feature: "Added subdivision support"
- [x] List subdivision modes: eighth notes, sixteenth notes, triplets
- [x] Note customizable volume and sound type
- [x] Mention visual indicators
- [x] Document new settings keys
- [x] Note performance characteristics (no timing impact)

**Validation**: CHANGELOG accurately reflects all changes

**Dependencies**: Task 26

---

### Task 28: Update user-facing documentation (if exists)
- [x] Add subdivision feature to README.md features list
- [x] Explain what subdivisions are for musicians
- [x] Document how to enable/use subdivisions
- [x] Add screenshots of subdivision indicators (if applicable)
- [x] Document subdivision settings in preferences

**Validation**: Documentation clear for end users

**Dependencies**: Task 26

---

## Estimated Effort

- **Phase 1 (Core Engine)**: 8-12 hours
- **Phase 2 (Audio System)**: 4-6 hours
- **Phase 3 (Settings)**: 2-3 hours
- **Phase 4 (Visual Indicators)**: 4-6 hours
- **Phase 5 (UI Controls)**: 3-4 hours
- **Phase 6 (Testing)**: 8-12 hours
- **Phase 7 (Documentation)**: 2-3 hours

**Total Estimated Effort**: 31-46 hours

## Parallelization Opportunities

These tasks can be worked on in parallel:

- **Track A (Core)**: Phase 1 → Phase 2 → Integration
- **Track B (UI)**: Phase 4 → Phase 5 → Testing
- **Track C (Settings)**: Phase 3 → Testing
- **Track D (Documentation)**: Can start alongside implementation

## Success Criteria

All tasks completed AND:
- ✅ Subdivisions play with precise timing at all tempos (40-240 BPM)
- ✅ Eighth notes, sixteenth notes, and triplets all work correctly
- ✅ Subdivision volume audibly lighter than main beats
- ✅ Visual indicators synchronized with audio
- ✅ No timing regressions (sub-millisecond accuracy maintained)
- ✅ All manual, integration, and edge case tests pass
- ✅ Performance targets met (< 2% CPU, < 2KB memory)
- ✅ Settings persist across app restarts
- ✅ UI clean and intuitive
- ✅ Code follows project conventions
- ✅ Documentation updated

## Dependencies on Other Features

- **None**: This feature is independent
- **Benefits from**: Recently added sound type selection (v1.4.0)
- **Foundation for**: Future rhythm patterns feature (#6) and polyrhythms (#10)
