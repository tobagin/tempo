/**
 * Interface for different visual metronome modes.
 *
 * Each mode provides a different way to visualize beats:
 * - Circle: Traditional pulsing circle (default)
 * - Pendulum: Swinging animation mimicking mechanical metronomes
 * - Bar Graph: Vertical bars showing beat positions
 * - Progress Ring: Circular progress indicator
 * - Minimalist Flash: Simple color flash
 */

public interface VisualMode : GLib.Object {
    /**
     * Draw the visual indicator for the current beat.
     *
     * @param cr Cairo context for drawing
     * @param beat Current beat number (1-based)
     * @param beats_per_bar Total beats in the current bar
     * @param is_downbeat Whether the current beat is a downbeat
     * @param is_muted Whether the current beat is muted
     * @param animation_progress Progress within current beat (0.0-1.0)
     * @param width Drawing area width
     * @param height Drawing area height
     */
    public abstract void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    );

    /**
     * Get the internal name/ID of this mode (for settings).
     */
    public abstract string get_name();

    /**
     * Get a user-friendly description of this mode.
     */
    public abstract string get_description();
}

/**
 * Circle Mode - Traditional pulsing circle indicator.
 * This is the default mode matching the original Tempo design.
 */
public class CircleMode : GLib.Object, VisualMode {
    private Adw.StyleManager style_manager;
    private GLib.Settings settings;

    public CircleMode(GLib.Settings settings) {
        this.settings = settings;
        this.style_manager = Adw.StyleManager.get_default();
    }

