# Implementation Tasks

## Phase 1: Core Polyrhythm Engine

### Task 1: Create PolyrhythmEngine class skeleton
- Create `src/utils/PolyrhythmEngine.vala`
- Properties: stream1_beats, stream2_beats, bpm, is_running
- State: lcm_ticks, current_tick, next_tick_time
- Signals: stream1_beat, stream2_beat, cycle_complete
- Add to `src/meson.build`

**Validation**: Class compiles, instantiates

**Dependencies**: None

---

### Task 2: Implement LCM and GCD calculation
- In `PolyrhythmEngine`, add `calculate_gcd(int a, int b) -> int`
- Add `calculate_lcm(int a, int b) -> int`
- Test: LCM(3,4)=12, LCM(5,7)=35, LCM(4,6)=12

**Validation**: Math functions correct

**Dependencies**: Task 1

---

### Task 3: Implement tick scheduling logic
- In `PolyrhythmEngine`, implement `start()` method
- Calculate lcm_ticks and tick_duration
- Initialize timing state
- Implement `on_tick()` callback with absolute time scheduling
- Check if stream 1 or stream 2 should click on this tick

**Validation**: Correct ticks scheduled for both streams

**Dependencies**: Task 2

---

### Task 4: Implement audio playback for dual streams
- Initialize two audio players: stream1_player, stream2_player
- Implement `play_stream1_sound()`, `play_stream2_sound()`
- Set up GStreamer playbin for each stream
- Handle audio initialization errors

**Validation**: Both streams play distinct sounds

**Dependencies**: Task 3

---

### Task 5: Implement stereo panning
- Add panning support using GStreamer audiopanorama or balance property
- Stream 1: Pan left (balance = -1.0)
- Stream 2: Pan right (balance = +1.0)
- Add panning_enabled property

**Validation**: Stereo separation audible

**Dependencies**: Task 4

---

## Phase 2: UI Controls

### Task 6: Add polyrhythm settings to schema
- In `gschema.xml.in`, add keys: polyrhythm-enabled, stream1-beats, stream2-beats, panning-enabled
- Defaults: enabled=false, stream1=3, stream2=4, panning=true

**Validation**: Settings accessible

**Dependencies**: None

---

### Task 7: Add polyrhythm toggle to main window
- In `main_window.blp`, add Switch for polyrhythm mode
- Add spin buttons for stream beat counts
- Add preset dropdown for common polyrhythms
- Bind to GSettings

**Validation**: Controls display correctly

**Dependencies**: Task 6

---

### Task 8: Implement polyrhythm mode switching in MainWindow
- In `MainWindow.vala`, add polyrhythm_enabled property
- Switch between MetronomeEngine and PolyrhythmEngine based on mode
- Connect signals from PolyrhythmEngine to visual indicators

**Validation**: Mode switches correctly

**Dependencies**: Task 7

---

### Task 9: Implement polyrhythm presets
- Add preset data structure: name, stream1, stream2
- Presets: 2v3, 3v4, 3v5, 4v5, 5v7
- Populate preset dropdown in UI
- Apply preset on selection

**Validation**: Selecting preset configures streams

**Dependencies**: Task 7

---

## Phase 3: Visual Feedback

### Task 10: Implement dual visual indicators
- In `MainWindow.vala`, add `draw_polyrhythm_indicators()` method
- Draw two separate beat indicators (left and right)
- Each indicator shows beat position within its stream
- Use different colors or styles for distinction

**Validation**: Both indicators visible and update correctly

**Dependencies**: Task 8

---

### Task 11: Implement LCM cycle progress indicator
- Add progress bar showing current tick / lcm_ticks
- Display tick count label (e.g., "8/12")
- Update on each tick
- Reset on cycle completion

**Validation**: Progress bar fills and resets correctly

**Dependencies**: Task 10

---

## Phase 4: Testing

### Task 12: Test LCM calculations
- Unit tests for various stream combinations
- Test: 3v4, 5v7, 2v3, 7v11
- Verify tick positions correct

**Validation**: All polyrhythms mathematically correct

**Dependencies**: Task 2

---

### Task 13: Test timing accuracy
- Measure tick timing over 1000 cycles
- Verify < 1ms jitter
- Test at various BPMs (60, 120, 180, 240)
- Test complex polyrhythms (5v7)

**Validation**: Timing accurate at all BPMs

**Dependencies**: Task 3

---

### Task 14: Test stereo panning
- Verify left/right channel separation
- Test with headphones
- Ensure clear spatial distinction
- Test panning toggle

**Validation**: Stereo panning functional

**Dependencies**: Task 5

---

### Task 15: Manual musician testing
- Test with musicians practicing polyrhythms
- Gather usability feedback
- Verify clarity and helpfulness
- Test common polyrhythms (3v4 most common)

**Validation**: Feature usable for intended purpose

**Dependencies**: All previous tasks

---

### Task 16: Update CHANGELOG and documentation
- Add feature: "Add polyrhythm and polymetric support with dual rhythmic streams"
- Document how to use polyrhythm mode
- Explain stereo panning
- Provide musical examples

**Validation**: Documentation complete

**Dependencies**: All tasks complete

---

## Notes
- Total tasks: 16
- Complexity: Very High
- Priority: Low (⭐⭐ per TODO.md)
- User impact: Low (advanced users only)
- Recommendation: Implement after high-priority features
- Consider as "Pro" mode or separate feature flag
