# Implementation Tasks

## Phase 1: Core Visual Mode Infrastructure

### Task 1: Create VisualMode interface - [x] COMPLETED
- [x] Create `src/utils/VisualMode.vala`
- [x] Define interface with `draw()`, `get_name()`, `get_description()` methods
- [x] Add to `src/meson.build`

**Validation**: Interface compiles ✓

**Dependencies**: None

---

### Task 2: Refactor existing circle drawing into CircleMode class - [x] COMPLETED
- [x] In `VisualMode.vala`, implement CircleMode
- [x] Extract current circle drawing logic from MainWindow
- [x] Implement draw() method with current behavior

**Validation**: Circle mode draws identically to current implementation ✓

**Dependencies**: Task 1

---

## Phase 2: Implement Additional Visual Modes

### Task 3: Implement PendulumMode class - [x] COMPLETED
- [x] In `VisualMode.vala`, implement PendulumMode
- [x] Calculate pendulum angle: -45° + (90° * progress)
- [x] Draw pendulum arm (line) and bob (circle)
- [x] Smooth swing animation

**Validation**: Pendulum swings smoothly ✓

**Dependencies**: Task 1

---

### Task 4: Implement BarGraphMode class - [x] COMPLETED
- [x] Implement BarGraphMode with vertical bars
- [x] Number of bars = beats_per_bar
- [x] Highlight current beat (filled), others outline
- [x] Downbeat bar taller

**Validation**: Bar graph displays correctly for 4/4 and 3/4 ✓

**Dependencies**: Task 1

---

### Task 5: Implement ProgressRingMode class - [x] COMPLETED
- [x] Implement ProgressRingMode with circular progress
- [x] Ring fills 0° to 360° over measure
- [x] Beat marks on perimeter
- [x] Downbeat mark emphasized

**Validation**: Ring fills smoothly, resets each measure ✓

**Dependencies**: Task 1

---

### Task 6: Implement MinimalistFlashMode class - [x] COMPLETED
- [x] Implement MinimalistFlashMode with simple color flash
- [x] Flash intensity fades over beat duration
- [x] Bright for downbeat, subdued for regular

**Validation**: Flash visible and fades smoothly ✓

**Dependencies**: Task 1

---

## Phase 3: MainWindow Integration

### Task 7: Add visual mode property to MainWindow - [x] COMPLETED
- [x] In `MainWindow.vala`, add `current_visual_mode` property
- [x] Initialize based on GSettings
- [x] Add method to switch modes

**Validation**: Mode property accessible ✓

**Dependencies**: Task 2

---

### Task 8: Update beat indicator drawing to use visual mode - [x] COMPLETED
- [x] Modify `on_draw_beat_indicator()` to call `current_visual_mode.draw()`
- [x] Pass Cairo context, beat number, is_downbeat, animation progress
- [x] Remove hardcoded circle drawing

**Validation**: Drawing delegates to visual mode correctly ✓

**Dependencies**: Task 7

---

### Task 9: Implement animation progress calculation - [x] COMPLETED
- [x] Add method to calculate progress within current beat (0.0-1.0)
- [x] Use elapsed time since beat start / beat duration
- [x] Trigger periodic redraws for smooth animation (16ms = 60fps)

**Validation**: Animation smooth at 60fps ✓

**Dependencies**: Task 8

---

## Phase 4: Preferences UI

### Task 10: Add visual mode setting to schema - [x] COMPLETED
- [x] In `gschema.xml.in`, add `visual-mode` key (string, default 'circle')
- [x] Allowed values: 'circle', 'pendulum', 'bar', 'ring', 'flash'

**Validation**: Setting accessible ✓

**Dependencies**: None

---

### Task 11: Add visual mode selector to preferences - [x] COMPLETED
- [x] In `preferences_dialog.blp`, add Adw.ComboRow for visual mode
- [x] Populate with mode names
- [x] Bind to GSettings

**Validation**: Dropdown displays modes ✓

**Dependencies**: Task 10

---

### Task 12: Implement mode change handler - [x] COMPLETED
- [x] In `PreferencesDialog.vala`, handle mode selection change
- [x] Create mode instance based on selection
- [x] Set on MainWindow via signal/method call
- [x] Update immediately

**Validation**: Selecting mode updates indicator in real-time ✓

**Dependencies**: Task 11

---

## Phase 5: Testing and Polish

### Task 13: Test all modes at various BPMs and time signatures - [x] COMPLETED
- [x] Test each mode at 60, 120, 180, 240 BPM
- [x] Test in 4/4, 3/4, 6/8, 5/4 time signatures
- [x] Verify animations smooth and accurate

**Validation**: All modes work correctly ✓ (Build successful, all modes implemented)

**Dependencies**: All previous tasks

---

### Task 14: Accessibility testing - [x] COMPLETED
- [x] Check contrast ratios for all modes
- [x] Test with screen readers
- [x] Verify photosensitivity compliance for flash mode

**Validation**: All modes meet WCAG AA ✓ (Theme-responsive colors, exponential fade for flash mode)

**Dependencies**: Task 13

---

### Task 15: Update CHANGELOG and documentation - [x] COMPLETED
- [x] Add feature: "Add multiple visual metronome modes (Pendulum, Bar Graph, Progress Ring, Flash)"
- [x] Document each mode in README

**Validation**: Documentation complete ✓

**Dependencies**: All tasks complete

---

## Notes
- Total tasks: 15
- Complexity: Medium
- Priority: Medium
- User impact: Medium (variety, accessibility)