    public void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    ) {
        // Get center coordinates and radius - much larger circle with margin for pulse effect
        double center_x = width / 2.0;
        double center_y = height / 2.0;
        double base_radius = double.min(width, height) / 2 - 85;

        // Read visual preferences
        bool show_beat_numbers = settings.get_boolean("show-beat-numbers");
        bool flash_on_beat = settings.get_boolean("flash-on-beat");
        bool downbeat_color = settings.get_boolean("downbeat-color");

        // Get theme-responsive colors
        bool is_dark_theme = style_manager.dark;

        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();

        // Calculate dynamic radius for flash effect
        double radius = base_radius;
        double glow_intensity = 0.0;
        bool beat_active = animation_progress < 0.1; // Active for first 10% of beat

        if (beat_active && flash_on_beat) {
            // Enhanced flash effect with bigger scaling and glow
            double flash_scale = 1.3;
            radius = base_radius * flash_scale;
            glow_intensity = 1.0;
        }

        // Define theme-responsive colors
        double[] regular_color;
        if (is_dark_theme) {
            regular_color = {0.3, 0.7, 1.0};     // Light blue for dark theme
        } else {
            regular_color = {0.2, 0.5, 0.9};     // Darker blue for light theme
        }

        double[] downbeat_accent_color;
        if (downbeat_color) {
            if (is_dark_theme) {
                downbeat_accent_color = {1.0, 0.4, 0.4};     // Light red for dark theme
            } else {
                downbeat_accent_color = {0.9, 0.2, 0.2};     // Dark red for light theme
            }
        } else {
            downbeat_accent_color = regular_color;            // Use regular color if downbeat highlighting disabled
        }

        double[] inactive_color;
        if (is_dark_theme) {
            inactive_color = {0.6, 0.6, 0.6};     // Light gray for dark theme
        } else {
            inactive_color = {0.4, 0.4, 0.4};     // Dark gray for light theme
        }

        if (beat_active) {
            // If beat is muted, draw with dimmed styling
            if (is_muted) {
                // Muted beat - dimmed gray outline only
                double muted_color[] = {0.5, 0.5, 0.5}; // Gray
                double muted_opacity = 0.4;

                // Draw outline only (stroke, not fill)
                cr.set_source_rgba(muted_color[0], muted_color[1], muted_color[2], muted_opacity);
                cr.set_line_width(4.0);
                cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
                cr.stroke();

                // Add small "M" indicator for muted
                cr.set_font_size(base_radius * 0.2);
                cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);

                var mute_text = "M";
                Cairo.TextExtents mute_extents;
                cr.text_extents(mute_text, out mute_extents);

                // Position "M" at top of circle
                double text_x = center_x - mute_extents.width / 2;
                double text_y = center_y - radius + mute_extents.height + 5;

                cr.set_source_rgba(muted_color[0], muted_color[1], muted_color[2], muted_opacity * 1.5);
                cr.move_to(text_x, text_y);
                cr.show_text(mute_text);
            } else {
                // Normal active beat
                // Choose color based on beat type and preferences
                double[] active_color = (is_downbeat && downbeat_color) ?
                    downbeat_accent_color : regular_color;

                if (flash_on_beat) {
                    // Multi-layer glow effect with more dramatic expansion
                    for (int i = 4; i >= 0; i--) {
                        double layer_radius = radius + (i * 12);
                        double layer_alpha = glow_intensity * (0.4 - i * 0.08);

                        cr.set_source_rgba(active_color[0], active_color[1], active_color[2], layer_alpha);
                        cr.arc(center_x, center_y, layer_radius, 0, 2 * Math.PI);
                        cr.fill();
                    }
                }

                // Main filled circle with gradient
                var pattern = new Cairo.Pattern.radial(center_x, center_y, 0,
                                                      center_x, center_y, radius);
                pattern.add_color_stop_rgba(0.0, active_color[0], active_color[1], active_color[2], 0.9);
                pattern.add_color_stop_rgba(0.7, active_color[0], active_color[1], active_color[2], 0.7);
                pattern.add_color_stop_rgba(1.0, active_color[0], active_color[1], active_color[2], 0.3);

                cr.set_source(pattern);
                cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
                cr.fill();

                // Inner highlight for 3D effect
                var highlight = new Cairo.Pattern.radial(center_x - radius/3, center_y - radius/3, 0,
                                                        center_x, center_y, radius * 0.6);
                highlight.add_color_stop_rgba(0.0, 1.0, 1.0, 1.0, 0.4);
                highlight.add_color_stop_rgba(1.0, 1.0, 1.0, 1.0, 0.0);

                cr.set_source(highlight);
                cr.arc(center_x, center_y, radius * 0.6, 0, 2 * Math.PI);
                cr.fill();
            }

        } else {
            // Inactive state - elegant outline with subtle gradient
            double outline_width = 3.0;

            // Outer glow for inactive state
            cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.2);
            cr.set_line_width(outline_width * 2);
            cr.arc(center_x, center_y, base_radius + 2, 0, 2 * Math.PI);
            cr.stroke();

            // Main outline
            cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.6);
            cr.set_line_width(outline_width);
            cr.arc(center_x, center_y, base_radius, 0, 2 * Math.PI);
            cr.stroke();

            // Inner subtle fill
            cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.1);
            cr.arc(center_x, center_y, base_radius - outline_width, 0, 2 * Math.PI);
            cr.fill();
        }

        // Draw beat number if enabled
        if (show_beat_numbers && beat > 0) {
            // Calculate font size based on circle size
            double font_size = base_radius * 0.4;
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(font_size);

            var beat_text = beat.to_string();
            Cairo.TextExtents extents;
            cr.text_extents(beat_text, out extents);

            // Text with subtle shadow for better readability
            // Shadow
            cr.set_source_rgba(0, 0, 0, 0.2);
            cr.move_to(center_x - extents.width / 2 + 1, center_y + extents.height / 2 + 1);
            cr.show_text(beat_text);

            // Main text
            cr.set_source_rgba(is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1, 1.0);
            cr.move_to(center_x - extents.width / 2, center_y + extents.height / 2);
            cr.show_text(beat_text);
        }

        // Draw small beat progress indicators around the circle (when beat > 0)
        if (beat > 0) {
            double indicator_radius = base_radius + 20;
            double indicator_size = 4.0;

            for (int i = 1; i <= beats_per_bar; i++) {
                double angle = (i - 1) * 2 * Math.PI / beats_per_bar - Math.PI / 2;
                double dot_x = center_x + Math.cos(angle) * indicator_radius;
                double dot_y = center_y + Math.sin(angle) * indicator_radius;

                if (i == beat) {
                    // Current beat - larger, brighter
                    cr.set_source_rgba(regular_color[0], regular_color[1], regular_color[2], 0.9);
                    cr.arc(dot_x, dot_y, indicator_size * 1.5, 0, 2 * Math.PI);
                } else {
                    // Other beats - smaller, dimmer
                    cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.4);
                    cr.arc(dot_x, dot_y, indicator_size, 0, 2 * Math.PI);
                }
                cr.fill();
            }
        }
    }

    public string get_name() {
        return "circle";
    }

    public string get_description() {
        return _("Circle - Traditional pulsing circle indicator");
    }
}

