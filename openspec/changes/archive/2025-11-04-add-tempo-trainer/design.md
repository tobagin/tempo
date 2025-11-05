# Tempo Trainer Design

## Architecture Overview

The Tempo Trainer feature adds intelligent tempo progression without compromising timing precision. The design uses a separate `TempoTrainer` utility class that monitors metronome progress and triggers tempo changes at appropriate intervals, maintaining clean separation from the core timing engine.

## Core Concepts

### Tempo Progression
A tempo trainer session consists of:
- **Start Tempo**: Initial BPM (40-240 range)
- **Target Tempo**: Desired ending BPM (40-240 range)
- **Increment**: BPM change per step (±1 to ±50 BPM)
- **Interval Type**: When to apply increment (bars or seconds)
- **Interval Value**: How many bars/seconds between increments

### Progression Modes

#### Bar-Based Progression
Tempo increases after completing N bars (measures).

**Example**: 60 BPM → 120 BPM, +5 BPM every 8 bars
```
Bars 1-8:    60 BPM
Bars 9-16:   65 BPM  (after 8 bars)
Bars 17-24:  70 BPM  (after 16 bars)
...
Bars 97-104: 120 BPM (target reached)
```

**Use Case**: Learning a musical passage - practice the same phrase multiple times with gradual speed increase.

#### Time-Based Progression
Tempo increases after N seconds of playing time.

**Example**: 80 BPM → 140 BPM, +2 BPM every 30 seconds
```
0-30s:   80 BPM
30-60s:  82 BPM  (after 30s)
60-90s:  84 BPM  (after 60s)
...
900s:    140 BPM (target reached after 15 minutes)
```

**Use Case**: Warm-up exercises - gradually increase speed over fixed time period.

### Direction Support
- **Ascending** (start < target): Build speed gradually
- **Descending** (start > target): Cool down or tempo challenges

## Core Components

### 1. TempoTrainer Class (`src/utils/TempoTrainer.vala`)

```vala
public class TempoTrainer : GLib.Object {
    // Configuration properties
    public bool enabled { get; set; default = false; }
    public int start_tempo { get; set; default = 60; }
    public int target_tempo { get; set; default = 120; }
    public int increment { get; set; default = 5; }
    public IntervalType interval_type { get; set; default = IntervalType.BARS; }
    public int interval_value { get; set; default = 8; }
    public bool auto_stop_at_target { get; set; default = false; }

    // Runtime state (not persisted)
    public bool is_active { get; private set; default = false; }
    public int current_tempo { get; private set; }
    public int bars_completed { get; private set; default = 0; }
    public int64 seconds_elapsed { get; private set; default = 0; }
    public int increments_completed { get; private set; default = 0; }

    // Methods
    public void start();
    public void pause();
    public void resume();
    public void reset();
    public void on_beat_occurred(int beat_num, int beats_per_bar);
    public void on_second_elapsed();

    // Signals
    public signal void tempo_should_change(int new_tempo);
    public signal void target_reached();
    public signal void progression_updated(int current, int target, int remaining);
}

public enum IntervalType {
    BARS,     // Every N bars
    SECONDS   // Every N seconds
}
```

### 2. Progression Logic

#### Calculating Next Tempo
```vala
private int calculate_next_tempo() {
    int next_tempo = current_tempo + increment;

    // Clamp to target (don't overshoot)
    if (increment > 0) {
        // Ascending: don't exceed target
        next_tempo = int.min(next_tempo, target_tempo);
    } else {
        // Descending: don't go below target
        next_tempo = int.max(next_tempo, target_tempo);
    }

    // Ensure within valid BPM range
    next_tempo = int.max(40, int.min(240, next_tempo));

    return next_tempo;
}
```

#### Checking If Target Reached
```vala
private bool is_target_reached() {
    if (increment > 0) {
        return current_tempo >= target_tempo;
    } else {
        return current_tempo <= target_tempo;
    }
}
```

