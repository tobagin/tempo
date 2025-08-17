/**
 * Main entry point for the Tempo metronome application.
 * 
 * This application uses Blueprint UI templates for a professional interface.
 */

using Gtk;
using Adw;
using Gst;

/**
 * Main application class for Tempo.
 */
public class TempoApplication : Adw.Application {
    
    private TempoWindow? main_window = null;
    
    public TempoApplication() {
        GLib.Object(
            application_id: "io.github.tobagin.tempo",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }
    
    protected override void startup() {
        base.startup();
        
        // Setup application actions
        setup_actions();
    }
    
    protected override void activate() {
        if (main_window == null) {
            // Create main window using Blueprint template
            main_window = new TempoWindow(this);
        }
        
        main_window.present();
    }
    
    private void setup_actions() {
        // Preferences action
        var preferences_action = new SimpleAction("preferences", null);
        preferences_action.activate.connect(on_preferences_action);
        this.add_action(preferences_action);
        
        // About action
        var about_action = new SimpleAction("about", null);
        about_action.activate.connect(on_about_action);
        this.add_action(about_action);
        
        // Quit action
        var quit_action = new SimpleAction("quit", null);
        quit_action.activate.connect(on_quit_action);
        this.add_action(quit_action);
        this.set_accels_for_action("app.quit", {"<Control>q"});
    }
    
    private void on_preferences_action() {
        if (main_window != null) {
            main_window.show_preferences();
        }
    }
    
    private void on_about_action() {
        var about_dialog = new Adw.AboutDialog();
        about_dialog.application_name = _("Tempo");
        about_dialog.application_icon = "io.github.tobagin.tempo";
        about_dialog.developer_name = _("Thiago Fernandes");
        about_dialog.version = "1.1.8";
        about_dialog.website = "https://github.com/tobagin/Tempo";
        about_dialog.issue_url = "https://github.com/tobagin/Tempo/issues";
        about_dialog.copyright = _("Copyright © 2025 Thiago Fernandes");
        about_dialog.license_type = License.GPL_3_0;
        
        about_dialog.comments = _("A precise and professional metronome application");
        about_dialog.set_developers({
            _("Thiago Fernandes"),
        });
        
        // Translator credits
        about_dialog.translator_credits = _("Italian: Albano Battistella (github.com/albanobattistella)\nTurkish: Erdem Uygun (github.com/erdemuygun)");
        if (main_window != null) {
            about_dialog.present(main_window);
        }
    }
    
    private void on_quit_action() {
        this.quit();
    }
}

/**
 * Main function - entry point for the application.
 */
public int main(string[] args) {
    // Initialize GStreamer for audio playback
    Gst.init(ref args);
    
    var app = new TempoApplication();
    return app.run(args);
}