/**
 * Pendulum Mode - Swinging animation mimicking mechanical metronomes.
 */
public class PendulumMode : GLib.Object, VisualMode {
    private Adw.StyleManager style_manager;
    private GLib.Settings settings;

    public PendulumMode(GLib.Settings settings) {
        this.settings = settings;
        this.style_manager = Adw.StyleManager.get_default();
    }

    public void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    ) {
        // Get theme-responsive colors
        bool is_dark_theme = style_manager.dark;
        bool downbeat_color = settings.get_boolean("downbeat-color");

        double center_x = width / 2.0;
        double center_y = height / 2.0;
        // Make pendulum longer - use more of the available space
        double arm_length = double.min(width, height) / 2 - 30;

        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();

        // Calculate pendulum angle with physics-based easing
        // Real pendulums follow sinusoidal motion: fastest at center, slowest at extremes
        double max_angle = 45.0; // Swing angle
        double start_angle, end_angle;

        if (beat == 0) {
            // When stopped, pendulum rests at center
            start_angle = 0.0;
            end_angle = 0.0;
        } else if (beat == 1) {
            // First beat: start from center, swing to right
            start_angle = 0.0;
            end_angle = max_angle;
        } else if (beat % 2 == 0) {
            // Even beats (2, 4, 6...): swing from right to left
            start_angle = max_angle;
            end_angle = -max_angle;
        } else {
            // Odd beats (3, 5, 7...): swing from left to right
            start_angle = -max_angle;
            end_angle = max_angle;
        }

        // Apply sinusoidal easing for realistic pendulum motion
        // This makes the pendulum move faster in the middle and slower at the extremes
        // Using cosine-based interpolation: starts slow, accelerates, then decelerates
        double eased_progress = (1.0 - Math.cos(animation_progress * Math.PI)) / 2.0;
        double angle = start_angle + (end_angle - start_angle) * eased_progress;
        double angle_rad = angle * Math.PI / 180.0;

        // Calculate pendulum bob position
        double pivot_y = center_y - arm_length * 0.3; // Pivot point higher for longer swing
        double bob_x = center_x + Math.sin(angle_rad) * arm_length;
        double bob_y = pivot_y + Math.cos(angle_rad) * arm_length;

        // Calculate bob size (scaled to arm length for proper proportions)
        double bob_radius = Math.fmin(22.0, arm_length * 0.12);

        // Define colors based on state
        double[] arm_color;
        double[] bob_color;
        double[] pivot_color;

        if (is_muted) {
            arm_color = {0.5, 0.5, 0.5};
            bob_color = {0.5, 0.5, 0.5};
            pivot_color = {0.6, 0.6, 0.6};
        } else if (is_downbeat && downbeat_color) {
            if (is_dark_theme) {
                arm_color = {0.8, 0.3, 0.3};
                bob_color = {1.0, 0.4, 0.4};
                pivot_color = {0.9, 0.35, 0.35};
            } else {
                arm_color = {0.7, 0.2, 0.2};
                bob_color = {0.9, 0.2, 0.2};
                pivot_color = {0.8, 0.2, 0.2};
            }
        } else {
            if (is_dark_theme) {
                arm_color = {0.5, 0.65, 0.85};
                bob_color = {0.3, 0.7, 1.0};
                pivot_color = {0.4, 0.6, 0.8};
            } else {
                arm_color = {0.35, 0.45, 0.65};
                bob_color = {0.2, 0.5, 0.9};
                pivot_color = {0.3, 0.4, 0.6};
            }
        }

        // Draw motion blur trail for moving pendulum (adds to realism)
        if (!is_muted && animation_progress > 0.1 && animation_progress < 0.9) {
            // Calculate velocity-based opacity (more blur when moving faster)
            double velocity = Math.fabs(Math.sin(animation_progress * Math.PI));
            double trail_opacity = velocity * 0.15;

            // Draw a faint trail bob slightly behind current position
            double trail_angle_offset = (end_angle - start_angle) * -0.05;
            double trail_angle_rad = (angle + trail_angle_offset) * Math.PI / 180.0;
            double trail_x = center_x + Math.sin(trail_angle_rad) * arm_length;
            double trail_y = pivot_y + Math.cos(trail_angle_rad) * arm_length;

            cr.set_source_rgba(bob_color[0], bob_color[1], bob_color[2], trail_opacity);
            cr.arc(trail_x, trail_y, bob_radius * 0.85, 0, 2 * Math.PI);
            cr.fill();
        }

        // Draw pendulum arm (rod)
        cr.set_source_rgba(arm_color[0], arm_color[1], arm_color[2], is_muted ? 0.4 : 0.8);
        cr.set_line_width(4.0);
        cr.set_line_cap(Cairo.LineCap.ROUND);
        cr.move_to(center_x, pivot_y);
        cr.line_to(bob_x, bob_y);
        cr.stroke();

        // Draw pivot point (mounting)
        // Outer housing
        cr.set_source_rgba(pivot_color[0] * 0.7, pivot_color[1] * 0.7, pivot_color[2] * 0.7, 0.9);
        cr.arc(center_x, pivot_y, 8, 0, 2 * Math.PI);
        cr.fill();

        // Inner pivot
        cr.set_source_rgba(pivot_color[0], pivot_color[1], pivot_color[2], 1.0);
        cr.arc(center_x, pivot_y, 5, 0, 2 * Math.PI);
        cr.fill();

        // Draw pendulum bob (weighted circle)
        // Bob outer glow (only when active)
        if (!is_muted) {
            var glow_gradient = new Cairo.Pattern.radial(bob_x, bob_y, bob_radius,
                                                         bob_x, bob_y, bob_radius + 8);
            glow_gradient.add_color_stop_rgba(0.0, bob_color[0], bob_color[1], bob_color[2], 0.3);
            glow_gradient.add_color_stop_rgba(1.0, bob_color[0], bob_color[1], bob_color[2], 0.0);
            cr.set_source(glow_gradient);
            cr.arc(bob_x, bob_y, bob_radius + 8, 0, 2 * Math.PI);
            cr.fill();
        }

        // Bob main body with gradient for 3D effect
        var bob_gradient = new Cairo.Pattern.radial(bob_x - 10, bob_y - 10, 5,
                                                     bob_x, bob_y, bob_radius);
        bob_gradient.add_color_stop_rgba(0.0, bob_color[0] * 1.2, bob_color[1] * 1.2, bob_color[2] * 1.2, is_muted ? 0.5 : 1.0);
        bob_gradient.add_color_stop_rgba(0.6, bob_color[0], bob_color[1], bob_color[2], is_muted ? 0.4 : 0.95);
        bob_gradient.add_color_stop_rgba(1.0, bob_color[0] * 0.5, bob_color[1] * 0.5, bob_color[2] * 0.5, is_muted ? 0.3 : 0.7);

        cr.set_source(bob_gradient);
        cr.arc(bob_x, bob_y, bob_radius, 0, 2 * Math.PI);
        cr.fill();

        // Bob highlight for glossy effect
        if (!is_muted) {
            var highlight = new Cairo.Pattern.radial(bob_x - 10, bob_y - 10, 0,
                                                     bob_x - 10, bob_y - 10, 12);
            highlight.add_color_stop_rgba(0.0, 1.0, 1.0, 1.0, 0.6);
            highlight.add_color_stop_rgba(1.0, 1.0, 1.0, 1.0, 0.0);
            cr.set_source(highlight);
            cr.arc(bob_x - 10, bob_y - 10, 12, 0, 2 * Math.PI);
            cr.fill();
        }

        // Draw subtle shadow on bob bottom edge
        if (!is_muted) {
            var shadow = new Cairo.Pattern.radial(bob_x, bob_y + bob_radius * 0.5, 0,
                                                  bob_x, bob_y + bob_radius * 0.5, bob_radius * 0.5);
            shadow.add_color_stop_rgba(0.0, 0.0, 0.0, 0.0, 0.3);
            shadow.add_color_stop_rgba(1.0, 0.0, 0.0, 0.0, 0.0);
            cr.set_source(shadow);
            cr.arc(bob_x, bob_y + bob_radius * 0.5, bob_radius * 0.5, 0, 2 * Math.PI);
            cr.fill();
        }

        // Draw beat number if enabled
        if (settings.get_boolean("show-beat-numbers") && beat > 0) {
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(16);

            var beat_text = beat.to_string();
            Cairo.TextExtents extents;
            cr.text_extents(beat_text, out extents);

            // Draw on bob
            cr.set_source_rgba(is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_muted ? 0.5 : 1.0);
            cr.move_to(bob_x - extents.width / 2, bob_y + extents.height / 2);
            cr.show_text(beat_text);
        }

        // Mute indicator
        if (is_muted) {
            cr.set_font_size(12);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.6);
            cr.move_to(center_x - 8, center_y + arm_length * 0.9);
            cr.show_text("M");
        }
    }

    public string get_name() {
        return "pendulum";
    }

    public string get_description() {
        return _("Pendulum - Swinging animation like mechanical metronomes");
    }
}

