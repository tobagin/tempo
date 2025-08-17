/**
 * Main window for the Tempo metronome application.
 * 
 * This class uses the Blueprint UI template for a professional interface.
 */

using Gtk;
using Adw;

[GtkTemplate (ui = "/io/github/tobagin/tempo/ui/main_window.ui")]
public class TempoWindow : Adw.ApplicationWindow {
    
    // UI Elements from Blueprint template
    [GtkChild] private unowned Label tempo_label;
    [GtkChild] private unowned SpinButton tempo_spin;
    [GtkChild] private unowned Scale tempo_scale;
    [GtkChild] private unowned SpinButton beats_spin;
    [GtkChild] private unowned DropDown beat_value_dropdown;
    [GtkChild] private unowned DrawingArea beat_indicator;
    [GtkChild] private unowned Button play_button;
    [GtkChild] private unowned Button tap_button;
    
    // Engine components
    private MetronomeEngine metronome_engine;
    private TapTempo tap_tempo;
    
    // Preferences dialog
    private PreferencesDialog? preferences_dialog = null;
    
    // Settings for visual preferences
    private GLib.Settings settings;
    
    // Beat indicator state
    private bool beat_active = false;
    private bool is_downbeat = false;
    private int current_beat_number = 1;
    
    public TempoWindow(Adw.Application app) {
        Object(application: app);
        
        // Initialize settings
        settings = new GLib.Settings("io.github.tobagin.tempo");
        
        // Initialize engines
        metronome_engine = new MetronomeEngine();
        tap_tempo = new TapTempo();
        
        setup_ui();
        connect_signals();
        
        // Listen for settings changes to update visuals
        settings.changed.connect(on_settings_changed);
        
        // Apply initial keep-on-top setting when window is realized
        this.realize.connect(() => {
            apply_keep_on_top_setting();
            apply_start_on_launch_setting();
        });
    }
    
