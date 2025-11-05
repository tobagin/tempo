# Polyrhythm Design

## Core Concept: Polyrhythm vs Polymetric

### Polyrhythm
- Two different note subdivisions played against each other
- Example: 3 notes against 4 notes in same time span
- Both streams at same tempo, different division

### Polymetric
- Two different time signatures played simultaneously
- Example: 3/4 against 4/4
- Same tempo, bars complete at different times

## Mathematical Foundation

### Least Common Multiple (LCM) Scheduling
For 3 against 4:
- LCM(3, 4) = 12
- Stream 1: Click every 4 ticks (positions: 0, 4, 8)
- Stream 2: Click every 3 ticks (positions: 0, 3, 6, 9)
- Cycle completes after 12 ticks, both streams align

### Timing Calculation
```
BPM = 120 (0.5s per beat)
Stream 1 (3): 3 clicks per 0.5s = 0.1667s interval
Stream 2 (4): 4 clicks per 0.5s = 0.125s interval
LCM = 12 ticks in 0.5s = 0.04167s per tick
```

## Architecture

### PolyrhythmEngine Class

```vala
public class PolyrhythmEngine : GLib.Object {
    // Stream configurations
    public int stream1_beats { get; set; } // e.g., 3
    public int stream2_beats { get; set; } // e.g., 4
    public int bpm { get; set; }

    // Audio players (stereo or different sounds)
    private Gst.Element? stream1_player;
    private Gst.Element? stream2_player;

    // Timing
    private int lcm_ticks;
    private int current_tick = 0;
    private int64 next_tick_time = 0;
    private double tick_duration;

    // Signals
    public signal void stream1_beat(int beat_in_cycle);
    public signal void stream2_beat(int beat_in_cycle);
    public signal void cycle_complete();

    public void start() {
        lcm_ticks = calculate_lcm(stream1_beats, stream2_beats);
        tick_duration = calculate_tick_duration();
        next_tick_time = GLib.get_monotonic_time();
        schedule_next_tick();
    }

    private bool on_tick() {
        // Check if stream 1 should click
        if (current_tick % (lcm_ticks / stream1_beats) == 0) {
            play_stream1_sound();
            emit stream1_beat signal;
        }

        // Check if stream 2 should click
        if (current_tick % (lcm_ticks / stream2_beats) == 0) {
            play_stream2_sound();
            emit stream2_beat signal;
        }

        current_tick++;
        if (current_tick >= lcm_ticks) {
            current_tick = 0;
            emit cycle_complete();
        }

        next_tick_time += (int64)(tick_duration * 1000000);
        schedule_next_tick();
        return false;
    }

    private double calculate_tick_duration() {
        double beat_duration = 60.0 / (double)bpm;
        return beat_duration / (double)lcm_ticks;
    }

    private int calculate_lcm(int a, int b) {
        return (a * b) / calculate_gcd(a, b);
    }

    private int calculate_gcd(int a, int b) {
        while (b != 0) {
            int temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }
}
```

### Stereo Panning

```vala
// In PolyrhythmEngine
private void setup_audio_panning() {
    // Stream 1: Pan left
    stream1_player.set_property("volume", 1.0);
    // Use GStreamer audiopanorama element or set balance property
    // balance = -1.0 (full left)

    // Stream 2: Pan right
    stream2_player.set_property("volume", 1.0);
    // balance = 1.0 (full right)
}
```

### Dual Visual Indicators

```vala
// In MainWindow
private void draw_polyrhythm_indicators(Cairo.Context cr) {
    // Left side: Stream 1 indicator
    draw_stream_indicator(cr, stream1_beat, stream1_total, 50, is_stream1_left_aligned);

    // Right side: Stream 2 indicator
    draw_stream_indicator(cr, stream2_beat, stream2_total, width - 50, is_stream2_right_aligned);

    // Optionally: Show LCM cycle progress
    draw_cycle_progress(cr, current_tick, lcm_ticks);
}
```

## UI Design

### Polyrhythm Toggle
- Switch in main window: "Polyrhythm Mode"
- When enabled, show dual time signature controls

### Stream Configuration
- **Stream 1**: Spin button for beat count (1-16)
- **Stream 2**: Spin button for beat count (1-16)
- **Common BPM**: Single tempo control applies to both

### Presets
- Dropdown with common polyrhythms:
  - "2 against 3"
  - "3 against 4"
  - "3 against 5"
  - "4 against 5"
  - "5 against 7"
  - Custom

### Visual Layout
```
┌─────────────────────────────────────┐
│  Polyrhythm Mode: [ON]              │
│                                      │
│  Stream 1: [3] beats                │
│  Stream 2: [4] beats                │
│                                      │
│  Preset: [3 against 4 ▼]            │
│                                      │
│  ┌────────┐        ┌────────┐      │
│  │Stream 1│        │Stream 2│      │
│  │   ●    │        │   ●    │      │
│  │  1/3   │        │  2/4   │      │
│  └────────┘        └────────┘      │
│                                      │
│  Cycle: ████████░░░░ 8/12            │
└─────────────────────────────────────┘
```

## Settings

```xml
<key name="polyrhythm-enabled" type="b">
  <default>false</default>
</key>

<key name="polyrhythm-stream1-beats" type="i">
  <default>3</default>
  <range min="1" max="16"/>
</key>

<key name="polyrhythm-stream2-beats" type="i">
  <default>4</default>
  <range min="1" max="16"/>
</key>

<key name="polyrhythm-panning-enabled" type="b">
  <default>true</default>
  <summary>Use stereo panning for streams</summary>
</key>
```

## Testing Strategy

### Unit Tests
- LCM calculation: LCM(3,4)=12, LCM(5,7)=35
- GCD calculation: GCD(12,18)=6
- Tick scheduling: Verify correct ticks for each stream
- Beat alignment: Both streams align at cycle completion

### Integration Tests
- 3 against 4: Verify 3 clicks in stream 1, 4 in stream 2 per cycle
- Timing accuracy: Maintain < 1ms jitter over 100 cycles
- Audio panning: Verify left/right separation
- Visual indicators: Both streams update correctly

### Manual Testing
- Practice common polyrhythms with musicians
- Verify usability and clarity
- Test at various BPMs
- Ensure not confusing for users

## Performance Considerations

### Timing Complexity
- More tick callbacks than simple metronome
- 3 against 4: 12 ticks per beat vs 1 tick per beat
- At 120 BPM with 3v4: 1440 callbacks/minute vs 120
- Still < 0.1ms per callback, acceptable

### Memory
- PolyrhythmEngine: ~5KB
- Dual audio players: ~20KB
- Minimal overhead

## Implementation Recommendation

Given very high complexity and low user demand (priority ⭐⭐), recommend:
1. Complete high-priority features first (subdivisions, tempo trainer, presets)
2. Gather user feedback on polyrhythm demand
3. Consider as separate "Pro" mode or plugin
4. Alternative: Recommend users layer two Tempo instances with different time signatures