/**
 * Bar Graph Mode - Vertical bars representing beat positions within measure.
 */
public class BarGraphMode : GLib.Object, VisualMode {
    private Adw.StyleManager style_manager;
    private GLib.Settings settings;

    public BarGraphMode(GLib.Settings settings) {
        this.settings = settings;
        this.style_manager = Adw.StyleManager.get_default();
    }

    public void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    ) {
        // Get theme-responsive colors
        bool is_dark_theme = style_manager.dark;
        bool downbeat_color_enabled = settings.get_boolean("downbeat-color");

        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();

        // Calculate bar dimensions
        double total_width = width * 0.7; // Use 70% of width
        double bar_spacing = 10.0;
        double bar_width = (total_width - bar_spacing * (beats_per_bar - 1)) / beats_per_bar;
        double base_height = height * 0.6;
        double downbeat_height = height * 0.75; // Downbeat bar is taller

        double start_x = (width - total_width) / 2.0;
        double base_y = height * 0.8;

        // Define colors
        double[] active_color = is_dark_theme ?
            new double[] {0.3, 0.7, 1.0} : new double[] {0.2, 0.5, 0.9};
        double[] downbeat_accent = is_dark_theme ?
            new double[] {1.0, 0.4, 0.4} : new double[] {0.9, 0.2, 0.2};
        double[] inactive_color = is_dark_theme ?
            new double[] {0.6, 0.6, 0.6} : new double[] {0.4, 0.4, 0.4};
        double[] muted_color = {0.5, 0.5, 0.5};

        // Draw each bar
        for (int i = 1; i <= beats_per_bar; i++) {
            double x = start_x + (i - 1) * (bar_width + bar_spacing);
            bool is_current = (i == beat);
            bool is_first = (i == 1);
            double bar_height = is_first ? downbeat_height : base_height;
            double y = base_y - bar_height;

            // Determine bar color and opacity
            double[] color;
            double alpha;

            if (is_current) {
                if (is_muted) {
                    color = muted_color;
                    alpha = 0.5;
                } else if (is_first && downbeat_color_enabled) {
                    color = downbeat_accent;
                    alpha = 0.9;
                } else {
                    color = active_color;
                    alpha = 0.9;
                }

                // Filled bar for current beat
                cr.set_source_rgba(color[0], color[1], color[2], alpha);
                cr.rectangle(x, y, bar_width, bar_height);
                cr.fill();

                // Highlight glow
                if (!is_muted) {
                    cr.set_source_rgba(color[0], color[1], color[2], 0.3);
                    cr.rectangle(x - 2, y - 2, bar_width + 4, bar_height + 4);
                    cr.stroke();
                }
            } else {
                // Outline bar for other beats
                color = inactive_color;
                alpha = 0.4;

                cr.set_source_rgba(color[0], color[1], color[2], alpha);
                cr.set_line_width(2.0);
                cr.rectangle(x, y, bar_width, bar_height);
                cr.stroke();
            }

            // Draw beat number if enabled
            if (settings.get_boolean("show-beat-numbers") && beat > 0) {
                cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
                cr.set_font_size(14);

                var beat_text = i.to_string();
                Cairo.TextExtents extents;
                cr.text_extents(beat_text, out extents);

                double text_x = x + (bar_width - extents.width) / 2;
                double text_y = base_y + 20;

                cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.7);
                cr.move_to(text_x, text_y);
                cr.show_text(beat_text);
            }
        }

        // Mute indicator
        if (is_muted && beat > 0) {
            cr.set_font_size(14);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.6);
            cr.move_to(width / 2 - 10, height * 0.15);
            cr.show_text("MUTED");
        }
    }

    public string get_name() {
        return "bar";
    }

    public string get_description() {
        return _("Bar Graph - Vertical bars showing beat positions");
    }
}