    private void setup_ui() {
        // Load CSS styles using modern approach
        var css_provider = new CssProvider();
        css_provider.load_from_resource("/io/github/tobagin/tempo/style.css");
        
        // Add CSS provider to display using modern API
        var display = this.get_display() ?? Gdk.Display.get_default();
        Gtk.StyleContext.add_provider_for_display(
            display,
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
        
        // Initialize UI values
        update_tempo_display();
        update_time_signature_display();
        
        // Setup beat indicator drawing
        beat_indicator.set_draw_func(draw_beat_indicator);
    }
    
    private void connect_signals() {
        // Tempo controls
        tempo_spin.value_changed.connect(on_tempo_changed);
        tempo_scale.value_changed.connect(on_tempo_scale_changed);
        
        // Time signature controls
        beats_spin.value_changed.connect(on_beats_changed);
        beat_value_dropdown.notify["selected"].connect(on_beat_value_changed);
        
        // Control buttons
        play_button.clicked.connect(on_play_clicked);
        tap_button.clicked.connect(on_tap_clicked);
        
        // Metronome engine signals
        metronome_engine.beat_occurred.connect(on_beat_occurred);
        
        // Keyboard shortcuts
        setup_keyboard_shortcuts();
    }
    
    private void update_tempo_display() {
        var bpm = metronome_engine.bpm;
        tempo_label.label = bpm.to_string();
        tempo_spin.value = bpm;
    }
    
    private void update_time_signature_display() {
        beats_spin.value = metronome_engine.beats_per_bar;
        
        // Set beat value dropdown based on current beat value
        switch (metronome_engine.beat_value) {
            case 2: beat_value_dropdown.selected = 0; break;
            case 4: beat_value_dropdown.selected = 1; break;
            case 8: beat_value_dropdown.selected = 2; break;
            case 16: beat_value_dropdown.selected = 3; break;
        }
    }
    
    // Signal handlers
    private void on_tempo_changed() {
        var new_bpm = (int)tempo_spin.value;
        try {
            metronome_engine.set_tempo(new_bpm);
            update_tempo_display();
        } catch (MetronomeError e) {
            warning("Failed to set tempo: %s", e.message);
            // Revert to previous value
            tempo_spin.value = metronome_engine.bpm;
        }
    }
    
    private void on_tempo_scale_changed() {
        var new_bpm = (int)tempo_scale.get_value();
        try {
            metronome_engine.set_tempo(new_bpm);
            tempo_label.label = new_bpm.to_string();
            tempo_spin.value = new_bpm;
        } catch (MetronomeError e) {
            warning("Failed to set tempo: %s", e.message);
            // Revert to previous value
            tempo_scale.set_value(metronome_engine.bpm);
        }
    }
    
    private void on_beats_changed() {
        var new_beats = (int)beats_spin.value;
        var denominator = get_beat_value_from_dropdown();
        
        try {
            metronome_engine.set_time_signature(new_beats, denominator);
        } catch (MetronomeError e) {
            warning("Failed to set time signature: %s", e.message);
            // Revert to previous value
            beats_spin.value = metronome_engine.beats_per_bar;
        }
    }
    
    private void on_beat_value_changed() {
        var numerator = (int)beats_spin.value;
        var new_denominator = get_beat_value_from_dropdown();
        
        try {
            metronome_engine.set_time_signature(numerator, new_denominator);
        } catch (MetronomeError e) {
            warning("Failed to set time signature: %s", e.message);
            // Revert to previous value
            update_time_signature_display();
        }
    }
    
    private int get_beat_value_from_dropdown() {
        switch (beat_value_dropdown.selected) {
            case 0: return 2;
            case 1: return 4;
            case 2: return 8;
            case 3: return 16;
            default: return 4;
        }
    }
    
    private void on_play_clicked() {
        if (metronome_engine.is_running) {
            metronome_engine.stop();
            play_button.label = _("Start");
            play_button.add_css_class("suggested-action");
            play_button.remove_css_class("destructive-action");
        } else {
            metronome_engine.start();
            play_button.label = _("Stop");
            play_button.remove_css_class("suggested-action");
            play_button.add_css_class("destructive-action");
        }
    }
    
    private void on_tap_clicked() {
        var bpm = tap_tempo.tap();
        if (bpm != null) {
            try {
                metronome_engine.set_tempo(bpm);
                update_tempo_display();
                tempo_scale.set_value(bpm);
            } catch (MetronomeError e) {
                warning("Failed to set tempo from tap: %s", e.message);
            }
        }
    }
    
    private void on_beat_occurred(int beat_number, bool downbeat) {
        // Update beat indicator state
        beat_active = true;
        is_downbeat = downbeat;
        
        // Store the beat number to display (convert to 1-based beat-in-bar)
        var beat_info = metronome_engine.get_beat_info();
        current_beat_number = beat_info["beat_in_bar"].get_int32();
        
        // Trigger redraw of beat indicator
        beat_indicator.queue_draw();
        
        // Reset beat indicator after short delay
        Timeout.add(100, () => {
            beat_active = false;
            beat_indicator.queue_draw();
            return false;
        });
    }
    
    // Keyboard shortcuts setup
    private void setup_keyboard_shortcuts() {
        var key_controller = new EventControllerKey();
        key_controller.key_pressed.connect(on_key_pressed);
        ((Widget)this).add_controller(key_controller);
        
        // Make sure window can receive focus for keyboard events
        this.can_focus = true;
    }
    
    private bool on_key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
        // Check for modifier keys
        bool ctrl_pressed = (state & Gdk.ModifierType.CONTROL_MASK) != 0;
        bool shift_pressed = (state & Gdk.ModifierType.SHIFT_MASK) != 0;
        
        switch (keyval) {
            case Gdk.Key.space:
                // Spacebar: Toggle play/stop
                on_play_clicked();
                return true;
                
            case Gdk.Key.t:
            case Gdk.Key.T:
                // T: Tap tempo
                on_tap_clicked();
                return true;
                
            case Gdk.Key.Up:
                // Arrow Up: Increase tempo
                adjust_tempo(shift_pressed ? 10 : 1);
                return true;
                
            case Gdk.Key.Down:
                // Arrow Down: Decrease tempo
                adjust_tempo(shift_pressed ? -10 : -1);
                return true;
                
            case Gdk.Key.Left:
                // Arrow Left: Decrease tempo (alternative)
                adjust_tempo(shift_pressed ? -10 : -1);
                return true;
                
            case Gdk.Key.Right:
                // Arrow Right: Increase tempo (alternative)
                adjust_tempo(shift_pressed ? 10 : 1);
                return true;
                
            case Gdk.Key.r:
            case Gdk.Key.R:
                // R: Reset beat counter
                if (ctrl_pressed) {
                    metronome_engine.reset_beat_counter();
                    return true;
                }
                break;
                
            case Gdk.Key.@1:
            case Gdk.Key.@2:
            case Gdk.Key.@3:
            case Gdk.Key.@4:
            case Gdk.Key.@5:
            case Gdk.Key.@6:
            case Gdk.Key.@7:
            case Gdk.Key.@8:
            case Gdk.Key.@9:
                // Number keys 1-9: Set beats per bar
                if (ctrl_pressed) {
                    var beats = (int)(keyval - Gdk.Key.@0);
                    set_beats_per_bar(beats);
                    return true;
                }
                break;
                
            case Gdk.Key.Escape:
                // Escape: Stop metronome
                if (metronome_engine.is_running) {
                    on_play_clicked();
                    return true;
                }
                break;
                
            case Gdk.Key.F1:
                // F1: Show help/shortcuts (placeholder for future)
                show_shortcuts_help();
                return true;
                
            case Gdk.Key.plus:
            case Gdk.Key.equal:
            case Gdk.Key.KP_Add:
                // Plus: Increase tempo
                adjust_tempo(shift_pressed ? 10 : 5);
                return true;
                
            case Gdk.Key.minus:
            case Gdk.Key.underscore:
            case Gdk.Key.KP_Subtract:
                // Minus: Decrease tempo
                adjust_tempo(shift_pressed ? -10 : -5);
                return true;
        }
        
        return false; // Let other handlers process the key
    }
    
