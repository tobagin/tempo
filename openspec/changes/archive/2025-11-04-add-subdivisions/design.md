# Subdivisions Design

## Architecture Overview

Subdivisions add rhythmic divisions within each beat without compromising Tempo's sub-millisecond timing precision. The design extends the existing MetronomeEngine's absolute time reference architecture to schedule and play subdivision clicks between main beats, while maintaining the same drift-free timing guarantees.

## Core Concepts

### Musical Subdivisions
- **Eighth Notes (8ths)**: 2 subdivisions per beat - each beat divided in half
- **Sixteenth Notes (16ths)**: 4 subdivisions per beat - each beat divided into quarters
- **Triplets**: 3 subdivisions per beat - each beat divided into thirds (swing/shuffle feel)
- **None**: No subdivisions (current behavior)

### Timing Model
Each subdivision must be scheduled with absolute time precision to maintain musical accuracy:

```
Beat 1         Beat 2         Beat 3         Beat 4
|              |              |              |        (None)
| .            | .            | .            | .      (8ths - 2 per beat)
| . . .        | . . .        | . . .        | . . .  (16ths - 4 per beat)
| .  .         | .  .         | .  .         | .  .   (Triplets - 3 per beat, uneven spacing)
```

**Key Insight**: Subdivisions are NOT separate from beats - beat 1 IS the first subdivision. We only schedule the *additional* subdivisions between beats.

## Core Components

### 1. MetronomeEngine Extensions

#### New Properties
```vala
public class MetronomeEngine : GLib.Object {
    // Existing properties...

    // NEW: Subdivision properties
    public SubdivisionMode subdivision_mode { get; set; default = SubdivisionMode.NONE; }
    public double subdivision_volume { get; set; default = 0.5; }

    // NEW: Subdivision timing state
    private int subdivisions_per_beat = 1;
    private int64 next_subdivision_time = 0;
    private int current_subdivision_index = 0; // 0 = main beat, 1,2,3... = subdivisions

    // NEW: Subdivision audio player
    private Gst.Element? subdivision_sound_player = null;

    // NEW: Signal for subdivision events
    public signal void subdivision_occurred(int beat_number, int subdivision_index, int subdivisions_per_beat);
}

public enum SubdivisionMode {
    NONE = 0,      // No subdivisions (current behavior)
    EIGHTH = 2,    // 2 per beat (eighth notes)
    SIXTEENTH = 4, // 4 per beat (sixteenth notes)
    TRIPLET = 3    // 3 per beat (triplet feel)
}
```

#### Timing Calculation Logic

**Current beat scheduling** (simplified):
```vala
// Current implementation
next_beat_time = current_time + (int64)(beat_duration * 1000000);
```

**New subdivision scheduling** (per-click scheduling):
```vala
// Calculate duration for current subdivision/beat
double click_duration = calculate_click_duration(current_subdivision_index);
next_subdivision_time = current_time + (int64)(click_duration * 1000000);
```

**Helper function**:
```vala
private double calculate_click_duration(int subdivision_index) {
    if (subdivision_mode == SubdivisionMode.NONE) {
        return beat_duration;
    }

    // Duration per subdivision
    double subdivision_duration;

    if (subdivision_mode == SubdivisionMode.TRIPLET) {
        // Triplets: divide beat into 3 equal parts
        subdivision_duration = beat_duration / 3.0;
    } else {
        // Eighths (2) or Sixteenths (4): divide evenly
        subdivision_duration = beat_duration / (double)subdivisions_per_beat;
    }

    return subdivision_duration;
}
```

### 2. Modified Timing Loop

**Current loop** (one timeout per beat):
```
on_beat_timeout() {
    current_beat++;
    play_click(is_downbeat);
    emit beat_occurred();
    next_beat_time += beat_duration;
    schedule_next_beat();
}
```

