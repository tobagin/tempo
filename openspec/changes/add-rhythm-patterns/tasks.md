# Implementation Tasks

## Phase 1: Core Pattern Data Structure

### Task 1: Create RhythmPattern class with JSON support
- Create `src/utils/RhythmPattern.vala`
- Define `RhythmPattern` class with properties: name, description, length_beats, time_signature_numerator, time_signature_denominator
- Define `PatternStep` class with properties: beat, subdivision, accent (enum), sound_type
- Define `AccentLevel` enum: GHOST, REGULAR, STRONG
- Implement `from_json_file(string path)` static method using Json.Parser
- Implement `to_json_file(string path)` method using Json.Generator
- Implement `get_steps_at_beat(int beat)` method
- Add to `src/meson.build`

**Validation**: File compiles, JSON parsing/generation works with test file

**Dependencies**: None

---

### Task 2: Create PatternLibrary manager
- Create `src/utils/PatternLibrary.vala`
- Implement HashMap storage for built-in and user patterns
- Implement `load_built_in_patterns()` - iterate gresource `/io/github/tobagin/tempo/patterns/`
- Implement `load_user_patterns()` - iterate `~/.var/app/.../config/tempo/patterns/`
- Implement `get_all_patterns()` returning sorted list (built-in first, then user)
- Implement `save_user_pattern()` - save to user patterns directory
- Implement `delete_user_pattern()` - remove JSON file
- Add pattern count limit (100 user patterns)
- Add to `src/meson.build`

**Validation**: Can load patterns from both sources, save/delete user patterns

**Dependencies**: Task 1

---

## Phase 2: Pattern Playback Engine

### Task 3: Create PatternEngine class
- Create `src/utils/PatternEngine.vala`
- Add properties: active_pattern, is_running, current_beat, bpm
- Add timing state: next_step_time, pattern_position, subdivisions_per_beat
- Add audio players: strong_player, regular_player, ghost_player
- Define signals: step_occurred(PatternStep, int), pattern_loop_completed()
- Implement `start()` method - initialize timing, schedule first step
- Implement `stop()` method - cancel timeout, reset state
- Implement `set_pattern()` method - load pattern and pre-calculate step times
- Add to `src/meson.build`

**Validation**: Engine instantiates, pattern can be set

**Dependencies**: Task 1, Task 2

---

### Task 4: Implement pattern timing logic
- In `PatternEngine`, add `calculate_step_time(PatternStep step) -> int64` method
- Calculate absolute time for step based on beat + subdivision + BPM
- Add `on_step_timeout() -> bool` callback method
- Get current pattern step from pattern_position
- Play sound with accent level volume scaling (ghost=0.3, regular=0.7, strong=1.0)
- Emit step_occurred signal
- Increment pattern_position, wrap to pattern length
- Schedule next step using GLib.Timeout
- Handle pattern loop completion (emit signal when wrapping to beat 0)

**Validation**: Pattern plays with correct timing, steps occur at right intervals

**Dependencies**: Task 3

---

### Task 5: Initialize audio players with accent volumes
- In `PatternEngine`, implement `initialize_audio_system()` method
- Create three GStreamer playbin elements: strong_player, regular_player, ghost_player
- Set volume property: strong=1.0, regular=0.7, ghost=0.3
- Implement sound loading: `load_sounds_for_pattern(RhythmPattern pattern)`
- Map sound_type to URI (use settings for custom sounds)
- Set URIs on appropriate players based on accent level
- Add error handling for audio initialization failures
- Emit audio_system_failed signal on errors

**Validation**: Three players initialized with correct volumes, sounds loaded

**Dependencies**: Task 3, Task 4

---