    private void adjust_tempo(int delta) {
        var current_bpm = metronome_engine.bpm;
        var new_bpm = current_bpm + delta;
        
        try {
            metronome_engine.set_tempo(new_bpm);
            update_tempo_display();
            tempo_scale.set_value(new_bpm);
        } catch (MetronomeError e) {
            // Silently ignore out of range values for keyboard shortcuts
        }
    }
    
    private void set_beats_per_bar(int beats) {
        var denominator = get_beat_value_from_dropdown();
        
        try {
            metronome_engine.set_time_signature(beats, denominator);
            update_time_signature_display();
        } catch (MetronomeError e) {
            warning("Failed to set beats per bar: %s", e.message);
        }
    }
    
    private void show_shortcuts_help() {
        var dialog = new Adw.AlertDialog(_("Keyboard Shortcuts"), 
                                        _("Quick reference for keyboard shortcuts"));
        
        var shortcuts_text = _("""<b>Playback Control:</b>
• <b>Spacebar</b> - Start/Stop metronome
• <b>Escape</b> - Stop metronome
• <b>T</b> - Tap tempo

<b>Tempo Adjustment:</b>
• <b>↑/↓ Arrow</b> - Adjust tempo (±1 BPM)
• <b>←/→ Arrow</b> - Adjust tempo (±1 BPM)
• <b>Shift + Arrows</b> - Adjust tempo (±10 BPM)
• <b>+/-</b> - Adjust tempo (±5 BPM)
• <b>Shift + +/-</b> - Adjust tempo (±10 BPM)

<b>Time Signature:</b>
• <b>Ctrl + 1-9</b> - Set beats per bar
• <b>Ctrl + R</b> - Reset beat counter

<b>Help:</b>
• <b>F1</b> - Show this help""");
        
        dialog.set_body_use_markup(true);
        dialog.set_body(shortcuts_text);
        dialog.add_response("ok", _("OK"));
        dialog.set_default_response("ok");
        dialog.set_close_response("ok");
        
        dialog.present(this);
    }
    
