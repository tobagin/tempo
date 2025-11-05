# Rhythm Patterns Design

## Architecture Overview

Rhythm patterns extend Tempo's metronome functionality with programmed rhythmic sequences. The design introduces a pattern sequencer that schedules note events based on pattern definitions, maintaining sub-millisecond timing accuracy while supporting complex rhythmic structures.

## Core Concepts

### Pattern Structure
A rhythm pattern is a sequence of steps, where each step specifies:
- **Position**: Time offset within the pattern (in beats or subdivisions)
- **Accent level**: Strength of the note (accent, regular, ghost)
- **Sound type**: Which sound to play (from available sound types)
- **Duration**: Note length (for future staccato/legato support)

### Pattern Types
1. **Clave Patterns**: 2-bar cycles with specific accent placements (3-2, 2-3)
2. **Groove Patterns**: Repeating rhythmic feels (bossa, samba, swing)
3. **Custom Patterns**: User-created sequences up to 64 beats

### Pattern JSON Format
```json
{
  "name": "Son Clave (3-2)",
  "description": "Traditional Cuban clave pattern",
  "length_beats": 8,
  "time_signature": "4/4",
  "steps": [
    {"beat": 0, "subdivision": 0, "accent": "strong", "sound": "high"},
    {"beat": 0, "subdivision": 2, "accent": "regular", "sound": "low"},
    {"beat": 1, "subdivision": 1, "accent": "regular", "sound": "low"},
    {"beat": 3, "subdivision": 0, "accent": "regular", "sound": "low"},
    {"beat": 3, "subdivision": 2, "accent": "regular", "sound": "low"},
    {"beat": 5, "subdivision": 1, "accent": "regular", "sound": "low"},
    {"beat": 7, "subdivision": 0, "accent": "regular", "sound": "low"}
  ]
}
```

## Core Components

### 1. RhythmPattern Class

```vala
public class RhythmPattern : GLib.Object {
    public string name { get; set; }
    public string description { get; set; }
    public int length_beats { get; set; }
    public int time_signature_numerator { get; set; }
    public int time_signature_denominator { get; set; }

    private Gee.ArrayList<PatternStep> steps;

    // Load from JSON file
    public static RhythmPattern? from_json_file(string path) throws Error;

    // Save to JSON file
    public void to_json_file(string path) throws Error;

    // Get steps for a specific beat
    public Gee.ArrayList<PatternStep> get_steps_at_beat(int beat);
}

public class PatternStep : GLib.Object {
    public int beat { get; set; }           // 0-based beat number
    public int subdivision { get; set; }     // Subdivision within beat (0 = on beat)
    public AccentLevel accent { get; set; }
    public string sound_type { get; set; }   // "high", "low", or custom sound name
}

public enum AccentLevel {
    GHOST,      // Very soft (volume 0.3)
    REGULAR,    // Normal (volume 0.7)
    STRONG      // Accented (volume 1.0)
}
```

### 2. PatternEngine Class

```vala
public class PatternEngine : GLib.Object {
    public RhythmPattern? active_pattern { get; set; }
    public bool is_running { get; private set; }
    public int current_beat { get; private set; }

    // Timing properties (mirrors MetronomeEngine)
    public int bpm { get; set; }

    // Audio players for different accent levels
    private Gst.Element? strong_player;
    private Gst.Element? regular_player;
    private Gst.Element? ghost_player;

    // Timing state
    private uint timeout_id = 0;
    private int64 next_step_time = 0;
    private int pattern_position = 0;  // Current step index

    // Signals
    public signal void step_occurred(PatternStep step, int beat_number);
    public signal void pattern_loop_completed();

    // Control methods
    public void start();
    public void stop();
    public void set_pattern(RhythmPattern pattern);
}
```

### 3. Pattern Library Manager

```vala
public class PatternLibrary : GLib.Object {
    private Gee.HashMap<string, RhythmPattern> built_in_patterns;
    private Gee.HashMap<string, RhythmPattern> user_patterns;

    // Load built-in patterns from gresource
    public void load_built_in_patterns() throws Error;

    // Load user patterns from config directory
    public void load_user_patterns() throws Error;

    // Get all patterns (built-in + user)
    public Gee.ArrayList<RhythmPattern> get_all_patterns();

    // Save user pattern
    public void save_user_pattern(RhythmPattern pattern) throws Error;

    // Delete user pattern
    public void delete_user_pattern(string name) throws Error;
}
```

