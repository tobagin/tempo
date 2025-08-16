/**
 * Main entry point for the Tempo metronome application.
 * 
 * This application uses Blueprint UI templates for a professional interface.
 */

using Gtk;
using Adw;

/**
 * Main application class for Tempo.
 */
public class TempoApplication : Adw.Application {
    
    public TempoApplication() {
        Object(
            application_id: "io.github.tobagin.tempo",
            flags: ApplicationFlags.DEFAULT_FLAGS
        );
    }
    
    protected override void activate() {
        // Create main window using Blueprint template
        var window = new TempoWindow(this);
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