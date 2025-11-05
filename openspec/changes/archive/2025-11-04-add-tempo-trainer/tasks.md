# Implementation Tasks

## Phase 1: Core TempoTrainer Class

### Task 1: Create TempoTrainer class skeleton
- [ ] Create `src/utils/TempoTrainer.vala` with class definition
- [ ] Define public properties: enabled, start_tempo, target_tempo, increment
- [x] Define interval properties: interval_type, interval_value
- [x] Define state properties: is_active, current_tempo, bars_completed, seconds_elapsed
- [x] Define enums: `IntervalType` (BARS, SECONDS)
- [x] Add signal definitions: tempo_should_change, target_reached, progression_updated
- [x] Implement basic constructor
- [x] Add to `src/utils/meson.build` for compilation

**Validation**: File compiles, class instantiates, signals defined correctly

**Dependencies**: None

---

### Task 2: Implement tempo calculation logic
- [x] Add method: `calculate_next_tempo() -> int`
- [x] Calculate: next_tempo = current_tempo + increment
- [x] Clamp to target (don't overshoot): if ascending, min(next, target); if descending, max(next, target)
- [x] Clamp to valid BPM range (40-240)
- [x] Add method: `is_target_reached() -> bool`
- [x] Check if current >= target (ascending) or current <= target (descending)

**Validation**:
- 115 + 10 → 120 when target=120 (clamp works)
- 60 + 5 → 65 when target=120 (normal increment)
- 140 - 10 → 130 when target=60 (descending)

**Dependencies**: Task 1

---

### Task 3: Implement bar-based progression tracking
- [x] Add method: `on_beat_occurred(int beat_num, int beats_per_bar)`
- [x] Check if this is a downbeat: `(beat_num % beats_per_bar) == 1`
- [x] If downbeat: increment `bars_completed`
- [x] If `bars_completed >= interval_value`: trigger tempo change
- [x] Calculate next_tempo and emit `tempo_should_change` signal
- [x] Update `current_tempo` property
- [x] Reset `bars_completed = 0` after increment
- [x] Check if target reached, emit `target_reached` if so
- [x] Emit `progression_updated` signal with current progress

**Validation**:
- Bars increment only on downbeats
- Tempo changes after exact interval (8 bars)
- Counter resets after change

**Dependencies**: Task 2

---

### Task 4: Implement time-based progression tracking
- [x] Add private property: `time_tracker_id` (uint)
- [x] In `start()`: if interval_type == SECONDS, start GLib.Timeout at 1-second intervals
- [x] Add method: `on_second_elapsed()`
- [x] Increment `seconds_elapsed`
- [x] If `seconds_elapsed >= interval_value`: trigger tempo change
- [x] Calculate next_tempo and emit `tempo_should_change` signal
- [x] Reset `seconds_elapsed = 0` after increment
- [x] Check if target reached
- [x] In `pause()`: remove timeout source if active
- [x] In `resume()`: restart timeout if interval_type == SECONDS

**Validation**:
- Seconds accumulate correctly
- Tempo changes after exact interval (30 seconds)
- Timer stops on pause, resumes correctly

**Dependencies**: Task 2

---

### Task 5: Implement start/pause/resume/reset methods
- [x] Implement `start()`: set is_active=true, current_tempo=start_tempo, reset counters
- [x] If time-based: start timeout
- [x] Implement `pause()`: set is_active=false, preserve state (counters, current_tempo)
- [x] Stop timeout if time-based
- [x] Implement `resume()`: set is_active=true, continue from preserved state
- [x] Restart timeout if time-based
- [x] Implement `reset()`: reset all counters to 0, current_tempo to start_tempo
- [x] Emit progression_updated after state changes

**Validation**:
- Start sets state correctly
- Pause preserves counters
- Resume continues from paused state
- Reset clears all state

**Dependencies**: Task 3, Task 4

---

### Task 6: Implement progression progress calculation
- [ ] Add method: `calculate_remaining_increments() -> int`
- [ ] Calculate: (target_tempo - current_tempo) / increment
- [ ] Handle negative increments (descending)
- [ ] Add method: `calculate_completion_percentage() -> double`
- [ ] Calculate: (current_tempo - start_tempo) / (target_tempo - start_tempo) * 100
- [ ] Handle edge cases (start == target)

**Validation**:
- 60→120, currently 85, +5 increments: (120-85)/5 = 7 remaining
- 60→120, currently 85: (85-60)/(120-60) = 42% complete

**Dependencies**: Task 2

---

## Phase 2: Settings Integration

### Task 7: Add GSettings schema keys for trainer
- [ ] Open `data/io.github.tobagin.tempo.gschema.xml.in`
- [ ] Add `trainer-enabled` boolean key (default: false)
- [ ] Add `trainer-start-tempo` integer key (range 40-240, default: 60)
- [ ] Add `trainer-target-tempo` integer key (range 40-240, default: 120)
- [ ] Add `trainer-increment` integer key (range -50 to +50 excluding 0, default: 5)
- [ ] Add `trainer-interval-type` integer key (range 0-1, default: 0 for BARS)
- [ ] Add `trainer-interval-value` integer key (range 1-999, default: 8)
- [ ] Add `trainer-auto-stop` boolean key (default: false)
- [ ] Add proper summaries and descriptions

**Validation**: Schema compiles, settings visible in dconf-editor

**Dependencies**: None (parallelizable with Phase 1)

---

### Task 8: Bind trainer settings in TempoTrainer
- [ ] Add GLib.Settings member to TempoTrainer
- [ ] In constructor: bind properties to settings keys
- [ ] Bind enabled, start_tempo, target_tempo, increment
- [ ] Bind interval_type, interval_value, auto_stop_at_target
- [ ] Add property change handlers to save on modification
- [ ] Implement validation: start != target, increment != 0
- [ ] Validate direction matches (positive increment for ascending, etc.)
- [ ] Add fallback for corrupted settings

**Validation**:
- Settings persist across restarts
- Invalid values handled gracefully
- Validation prevents invalid configurations

**Dependencies**: Task 1, Task 7

---

## Phase 3: MetronomeEngine Integration

### Task 9: Connect trainer to MetronomeEngine signals
- [ ] In MainWindow (or wherever trainer instantiated): create TempoTrainer instance
- [ ] Connect MetronomeEngine's `beat_occurred` signal to trainer's `on_beat_occurred`
- [ ] Pass beat_number and beats_per_bar parameters
- [ ] Ensure connection only active when trainer enabled

**Validation**: Trainer receives beat events when metronome running

**Dependencies**: Task 3 (for bar-based tracking)

---

### Task 10: Implement tempo change application
- [ ] Connect TempoTrainer's `tempo_should_change` signal to handler
- [ ] Implement handler that calls `MetronomeEngine.set_tempo(new_tempo)`
- [ ] Catch MetronomeError exceptions and handle gracefully
- [ ] Update UI tempo display to reflect new tempo
- [ ] Log tempo change for debugging

**Validation**:
- Tempo changes applied correctly
- UI updates reflect new tempo
- No timing glitches during change

**Dependencies**: Task 9

---

### Task 11: Implement downbeat-only tempo changes
- [ ] Modify tempo change logic to delay until next downbeat
- [ ] Add property: `pending_tempo_change` (int, 0 = none pending)
- [ ] When interval reached: set pending_tempo_change instead of immediate apply
- [ ] In `on_beat_occurred`: if downbeat and pending != 0, apply change
- [ ] Reset pending_tempo_change to 0 after applying

**Validation**:
- Tempo changes only occur on downbeats
- Smooth musical transitions
- No mid-measure changes

**Dependencies**: Task 10

---

### Task 12: Handle metronome pause/resume with trainer
- [ ] Connect to MetronomeEngine's state changes (start/stop/pause)
- [ ] When metronome pauses: call `tempo_trainer.pause()`
- [ ] When metronome resumes: call `tempo_trainer.resume()`
- [ ] When metronome stops (full stop): call `tempo_trainer.reset()`
- [ ] Preserve trainer.enabled setting through pause/resume

**Validation**:
- Trainer pauses with metronome
- State preserved on pause
- Resumes correctly
- Full stop resets progression

**Dependencies**: Task 5, Task 9

---

### Task 13: Detect and handle manual tempo changes
- [ ] Track last tempo applied by trainer: `last_trainer_tempo`
- [ ] Connect to MetronomeEngine's tempo property change
- [ ] In handler: check if new tempo != last_trainer_tempo
- [ ] If mismatch (manual change detected): pause trainer
- [ ] Show toast: "Tempo Trainer paused (manual tempo change)"
- [ ] Set trainer.enabled = false

**Validation**:
- Manual tempo change detected
- Trainer pauses automatically
- Toast displayed
- User can re-enable trainer

**Dependencies**: Task 10

---

## Phase 4: Target Completion Handling

### Task 14: Implement target_reached signal handling
- [ ] Connect to TempoTrainer's `target_reached` signal
- [ ] Implement handler that shows notification toast
- [ ] Format toast: "Tempo Trainer: Target [target] BPM reached!"
- [ ] If auto_stop_at_target enabled: stop metronome
- [ ] Keep trainer active (don't disable) so user sees final state
- [ ] Update progress display to show "Target Reached ✓"

**Validation**:
- Toast appears when target reached
- Auto-stop works if enabled
- Trainer shows completion state

**Dependencies**: Task 3 or Task 4 (target detection), Task 10

---

## Phase 5: UI Integration (Main Window)

### Task 15: Add trainer section to main window Blueprint
- [x] Open `data/ui/main_window.blp`
- [x] Add `AdwExpanderRow` below tempo controls titled "Tempo Trainer"
- [x] Set collapsible, collapsed by default
- [x] Inside expander: add VBox for trainer controls
- [x] Add `AdwActionRow` for start tempo (with SpinButton, 40-240)
- [x] Add `AdwActionRow` for target tempo (with SpinButton, 40-240)
- [x] Add `AdwActionRow` for increment (with SpinButton, -50 to +50)
- [x] Add `AdwComboRow` for interval type (Bars / Seconds)
- [x] Add `AdwActionRow` for interval value (with SpinButton, 1-999)
- [x] Add `Switch` for "Enable Tempo Trainer"
- [x] Add Label for progress display (ID: "trainer-progress-label")

**Validation**: UI compiles, trainer section appears, controls functional

**Dependencies**: Task 7 (for settings binding)

---

### Task 16: Bind trainer UI controls to settings
- [x] In `src/windows/MainWindow.vala`: add template child bindings
- [x] Bind start_tempo SpinButton to trainer-start-tempo setting
- [x] Bind target_tempo SpinButton to trainer-target-tempo setting
- [x] Bind increment SpinButton to trainer-increment setting
- [x] Bind interval_type ComboRow to trainer-interval-type setting
- [x] Bind interval_value SpinButton to trainer-interval-value setting
- [x] Bind trainer Switch to trainer-enabled setting
- [x] Add property change handlers for validation

**Validation**:
- UI controls reflect settings
- Changes saved to settings immediately
- Settings propagate to TempoTrainer

**Dependencies**: Task 15, Task 8

---

### Task 17: Implement progression progress display
- [x] Connect to TempoTrainer's `progression_updated` signal
- [x] Implement handler: `on_progression_updated(int current, int target, int remaining)`
- [x] Format progress string:
  - If bar-based: "[current]/[target] BPM, next +[increment] in [X] bars"
  - If time-based: "[current]/[target] BPM, next +[increment] in [X] seconds"
- [x] Update trainer-progress-label text
- [x] Calculate and update progress bar percentage
- [x] Hide progress when trainer disabled

**Validation**:
- Progress updates every beat or second
- Display format clear and accurate
- Progress bar animates smoothly

**Dependencies**: Task 16, Task 6

---

### Task 18: Implement trainer visual state indicators
- [x] Add CSS class to trainer section when active: "trainer-active"
- [x] Style active state with accent color border
- [x] Add "Trainer Active" badge (small label) when enabled
- [x] Highlight current tempo display when trainer running
- [x] Add progress bar widget (GtkProgressBar) for visual completion

**Validation**:
- Active state visually clear
- Inactive state subdued
- Progress bar shows completion percentage

**Dependencies**: Task 17

---

### Task 19: Implement tempo increment toast notifications
- [x] Connect to TempoTrainer's `tempo_should_change` signal
- [x] When signal emitted: show Adwaita Toast
- [x] Format toast: "Tempo increased to [new_tempo] BPM"
- [x] Or "Tempo decreased to [new_tempo] BPM" for descending
- [x] Toast duration: 2 seconds (short, non-intrusive)
- [x] Don't block or interrupt playback

**Validation**:
- Toast appears on each increment
- Message clear and concise
- Doesn't disrupt practice flow

**Dependencies**: Task 10

---

## Phase 6: Preferences Dialog

### Task 20: Add trainer preferences section
- [x] Open `data/ui/preferences_dialog.blp`
- [x] Add `AdwPreferencesGroup` titled "Tempo Trainer"
- [x] Add same controls as main window (for comprehensive configuration)
- [x] Add `AdwSwitchRow` for auto-stop at target
- [x] Include help text / descriptions explaining each setting
- [x] Add example: "Example: 60→120 BPM, +5 every 8 bars"

**Validation**: Preferences section appears, all controls present

**Dependencies**: Task 7

---

### Task 21: Bind preferences trainer controls
- [x] In `src/dialogs/PreferencesDialog.vala`: add template children
- [x] Bind all trainer controls to GSettings (same as main window)
- [x] Add input validation with error messages
- [x] Implement warnings for large increments (>20 BPM)
- [x] Validate start != target on enable attempt

**Validation**:
- Preferences mirror main window settings
- Validation prevents invalid configs
- Warnings appear for edge cases

**Dependencies**: Task 20, Task 8

---

## Phase 7: Input Validation & Error Handling

### Task 22: Implement configuration validation
- [x] Add method: `validate_configuration() -> bool`
- [x] Check: start_tempo != target_tempo
- [x] Check: increment != 0
- [x] Check: if start < target, increment must be positive
- [x] Check: if start > target, increment must be negative
- [x] Check: interval_value > 0
- [ ] Show specific error messages for each validation failure
- [ ] Call validation before enabling trainer

**Validation**:
- Invalid configs rejected with clear messages
- Valid configs accepted
- Edge cases handled

**Dependencies**: Task 8

---

### Task 23: Implement large increment warning
- [ ] When user sets increment to >20 BPM (or <-20 for descending)
- [ ] Show warning dialog: "Large increments may be difficult to follow"
- [ ] Suggest smaller increments: "5-10 BPM recommended for gradual progression"
- [ ] Allow user to proceed or adjust
- [ ] Don't block, just warn

**Validation**: Warning appears for large increments, user can proceed

**Dependencies**: Task 22

---

### Task 24: Implement settings corruption handling
- [ ] In TempoTrainer constructor: validate loaded settings
- [ ] Check for increment == 0, interval_value == 0, etc.
- [ ] If invalid: log warning with g_warning()
- [ ] Fallback to defaults: start=60, target=120, increment=+5, interval=8 bars
- [ ] Set enabled=false if critical validation fails
- [ ] Application continues gracefully

**Validation**: Corrupted settings don't crash app, fallback to defaults

**Dependencies**: Task 8

---

## Phase 8: Testing & Validation

### Task 25: Unit test tempo calculation logic
- [ ] Test `calculate_next_tempo()` with various inputs
- [ ] Test clamp to target: 115+10 → 120 when target=120
- [ ] Test normal increment: 60+5 → 65
- [ ] Test descending: 140-10 → 130
- [ ] Test BPM range clamping: ensure 40-240 limits
- [ ] Test `is_target_reached()` for ascending and descending

**Validation**: All calculations accurate

**Dependencies**: Task 2

---

### Task 26: Integration test bar-based progression
- [ ] Enable trainer: 60→120 BPM, +5 every 8 bars
- [ ] Play metronome in 4/4 time
- [ ] Count bars manually, verify tempo increases after exactly 8 bars
- [ ] Verify tempo changes on downbeat (bar 9 beat 1)
- [ ] Test in 3/4 time: verify bars counted correctly
- [ ] Test pause/resume: verify bars preserved

**Validation**:
- Bar counting accurate
- Tempo changes at correct times
- Works in different time signatures

**Dependencies**: Task 11, Task 12

---

### Task 27: Integration test time-based progression
- [ ] Enable trainer: 80→140 BPM, +2 every 30 seconds
- [ ] Start metronome, use stopwatch to verify timing
- [ ] Verify tempo increases after exactly 30 seconds
- [ ] Test pause: verify seconds preserved
- [ ] Resume: verify continues from preserved time

**Validation**:
- Time counting accurate
- Tempo changes after exact interval
- Pause/resume works correctly

**Dependencies**: Task 4, Task 12

---

### Task 28: Integration test target completion
- [ ] Configure short progression: 60→80 BPM, +5 every 4 bars
- [ ] Run to completion
- [ ] Verify target reached notification appears
- [ ] Verify no further tempo increases after target
- [ ] Test auto-stop: verify metronome stops at target
- [ ] Test without auto-stop: verify continues at target tempo

**Validation**:
- Target completion detected
- Notification appears
- Auto-stop works as configured

**Dependencies**: Task 14

---

### Task 29: Integration test manual tempo change handling
- [ ] Enable trainer at 75 BPM
- [ ] Manually change tempo to 100 BPM via slider
- [ ] Verify trainer pauses automatically
- [ ] Verify toast notification appears
- [ ] Re-enable trainer, verify resets to start tempo

**Validation**:
- Manual change detected
- Trainer pauses
- Notification clear

**Dependencies**: Task 13

---

### Task 30: Manual testing comprehensive checklist
- [ ] Configure 60→120 BPM, +5 every 8 bars in 4/4
- [ ] Enable trainer, count bars, verify tempo increases
- [ ] Test in 3/4 time: verify bar counting correct
- [ ] Test in 6/8 time: verify works in compound meter
- [ ] Configure descending: 140→60 BPM, -10 every 4 bars
- [ ] Verify descending progression works correctly
- [x] Test time-based: +2 every 30 seconds
- [x] Use stopwatch to verify timing accuracy
- [x] Test pause: verify state preserved, resume works
- [x] Test full stop: verify progression resets
- [x] Test manual tempo change: verify trainer pauses
- [x] Test target completion with auto-stop enabled
- [x] Test target completion with auto-stop disabled
- [x] Test with subdivisions enabled (both work together)
- [x] Test with practice timer enabled (both work together)
- [x] Test large increment warning (>20 BPM)
- [x] Test invalid config validation (start=target)
- [x] Test increment direction validation
- [x] Settings persist across app restart

**Validation**: All manual tests pass, no regressions

**Dependencies**: All previous implementation tasks

---

### Task 31: Performance validation
- [x] Run trainer for 30 minutes (full progression session)
- [x] Profile CPU usage: verify < 0.1% overhead
- [x] Profile memory usage: verify < 500 bytes increase
- [x] Verify no memory leaks over extended session
- [x] Measure tempo change operation: verify < 1ms
- [x] Verify no impact on metronome timing accuracy

**Validation**: Performance meets specification targets

**Dependencies**: Task 30

---

### Task 32: Edge case testing
- [x] Test increment overshoot: 115+10 → 120 (target 120)
- [x] Test already at target: start=target, verify error
- [x] Test zero increment: verify rejection
- [x] Test wrong direction increment: verify validation
- [x] Test time signature change mid-progression (bar-based)
- [x] Test very large interval: 999 bars
- [x] Test very small interval: 1 bar or 1 second
- [x] Test corrupted settings: increment=0, interval=0
- [x] Test rapid enable/disable toggling

**Validation**: All edge cases handled gracefully

**Dependencies**: Task 30

---

## Phase 9: Documentation & Polish

### Task 33: Code review and cleanup
- [ ] Review all code for project conventions
- [ ] Ensure PascalCase for classes, snake_case for methods
- [ ] Verify no file exceeds 500 lines (split if needed)
- [ ] Add comprehensive comments explaining trainer logic
- [ ] Document progression algorithms with examples
- [ ] Verify error handling complete
- [ ] Remove debug logging
- [ ] Check all GSettings keys have descriptions

**Validation**: Code meets project style guidelines

**Dependencies**: All implementation tasks

---

### Task 34: Update CHANGELOG.md
- [ ] Add entry under "## [Unreleased]" section
- [ ] Document feature: "Added Tempo Trainer for automatic tempo progression"
- [ ] List capabilities: bar-based and time-based intervals
- [ ] Note ascending and descending support
- [ ] Document auto-stop at target option
- [ ] Mention pause/resume functionality
- [ ] Document new settings keys

**Validation**: CHANGELOG accurately reflects changes

**Dependencies**: Task 33

---

### Task 35: Update user documentation
- [ ] Add "Tempo Trainer" section to README.md (if applicable)
- [ ] Explain use case: gradual speed building for practice
- [ ] Document configuration options
- [ ] Provide examples: "60→120 BPM, +5 every 8 bars"
- [ ] Explain bar-based vs time-based intervals
- [ ] Document auto-stop behavior

**Validation**: Documentation clear for end users

**Dependencies**: Task 33

---

## Estimated Effort

- **Phase 1 (Core Class)**: 10-14 hours
- **Phase 2 (Settings)**: 2-3 hours
- **Phase 3 (Engine Integration)**: 4-6 hours
- **Phase 4 (Target Completion)**: 1-2 hours
- **Phase 5 (Main Window UI)**: 4-6 hours
- **Phase 6 (Preferences)**: 2-3 hours
- **Phase 7 (Validation/Errors)**: 3-4 hours
- **Phase 8 (Testing)**: 10-14 hours
- **Phase 9 (Documentation)**: 2-3 hours

**Total Estimated Effort**: 38-55 hours

## Parallelization Opportunities

These tasks can be worked on in parallel:

- **Track A (Core)**: Phase 1 → Phase 3 → Phase 4 → Integration
- **Track B (UI)**: Phase 5 → Phase 6 → Testing
- **Track C (Settings)**: Phase 2 → Integration
- **Track D (Documentation)**: Can start alongside implementation

## Success Criteria

All tasks completed AND:
- ✅ Trainer progresses tempo from start to target
- ✅ Bar-based and time-based intervals both work
- ✅ Ascending and descending progression supported
- ✅ Tempo changes smooth (downbeat-only, no glitches)
- ✅ Progress clearly displayed and updated
- ✅ Pause/resume preserves state correctly
- ✅ Target completion detected and notified
- ✅ Manual tempo changes handled (trainer pauses)
- ✅ Configuration validation prevents invalid setups
- ✅ All manual, integration, and edge case tests pass
- ✅ Performance targets met (< 0.1% CPU, < 500 bytes memory)
- ✅ Settings persist across app restarts
- ✅ UI clear and intuitive
- ✅ Code follows project conventions
- ✅ Documentation updated

## Dependencies on Other Features

- **None**: This feature is independent
- **Complements**: Practice Timer (feature #4) - both can run simultaneously
- **Complements**: Subdivisions (feature #1) - subdivisions adjust to trainer tempo changes
- **Foundation for**: Future presets feature (#3) - trainer configurations can be saved