**New loop** (one timeout per click, which may be beat or subdivision):
```
on_click_timeout() {
    // Determine if this is a main beat or subdivision
    bool is_main_beat = (current_subdivision_index == 0);
    bool is_downbeat = is_main_beat && (current_beat % beats_per_bar == 1);

    if (is_main_beat) {
        current_beat++;
        play_click(is_downbeat);  // Full volume main beat
        emit beat_occurred(current_beat, is_downbeat);
    } else {
        play_subdivision_click();  // Lighter volume subdivision
        emit subdivision_occurred(current_beat, current_subdivision_index, subdivisions_per_beat);
    }

    // Advance to next subdivision
    current_subdivision_index++;
    if (current_subdivision_index >= subdivisions_per_beat) {
        current_subdivision_index = 0;  // Next click will be a main beat
    }

    // Calculate next click time (absolute time)
    double click_duration = calculate_click_duration(current_subdivision_index);
    next_subdivision_time += (int64)(click_duration * 1000000);

    // Schedule next click
    schedule_next_click();
}
```

### 3. Audio Architecture

#### Sound Hierarchy
1. **Main Beat (Downbeat)**: High sound, accent volume (highest)
2. **Main Beat (Regular)**: Low sound, click volume (medium)
3. **Subdivision**: Subdivision sound, subdivision volume (lightest)

#### GStreamer Players
- **Existing**: `high_sound_player`, `low_sound_player`
- **New**: `subdivision_sound_player`

#### Sound Selection Strategy
- **Option A** (Simple): Use low sound at reduced volume (50% default)
- **Option B** (Customizable): Add `subdivision-sound-type` setting for separate sound
- **Recommendation**: Start with Option A, add Option B in future if requested

#### Volume Mixing
At 240 BPM with 16th notes:
- 240 beats/min = 4 beats/sec
- 4 subdivisions/beat = 16 clicks/sec
- Click duration must be < 62.5ms to avoid overlap

**Mitigation**:
- Keep subdivision sounds short (< 30ms)
- Reduce subdivision volume to 50% of click volume
- Add `overlap_check()` that shortens previous sound if needed

### 4. Visual Feedback

#### Beat Indicator Modifications

**Current**: Circular beat indicator shows only main beats

**New**: Add subdivision dots/pulses around circle

```
Eighth Notes (2 per beat):
    ●           Top = Main beat (current)
   . .          Sides = Subdivisions

Sixteenth Notes (4 per beat):
    ●           Top = Main beat
   . . .        Three positions for subdivisions

Triplets (3 per beat):
    ●           Top = Main beat
   . · .        Two positions for subdivisions (uneven spacing)
```

#### Drawing Logic
```vala
// In MainWindow drawing function
private void draw_subdivision_indicators(Cairo.Context cr, int beat_num, int subdiv_index) {
    if (subdivision_mode == SubdivisionMode.NONE) {
        return;
    }

    // Draw dots around circle at subdivision positions
    int total_subdivisions = get_subdivisions_per_beat();

    for (int i = 1; i < total_subdivisions; i++) {  // Skip 0 (main beat)
        double angle = (Math.PI * 2.0 * i) / total_subdivisions - Math.PI / 2;
        double x = center_x + radius * 1.2 * Math.cos(angle);
        double y = center_y + radius * 1.2 * Math.sin(angle);

        // Highlight current subdivision
        if (i == subdiv_index) {
            cr.set_source_rgba(accent_color.red, accent_color.green, accent_color.blue, 1.0);
            cr.arc(x, y, 6, 0, 2 * Math.PI);
        } else {
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.3);
            cr.arc(x, y, 3, 0, 2 * Math.PI);
        }
        cr.fill();
    }
}
```

### 5. Settings Schema Extensions

Add to `data/io.github.tobagin.tempo.gschema.xml.in`:

```xml
<!-- Subdivision Settings -->
<key name="subdivision-mode" type="i">
  <range min="0" max="3"/>
  <default>0</default>
  <summary>Subdivision mode</summary>
  <description>0=None, 2=Eighths, 3=Triplets, 4=Sixteenths</description>
</key>

<key name="subdivision-volume" type="d">
  <range min="0.0" max="1.0"/>
  <default>0.5</default>
  <summary>Subdivision volume</summary>
  <description>Volume level for subdivision clicks (relative to main beat)</description>
</key>

<key name="subdivision-sound-type" type="s">
  <default>"default"</default>
  <summary>Subdivision sound type</summary>
  <description>Built-in sound type for subdivisions: "default", "woodblock", "metal", or "digital"</description>
</key>

<key name="show-subdivision-indicators" type="b">
  <default>true</default>
  <summary>Show subdivision visual indicators</summary>
  <description>Whether to display subdivision dots/markers around beat circle</description>
</key>
```