### Task 6: Handle BPM changes during playback
- In `PatternEngine`, add property change handler for `bpm`
- If running, recalculate next_step_time for new BPM
- Maintain pattern position (don't reset)
- Ensure smooth tempo transition without glitches

**Validation**: Changing BPM mid-pattern adjusts tempo smoothly

**Dependencies**: Task 4

---

## Phase 3: Built-in Patterns

### Task 7: Create built-in pattern JSON files
- Create `data/patterns/` directory
- Create `son-clave-32.json` - Son Clave (3-2) pattern
- Create `son-clave-23.json` - Son Clave (2-3) pattern
- Create `rumba-clave.json` - Rumba Clave pattern
- Create `bossa-nova.json` - Bossa Nova pattern
- Create `swing-ride.json` - Swing Ride pattern
- Create `backbeat.json` - Simple backbeat (beats 2 & 4)
- Validate each JSON parses correctly
- Add patterns to `data/meson.build` for installation
- Register in `data/io.github.tobagin.tempo.gresource.xml.in`

**Validation**: All patterns load successfully, appear in UI

**Dependencies**: Task 1

---

## Phase 4: Pattern Selection UI

### Task 8: Add pattern selector to main window UI
- Open `data/ui/main_window.blp`
- Add Adw.ComboRow for pattern selection
- Position below tempo controls or in collapsible section
- Add "None" as first option
- Bind to GSettings `active-pattern` key
- Style consistently with existing controls

**Validation**: UI shows pattern dropdown, integrates cleanly

**Dependencies**: None

---

### Task 9: Populate pattern dropdown from library
- Open `src/windows/MainWindow.vala`
- Add `PatternLibrary` member variable
- In constructor, call library.load_built_in_patterns() and load_user_patterns()
- Create Gtk.StringList model with pattern names
- Add "None" as first item
- Bind model to pattern ComboRow
- Store library reference for later use

**Validation**: Dropdown populated with all patterns on startup

**Dependencies**: Task 2, Task 8

---

### Task 10: Implement pattern selection handler
- In `MainWindow.vala`, add signal handler for pattern ComboRow selection
- On selection, get pattern name from model
- If "None", deactivate pattern (call deactivate_pattern())
- Otherwise, load pattern from library and call activate_pattern()
- Save selection to GSettings `active-pattern`
- Update UI to show pattern name

**Validation**: Selecting pattern activates it, selecting None deactivates

**Dependencies**: Task 9

---

## Phase 5: Pattern Mode Integration

### Task 11: Add mode switching logic to MainWindow
- In `MainWindow.vala`, add `MetronomeMode` enum (SIMPLE_BEATS, PATTERN)
- Add member variables: current_mode, pattern_engine
- Implement `activate_pattern(RhythmPattern pattern)` method
  - Stop metronome if running
  - Set current_mode = PATTERN
  - Set pattern on pattern_engine
  - Connect pattern_engine.step_occurred to visual indicator
  - Update UI to show pattern controls
- Implement `deactivate_pattern()` method
  - Stop pattern if running
  - Set current_mode = SIMPLE_BEATS
  - Disconnect pattern_engine signals
  - Update UI to standard mode

**Validation**: Mode switches correctly, pattern plays when activated

**Dependencies**: Task 3, Task 10

---

### Task 12: Update play/pause button for pattern mode
- In `MainWindow.vala`, modify play button handler
- Check current_mode
- If SIMPLE_BEATS: use metronome_engine (existing behavior)
- If PATTERN: use pattern_engine.start()/stop()
- Ensure button state reflects running status

**Validation**: Play button starts/stops correct engine based on mode

**Dependencies**: Task 11

---

### Task 13: Update visual indicator for pattern mode
- In `MainWindow.vala`, add handler for pattern_engine.step_occurred signal
- Get accent level from PatternStep
- Map accent to color: STRONG=bright red, REGULAR=standard, GHOST=dimmed
- Trigger beat indicator redraw with appropriate color
- Update beat counter to show position/length (e.g., "3/8")
- Ensure indicator pulses on each step

**Validation**: Visual indicator responds to pattern steps with correct colors

**Dependencies**: Task 11

---

## Phase 6: Pattern Editor Dialog

### Task 14: Create PatternEditorDialog UI markup
- Create `data/ui/pattern_editor_dialog.blp`
- Use Adw.Dialog as root
- Add header with title "Pattern Editor", Save/Cancel buttons
- Add content area with:
  - Adw.EntryRow for pattern name
  - Adw.EntryRow for description
  - Adw.SpinRow for length (1-64 beats)
  - Time signature controls (numerator/denominator)
  - Grid container for pattern sequencer
  - Preview button
- Register in `data/io.github.tobagin.tempo.gresource.xml.in`
- Compile with blueprint-compiler

**Validation**: Dialog UI renders correctly

**Dependencies**: None

---

### Task 15: Create PatternEditorDialog class
- Create `src/dialogs/PatternEditorDialog.vala`
- Use @Gtk.Template to bind to UI markup
- Add properties: edited_pattern, is_preview_playing
- Bind template children: name_entry, description_entry, length_spin, grid_container
- Implement constructor with optional pattern parameter
- If pattern provided, populate fields with pattern data
- Add to `src/meson.build`

**Validation**: Dialog instantiates and displays

**Dependencies**: Task 14

---

### Task 16: Implement pattern grid sequencer
- In `PatternEditorDialog`, implement `build_pattern_grid()` method
- Create Gtk.Grid with rows for accent levels (STRONG, REGULAR, GHOST)
- Create columns for each beat (based on length_spin value)
- Each cell is Gtk.ToggleButton
- Style buttons with CSS (filled when toggled)
- Connect toggled signals to update internal pattern representation
- Show sound type icon on filled cells
- Update grid when length changes

**Validation**: Grid displays correctly, cells toggle on click

**Dependencies**: Task 15

---

### Task 17: Implement pattern preview functionality
- In `PatternEditorDialog`, add Preview button handler
- On click, create temporary PatternEngine
- Load current edited pattern (build from grid state)
- Start pattern engine at current BPM
- Highlight current step in grid during preview
- Stop preview on second click or dialog close
- Clean up pattern engine resources

**Validation**: Preview plays current pattern, grid highlights current step

**Dependencies**: Task 3, Task 16

---

### Task 18: Implement pattern save logic
- In `PatternEditorDialog`, add Save button handler
- Validate pattern name is not empty
- Build RhythmPattern object from UI fields and grid state
- Call pattern_library.save_user_pattern()
- Show success toast "Pattern '[name]' saved"
- Emit pattern_saved signal
- Close dialog
- Handle errors (e.g., file write failure)

**Validation**: Pattern saved to user directory, loads on restart

**Dependencies**: Task 2, Task 16

---

## Phase 7: Pattern Management Actions

### Task 19: Add pattern management actions to MainWindow
- In `src/windows/MainWindow.vala`, add actions: new-pattern, edit-pattern, delete-pattern
- Add menu items or buttons for actions
- Implement new-pattern handler: open PatternEditorDialog with empty pattern
- Implement edit-pattern handler: open PatternEditorDialog with selected pattern
- Implement delete-pattern handler: confirm and delete pattern from library
- Update pattern dropdown after add/delete

**Validation**: Can create, edit, delete patterns from UI

**Dependencies**: Task 15, Task 18

---

## Phase 8: Settings and Persistence

### Task 20: Add pattern settings to GSettings schema
- Open `data/io.github.tobagin.tempo.gschema.xml.in`
- Add key: `active-pattern` (string, default "")
- Add key: `last-used-pattern` (string, default "")
- Validate schema compiles

**Validation**: Settings keys available, persist across restarts

**Dependencies**: None

---

### Task 21: Implement pattern settings persistence
- In `MainWindow.vala`, load `active-pattern` on startup
- If not empty, load pattern from library and activate
- Save `active-pattern` whenever pattern selected
- Update `last-used-pattern` when pattern successfully plays
- Handle case where saved pattern no longer exists (fall back to None)

**Validation**: Pattern selection persists across app restarts

**Dependencies**: Task 11, Task 20

---

## Phase 9: Testing and Polish

### Task 22: Test built-in patterns at various BPMs
- Load each built-in pattern
- Test at 60, 120, 180, 240 BPM
- Verify timing accuracy with audio recording/analysis
- Check visual indicator synchronization
- Ensure no audio glitches or dropouts
- Test pattern loops correctly

**Validation**: All patterns play accurately at all BPMs

**Dependencies**: All previous tasks

---

### Task 23: Test pattern editor usability
- Create new patterns with various lengths and steps
- Edit existing patterns
- Test preview functionality
- Verify grid state saves correctly
- Test edge cases: empty pattern, single step, max length (64 beats)
- Ensure UI responsive and intuitive

**Validation**: Editor is usable and produces valid patterns

**Dependencies**: Task 16, Task 17, Task 18

---

### Task 24: Performance testing with 100+ patterns
- Create 100 user patterns programmatically
- Test application startup time
- Test pattern dropdown population time
- Test memory usage with all patterns loaded
- Ensure UI remains responsive
- Test pattern limit enforcement

**Validation**: Performance acceptable with maximum patterns

**Dependencies**: Task 2, Task 9

---

### Task 25: Update CHANGELOG and documentation
- Add feature entry to CHANGELOG.md: "Add rhythm patterns with library, editor, and playback"
- Update README.md with pattern feature description
- Document built-in patterns
- Document how to create custom patterns
- Add keyboard shortcuts for pattern actions (if applicable)

**Validation**: Documentation complete and accurate

**Dependencies**: All feature tasks complete

---

## Notes
- Total tasks: 25
- Estimated complexity: High
- Dependencies: Requires subdivisions feature for fine-grained timing
- Priority: Medium (per TODO.md)
- User impact: Medium (advanced users, genre-specific practice)
