# Implementation Tasks

## Phase 1: Foundation (Core Timer Logic)

### Task 1: Create PracticeTimer class skeleton
- [x] Create `src/utils/PracticeTimer.vala` with class definition
- [x] Define public properties (enabled, mode, elapsed_microseconds, is_running)
- [x] Define enums: TimerMode (COUNT_UP, COUNTDOWN), AutoStopMode (NONE, BEATS, BARS, TIME)
- [x] Add signal definitions (tick, auto_stop_triggered, countdown_completed)
- [x] Implement basic constructor with property initialization
- [x] Add to `src/utils/meson.build` for compilation

**Validation**: File compiles without errors, class instantiates successfully

**Dependencies**: None

---

### Task 2: Implement core timer logic (count-up mode)
- [x] Add private properties: start_time, timeout_id, paused_elapsed
- [x] Implement `start()` method: capture GLib.get_monotonic_time(), schedule timeout
- [x] Implement `pause()` method: cancel timeout, save elapsed time
- [x] Implement `resume()` method: adjust start_time, reschedule timeout
- [x] Implement `reset()` method: clear elapsed time, cancel timeout
- [x] Add timeout callback that calculates elapsed from monotonic time
- [x] Emit `tick` signal every second with current elapsed time

**Validation**: Timer counts up accurately, pause/resume maintains correct time, no drift over 10 minutes

**Dependencies**: Task 1

---

### Task 3: Implement countdown mode
- [x] Add property: `countdown_duration` (in microseconds)
- [x] Modify timeout callback to calculate remaining = duration - elapsed
- [x] Emit `tick` signal with both elapsed and remaining time
- [x] Detect countdown completion (remaining ≤ 0)
- [x] Emit `countdown_completed` signal when reaching zero
- [x] Auto-reset to countdown_duration after completion

**Validation**: Countdown decrements correctly, triggers completion signal at 00:00, resets properly

**Dependencies**: Task 2

---

### Task 4: Implement auto-stop beat/bar tracking
- [x] Add properties: auto_stop_mode, auto_stop_value, current_beat_count, current_bar_count
- [x] Add method: `on_beat_occurred(int beat_num, int beats_per_bar)` to track beats/bars
- [x] Implement beat counting logic (increment on each beat)
- [x] Implement bar counting logic (increment when beat_num == beats_per_bar)
- [x] Check auto-stop condition on each beat
- [x] Emit `auto_stop_triggered` signal when condition met (beats or bars)
- [x] Reset counters on timer reset

**Validation**: Beat/bar counting accurate across different time signatures, auto-stop triggers at correct count

**Dependencies**: Task 2

---

### Task 5: Implement auto-stop time tracking
- [x] Modify auto-stop condition check to handle TIME mode
- [x] Compare elapsed_microseconds against auto_stop_value (converted to microseconds)
- [x] Emit `auto_stop_triggered` when time limit reached
- [x] Ensure time-based auto-stop works in both count-up and countdown modes

**Validation**: Auto-stop triggers at correct time duration, works with timer pause/resume

**Dependencies**: Task 2, Task 3

---

## Phase 2: Settings Integration

### Task 6: Add GSettings schema keys
- [x] Open `data/io.github.tobagin.tempo.gschema.xml.in`
- [x] Add `timer-enabled` boolean key (default: false)
- [x] Add `timer-mode` integer key (default: 0 for COUNT_UP)
- [x] Add `timer-countdown-duration` integer key (range 1-180, default: 25)
- [x] Add `timer-pause-with-metronome` boolean key (default: true)
- [x] Add `timer-auto-stop-mode` integer key (range 0-3, default: 0 for NONE)
- [x] Add `timer-auto-stop-value` integer key (range 1-10000, default: 100)
- [x] Add `timer-show-in-main-window` boolean key (default: true)

**Validation**: Schema compiles, settings appear in dconf-editor, defaults are sensible

**Dependencies**: None (parallelizable with Phase 1)

---

### Task 7: Connect PracticeTimer to GSettings
- [x] Add GLib.Settings member to PracticeTimer class
- [x] Bind `enabled` property to `timer-enabled` setting
- [x] Bind `mode` property to `timer-mode` setting
- [x] Bind `countdown_duration` property to `timer-countdown-duration` (convert minutes to microseconds)
- [x] Bind `auto_stop_mode` property to `timer-auto-stop-mode` setting
- [x] Bind `auto_stop_value` property to `timer-auto-stop-value` setting
- [x] Add property change handlers to save settings when modified
- [x] Implement settings validation with fallbacks for corrupted values

**Validation**: Settings persist across app restarts, invalid values fallback gracefully

**Dependencies**: Task 1, Task 6

---

## Phase 3: MetronomeEngine Integration

### Task 8: Add PracticeTimer instance to MetronomeEngine
- [x] Open `src/utils/MetronomeEngine.vala`
- [x] Add member variable: `private PracticeTimer? practice_timer`
- [x] Inject PracticeTimer via constructor or setter method
- [x] Connect `auto_stop_triggered` signal to `stop()` method
- [x] Add null checks before timer operations (timer is optional)

