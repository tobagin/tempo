# Visual Modes Design

## Visual Mode Types

### 1. Circle Mode (Current Default)
- Filled circle that pulses on each beat
- Downbeat: Red, larger radius
- Regular beat: Blue, standard radius
- Existing implementation

### 2. Pendulum Mode
- Swinging animation mimicking mechanical metronome
- Pendulum swings left-right-center rhythm
- Downbeat: Center position with emphasis
- Angle calculated: -45° to +45° swing
- Smooth interpolation between beats

### 3. Bar Graph Mode
- Vertical bars representing beat positions within measure
- Current beat: Highlighted bar (filled)
- Upcoming beats: Dimmed bars (outline)
- Downbeat: Taller/brighter first bar
- Bar width proportional to window size

### 4. Progress Ring Mode
- Circular progress indicator
- Ring fills clockwise from 12 o'clock
- Completes full circle per measure
- Beat marks on ring perimeter
- Downbeat: Emphasized mark at 12 o'clock

### 5. Minimalist Flash Mode
- Simple color flash filling entire indicator area
- Downbeat: Bright flash (high intensity)
- Regular: Subdued flash (medium intensity)
- No persistent indicator between beats
- Accessibility-friendly for photosensitivity

## Architecture

```vala
public interface VisualMode : GLib.Object {
    public abstract void draw(Cairo.Context cr, int beat, int beats_per_bar, bool is_downbeat, double animation_progress);
    public abstract string get_name();
    public abstract string get_description();
}

public class CircleMode : GLib.Object, VisualMode {
    public void draw(Cairo.Context cr, int beat, int beats_per_bar, bool is_downbeat, double progress) {
        // Current circle implementation
    }
}

public class PendulumMode : GLib.Object, VisualMode {
    public void draw(Cairo.Context cr, int beat, int beats_per_bar, bool is_downbeat, double progress) {
        // Draw pendulum arm and bob
        // Angle = -45° + (90° * progress)
    }
}
// Similar for BarGraphMode, ProgressRingMode, MinimalistFlashMode
```

## MainWindow Integration

```vala
public class MainWindow {
    private VisualMode current_visual_mode;

    private void on_beat_occurred(int beat, bool is_downbeat) {
        // Calculate animation progress (0.0 to 1.0 within beat)
        double progress = calculate_animation_progress();

        // Trigger redraw with current mode
        beat_indicator_area.queue_draw();
    }

    private void on_draw_beat_indicator(Cairo.Context cr) {
        current_visual_mode.draw(cr, current_beat, beats_per_bar, is_downbeat, animation_progress);
    }
}
```

## Settings

```xml
<key name="visual-mode" type="s">
  <default>'circle'</default>
  <summary>Visual indicator mode</summary>
  <description>One of: 'circle', 'pendulum', 'bar', 'ring', 'flash'</description>
</key>
```

## Performance

- Each draw call < 5ms
- Maintain 60fps for smooth animations
- Use double buffering to prevent flicker
- Minimize Cairo operations per frame
