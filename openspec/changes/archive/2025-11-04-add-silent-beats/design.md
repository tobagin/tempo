# Silent Beats Design

## Architecture Overview

Silent/muted beats extend the metronome's training capabilities by selectively suppressing audio playback while maintaining visual feedback. The design introduces mute pattern strategies that determine which beats to silence, helping musicians develop internal timing.

## Core Concepts

### Mute vs. Skip
- **Mute**: Beat timing occurs, visual indicator shows, but NO audio plays
- **Skip**: Would remove beat entirely (NOT what we're doing)

This distinction is critical - muted beats still exist in the timing loop, only the audio playback is suppressed.

### Mute Patterns

#### 1. Every Nth Beat
- Mute every 2nd, 3rd, 4th, etc. beat
- Examples:
  - Every 2nd: Beat pattern `X - X - X -` (alternating)
  - Every 3rd: Beat pattern `X X - X X -`
  - Every 4th: Beat pattern `X X X - X X X -`
- Use case: Regular intervals for consistent practice

#### 2. Random Percentage
- Mute randomly selected percentage of beats
- Percentages: 25%, 50%, 75%
- Use pseudo-random with seed for reproducibility (optional: truly random)
- Use case: Unpredictable muting forces constant attention

#### 3. Specific Beats
- Mute only certain beats in the bar
- Common patterns:
  - Beats 2 & 4 only (for backbeat emphasis training)
  - Only downbeat (beat 1)
  - All except downbeat
- Use case: Genre-specific or emphasis training

#### 4. Progressive Muting
- Gradually increase mute frequency over time
- Start with 0% muted, increase to target (e.g., 75%)
- Time-based (every 30 seconds) or bar-based (every 16 bars)
- Use case: Building confidence gradually

### Visual Feedback for Muted Beats

Muted beats must still be visible:
- **Dimmed**: Lower opacity (0.4)
- **Outline only**: Hollow circle instead of filled
- **Different color**: Gray instead of normal color
- **Label**: Small "M" indicator or mute icon

## Core Components

### 1. MutePattern Interface

```vala
public interface MutePattern : GLib.Object {
    /**
     * Determine if a beat should be muted.
     * @param beat_number Current beat number (1-indexed)
     * @param beats_per_bar Beats per measure
     * @return true if beat should be muted (silent)
     */
    public abstract bool should_mute_beat(int beat_number, int beats_per_bar);

    /**
     * Reset pattern state (for patterns with internal state like progressive)
     */
    public abstract void reset();

    /**
     * Get human-readable description of pattern
     */
    public abstract string get_description();
}
```

### 2. Concrete Pattern Implementations

```vala
public class EveryNthPattern : GLib.Object, MutePattern {
    public int interval { get; set; } // Every Nth beat to mute

    public bool should_mute_beat(int beat_number, int beats_per_bar) {
        return (beat_number % interval) == 0;
    }

    public void reset() {
        // No state to reset
    }

    public string get_description() {
        return @"Every $(interval) beats muted";
    }
}

public class RandomPercentagePattern : GLib.Object, MutePattern {
    public double percentage { get; set; } // 0.0 to 1.0
    private GLib.Rand random;
    private uint32 seed;

    public RandomPercentagePattern(double percentage, uint32? seed = null) {
        this.percentage = percentage;
        this.seed = seed ?? (uint32)GLib.get_real_time();
        this.random = new GLib.Rand.with_seed(this.seed);
    }

    public bool should_mute_beat(int beat_number, int beats_per_bar) {
        return random.next_double() < percentage;
    }

    public void reset() {
        random.set_seed(seed); // Reset to initial seed for reproducibility
    }

    public string get_description() {
        return @"$(percentage * 100)% random muting";
    }
}

public class SpecificBeatsPattern : GLib.Object, MutePattern {
    public Gee.ArrayList<int> muted_beats { get; set; }

    public bool should_mute_beat(int beat_number, int beats_per_bar) {
        int beat_in_bar = ((beat_number - 1) % beats_per_bar) + 1;
        return beat_in_bar in muted_beats;
    }

    public void reset() {
        // No state to reset
    }

    public string get_description() {
        return @"Beats $(string.joinv(\", \", muted_beats.to_array())) muted";
    }
}

public class ProgressivePattern : GLib.Object, MutePattern {
    public double start_percentage { get; set; default = 0.0; }
    public double end_percentage { get; set; default = 0.75; }
    public int bars_interval { get; set; default = 16; } // Increase every N bars

    private int bars_elapsed = 0;
    private double current_percentage = 0.0;
    private GLib.Rand random;

    public bool should_mute_beat(int beat_number, int beats_per_bar) {
        // Update percentage based on bars elapsed
        if (beat_number % beats_per_bar == 1) {
            bars_elapsed++;
            if (bars_elapsed % bars_interval == 0) {
                double increment = (end_percentage - start_percentage) / (100 / bars_interval);
                current_percentage = double.min(current_percentage + increment, end_percentage);
            }
        }

        return random.next_double() < current_percentage;
    }

    public void reset() {
        bars_elapsed = 0;
        current_percentage = start_percentage;
        random = new GLib.Rand();
    }

    public string get_description() {
        return @"Progressive: $(start_percentage * 100)% → $(end_percentage * 100)%";
    }
}
```

### 3. MetronomeEngine Integration

```vala
public class MetronomeEngine : GLib.Object {
    // Existing properties...

    // NEW: Mute properties
    public bool mute_enabled { get; set; default = false; }
    public MutePattern? mute_pattern { get; set; default = null; }

    private bool on_beat_timeout() {
        // ... existing timing code ...

        // Determine if this beat should be muted
        bool is_muted = should_mute_current_beat();

        // Emit beat signal (always, regardless of mute)
        this.beat_occurred(current_beat, is_downbeat, is_muted);

        // Play sound ONLY if not muted
        if (!is_muted) {
            if (is_downbeat) {
                play_high_sound();
            } else {
                play_low_sound();
            }
        }

        // ... schedule next beat ...
    }

    private bool should_mute_current_beat() {
        if (!mute_enabled || mute_pattern == null) {
            return false;
        }

        return mute_pattern.should_mute_beat(current_beat, beats_per_bar);
    }
}
```

### 4. UI Integration

#### Main Window Controls
- **Mute Toggle**: Switch or checkbox to enable/disable muting
- **Pattern Selector**: Dropdown to choose mute pattern type
- **Pattern Parameters**: Adjustable based on selected pattern (e.g., interval spinner, percentage slider)
- **Visual indicator**: Add `is_muted` parameter to beat indicator drawing

#### Preferences Dialog
- **Mute Settings Page**: Dedicated section for mute configuration
- Pattern type selection (radio buttons)
- Pattern-specific parameters
- Preview mode (test pattern before applying)

## Visual Indicator Modifications

### Current Beat Indicator
Modify `MainWindow.vala` drawing function:

```vala
private void draw_beat_indicator(Cairo.Context cr, bool is_downbeat, bool is_muted) {
    // ... existing setup ...

    if (is_muted) {
        // Draw with muted styling
        cr.set_source_rgba(0.5, 0.5, 0.5, 0.4); // Dimmed gray
        cr.set_line_width(3.0);
        cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
        cr.stroke(); // Outline only

        // Add mute indicator
        cr.set_font_size(12);
        cr.move_to(center_x - 5, center_y + 5);
        cr.show_text("M");
    } else {
        // Normal beat drawing (existing code)
        // ...
    }
}
```

## Settings Schema

Add to `data/io.github.tobagin.tempo.gschema.xml.in`:

```xml
<key name="mute-enabled" type="b">
  <default>false</default>
  <summary>Enable beat muting</summary>
</key>

<key name="mute-pattern-type" type="s">
  <default>'none'</default>
  <summary>Mute pattern type</summary>
  <description>One of: 'none', 'every-nth', 'random', 'specific', 'progressive'</description>
</key>

<key name="mute-interval" type="i">
  <default>2</default>
  <range min="2" max="16"/>
  <summary>Interval for every-Nth pattern</summary>
</key>

<key name="mute-percentage" type="d">
  <default>0.5</default>
  <range min="0.0" max="1.0"/>
  <summary>Percentage for random muting (0.0-1.0)</summary>
</key>

<key name="mute-specific-beats" type="s">
  <default>'2,4'</default>
  <summary>Comma-separated beat numbers to mute</summary>
</key>

<key name="mute-progressive-start" type="d">
  <default>0.0</default>
  <range min="0.0" max="1.0"/>
  <summary>Starting mute percentage for progressive mode</summary>
</key>

<key name="mute-progressive-end" type="d">
  <default>0.75</default>
  <range min="0.0" max="1.0"/>
  <summary>Ending mute percentage for progressive mode</summary>
</key>

<key name="mute-progressive-interval" type="i">
  <default>16</default>
  <range min="1" max="64"/>
  <summary>Bars between mute increases in progressive mode</summary>
</key>
```

## Pattern Factory

```vala
public class MutePatternFactory : GLib.Object {
    public static MutePattern? create_from_settings(GLib.Settings settings) {
        string pattern_type = settings.get_string("mute-pattern-type");

        switch (pattern_type) {
            case "every-nth":
                int interval = settings.get_int("mute-interval");
                return new EveryNthPattern() { interval = interval };

            case "random":
                double percentage = settings.get_double("mute-percentage");
                return new RandomPercentagePattern(percentage);

            case "specific":
                string beats_str = settings.get_string("mute-specific-beats");
                var beats = parse_beat_list(beats_str);
                return new SpecificBeatsPattern() { muted_beats = beats };

            case "progressive":
                double start = settings.get_double("mute-progressive-start");
                double end = settings.get_double("mute-progressive-end");
                int interval = settings.get_int("mute-progressive-interval");
                return new ProgressivePattern() {
                    start_percentage = start,
                    end_percentage = end,
                    bars_interval = interval
                };

            default:
                return null;
        }
    }

    private static Gee.ArrayList<int> parse_beat_list(string beats_str) {
        var beats = new Gee.ArrayList<int>();
        foreach (string beat in beats_str.split(",")) {
            beats.add(int.parse(beat.strip()));
        }
        return beats;
    }
}
```

## User Workflows

### Basic Muting (Every Other Beat)
1. User toggles "Mute beats" switch in main window
2. Selects "Every 2nd beat" from pattern dropdown
3. Starts metronome
4. Hears: Click - Silent - Click - Silent...
5. Sees: All beats visible, muted ones dimmed

### Random Muting Practice
1. User opens preferences → Mute Settings
2. Selects "Random" pattern
3. Sets percentage to 50%
4. Starts metronome
5. Roughly half of beats are silent (unpredictable)
6. Visual shows which beats are muted

### Progressive Difficulty
1. User selects "Progressive" pattern
2. Sets start: 0%, end: 75%, interval: 16 bars
3. Starts metronome
4. First 16 bars: All audible
5. Next 16 bars: Few muted
6. Continues: Gradually more beats muted
7. Final state: 75% of beats muted

## Performance Considerations

### Timing Impact
- Mute decision adds negligible overhead (< 0.1ms)
- Should_mute check happens in existing beat callback
- No additional threading needed

### Memory
- Pattern objects: < 1KB each
- No significant memory overhead

### Random Performance
- GLib.Rand is fast (< 10 microseconds per call)
- Pre-seed at pattern creation, not per-beat

## Testing Strategy

### Unit Tests
- Each pattern type: Verify correct beats muted
- EveryNthPattern: Test intervals 2, 3, 4
- RandomPattern: Test percentage distribution (over 1000 beats)
- SpecificBeatsPattern: Test correct beats muted in bar
- ProgressivePattern: Test percentage increases correctly

### Integration Tests
- Mute doesn't affect timing precision
- Visual indicator correctly shows muted beats
- Settings persist across restarts
- Pattern changes apply immediately

### Manual Testing
- Verify audio actually silent on muted beats
- Visual feedback clear and helpful
- Pattern switching works while metronome running
- Progressive mode increases smoothly