**Validation**: Engine compiles with timer integration, timer can be null without errors

**Dependencies**: Task 1, Task 5

---

### Task 9: Synchronize timer with metronome state
- [x] Modify `MetronomeEngine.start()` to call `practice_timer.start()` if sync enabled
- [x] Modify `MetronomeEngine.stop()` to call `practice_timer.pause()` if sync enabled
- [x] Read `timer-pause-with-metronome` setting to control sync behavior
- [x] On beat_occurred signal emission, call `practice_timer.on_beat_occurred(current_beat, beats_per_bar)`
- [x] Ensure timer state changes don't block metronome timing loop

**Validation**: Timer starts/stops with metronome when sync enabled, continues when sync disabled

**Dependencies**: Task 4, Task 8

---

### Task 10: Handle auto-stop triggering
- [x] Connect PracticeTimer's `auto_stop_triggered` signal to MetronomeEngine
- [x] Implement handler that calls `MetronomeEngine.stop()`
- [x] Add optional flag to differentiate user-initiated stop vs auto-stop
- [x] Emit notification signal for UI to show toast (e.g., "Auto-stop: 16 bars completed")

**Validation**: Metronome stops automatically at correct beat/bar/time, notification signal emitted

**Dependencies**: Task 8, Task 9

---

## Phase 4: UI Integration (Main Window)

### Task 11: Add timer display to main window Blueprint
- [x] Open `data/ui/main_window.blp`
- [x] Add Label widget below beat indicator circle with ID "timer-display"
- [x] Set label visibility binding to `timer-show-in-main-window` setting
- [x] Add Label widget for auto-stop progress with ID "auto-stop-progress"
- [x] Set appropriate styles (centered, system font, subtle color)
- [x] Ensure layout remains clean and uncluttered

**Validation**: Timer labels appear in correct position, visibility toggles work

**Dependencies**: Task 6 (for settings binding)

---

### Task 12: Connect timer display to PracticeTimer in MainWindow
- [x] Open `src/windows/MainWindow.vala`
- [x] Add template child bindings for timer-display and auto-stop-progress labels
- [x] Instantiate PracticeTimer in MainWindow constructor
- [x] Pass PracticeTimer reference to MetronomeEngine
- [x] Connect to PracticeTimer's `tick` signal
- [x] Implement tick handler that formats time and updates labels
- [x] Format time as MM:SS (< 1 hour) or HH:MM:SS (≥ 1 hour)

**Validation**: Timer displays update every second with correct formatting

**Dependencies**: Task 11, Task 8

---

### Task 13: Implement auto-stop progress display
- [x] In tick signal handler, check if auto-stop enabled
- [x] If auto-stop mode is BEATS: format as "(50/100 beats)"
- [x] If auto-stop mode is BARS: format as "(8/16 bars)"
- [x] If auto-stop mode is TIME (count-up): format as "(3:45 / 5:00)"
- [x] If auto-stop mode is TIME (countdown): format as "(1:15 remaining)"
- [x] Hide progress label when auto-stop mode is NONE
- [x] Update progress on every beat (for beats/bars) or every second (for time)

**Validation**: Progress displays correctly for all auto-stop modes, updates in real-time

**Dependencies**: Task 12

---

### Task 14: Add notification toasts for timer events
- [x] Connect to `countdown_completed` signal
- [x] Show Adwaita Toast: "Practice session completed" when countdown reaches zero
- [x] Connect to `auto_stop_triggered` signal
- [x] Show Toast with appropriate message:
  - "Auto-stop: 100 beats completed"
  - "Auto-stop: 16 bars completed"
  - "Auto-stop: 5 minutes completed"
- [x] Ensure toasts don't interrupt user workflow

**Validation**: Toasts appear at correct times with correct messages

**Dependencies**: Task 12

---

## Phase 5: Preferences Dialog

### Task 15: Add Practice Timer section to PreferencesDialog Blueprint
- [x] Open `data/ui/preferences_dialog.blp`
- [x] Add new AdwPreferencesGroup titled "Practice Timer"
- [x] Add AdwSwitchRow for timer enable/disable
- [x] Add AdwComboRow for timer mode (Count-up / Countdown)
- [x] Add AdwSpinRow for countdown duration (1-180 minutes)
- [x] Add AdwSwitchRow for "Pause with metronome"
- [x] Add AdwComboRow for auto-stop mode (None / Beats / Bars / Time)
- [x] Add AdwSpinRow for auto-stop value (dynamic range based on mode)
- [x] Add AdwSwitchRow for "Show in main window"

**Validation**: UI compiles, all widgets appear in Preferences dialog

**Dependencies**: Task 6 (for settings keys)

---

### Task 16: Bind preferences controls to GSettings
- [x] Open `src/dialogs/PreferencesDialog.vala`
- [x] Bind all timer preference widgets to corresponding GSettings keys
- [x] Implement dynamic auto-stop value range (changes based on auto-stop mode)
- [x] Add property change handler to reset timer when mode changes mid-session
- [x] Validate input ranges (1-180 for countdown, appropriate for auto-stop)

