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
    
    // Beat indicator state
    private bool beat_active = false;
    private bool is_downbeat = false;
    
    public TempoWindow(Adw.Application app) {
        Object(application: app);
        
        // Initialize engines
        metronome_engine = new MetronomeEngine();
        tap_tempo = new TapTempo();
        
        setup_ui();
        connect_signals();
    }
    
    private void setup_ui() {
        // Load CSS styles
        var css_provider = new CssProvider();
        css_provider.load_from_resource("/io/github/tobagin/tempo/style.css");
        StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
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
        
        // Window focus for keyboard shortcuts (will add in next feature)
        this.set_focus_visible(true);
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
        
        // Trigger redraw of beat indicator
        beat_indicator.queue_draw();
        
        // Reset beat indicator after short delay
        Timeout.add(100, () => {
            beat_active = false;
            beat_indicator.queue_draw();
            return false;
        });
    }
    
    // Beat indicator drawing function
    private void draw_beat_indicator(DrawingArea area, Cairo.Context cr, int width, int height) {
        // Get center coordinates
        double center_x = width / 2.0;
        double center_y = height / 2.0;
        double radius = double.min(width, height) / 2.0 - 10;
        
        // Get current beat info
        var beat_info = metronome_engine.get_beat_info();
        var current_beat_in_bar = beat_info["beat_in_bar"].get_int32();
        var beats_per_bar = beat_info["beats_per_bar"].get_int32();
        
        // Clear the area
        cr.set_source_rgba(0, 0, 0, 0);
        cr.paint();
        
        if (beat_active) {
            // Active beat indicator
            if (is_downbeat) {
                // Red for downbeat
                cr.set_source_rgba(0.9, 0.2, 0.2, 0.8);
            } else {
                // Blue for regular beat  
                cr.set_source_rgba(0.2, 0.6, 0.9, 0.8);
            }
            
            // Draw filled circle
            cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
            cr.fill();
            
            // Add glow effect
            cr.set_source_rgba(is_downbeat ? 0.9 : 0.2, 
                             is_downbeat ? 0.2 : 0.6, 
                             is_downbeat ? 0.2 : 0.9, 0.3);
            cr.arc(center_x, center_y, radius + 5, 0, 2 * Math.PI);
            cr.fill();
        } else {
            // Inactive beat indicator - just outline
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.5);
            cr.set_line_width(2);
            cr.arc(center_x, center_y, radius, 0, 2 * Math.PI);
            cr.stroke();
        }
        
        // Draw beat number if running
        if (metronome_engine.is_running) {
            cr.set_source_rgba(1, 1, 1, 0.9);
            cr.select_font_face("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size(24);
            
            var beat_text = current_beat_in_bar.to_string();
            Cairo.TextExtents extents;
            cr.text_extents(beat_text, out extents);
            
            cr.move_to(center_x - extents.width / 2, center_y + extents.height / 2);
            cr.show_text(beat_text);
        }
    }
}