#### Bar-Based Interval Tracking
```vala
public void on_beat_occurred(int beat_num, int beats_per_bar) {
    if (!is_active) return;
    if (interval_type != IntervalType.BARS) return;

    // Check if this is a downbeat (start of new bar)
    bool is_downbeat = (beat_num % beats_per_bar) == 1;
    if (!is_downbeat) return;

    bars_completed++;

    // Check if interval reached
    if (bars_completed >= interval_value) {
        if (!is_target_reached()) {
            int next_tempo = calculate_next_tempo();
            tempo_should_change(next_tempo);
            current_tempo = next_tempo;
            increments_completed++;
            bars_completed = 0;  // Reset counter
        }

        if (is_target_reached()) {
            target_reached();
        }
    }

    // Emit progress update
    progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
}
```

#### Time-Based Interval Tracking
```vala
private uint time_tracker_id = 0;

public void start() {
    // ...

    if (interval_type == IntervalType.SECONDS) {
        // Start 1-second timer
        time_tracker_id = GLib.Timeout.add_seconds(1, () => {
            on_second_elapsed();
            return is_active;  // Continue if active
        });
    }
}

public void on_second_elapsed() {
    if (!is_active) return;

    seconds_elapsed++;

    // Check if interval reached
    if (seconds_elapsed >= interval_value) {
        if (!is_target_reached()) {
            int next_tempo = calculate_next_tempo();
            tempo_should_change(next_tempo);
            current_tempo = next_tempo;
            increments_completed++;
            seconds_elapsed = 0;  // Reset counter
        }

        if (is_target_reached()) {
            target_reached();
        }
    }

    // Emit progress update
    progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
}
```

### 3. MetronomeEngine Integration

#### Connecting Signals
```vala
// In MainWindow or wherever TempoTrainer is instantiated
tempo_trainer = new TempoTrainer();

// Connect trainer to metronome
metronome_engine.beat_occurred.connect((beat_num, is_downbeat) => {
    int beats_per_bar = metronome_engine.beats_per_bar;
    tempo_trainer.on_beat_occurred(beat_num, beats_per_bar);
});

// Connect trainer's tempo change request to metronome
tempo_trainer.tempo_should_change.connect((new_tempo) => {
    try {
        metronome_engine.set_tempo(new_tempo);
        // Update UI tempo display
        update_tempo_display(new_tempo);
    } catch (MetronomeError e) {
        warning("Failed to apply tempo change: %s", e.message);
    }
});

// Handle target reached
tempo_trainer.target_reached.connect(() => {
    show_toast("Tempo Trainer: Target tempo %d BPM reached!".printf(tempo_trainer.target_tempo));

    if (tempo_trainer.auto_stop_at_target) {
        metronome_engine.stop();
    }
});
```

#### Tempo Change Application Strategy

**Critical Decision**: When to apply tempo change?

**Option A** - Immediate (as soon as interval reached):
- Pro: Responsive
- Con: May change mid-measure, disrupting timing

**Option B** - Next downbeat only:
- Pro: Musically aligned, smooth transition
- Con: Slight delay (max 1 measure)

**Recommendation**: **Option B** - Apply on next downbeat for smooth musical transitions.

```vala
public void on_beat_occurred(int beat_num, int beats_per_bar) {
    // ...existing interval checking...

    if (should_increment_tempo) {
        // Don't apply immediately - flag for next downbeat
        pending_tempo_change = calculate_next_tempo();
    }

    // At start of new measure
    bool is_downbeat = (beat_num % beats_per_bar) == 1;
    if (is_downbeat && pending_tempo_change != 0) {
        tempo_should_change(pending_tempo_change);
        current_tempo = pending_tempo_change;
        pending_tempo_change = 0;
    }
}
```

### 4. Settings Schema Extensions

Add to `data/io.github.tobagin.tempo.gschema.xml.in`:

