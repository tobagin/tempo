# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-26-timing-engine-conversion/spec.md

> Created: 2025-07-26
> Version: 1.0.0

## Technical Requirements

- **Timing Precision**: Maintain sub-millisecond accuracy using `GLib.get_monotonic_time()`
- **Thread Safety**: Use Vala async/await patterns instead of Python threading
- **Memory Management**: Leverage Vala's automatic memory management
- **Signal System**: Replace Python callbacks with GObject signals
- **State Persistence**: Maintain identical state structure and behavior
- **API Compatibility**: Preserve method signatures for seamless UI integration

## Approach Options

**Option A:** Direct Port with Async/Await
- Convert Python Thread to Vala async methods
- Use GLib.Timeout for timing loops
- Maintain separate timing thread equivalent

**Option B:** GLib MainLoop Integration (Selected)
- Use GLib.Timeout.add() for precision timing
- Integrate directly with GTK main loop
- Eliminate separate thread complexity

**Rationale:** Option B provides better integration with GTK, simpler debugging, and maintains timing precision while reducing thread complexity.

## External Dependencies

- **GLib-2.0** - Core timing functions and async support
- **GObject-2.0** - Signal system for callbacks

**Justification:** These are already part of the GTK4 stack, no additional dependencies required.

## Implementation Details

### MetronomeEngine Class Structure

```vala
public class MetronomeEngine : Object {
    // Properties
    public int bpm { get; set; default = 120; }
    public int beats_per_bar { get; set; default = 4; }
    public int beat_value { get; set; default = 4; }
    public bool is_running { get; private set; default = false; }
    public int current_beat { get; private set; default = 0; }
    
    // Signals
    public signal void beat_occurred(int beat_number, bool is_downbeat);
    
    // Methods
    public void start();
    public void stop();
    public void set_tempo(int bpm);
}
```

### Timing Implementation

- Use `GLib.get_monotonic_time()` for absolute time references
- Calculate next beat time using precise intervals
- Implement drift correction by adjusting to absolute timeline
- Use `GLib.Timeout.add()` with calculated intervals

### TapTempo Class Structure

```vala
public class TapTempo : Object {
    private int64[] tap_times;
    private int tap_count;
    
    public void add_tap();
    public int calculate_bpm();
    public void reset();
}
```

### State Management

- Convert Python dataclass to Vala struct or class
- Implement property change notifications
- Maintain thread-safe access patterns