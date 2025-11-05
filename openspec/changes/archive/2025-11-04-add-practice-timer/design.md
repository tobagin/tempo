# Practice Timer Design

## Architecture Overview

The practice timer feature introduces time tracking and auto-stop capabilities without compromising Tempo's core timing precision. The design follows the existing MVC pattern and maintains clean separation between timing logic, state management, and UI presentation.

## Core Components

### 1. PracticeTimer Class (`src/utils/PracticeTimer.vala`)
A new utility class responsible for timer logic and state management.

**Responsibilities:**
- Track elapsed practice time with millisecond precision
- Support count-up and countdown modes
- Implement auto-stop conditions (beats, bars, time)
- Emit signals for timer events (tick, completed, auto-stop triggered)
- Persist and restore timer state via GSettings

**Key Design Decisions:**
- **Separate from MetronomeEngine**: Keeps timing engine focused on metronome precision
- **Signal-based communication**: Uses GLib signals to notify UI of timer changes
- **Stateless time calculation**: Derives current time from start timestamp and GLib.get_monotonic_time()
- **No direct UI coupling**: Timer logic remains testable and UI-independent

**Public API:**
```vala
public class PracticeTimer : GLib.Object {
    // Properties
    public bool enabled { get; set; }
    public TimerMode mode { get; set; }  // COUNT_UP, COUNTDOWN
    public int64 elapsed_microseconds { get; private set; }
    public bool is_running { get; private set; }

    // Auto-stop configuration
    public AutoStopMode auto_stop_mode { get; set; }  // NONE, BEATS, BARS, TIME
    public int auto_stop_value { get; set; }

    // Methods
    public void start();
    public void pause();
    public void resume();
    public void reset();

    // Signals
    public signal void tick(int64 elapsed_microseconds, int64 remaining_microseconds);
    public signal void auto_stop_triggered();
    public signal void countdown_completed();
}

public enum TimerMode {
    COUNT_UP,
    COUNTDOWN
}

public enum AutoStopMode {
    NONE,
    BEATS,    // Stop after N beats
    BARS,     // Stop after N bars
    TIME      // Stop after N minutes
}
```

### 2. MetronomeEngine Integration
Minimal changes to existing `MetronomeEngine.vala` to support timer integration.

**Integration Points:**
- Add `PracticeTimer` instance as member variable
- Connect to timer's `auto_stop_triggered` signal to stop metronome
- Update beat counter to notify timer of beat/bar progress
- Synchronize timer start/stop with metronome state

**Design Rationale:**
- Timer is optional dependency injected into engine
- Engine remains testable without timer
- Timer can be disabled with zero performance impact

### 3. UI Integration (`src/windows/MainWindow.vala`)
Add timer display and controls to main window.

**UI Elements:**
- **Timer Display**: Label showing HH:MM:SS or MM:SS (toggleable visibility)
- **Timer Controls**: Integrated into existing control layout (no new buttons needed)
- **Auto-Stop Indicator**: Subtle badge or text showing active auto-stop condition
- **Preferences Section**: New "Practice Timer" group in PreferencesDialog

**Layout Strategy:**
```
┌─────────────────────┐
│   Beat Indicator    │
│      (Circle)       │
├─────────────────────┤
│    [12:34] ⏱️       │  ← Timer display (toggleable)
│  (15 bars remaining)│  ← Auto-stop progress (when active)
├─────────────────────┤
│   [▶️] [🔁] [⏹️]    │
│      Controls       │
└─────────────────────┘
```

### 4. Settings Schema Changes
Add new GSettings keys to `data/io.github.tobagin.tempo.gschema.xml.in`:

```xml
<!-- Practice Timer Settings -->
<key name="timer-enabled" type="b">
  <default>false</default>
  <summary>Timer enabled</summary>
  <description>Whether the practice timer is visible and active</description>
</key>

<key name="timer-mode" type="i">
  <range min="0" max="1"/>
  <default>0</default>
  <summary>Timer mode</summary>
  <description>0=Count-up, 1=Countdown</description>
</key>

<key name="timer-countdown-duration" type="i">
  <range min="1" max="180"/>
  <default>25</default>
  <summary>Countdown duration in minutes</summary>
  <description>Target duration for countdown timer</description>
</key>

<key name="timer-pause-with-metronome" type="b">
  <default>true</default>
  <summary>Pause timer when metronome stops</summary>
  <description>Whether timer should pause when metronome is stopped</description>
</key>

<key name="timer-auto-stop-mode" type="i">
  <range min="0" max="3"/>
  <default>0</default>
  <summary>Auto-stop mode</summary>
  <description>0=None, 1=Beats, 2=Bars, 3=Time</description>
</key>

<key name="timer-auto-stop-value" type="i">
  <range min="1" max="10000"/>
  <default>100</default>
  <summary>Auto-stop value</summary>
  <description>Number of beats/bars or minutes for auto-stop</description>
</key>

<key name="timer-show-in-main-window" type="b">
  <default>true</default>
  <summary>Show timer in main window</summary>
  <description>Whether to display timer in main window</description>
</key>
```

## Data Flow

### Timer Start Sequence
```
User clicks Play
    ↓
MainWindow.on_play_clicked()
    ↓
MetronomeEngine.start()
    ↓
PracticeTimer.start() (if timer_pause_with_metronome == true)
    ↓
Timer updates every second via GLib.Timeout
    ↓
PracticeTimer.tick signal emitted
    ↓
MainWindow updates timer display
```