```xml
<!-- Tempo Trainer Settings -->
<key name="trainer-enabled" type="b">
  <default>false</default>
  <summary>Tempo trainer enabled</summary>
  <description>Whether tempo trainer is currently active</description>
</key>

<key name="trainer-start-tempo" type="i">
  <range min="40" max="240"/>
  <default>60</default>
  <summary>Trainer start tempo</summary>
  <description>Initial BPM for tempo progression</description>
</key>

<key name="trainer-target-tempo" type="i">
  <range min="40" max="240"/>
  <default>120</default>
  <summary>Trainer target tempo</summary>
  <description>Target BPM for tempo progression</description>
</key>

<key name="trainer-increment" type="i">
  <range min="-50" max="50"/>
  <default>5</default>
  <summary>Trainer increment</summary>
  <description>BPM change per interval (negative for decrease)</description>
</key>

<key name="trainer-interval-type" type="i">
  <range min="0" max="1"/>
  <default>0</default>
  <summary>Trainer interval type</summary>
  <description>0=Bars, 1=Seconds</description>
</key>

<key name="trainer-interval-value" type="i">
  <range min="1" max="999"/>
  <default>8</default>
  <summary>Trainer interval value</summary>
  <description>Number of bars or seconds between tempo changes</description>
</key>

<key name="trainer-auto-stop" type="b">
  <default>false</default>
  <summary>Auto-stop at target tempo</summary>
  <description>Whether to stop metronome when target tempo is reached</description>
</key>
```

### 5. UI Integration

#### Main Window Trainer Section

**Layout Strategy**: Collapsible section below tempo controls

```
┌─────────────────────────────────┐
│       Tempo: 105 BPM            │
│  [━━━━━━━━━━━━━━━━━━━━━━━]     │  ← Tempo slider
│                                 │
│  ▼ Tempo Trainer                │  ← Expandable section
│  ┌─────────────────────────────┐│
│  │ Start: [60] → Target: [120] ││
│  │ Increment: [+5] every [8]bars││
│  │                              ││
│  │ Progress: 105/120 BPM        ││
│  │ Next change in 3 bars        ││
│  │                              ││
│  │ [Enable Trainer]  [⚙️]        ││
│  └─────────────────────────────┘│
│                                 │
│        Beat Indicator           │
└─────────────────────────────────┘
```

#### Progress Display Formats

**Bar-based**:
- "105/120 BPM, next +5 in 3 bars"
- "12 bars @ 105 BPM → 16 bars @ 110 BPM"

**Time-based**:
- "90/140 BPM, next +2 in 15 seconds"
- "2:30 @ 90 BPM → 3:00 @ 92 BPM"

**Target reached**:
- "Target reached: 120 BPM ✓"

#### Visual Indicators

**Active State**:
- Trainer section has accent color border
- Progress bar showing completion percentage
- "Trainer Active" badge on main window

**Inactive State**:
- Greyed out appearance
- No progress display

### 6. State Management

#### State Persistence

**Persisted (GSettings)**:
- Configuration: start_tempo, target_tempo, increment, interval_type, interval_value, auto_stop
- Enabled flag

**Not Persisted (Runtime Only)**:
- is_active (whether currently running)
- bars_completed / seconds_elapsed
- current_tempo
- increments_completed

**Rationale**: Each session starts fresh, but configuration is remembered for convenience.

#### Pause/Resume Behavior

```vala
public void pause() {
    if (!is_active) return;

    is_active = false;

    // Stop time tracker if time-based
    if (interval_type == IntervalType.SECONDS && time_tracker_id != 0) {
        Source.remove(time_tracker_id);
        time_tracker_id = 0;
    }

    // Preserve state: bars_completed, seconds_elapsed, current_tempo
}

public void resume() {
    if (is_active) return;

    is_active = true;

    // Resume from preserved state
    if (interval_type == IntervalType.SECONDS) {
        time_tracker_id = GLib.Timeout.add_seconds(1, () => {
            on_second_elapsed();
            return is_active;
        });
    }
}
```

## Data Flow

### Tempo Progression Sequence (Bar-Based)