**Validation**: Preference changes immediately reflected in settings and timer behavior

**Dependencies**: Task 15, Task 7

---

## Phase 6: Testing & Polish

### Task 17: Manual testing checklist
- [x] Test count-up timer accuracy over 10+ minutes (no drift)
- [x] Test countdown timer from various durations (1, 10, 60 minutes)
- [x] Test countdown completion (reaches zero, resets correctly)
- [x] Test auto-stop beats (count accuracy, stops at correct beat)
- [x] Test auto-stop bars across different time signatures (4/4, 3/4, 6/8, 5/4)
- [x] Test auto-stop time (stops at correct duration)
- [x] Test timer pause/resume with metronome sync enabled
- [x] Test timer continues when metronome stops with sync disabled
- [x] Test settings persistence (close/reopen app, verify settings preserved)
- [x] Test settings validation (enter invalid values, verify fallback)
- [x] Test timer visibility toggle
- [x] Test auto-stop mode changes mid-session (progress resets correctly)
- [x] Test metronome timing accuracy with timer enabled (no degradation)
- [x] Test accessibility (screen reader announces timer, keyboard navigation works)

**Validation**: All manual tests pass, no regressions in existing functionality

**Dependencies**: All previous tasks

---

### Task 18: Edge case testing
- [x] Test auto-stop on beat 1 of measure (immediate stop)
- [x] Test auto-stop on beat 4 of 4/4 measure (stops after beat completes)
- [x] Test time signature change mid-session with bar auto-stop
- [x] Test tempo change mid-session (beat count unaffected)
- [x] Test timer with very fast tempo (240 BPM)
- [x] Test timer with very slow tempo (40 BPM)
- [x] Test countdown with 1-minute duration (edge of range)
- [x] Test countdown with 180-minute duration (maximum)
- [x] Test auto-stop with 1 beat (minimum)
- [x] Test auto-stop with 10000 beats (maximum)
- [x] Test corrupted GSettings values (negative durations, out-of-range values)
- [x] Test timer state when app crashes and restarts

**Validation**: All edge cases handled gracefully, no crashes or undefined behavior

**Dependencies**: Task 17

---

### Task 19: Performance validation
- [x] Profile CPU usage with timer enabled at 240 BPM (verify < 0.1% overhead)
- [x] Profile memory usage with timer enabled (verify < 1KB overhead)
- [x] Measure metronome timing accuracy with timer enabled (verify sub-millisecond)
- [x] Test timer over 60+ minute session (verify no memory leaks)
- [x] Verify timer updates don't block main thread (UI remains responsive)

**Validation**: Performance metrics meet design targets, no regressions

**Dependencies**: Task 17

---

### Task 20: Code review and cleanup
- [x] Review all code for consistency with project conventions
- [x] Ensure PascalCase for classes, snake_case for methods/variables
- [x] Verify no file exceeds 500 lines (split PracticeTimer if needed)
- [x] Add comprehensive comments and documentation
- [x] Remove debug logging statements
- [x] Verify error handling is comprehensive
- [x] Check all GSettings keys have proper summaries and descriptions

**Validation**: Code passes project style guidelines, ready for review

**Dependencies**: All previous tasks

---

### Task 21: Update CHANGELOG.md
- [x] Add entry under "## [Unreleased]" section
- [x] Document new features:
  - Practice session timer with count-up and countdown modes
  - Auto-stop by beats, bars, or time duration
  - Timer synchronization with metronome playback
  - Configurable timer display and preferences
- [x] Note any behavior changes or new settings

**Validation**: CHANGELOG accurately reflects changes

**Dependencies**: Task 20

---

## Estimated Effort

- **Phase 1 (Core Timer Logic)**: 4-6 hours
- **Phase 2 (Settings Integration)**: 2-3 hours
- **Phase 3 (Engine Integration)**: 2-3 hours
- **Phase 4 (UI Integration)**: 3-4 hours
- **Phase 5 (Preferences)**: 2-3 hours
- **Phase 6 (Testing & Polish)**: 4-6 hours

**Total Estimated Effort**: 17-25 hours

## Parallelization Opportunities

These tasks can be worked on in parallel:

- **Track A**: Phase 1 (Timer Logic) → Phase 2 (Settings) → Integration
- **Track B**: Phase 4 (UI Blueprint) → Phase 5 (Preferences Blueprint) → Wiring
- **Track C**: Documentation and test planning can start immediately

## Success Criteria

All tasks completed AND:
- ✅ Timer displays accurate elapsed/remaining time
- ✅ Auto-stop works correctly for beats, bars, and time
- ✅ Settings persist across app restarts
- ✅ No metronome timing regressions (sub-millisecond accuracy maintained)
- ✅ All manual and edge case tests pass
- ✅ Performance targets met (< 0.1% CPU, < 1KB memory)
- ✅ UI remains clean and uncluttered
- ✅ Code follows project conventions
- ✅ CHANGELOG updated