### 4. Pattern Editor Dialog

Grid-based sequencer UI:
- Horizontal: Beats (columns)
- Vertical: Accent levels (rows)
- Cells: Clickable to toggle notes
- Controls: Name, description, length, time signature
- Preview button to test pattern
- Save/Cancel actions

## Built-in Patterns

### Latin Patterns
1. **Son Clave (3-2)** - 8 beats, classic Cuban clave
2. **Son Clave (2-3)** - 8 beats, reversed clave
3. **Rumba Clave (3-2)** - 8 beats, with displaced third note
4. **Bossa Nova** - 8 beats, Brazilian groove pattern

### Jazz/Swing Patterns
5. **Swing Ride** - 4 beats, triplet-based swing feel
6. **Jazz Waltz** - 6 beats (3/4 time), emphasis on 1 and 3

### Simple Patterns
7. **Two Against Three** - 6 beats, polyrhythmic pattern
8. **Backbeat** - 4 beats, emphasis on 2 and 4

## Integration with MetronomeEngine

### Mode Switching
```vala
public enum MetronomeMode {
    SIMPLE_BEATS,    // Current behavior
    PATTERN         // Use PatternEngine
}
```

MainWindow manages mode:
- Simple mode: Uses MetronomeEngine directly
- Pattern mode: Uses PatternEngine instead
- Toggle via UI dropdown/button

### Shared Timing Infrastructure
Both engines share:
- BPM setting
- Start/stop controls
- Beat number display
- Visual indicator updates

## Visual Feedback

### Pattern Mode Indicators
- Pattern name displayed in UI when active
- Beat indicator shows current position in pattern cycle
- Pattern length indicator (e.g., "Beat 3/8")
- Different colors for accent levels:
  - Strong: Bright color (e.g., red)
  - Regular: Standard color
  - Ghost: Dimmed color

### Pattern Visualization
Optional: Show pattern grid in compact view
- Small grid showing next 4 beats
- Filled cells indicate notes
- Current position highlighted

## Performance Considerations

### Memory
- Each pattern ~1-2KB in memory
- 20 built-in patterns ≈ 40KB
- User patterns limited to 100 (configurable)
- Total: < 300KB for pattern data

### Timing Precision
- Use same absolute time reference as MetronomeEngine
- Schedule next step dynamically based on pattern definition
- Maintain sub-millisecond accuracy
- No drift over long pattern cycles

### Audio Loading
- Pre-load all sound files at pattern activation
- Use separate GStreamer players for each accent level
- Avoid audio glitches during pattern playback

## File Locations

### Built-in Patterns
```
data/patterns/
├── son-clave-32.json
├── son-clave-23.json
├── rumba-clave.json
├── bossa-nova.json
├── swing-ride.json
└── ...
```

### User Patterns
```
~/.var/app/io.github.tobagin.tempo/config/tempo/patterns/
├── my-pattern-1.json
├── my-pattern-2.json
└── ...
```

## Error Handling

### Pattern Loading
- Invalid JSON: Display error, skip pattern
- Missing required fields: Use defaults where possible
- Duplicate names: Append number (e.g., "Pattern (2)")
- Corrupted user patterns: Log error, continue loading others

### Pattern Playback
- Invalid beat/subdivision: Clamp to valid range
- Missing sound type: Fall back to "high"/"low"
- Pattern longer than time signature: Wrap to pattern length

## Testing Strategy

### Unit Tests
- Pattern JSON serialization/deserialization
- Step timing calculation
- Pattern library loading
- Accent level volume mapping

### Integration Tests
- Pattern playback timing accuracy
- Mode switching (simple ↔ pattern)
- Pattern loops correctly
- UI updates on step events

### Manual Testing
- Load all built-in patterns successfully
- Create and save custom pattern
- Pattern playback maintains timing at various BPMs
- Editor UI intuitive and responsive