```
User enables trainer (60 → 120 BPM, +5 every 8 bars)
    ↓
TempoTrainer.start()
    ↓
Set current_tempo = start_tempo (60 BPM)
Set bars_completed = 0
    ↓
MetronomeEngine plays, emits beat_occurred signals
    ↓
TempoTrainer.on_beat_occurred() called for each beat
    ↓
  Is downbeat?
    ├─ NO: Ignore (only count bars on downbeats)
    └─ YES: bars_completed++
        ↓
      bars_completed >= interval_value (8)?
        ├─ NO: Continue, emit progress update
        └─ YES: Calculate next tempo
            ↓
          next_tempo = current_tempo + increment (65 BPM)
            ↓
          next_tempo <= target_tempo?
            ├─ YES: Emit tempo_should_change(65)
            │       MetronomeEngine.set_tempo(65)
            │       bars_completed = 0 (reset)
            │       Show toast: "Tempo increased to 65 BPM"
            └─ NO: Target reached!
                   Emit target_reached()
                   Show toast: "Target 120 BPM reached"
                   Optional: Auto-stop metronome
```

### UI Update Sequence

```
TempoTrainer emits progression_updated signal
    ↓
MainWindow.on_progression_updated(current, target, remaining)
    ↓
Update progress label: "105/120 BPM"
    ↓
Calculate percentage: (105-60)/(120-60) = 75%
    ↓
Update progress bar to 75%
    ↓
  Interval type?
    ├─ BARS: Display "Next in X bars"
    └─ SECONDS: Display "Next in X seconds"
    ↓
Display updates complete (<16ms for smooth UI)
```

## Edge Cases & Error Handling

### Edge Case: User manually changes tempo during training
**Scenario**: Trainer running at 80 BPM, user drags slider to 100 BPM
**Handling**:
- Detect tempo change not from trainer (track last_applied_tempo)
- Pause trainer automatically
- Show toast: "Tempo Trainer paused (manual tempo change detected)"
- User must re-enable trainer to resume progression

### Edge Case: Increment overshoot target
**Scenario**: current=115 BPM, target=120 BPM, increment=+10 BPM
**Handling**:
- calculate_next_tempo() clamps to target (115+10 → 120, not 125)
- One final increment to exactly target
- Target reached after this increment

### Edge Case: Target already met at start
**Scenario**: start=120, target=120, increment=+5
**Handling**:
- Validate on trainer enable: show error "Start and target must differ"
- Prevent enabling with invalid configuration

### Edge Case: Time signature change during bar-based training
**Scenario**: Training in 4/4, user changes to 3/4 mid-session
**Handling**:
- Bar completion logic uses current beats_per_bar
- Bars completed count continues (already completed bars still valid)
- Next bar completion uses new time signature

### Edge Case: Very large increment warning
**Scenario**: User sets increment to +30 BPM
**Handling**:
- Show warning dialog: "Large increments may be difficult to follow. Suggested: ≤20 BPM"
- Allow proceeding or adjusting
- No hard limit (user knows their skill level)

### Edge Case: Negative interval value (decrease tempo)
**Scenario**: start=140, target=60, increment=-5
**Handling**:
- Fully supported (tempo challenges, cooldown exercises)
- UI shows "decreasing" language ("slowdown", "⬇")
- Same logic, increment is negative

### Error Handling: Invalid configuration
**Scenario**: Corrupted settings (increment=0, interval_value=0)
**Handling**:
- Validate on load:
  - increment != 0 (enforce range -50 to +50, excluding 0)
  - interval_value > 0 (minimum 1)
  - start != target
  - Both start and target in 40-240 range
- Fallback to defaults with warning
- Show error toast: "Trainer configuration invalid, reset to defaults"

## Performance Considerations

### CPU Impact
- Bar-based: Zero overhead (uses existing beat_occurred signal)
- Time-based: 1 timeout callback per second (negligible < 0.01% CPU)
- Tempo change: One-time operation per interval (< 1ms)
- **Total: < 0.1% CPU overhead**