    /**
     * Show the preferences dialog.
     */
    public void show_preferences() {
        if (preferences_dialog == null) {
            preferences_dialog = new PreferencesDialog();
        }
        preferences_dialog.present(this);
    }
    
    /**
     * Handle settings changes to update visual preferences.
     */
    private void on_settings_changed(string key) {
        switch (key) {
            case "show-beat-numbers":
            case "flash-on-beat":
            case "downbeat-color":
            case "theme":
                // Redraw beat indicator with new settings
                beat_indicator.queue_draw();
                break;
            case "keep-on-top":
                apply_keep_on_top_setting();
                break;
        }
    }
    
    /**
     * Apply the keep-on-top window setting.
     */
    private void apply_keep_on_top_setting() {
        bool keep_on_top = settings.get_boolean("keep-on-top");
        
        // Get the surface from the native interface
        var native = this.get_native();
        if (native != null) {
            var surface = native.get_surface();
            if (surface != null) {
                if (keep_on_top) {
                    // Make window stay on top
                    surface.set_keep_above(true);
                } else {
                    // Allow normal window stacking
                    surface.set_keep_above(false);
                }
            }
        }
    }
    
    /**
     * Apply the start-on-launch setting by starting metronome if enabled.
     */
    private void apply_start_on_launch_setting() {
        bool start_on_launch = settings.get_boolean("start-on-launch");
        
        if (start_on_launch && !metronome_engine.is_playing) {
            // Start the metronome automatically
            metronome_engine.start();
            play_button.label = _("Stop");
        }
    }

    /**
     * Enhanced beat indicator drawing function with preference-driven visuals.
     */
    private void draw_beat_indicator(DrawingArea area, Cairo.Context cr, int width, int height) {
        // Get center coordinates and radius - much larger circle with margin for pulse effect
        double center_x = width / 2.0;
        double center_y = height / 2.0;
        double base_radius = double.min(width, height) / 2 - 85;
        
        // Get current beat info
        var beat_info = metronome_engine.get_beat_info();
        var current_beat_in_bar = beat_info["beat_in_bar"].get_int32();
        
        // Read visual preferences
        bool show_beat_numbers = settings.get_boolean("show-beat-numbers");
        bool flash_on_beat = settings.get_boolean("flash-on-beat");
        bool downbeat_color = settings.get_boolean("downbeat-color");
        
        // Get theme-responsive colors
        var style_manager = Adw.StyleManager.get_default();
        bool is_dark_theme = style_manager.dark;
        
        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();
        
        // Calculate dynamic radius for flash effect
        double radius = base_radius;
        double glow_intensity = 0.0;
        
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
        
        // Draw beat number if enabled and running
        if (show_beat_numbers && metronome_engine.is_running) {
            // Calculate font size based on circle size
            double font_size = base_radius * 0.4;
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(font_size);
            
            var beat_text = current_beat_number.to_string();
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
        
        // Draw small beat progress indicators around the circle (when running)
        if (metronome_engine.is_running) {
            var total_beats = metronome_engine.beats_per_bar;
            double indicator_radius = base_radius + 20;
            double indicator_size = 4.0;
            
            for (int i = 1; i <= total_beats; i++) {
                double angle = (i - 1) * 2 * Math.PI / total_beats - Math.PI / 2;
                double dot_x = center_x + Math.cos(angle) * indicator_radius;
                double dot_y = center_y + Math.sin(angle) * indicator_radius;
                
                if (i == current_beat_number) {
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
}
