# Implementation Tasks

## Phase 1: Core Mute Pattern Infrastructure

### [x] Task 1: Create MutePattern interface
- Create `src/utils/MutePattern.vala`
- Define interface with methods: should_mute_beat(int, int), reset(), get_description()
- Add to `src/meson.build`

**Validation**: Interface compiles, can be implemented

**Dependencies**: None

---

### [x] Task 2: Implement EveryNthPattern class
- In `src/utils/MutePattern.vala`, implement EveryNthPattern
- Property: interval (int, 2-16 range)
- Implement should_mute_beat: return (beat_number % interval) == 0
- Implement get_description: return "Every {interval} beats muted"

**Validation**: Pattern correctly identifies beats 2,4,6... for interval=2

**Dependencies**: Task 1

---

### [x] Task 3: Implement RandomPercentagePattern class
- In `src/utils/MutePattern.vala`, implement RandomPercentagePattern
- Properties: percentage (double 0.0-1.0), seed (uint32)
- Use GLib.Rand with seed for pseudo-random
- Implement should_mute_beat: return random.next_double() < percentage
- Implement reset: re-seed random generator

**Validation**: ~50% beats muted over 1000 beats when percentage=0.5

**Dependencies**: Task 1

---

### [x] Task 4: Implement SpecificBeatsPattern class
- In `src/utils/MutePattern.vala`, implement SpecificBeatsPattern
- Property: muted_beats (ArrayList<int>)
- Implement should_mute_beat: check if beat_in_bar is in muted_beats list
- Handle beat wrapping: beat_in_bar = ((beat_number - 1) % beats_per_bar) + 1

**Validation**: Only beats 2 and 4 muted when list=[2,4] in 4/4 time

**Dependencies**: Task 1

---

### [x] Task 5: Implement ProgressivePattern class
- In `src/utils/MutePattern.vala`, implement ProgressivePattern
- Properties: start_percentage, end_percentage, bars_interval
- State: bars_elapsed, current_percentage
- Implement should_mute_beat: increment percentage every bars_interval
- Use random component for mute decision at current_percentage
- Implement reset: reset bars_elapsed and current_percentage

**Validation**: Percentage increases from 0% to 75% over configured intervals

**Dependencies**: Task 1

---

## Phase 2: MetronomeEngine Integration

### [x] Task 6: Add mute properties to MetronomeEngine
- Open `src/utils/MetronomeEngine.vala`
- Add property: mute_enabled (bool, default false)
- Add property: mute_pattern (MutePattern?, nullable)
- Update beat_occurred signal signature to include is_muted parameter
- Bind properties to GSettings

**Validation**: Properties accessible, signal signature updated

**Dependencies**: Task 1

---

### [x] Task 7: Implement mute decision logic
- In `MetronomeEngine`, add method: should_mute_current_beat() -> bool
- Check mute_enabled and mute_pattern existence
- Call mute_pattern.should_mute_beat(current_beat, beats_per_bar)
- Return mute decision

**Validation**: Method returns correct mute decision

**Dependencies**: Task 6

---

### [x] Task 8: Apply mute to audio playback
- In `MetronomeEngine.on_beat_timeout()`, call should_mute_current_beat()
- Always emit beat_occurred signal with is_muted flag
- Skip play_sound() call if is_muted == true
- Ensure timing loop continues regardless of mute

**Validation**: Muted beats have no audio, timing unaffected

**Dependencies**: Task 7

---

## Phase 3: Settings Schema

### [x] Task 9: Add mute settings to GSettings schema
- Open `data/io.github.tobagin.tempo.gschema.xml.in`
- Add key: mute-enabled (bool, default false)
- Add key: mute-pattern-type (string, default 'none')
- Add key: mute-interval (int, range 2-16, default 2)
- Add key: mute-percentage (double, range 0.0-1.0, default 0.5)
- Add key: mute-specific-beats (string, default '2,4')
- Add key: mute-progressive-start/end/interval (double/double/int)
- Validate schema compiles

**Validation**: All keys accessible from settings

**Dependencies**: None

---

### [x] Task 10: Create MutePatternFactory
- Create `src/utils/MutePatternFactory.vala`
- Implement static method: create_from_settings(GLib.Settings) -> MutePattern?
- Read mute-pattern-type and create appropriate pattern instance
- Load pattern-specific parameters from settings
- Return null if pattern type is 'none'
- Add to `src/meson.build`

**Validation**: Factory creates correct pattern from settings

**Dependencies**: Tasks 2-5, Task 9

---

## Phase 4: UI Controls

### [x] Task 11: Add mute toggle to main window
- Open `data/ui/main_window.blp`
- Add Gtk.Switch for mute enable/disable
- Position in accessible location (near tempo controls or collapsible section)
- Bind to GSettings mute-enabled key

**Validation**: Toggle displays, state persists

**Dependencies**: Task 9

---

### [x] Task 12: Add mute pattern selector to preferences
- Open `data/ui/preferences_dialog.blp`
- Create new "Mute Settings" page
- Add Adw.ComboRow for pattern type selection
- Options: None, Every Nth, Random, Specific Beats, Progressive
- Bind to GSettings mute-pattern-type

**Validation**: Pattern selector displays, selection persists

**Dependencies**: Task 9

---

### [x] Task 13: Add dynamic pattern parameters UI
- In `preferences_dialog.blp`, add parameter controls:
  - Adw.SpinRow for interval (visible when Every Nth selected)
  - Adw.ScaleRow for percentage (visible when Random selected)
  - Adw.EntryRow for specific beats (visible when Specific selected)
  - Multiple rows for progressive parameters