### Memory Footprint
- TempoTrainer instance: ~200 bytes
- State variables: ~50 bytes
- GSettings keys: ~150 bytes
- **Total: < 500 bytes**

### Timing Impact
- Tempo changes applied at measure boundaries (no mid-beat changes)
- No impact on MetronomeEngine's sub-millisecond precision
- Tempo change operation takes < 1ms (recalculates beat_duration)

## Testing Strategy

### Unit Tests
1. **Tempo calculation**:
   - Test clamp to target (don't overshoot)
   - Test ascending (60→120, +5) and descending (120→60, -5)
   - Test edge: current=115, target=120, increment=+10 → 120

2. **Bar counting**:
   - Verify bars increment only on downbeats
   - Test across different time signatures (4/4, 3/4, 6/8)

3. **Time tracking**:
   - Verify seconds accumulate correctly
   - Test pause/resume preserves elapsed time

### Integration Tests
1. **Tempo changes applied correctly**:
   - Enable trainer, verify tempo increases after intervals
   - Verify tempo changes happen on downbeats
   - Verify target clamping

2. **Pause/resume state**:
   - Start trainer, pause metronome, verify bars_completed preserved
   - Resume, verify continues from same state

3. **Target completion**:
   - Run full progression to target
   - Verify target_reached signal emitted
   - Verify auto-stop if enabled

### Manual Testing Checklist
- [ ] Configure trainer: 60→120 BPM, +5 every 8 bars
- [ ] Enable trainer, verify starts at 60 BPM
- [ ] Count 8 bars, verify tempo increases to 65 BPM on 9th bar
- [ ] Verify smooth transition (no timing glitches)
- [ ] Progress display updates correctly
- [ ] Pause metronome, verify trainer pauses
- [ ] Resume, verify continues from same progression state
- [ ] Manual tempo change, verify trainer pauses with toast
- [ ] Target reached, verify notification and optional auto-stop
- [ ] Test time-based: +2 every 30 seconds
- [ ] Test descending: 140→60 BPM, -10 every 4 bars
- [ ] Test with subdivisions enabled (both work together)
- [ ] Test with practice timer enabled (both work together)
- [ ] Settings persist across app restart

## Accessibility Considerations

### Clear Labeling
- All trainer controls have clear labels and tooltips
- Progress format easy to read: "105/120 BPM"
- Interval explained: "every 8 bars" or "every 30 seconds"

### Keyboard Navigation
- All trainer controls accessible via keyboard
- Tab order logical (start → target → increment → interval)
- Enter key enables/disables trainer

### Screen Reader Support
- Progress updates announced: "Tempo increased to 65 beats per minute"
- Target completion announced: "Target tempo 120 beats per minute reached"
- Trainer state announced: "Tempo Trainer enabled" / "Tempo Trainer paused"

### Visual Feedback
- Progress bar provides visual representation
- Active state clearly indicated (color, border)
- Not relying on color alone (text + icons)

## Future Enhancements
Out of scope for this change:

1. **Progression Presets** (Feature #3 integration)
   - Save common progressions: "Warm-up", "Speed drill", "Cooldown"
   - Quick-load from dropdown

2. **Non-Linear Curves**
   - Logarithmic: fast start, slow approach to target
   - Exponential: slow start, accelerate toward target

3. **Adaptive Progression**
   - Monitor practice timer session length
   - Suggest optimal intervals based on tempo range

4. **Loop/Repeat**
   - After reaching target, loop back to start
   - Useful for continuous drills

5. **Multiple Targets**
   - Intermediate targets: 60→90→120 BPM
   - Different increments per stage

## Migration & Compatibility

### Settings Migration
- New settings have sensible defaults (trainer disabled)
- Existing users see no change until enabling trainer
- No migration script needed

### Backward Compatibility
- Trainer completely optional (disabled by default)
- When disabled, behavior identical to current version
- No breaking changes to existing APIs

### Forward Compatibility
- Trainer state designed for future session history integration
- Signal architecture supports future preset system
- Can extend with additional interval types (e.g., beats, minutes)