## Data Flow

### Subdivision Timing Sequence
```
User enables 16th notes (subdivisions_per_beat = 4)
    ↓
MetronomeEngine.start()
    ↓
current_subdivision_index = 0 (first click is main beat)
    ↓
schedule_next_click() calculates wait time to next click
    ↓
on_click_timeout() called
    ↓
  Is subdivision_index == 0?
    ├─ YES: Play main beat sound, emit beat_occurred signal
    └─ NO: Play subdivision sound, emit subdivision_occurred signal
    ↓
Increment subdivision_index (0→1→2→3→0→1→2→3...)
    ↓
Calculate next click time using absolute reference
    ↓
schedule_next_click() → repeat
```

### Visual Update Sequence
```
subdivision_occurred signal emitted
    ↓
MainWindow.on_subdivision_occurred(beat_num, subdiv_index, subdivs_per_beat)
    ↓
Update subdivision indicator positions
    ↓
Trigger Cairo redraw of beat indicator
    ↓
draw_subdivision_indicators() highlights active subdivision dot
    ↓
Display updates complete (< 16ms for 60fps)
```

## Performance Considerations

### Timing Accuracy
- **Target**: Sub-millisecond precision maintained at all tempos
- **Validation**:
  - Test at 240 BPM with 16ths (16 clicks/sec)
  - Measure drift over 10 minutes
  - Expected: < 1ms accumulated error

### CPU Impact
At maximum load (240 BPM, 16th notes):
- 16 clicks/sec × overhead per click
- Estimated overhead:
  - Audio playback: ~0.5% CPU
  - Visual updates: ~1% CPU
  - Timing calculations: < 0.1% CPU
- **Total: ~2% CPU overhead (acceptable)**

### Memory Footprint
- 3 GStreamer players (high, low, subdivision): ~1.5KB
- Subdivision state variables: ~32 bytes
- Settings keys: ~100 bytes
- **Total: < 2KB additional memory**

### Audio Latency
- Must maintain < 10ms latency for timing perception
- GStreamer buffer size already optimized
- Subdivision clicks use same pipeline (no additional latency)

## Edge Cases & Error Handling

### Edge Case: Tempo change mid-subdivision
**Scenario**: User changes tempo while subdivision 2 of 4 is playing
**Handling**:
- Complete current beat's subdivisions at old tempo
- Apply new tempo starting next main beat (subdivision_index = 0)
- Recalculate `next_subdivision_time` on beat boundary

### Edge Case: Subdivision mode change mid-beat
**Scenario**: User switches from 8ths to 16ths while subdivision 1 of 2 is playing
**Handling**:
- Stop current beat immediately
- Reset `current_subdivision_index = 0`
- Apply new subdivision mode starting next beat
- Show toast: "Subdivision mode changed to Sixteenth Notes"

### Edge Case: Very fast tempo with 16ths (240 BPM)
**Scenario**: 240 BPM = 4 beats/sec × 4 subdivisions = 16 clicks/sec (62.5ms per click)
**Handling**:
- Validate click sound duration < 50ms
- If sounds overlap, reduce subdivision volume further
- Add warning in preferences: "At very fast tempos, subdivisions may sound dense"

### Edge Case: Triplets in compound time (6/8, 9/8)
**Scenario**: 6/8 time signature with triplet subdivisions
**Handling**:
- Triplets divide the *beat* not the measure
- In 6/8: beat = dotted quarter (3 eighths), triplet divides each beat into 3
- Works correctly with current design (no special handling needed)

### Error Handling: Audio system failure with subdivisions
**Scenario**: Subdivision audio player fails to initialize
**Handling**:
- Fall back to visual-only mode for subdivisions
- Log warning: "Subdivision audio unavailable, visual-only mode"
- Main beat audio continues normally
- User sees subdivision indicators but no sound

### Error Handling: Invalid subdivision mode from settings
**Scenario**: Corrupted GSettings with subdivision_mode = 7 (invalid)
**Handling**:
- Validate on load: `if (mode < 0 || mode > 4) mode = 0`
- Log warning with g_warning()
- Fallback to NONE mode
- Reset settings key to default (0)