- Use visibility bindings to show only relevant parameters
- Bind each to corresponding GSettings key

**Validation**: Only relevant parameters visible, values persist

**Dependencies**: Task 12

---

### [x] Task 14: Implement pattern selection handler in PreferencesDialog
- Open `src/dialogs/PreferencesDialog.vala`
- Add handler for pattern type ComboRow changed signal
- Update parameter visibility based on selection
- Validate specific beats input (comma-separated integers)
- Create mute pattern from factory and test

**Validation**: Selecting pattern shows correct parameters

**Dependencies**: Task 10, Task 13

---

## Phase 5: Visual Feedback

### [x] Task 15: Modify MainWindow beat indicator for muted beats
- Open `src/windows/MainWindow.vala`
- Update beat_occurred signal handler to receive is_muted parameter
- Modify draw_beat_indicator() to accept is_muted flag
- Apply dimmed styling when is_muted:
  - Set opacity to 0.4
  - Draw outline only (stroke, not fill)
  - Use gray color (0.5, 0.5, 0.5)
  - Add "M" text indicator

**Validation**: Muted beats display with dimmed styling

**Dependencies**: Task 8

---

### [x] Task 16: Update beat indicator colors for mute
- In `MainWindow.vala`, define mute color constants
- Ensure muted styling distinct from normal beats
- Test with various themes (light/dark mode)
- Ensure accessibility (contrast ratio > 4.5:1)

**Validation**: Mute indicator visible in all themes

**Dependencies**: Task 15

---

## Phase 6: Pattern Loading and Application

### [x] Task 17: Load mute pattern on startup
- In `MainWindow.vala` constructor, read mute settings
- Use MutePatternFactory to create pattern from settings
- Set pattern on metronome_engine if mute_enabled
- Handle invalid settings gracefully (fall back to disabled)

**Validation**: Mute pattern restored from previous session

**Dependencies**: Task 10, Task 14

---

### [x] Task 18: Handle pattern changes during playback
- In `PreferencesDialog`, emit signal when pattern changes
- In `MainWindow`, listen for pattern change signal
- Recreate mute pattern from factory
- Set new pattern on metronome_engine
- Apply immediately if metronome running

**Validation**: Pattern changes apply without stopping metronome

**Dependencies**: Task 17

---

## Phase 7: Advanced Features

### [x] Task 19: Implement pattern reset action
- Add "Reset pattern" button in preferences or main window
- On click, call mute_pattern.reset() if pattern exists
- Reset visual feedback
- Useful for progressive pattern to restart from beginning

**Validation**: Reset button resets progressive pattern to start percentage

**Dependencies**: Task 5, Task 17

---

### [x] Task 20: Add mute preview mode
- In `PreferencesDialog`, add "Preview" button for each pattern
- On click, temporarily activate pattern for 8 bars
- Display preview indicator in UI
- Auto-stop after 8 bars, restore previous settings
- Allow manual stop with "Stop Preview" button

**Validation**: Preview plays pattern temporarily, restores settings

**Dependencies**: Task 17

---

### [x] Task 21: Implement subdivision muting (optional)
- If subdivisions feature implemented, extend mute to subdivisions
- Add setting: mute-subdivisions-only (bool)
- In MetronomeEngine, add is_subdivision parameter to should_mute
- Apply mute logic to subdivision_occurred signal
- Update visual indicator for muted subdivisions

**Validation**: Subdivisions can be muted independently

**Dependencies**: Subdivisions feature, Task 8

---

## Phase 8: Testing and Polish

### [x] Task 22: Test all mute patterns
- Test EveryNthPattern at intervals 2, 3, 4
- Test RandomPattern at percentages 25%, 50%, 75%
- Test SpecificBeatsPattern with various beat combinations
- Test ProgressivePattern progression over 100 bars
- Verify timing accuracy unaffected by muting

**Validation**: All patterns work as specified

**Dependencies**: All previous tasks

---

### [x] Task 23: Test mute with various time signatures
- Test mute patterns in 3/4, 6/8, 5/4, 7/8 time signatures
- Verify specific beats pattern respects time signature
- Test beat wrapping for specific beats beyond bar length

**Validation**: Mute works correctly in all time signatures

**Dependencies**: Task 22

---

### [x] Task 24: Performance testing
- Measure overhead of should_mute_current_beat() call
- Verify overhead < 0.1ms per beat
- Test with complex patterns (progressive + random)
- Ensure no timing drift over 1000 beats

**Validation**: Mute adds negligible performance overhead

**Dependencies**: Task 22

---

### [x] Task 25: Accessibility testing
- Test mute visual indication with screen readers
- Verify contrast ratio > 4.5:1 for muted vs audible beats
- Test with high contrast themes
- Ensure keyboard navigation works for all mute controls

**Validation**: Mute feature accessible to all users

**Dependencies**: Task 16

---

### [x] Task 26: Update CHANGELOG and documentation
- Add feature entry: "Add silent/muted beats for timing internalization training"
- Document mute patterns and use cases
- Add usage examples (e.g., "Practice with every other beat muted")
- Document keyboard shortcuts (if any)

**Validation**: Documentation complete

**Dependencies**: All feature tasks complete

---

## Notes
- Total tasks: 26
- Estimated complexity: Medium
- Dependencies: Optional dependency on subdivisions feature for Task 21
- Priority: Medium (per TODO.md)
- User impact: Medium (valuable training tool for serious musicians)