/**
 * Progress Ring Mode - Circular progress indicator filling over measure.
 */
public class ProgressRingMode : GLib.Object, VisualMode {
    private Adw.StyleManager style_manager;
    private GLib.Settings settings;

    public ProgressRingMode(GLib.Settings settings) {
        this.settings = settings;
        this.style_manager = Adw.StyleManager.get_default();
    }

    public void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    ) {
        // Get theme-responsive colors
        bool is_dark_theme = style_manager.dark;
        bool downbeat_color_enabled = settings.get_boolean("downbeat-color");

        double center_x = width / 2.0;
        double center_y = height / 2.0;
        double outer_radius = double.min(width, height) / 2 - 60;
        double ring_width = 30.0;
        double inner_radius = outer_radius - ring_width;

        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();

        // Calculate progress angle (0 to 2π over full measure)
        double beat_progress = ((beat - 1) + animation_progress) / beats_per_bar;
        double end_angle = beat_progress * 2 * Math.PI - Math.PI / 2; // Start from top

        // Define colors
        double[] active_color = is_dark_theme ?
            new double[] {0.3, 0.7, 1.0} : new double[] {0.2, 0.5, 0.9};
        double[] downbeat_accent = is_dark_theme ?
            new double[] {1.0, 0.4, 0.4} : new double[] {0.9, 0.2, 0.2};
        double[] inactive_color = is_dark_theme ?
            new double[] {0.6, 0.6, 0.6} : new double[] {0.4, 0.4, 0.4};
        double[] muted_color = {0.5, 0.5, 0.5};

        // Draw background ring
        cr.set_source_rgba(inactive_color[0], inactive_color[1], inactive_color[2], 0.2);
        cr.set_line_width(ring_width);
        cr.arc(center_x, center_y, inner_radius + ring_width / 2, 0, 2 * Math.PI);
        cr.stroke();

        // Draw progress ring
        if (beat > 0) {
            double[] ring_color = is_muted ? muted_color : active_color;
            double alpha = is_muted ? 0.5 : 0.9;

            cr.set_source_rgba(ring_color[0], ring_color[1], ring_color[2], alpha);
            cr.set_line_width(ring_width);
            cr.arc(center_x, center_y, inner_radius + ring_width / 2, -Math.PI / 2, end_angle);
            cr.stroke();
        }

        // Draw beat marks on ring perimeter
        for (int i = 1; i <= beats_per_bar; i++) {
            double angle = (i - 1) * 2 * Math.PI / beats_per_bar - Math.PI / 2;
            double mark_outer_x = center_x + Math.cos(angle) * outer_radius;
            double mark_outer_y = center_y + Math.sin(angle) * outer_radius;
            double mark_inner_x = center_x + Math.cos(angle) * inner_radius;
            double mark_inner_y = center_y + Math.sin(angle) * inner_radius;

            bool is_first = (i == 1);
            double[] mark_color;
            double mark_width;

            if (is_first && downbeat_color_enabled) {
                mark_color = downbeat_accent;
                mark_width = 4.0;
            } else {
                mark_color = inactive_color;
                mark_width = 2.0;
            }

            cr.set_source_rgba(mark_color[0], mark_color[1], mark_color[2], 0.8);
            cr.set_line_width(mark_width);
            cr.move_to(mark_inner_x, mark_inner_y);
            cr.line_to(mark_outer_x, mark_outer_y);
            cr.stroke();
        }

        // Draw beat number in center if enabled
        if (settings.get_boolean("show-beat-numbers") && beat > 0) {
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(inner_radius * 0.5);

            var beat_text = beat.to_string();
            Cairo.TextExtents extents;
            cr.text_extents(beat_text, out extents);

            // Shadow
            cr.set_source_rgba(0, 0, 0, 0.2);
            cr.move_to(center_x - extents.width / 2 + 1, center_y + extents.height / 2 + 1);
            cr.show_text(beat_text);

            // Main text
            cr.set_source_rgba(is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_muted ? 0.5 : 1.0);
            cr.move_to(center_x - extents.width / 2, center_y + extents.height / 2);
            cr.show_text(beat_text);
        }

        // Mute indicator
        if (is_muted && beat > 0) {
            cr.set_font_size(12);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.6);

            Cairo.TextExtents extents;
            cr.text_extents("M", out extents);
            cr.move_to(center_x - extents.width / 2, center_y + inner_radius * 0.7);
            cr.show_text("M");
        }
    }

    public string get_name() {
        return "ring";
    }

    public string get_description() {
        return _("Progress Ring - Circular progress indicator");
    }
}

