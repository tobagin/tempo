/**
 * Main entry point for the Tempo metronome application.
 * 
 * This is a basic GTK4/LibAdwaita application that uses the converted
 * Vala timing engine components.
 */

using Gtk;
using Adw;

/**
 * Main application class for Tempo.
 */
public class TempoApplication : Adw.Application {
    
    private MetronomeEngine metronome_engine;
    private TapTempo tap_tempo;
    
    public TempoApplication() {
        Object(
            application_id: "io.github.tobagin.tempo",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
        
        this.metronome_engine = new MetronomeEngine();
        this.tap_tempo = new TapTempo();
    }
    
    protected override void activate() {
        var window = new Adw.ApplicationWindow(this);
        window.title = "Tempo";
        window.default_width = 400;
        window.default_height = 300;
        
        // Create a simple UI for demonstration
        var header_bar = new Adw.HeaderBar();
        window.set_titlebar(header_bar);
        
        var vbox = new Box(Orientation.VERTICAL, 12);
        vbox.margin_top = 24;
        vbox.margin_bottom = 24;
        vbox.margin_start = 24;
        vbox.margin_end = 24;
        
        // BPM label and controls
        var bpm_label = new Label("BPM: %d".printf(metronome_engine.bpm));
        bpm_label.add_css_class("title-1");
        vbox.append(bpm_label);
        
        var bpm_scale = new Scale.with_range(Orientation.HORIZONTAL, 40, 240, 1);
        bpm_scale.set_value(metronome_engine.bpm);
        bpm_scale.value_changed.connect(() => {
            try {
                metronome_engine.set_tempo((int)bpm_scale.get_value());
                bpm_label.label = "BPM: %d".printf(metronome_engine.bpm);
            } catch (MetronomeError e) {
                warning("Failed to set tempo: %s", e.message);
            }
        });
        vbox.append(bpm_scale);
        
        // Play/Stop button
        var play_button = new Button.with_label("Start");
        play_button.add_css_class("suggested-action");
        play_button.clicked.connect(() => {
            if (metronome_engine.is_running) {
                metronome_engine.stop();
                play_button.label = "Start";
                play_button.add_css_class("suggested-action");
                play_button.remove_css_class("destructive-action");
            } else {
                metronome_engine.start();
                play_button.label = "Stop";
                play_button.remove_css_class("suggested-action");
                play_button.add_css_class("destructive-action");
            }
        });
        vbox.append(play_button);
        
        // Tap tempo button
        var tap_button = new Button.with_label("Tap Tempo");
        tap_button.clicked.connect(() => {
            var bpm = tap_tempo.tap();
            if (bpm != null) {
                try {
                    metronome_engine.set_tempo(bpm);
                    bpm_scale.set_value(bpm);
                    bpm_label.label = "BPM: %d".printf(bpm);
                } catch (MetronomeError e) {
                    warning("Failed to set tempo from tap: %s", e.message);
                }
            }
        });
        vbox.append(tap_button);
        
        // Beat indicator
        var beat_label = new Label("Ready");
        beat_label.add_css_class("title-2");
        vbox.append(beat_label);
        
        // Connect to beat events
        metronome_engine.beat_occurred.connect((beat, is_downbeat) => {
            if (is_downbeat) {
                beat_label.label = "BEAT %d (DOWN)".printf(beat + 1);
                beat_label.add_css_class("accent");
            } else {
                beat_label.label = "beat %d".printf(beat + 1);
                beat_label.remove_css_class("accent");
            }
        });
        
        window.content = vbox;
        window.present();
    }
}

/**
 * Main function - entry point for the application.
 */
public int main(string[] args) {
    var app = new TempoApplication();
    return app.run(args);
}