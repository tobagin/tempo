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
            application_id: Config.APP_ID,
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
        
        // Check if this is a new version and show release notes automatically
        if (should_show_release_notes()) {
            // Small delay to ensure main window is fully presented
            Timeout.add(500, () => {
                // Launch about dialog with automatic navigation to release notes
                show_about_with_release_notes();
                return false;
            });
        }
    }
    
    private void setup_actions() {
        // Preferences action
        var preferences_action = new SimpleAction("preferences", null);
        preferences_action.activate.connect(on_preferences_action);
        this.add_action(preferences_action);
        this.set_accels_for_action("app.preferences", {"<Control>comma"});
        
        // Keyboard shortcuts action
        var shortcuts_action = new SimpleAction("show-help-overlay", null);
        shortcuts_action.activate.connect(on_shortcuts_action);
        this.add_action(shortcuts_action);
        this.set_accels_for_action("app.show-help-overlay", {"<Control>question"});
        
        // About action
        var about_action = new SimpleAction("about", null);
        about_action.activate.connect(on_about_action);
        this.add_action(about_action);
        this.set_accels_for_action("app.about", {"F1"});
        
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
    
    private void on_shortcuts_action() {
        if (main_window != null) {
            main_window.show_keyboard_shortcuts();
        }
    }
    
    private void on_about_action() {
        string[] developers = { "Thiago Fernandes" };
        string[] designers = { "Thiago Fernandes" };
        string[] artists = { "Thiago Fernandes" };
        
        string app_name = "Tempo";
        string comments = "A modern metronome for musicians with precise timing and intuitive interface";
        
        if (Config.APP_ID.contains("Devel")) {
            app_name = "Tempo (Development)";
            comments = "A modern metronome for musicians with precise timing and intuitive interface (Development Version)";
        }

        var about = new Adw.AboutDialog() {
            application_name = app_name,
            application_icon = Config.APP_ID,
            developer_name = "The Tempo Team",
            version = Config.VERSION,
            developers = developers,
            designers = designers,
            artists = artists,
            license_type = Gtk.License.GPL_3_0,
            website = "https://tobagin.github.io/apps/tempo/",
            issue_url = "https://github.com/tobagin/Tempo/issues",
            comments = comments
        };

        // Load and set release notes from appdata
        try {
            var appdata_path = Path.build_filename(Config.DATADIR, "metainfo", "%s.metainfo.xml".printf(Config.APP_ID));
            var file = File.new_for_path(appdata_path);
            
            if (file.query_exists()) {
                uint8[] contents;
                file.load_contents(null, out contents, null);
                string xml_content = (string) contents;
                
                // Parse the XML to find the release matching Config.VERSION
                var parser = new Regex("<release version=\"%s\"[^>]*>(.*?)</release>".printf(Regex.escape_string(Config.VERSION)), 
                                       RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);
                MatchInfo match_info;
                
                if (parser.match(xml_content, 0, out match_info)) {
                    string release_section = match_info.fetch(1);
                    
                    // Extract description content
                    var desc_parser = new Regex("<description>(.*?)</description>", 
                                                RegexCompileFlags.DOTALL | RegexCompileFlags.MULTILINE);
                    MatchInfo desc_match;
                    
                    if (desc_parser.match(release_section, 0, out desc_match)) {
                        string release_notes = desc_match.fetch(1).strip();
                        about.set_release_notes(release_notes);
                        about.set_release_notes_version(Config.VERSION);
                    }
                }
            }
        } catch (Error e) {
            // If we can't load release notes from appdata, that's okay
            warning("Could not load release notes from appdata: %s", e.message);
        }

        // Set copyright
        about.set_copyright("© 2025 Thiago Fernandes");

        // Add acknowledgement section
        about.add_acknowledgement_section(
            "Special Thanks",
            {
                "The GNOME Project",
                "The GTK Project Team",
                "GTK Contributors",
                "LibAdwaita Contributors", 
                "Vala Programming Language Team",
                "GStreamer Team",
                "Blueprint Compiler Team"
            }
        );

        // Add translator credits
        about.set_translator_credits("Italian: Albano Battistella (github.com/albanobattistella)\nTurkish: Erdem Uygun (github.com/erdemuygun)");
        
        // Add Source link
        about.add_link("Source", "https://github.com/tobagin/Tempo");
        
        if (main_window != null) {
            about.present(main_window);
        }
    }
    
    private void show_about_with_release_notes() {
        // Open the about dialog first
        on_about_action();
        
        // Wait for the dialog to appear, then navigate to release notes
        Timeout.add(300, () => {
            simulate_tab_navigation();
            
            // Simulate Enter key press after another delay to open release notes
            Timeout.add(200, () => {
                simulate_enter_activation();
                return false;
            });
            return false;
        });
    }
    
    private bool should_show_release_notes() {
        var settings = new GLib.Settings(Config.APP_ID);
        string last_version_raw = settings.get_string("last-version-shown");
        string current_version = Config.VERSION;

        // Validate and sanitize the stored version string
        string last_version = sanitize_version_string(last_version_raw);

        // If sanitization failed or version invalid, treat as first run
        if (last_version == "" || !is_valid_version(last_version)) {
            settings.set_string("last-version-shown", current_version);
            return true;
        }

        // Show if version has changed
        if (last_version != current_version) {
            settings.set_string("last-version-shown", current_version);
            return true;
        }
        return false;
    }

    /**
     * Sanitize a version string to ensure it's safe for comparison.
     *
     * @param version The version string to sanitize
     * @return Sanitized version string or empty string if invalid
     */
    private string sanitize_version_string(string version) {
        if (version == null || version == "") {
            return "";
        }

        // Limit length to prevent abuse
        if (version.length > 32) {
            warning("Version string too long, treating as invalid: %s", version);
            return "";
        }

        // Remove any potentially dangerous characters
        // Keep only: digits, dots, hyphens, and alphanumeric (for pre-release tags)
        var sanitized = new StringBuilder();
        for (int i = 0; i < version.length; i++) {
            unichar c = version.get_char(i);
            if (c.isalnum() || c == '.' || c == '-') {
                sanitized.append_unichar(c);
            }
        }

        return sanitized.str;
    }

    /**
     * Validate that a version string follows semver-like format.
     *
     * @param version The version string to validate
     * @return true if valid, false otherwise
     */
    private bool is_valid_version(string version) {
        if (version == null || version == "") {
            return false;
        }

        // Basic semver validation: should start with digits and contain dots
        // Examples: "1.2.3", "1.0.0-beta", "2.1.0"
        if (!version[0].isdigit()) {
            return false;
        }

        bool has_dot = false;
        for (int i = 0; i < version.length; i++) {
            if (version[i] == '.') {
                has_dot = true;
                break;
            }
        }

        return has_dot;
    }
    
    private void simulate_tab_navigation() {
        // Get the focused widget and try to move focus
        var focused_widget = main_window.get_focus();
        if (focused_widget != null) {
            // Use grab_focus to move to the next focusable widget
            var parent = focused_widget.get_parent();
            if (parent != null) {
                // Try to move focus to the next sibling
                parent.child_focus(Gtk.DirectionType.TAB_FORWARD);
            }
        }
    }
    
    private void simulate_enter_activation() {
        // Get the currently focused widget and try to activate it
        var focused_widget = main_window.get_focus();
        if (focused_widget != null) {
            // If it's a button, click it
            if (focused_widget is Button) {
                ((Button)focused_widget).activate();
            }
            // For other widgets, try to activate the default action
            else {
                focused_widget.activate_default();
            }
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