### Auto-Stop Sequence
```
MetronomeEngine emits beat_occurred signal
    ↓
PracticeTimer.on_beat_occurred() increments beat/bar counter
    ↓
PracticeTimer checks auto-stop condition
    ↓
If condition met: emit auto_stop_triggered signal
    ↓
MetronomeEngine.stop() (connected to signal)
    ↓
Optional: Show notification toast
```

## Performance Considerations

### Timing Accuracy
- Timer uses separate GLib.Timeout (1 second interval) for display updates
- Does NOT interfere with metronome's high-precision timing loop
- Timer logic is event-driven, not polling-based
- Elapsed time calculated from monotonic timestamps (no accumulation drift)

### Memory Footprint
- PracticeTimer class: ~200 bytes per instance (single instance per app)
- GSettings keys: ~100 bytes total
- UI elements: Minimal (single label + optional progress text)
- **Total overhead: < 1KB**

### CPU Impact
- Timer tick: Once per second (negligible)
- Beat counter update: Triggered by existing beat_occurred signal
- No additional polling or busy-waiting
- **Expected CPU overhead: < 0.1%**

## Edge Cases & Error Handling

### Edge Case: Timer continues after metronome stop
**Scenario**: User stops metronome but timer keeps running
**Handling**: Controlled by `timer-pause-with-metronome` setting (default: pause)

### Edge Case: Countdown reaches zero
**Scenario**: Countdown timer reaches 00:00
**Handling**:
- Emit `countdown_completed` signal
- If auto-stop enabled: stop metronome
- Display notification toast
- Reset to countdown duration for next session

### Edge Case: Auto-stop triggered mid-measure
**Scenario**: Auto-stop condition met on beat 3 of 4/4 measure
**Handling**: Stop immediately (don't wait for downbeat)
**Rationale**: Precision more important than musical alignment for practice limits

### Edge Case: Settings changed while timer running
**Scenario**: User changes timer mode or auto-stop settings mid-session
**Handling**:
- Mode change: Reset timer to avoid confusion
- Auto-stop change: Apply immediately to current session
- Show toast: "Timer reset due to settings change"

### Error Handling: Invalid settings values
**Scenario**: Corrupted GSettings or programmatic error
**Handling**:
- Validate all timer settings on load
- Fallback to defaults for invalid values
- Log warning with g_warning()
- Continue gracefully (timer disabled if critical failure)

## Testing Strategy

### Unit Tests (Vala)
While Vala unit testing is limited, we can validate:
1. **Timer calculation accuracy**: Mock time source, verify elapsed calculation
2. **Auto-stop condition logic**: Test beat/bar/time thresholds
3. **State transitions**: Verify start/pause/resume/reset sequences
4. **Settings persistence**: Validate GSettings round-trip

### Integration Tests
1. **Metronome synchronization**: Timer starts/stops with metronome
2. **Auto-stop triggers**: Metronome stops at correct beat/bar/time
3. **Countdown completion**: Proper behavior at zero
4. **Settings changes**: UI updates reflect settings changes

### Manual Testing Checklist
- [ ] Timer displays correct elapsed time
- [ ] Count-up mode increments properly
- [ ] Countdown mode decrements to zero
- [ ] Auto-stop beats/bars/time work correctly
- [ ] Timer pauses/resumes with metronome (when setting enabled)
- [ ] Timer persists across app restarts
- [ ] Timer display toggles on/off
- [ ] Preferences UI controls work correctly
- [ ] No timing drift after 10+ minutes
- [ ] No performance degradation with timer enabled

## Accessibility Considerations

### Screen Reader Support
- Timer label has accessible name: "Practice timer"
- Auto-stop status announced: "Auto-stop in 15 bars"
- Timer completion announced via notification

### Visual Accessibility
- Timer uses system font size (respects accessibility settings)
- High contrast mode supported (inherits from GTK theme)
- Color not used as sole indicator (text always present)

### Keyboard Navigation
- Timer controls accessible via keyboard
- Shortcuts for timer toggle (Ctrl+T)
- All preferences keyboard-navigable

## Future Enhancements
These are explicitly out of scope for this change but documented for future reference:

1. **Session History** (Feature #11)
   - Store practice sessions in SQLite or JSON
   - Statistics view with graphs
   - Export to CSV

2. **Notifications**
   - Desktop notification when auto-stop triggers
   - Custom notification sounds
   - Milestone notifications (e.g., "30 minutes practiced!")

3. **Session Goals**
   - Weekly practice time goals
   - Streak tracking
   - Progress visualization

4. **Multiple Timers**
   - Separate timers for different practice activities
   - Timer presets (e.g., "Warm-up: 10 min", "Scales: 15 min")

## Migration & Compatibility

### Settings Migration
- New settings have sensible defaults (timer disabled)
- Existing users see no behavior change until they enable timer
- No migration script needed

### Backward Compatibility
- Timer is optional feature (no breaking changes)
- Can be completely disabled without affecting core functionality
- GSettings schema version remains compatible

### Forward Compatibility
- Timer settings designed to support future session history feature
- Auto-stop modes extensible (enum can add new values)
- Signal-based architecture allows future UI variations