## Testing Strategy

### Unit Tests
1. **Subdivision timing accuracy**:
   - Calculate 100 subdivision times at each mode
   - Verify equal spacing (8ths, 16ths) or 1:1:1 ratio (triplets)

2. **Click type determination**:
   - Verify subdivision_index = 0 triggers main beat
   - Verify subdivision_index > 0 triggers subdivision

3. **Mode switching**:
   - Test transition between all modes (None→8ths→16ths→Triplets→None)
   - Verify state reset correctly

### Integration Tests
1. **Audio playback**:
   - Verify correct sound player called for beats vs subdivisions
   - Verify volume differences (main beat > subdivision)

2. **Visual synchronization**:
   - Verify subdivision indicators update on correct timing
   - Verify indicator positions match subdivision mode

3. **Settings persistence**:
   - Set subdivision mode, restart app, verify mode preserved
   - Change volume, verify new value used on next play

### Manual Testing Checklist
- [ ] Enable 8ths: hear 2 clicks per beat (main + 1 subdivision)
- [ ] Enable 16ths: hear 4 clicks per beat (main + 3 subdivisions)
- [ ] Enable triplets: hear 3 clicks per beat with swing feel
- [ ] Subdivision volume is noticeably quieter than main beats
- [ ] Subdivision indicators visible and synchronized with audio
- [ ] Change tempo mid-play: subdivisions adjust correctly
- [ ] Change subdivision mode mid-play: switch applies cleanly
- [ ] Test at 40 BPM (slowest): subdivisions spaced properly
- [ ] Test at 240 BPM (fastest): no audio overlap or jitter
- [ ] Test in various time signatures (4/4, 3/4, 6/8, 5/4, 7/8)
- [ ] Disable subdivisions: returns to normal behavior
- [ ] Visual indicators toggle on/off with setting
- [ ] No timing regression for main beats (with subdivisions disabled)

### Performance Validation
- [ ] Profile CPU at 240 BPM with 16ths: verify < 2% overhead
- [ ] Measure memory: verify < 2KB increase
- [ ] Measure timing accuracy: verify < 1ms drift over 10 minutes
- [ ] Verify audio latency unchanged (< 10ms)
- [ ] Test battery impact on laptop (if applicable)

## Accessibility Considerations

### Audio Accessibility
- Subdivision volume independent of main beats (configurable)
- Distinct sound option for color-blind equivalent
- Volume range allows reducing to barely audible for reference

### Visual Accessibility
- Subdivision indicators use high contrast
- Size configurable (3px inactive, 6px active)
- Can be completely disabled via setting
- Work with dark/light themes

### Cognitive Accessibility
- Simple mode selection (dropdown with 4 options)
- Visual preview of subdivision pattern in preferences
- Clear labeling: "Eighth Notes (2 per beat)"
- Tooltip help text explaining each mode

## Future Enhancements
These are explicitly out of scope but documented for reference:

1. **Custom Subdivision Ratios** (Feature #6 - Rhythm Patterns)
   - 5-lets, 7-lets, custom patterns
   - Subdivision sequencer

2. **Polyrhythmic Subdivisions** (Feature #10)
   - 3 against 4, 5 against 7
   - Dual subdivision tracks

3. **Visual Subdivision Modes**
   - Bar graph style
   - Linear timeline view
   - Circular subdivisions (like clock)

4. **Subdivision Accents**
   - Accent every Nth subdivision
   - Custom accent patterns within subdivisions

5. **MIDI Subdivision Output** (Feature #8)
   - Send MIDI notes for subdivisions
   - Useful for syncing with DAWs

## Migration & Compatibility

### Settings Migration
- New settings have safe defaults (mode = NONE, volume = 0.5)
- Existing users see no change until subdivisions enabled
- No migration script needed

### Backward Compatibility
- Subdivisions completely optional (mode = NONE is default)
- When disabled, behavior identical to current version
- No breaking changes to existing API
- MetronomeEngine signal `beat_occurred` unchanged

### Forward Compatibility
- `subdivision_occurred` signal designed for future rhythm pattern features
- SubdivisionMode enum extensible (can add more modes)
- Visual indicator system can support custom patterns later
- Audio architecture supports future MIDI output