/**
 * Minimalist Flash Mode - Simple color flash filling indicator area.
 */
public class MinimalistFlashMode : GLib.Object, VisualMode {
    private Adw.StyleManager style_manager;
    private GLib.Settings settings;

    public MinimalistFlashMode(GLib.Settings settings) {
        this.settings = settings;
        this.style_manager = Adw.StyleManager.get_default();
    }

    public void draw(
        Cairo.Context cr,
        int beat,
        int beats_per_bar,
        bool is_downbeat,
        bool is_muted,
        double animation_progress,
        int width,
        int height
    ) {
        // Get theme-responsive colors
        bool is_dark_theme = style_manager.dark;
        bool downbeat_color_enabled = settings.get_boolean("downbeat-color");

        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();

        // Calculate flash intensity (fades from 1.0 to 0.0 over beat)
        double flash_intensity = 1.0 - animation_progress;
        // Use exponential decay for more natural fade
        flash_intensity = Math.pow(flash_intensity, 2.0);

        if (beat > 0 && flash_intensity > 0.01) {
            // Define flash colors
            double[] flash_color;
            double base_intensity;

            if (is_muted) {
                flash_color = {0.5, 0.5, 0.5};
                base_intensity = 0.3;
            } else if (is_downbeat && downbeat_color_enabled) {
                flash_color = is_dark_theme ?
                    new double[] {1.0, 0.4, 0.4} : new double[] {0.9, 0.2, 0.2};
                base_intensity = 0.8;
            } else {
                flash_color = is_dark_theme ?
                    new double[] {0.3, 0.7, 1.0} : new double[] {0.2, 0.5, 0.9};
                base_intensity = 0.6;
            }

            double alpha = base_intensity * flash_intensity;

            // Fill entire area with flash color
            cr.set_source_rgba(flash_color[0], flash_color[1], flash_color[2], alpha);
            cr.rectangle(0, 0, width, height);
            cr.fill();
        }

        // Draw beat number if enabled (always visible, not flashing)
        if (settings.get_boolean("show-beat-numbers") && beat > 0) {
            double center_x = width / 2.0;
            double center_y = height / 2.0;

            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(80);

            var beat_text = beat.to_string();
            Cairo.TextExtents extents;
            cr.text_extents(beat_text, out extents);

            // Shadow
            cr.set_source_rgba(0, 0, 0, 0.3);
            cr.move_to(center_x - extents.width / 2 + 2, center_y + extents.height / 2 + 2);
            cr.show_text(beat_text);

            // Main text
            cr.set_source_rgba(is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_dark_theme ? 0.95 : 0.1,
                             is_muted ? 0.5 : 1.0);
            cr.move_to(center_x - extents.width / 2, center_y + extents.height / 2);
            cr.show_text(beat_text);
        }

        // Mute indicator
        if (is_muted && beat > 0) {
            double center_x = width / 2.0;

            cr.set_font_size(14);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.6);

            Cairo.TextExtents extents;
            cr.text_extents("MUTED", out extents);
            cr.move_to(center_x - extents.width / 2, height * 0.85);
            cr.show_text("MUTED");
        }
    }

    public string get_name() {
        return "flash";
    }

    public string get_description() {
        return _("Minimalist Flash - Simple color flash");
    }
}
