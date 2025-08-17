/**
 * Preferences dialog for the Tempo metronome application.
 * 
 * This class handles user preferences and settings for the application,
 * including audio settings, sound customization, and visual preferences.
 */

using Gtk;
using Adw;
using Gst;

[GtkTemplate (ui = "/io/github/tobagin/tempo/ui/preferences_dialog.ui")]
public class PreferencesDialog : Adw.PreferencesDialog {
    
    // UI Elements from Blueprint template - Audio Settings
    [GtkChild] private unowned Scale volume_scale;
    [GtkChild] private unowned Scale accent_volume_scale;
    [GtkChild] private unowned Switch custom_sounds_switch;
    [GtkChild] private unowned Button high_sound_button;
    [GtkChild] private unowned Button low_sound_button;
    
    // UI Elements - Behavior Settings
    [GtkChild] private unowned SpinButton tap_sensitivity_spin;
    [GtkChild] private unowned Switch start_on_launch_switch;
    [GtkChild] private unowned Switch keep_on_top_switch;
    
    // UI Elements - Visual Settings
    [GtkChild] private unowned DropDown theme_dropdown;
    [GtkChild] private unowned Switch show_beat_numbers_switch;
    [GtkChild] private unowned Switch flash_on_beat_switch;
    [GtkChild] private unowned Switch downbeat_color_switch;
    
    // GSettings object for persistent storage
    private GLib.Settings settings;
    
    // File paths for custom sounds
    private string? high_sound_path = null;
    private string? low_sound_path = null;
    
    /**
     * Create a new preferences dialog.
     */
    public PreferencesDialog() {
        GLib.Object();
        
        // Initialize settings
        settings = new GLib.Settings("io.github.tobagin.tempo");
        
        // Load initial settings
        load_settings();
        
        // Connect signals
        connect_signals();
    }
    
    /**
     * Present the preferences dialog with a parent window.
     */
    public new void present(Gtk.Window parent) {
        // TODO: Fix transient_for method call
        base.present(parent);
    }
    
    /**
     * Load settings from GSettings.
     */
    private void load_settings() {
        // Audio settings
        volume_scale.set_value(settings.get_double("click-volume"));
        accent_volume_scale.set_value(settings.get_double("accent-volume"));
        custom_sounds_switch.set_active(settings.get_boolean("use-custom-sounds"));
        
        // Get custom sound paths if they exist
        high_sound_path = settings.get_string("high-sound-path");
        low_sound_path = settings.get_string("low-sound-path");
        
        // Update button labels if custom paths are set
        if (high_sound_path != null && high_sound_path != "") {
            update_sound_button_label(high_sound_button, high_sound_path);
        }
        
        if (low_sound_path != null && low_sound_path != "") {
            update_sound_button_label(low_sound_button, low_sound_path);
        }
        
        // Load behavior settings
        tap_sensitivity_spin.set_value(settings.get_int("tap-sensitivity"));
        start_on_launch_switch.set_active(settings.get_boolean("start-on-launch"));
        keep_on_top_switch.set_active(settings.get_boolean("keep-on-top"));
        
        // Load visual settings
        theme_dropdown.set_selected(settings.get_int("theme"));
        show_beat_numbers_switch.set_active(settings.get_boolean("show-beat-numbers"));
        flash_on_beat_switch.set_active(settings.get_boolean("flash-on-beat"));
        downbeat_color_switch.set_active(settings.get_boolean("downbeat-color"));
    }
    
    /**
     * Connect UI signals to handlers.
     */
    private void connect_signals() {
        // Audio settings
        volume_scale.value_changed.connect(() => {
            settings.set_double("click-volume", volume_scale.get_value());
        });
        
        accent_volume_scale.value_changed.connect(() => {
            settings.set_double("accent-volume", accent_volume_scale.get_value());
        });
        
        custom_sounds_switch.state_set.connect((state) => {
            settings.set_boolean("use-custom-sounds", state);
            return false; // Let the switch handle the state change
        });
        
        high_sound_button.clicked.connect(() => {
            // TODO: Implement file chooser
            warning(_("Sound file chooser not yet implemented"));
        });
        
        low_sound_button.clicked.connect(() => {
            // TODO: Implement file chooser
            warning(_("Sound file chooser not yet implemented"));
        });
        
        // Behavior settings
        tap_sensitivity_spin.value_changed.connect(() => {
            settings.set_int("tap-sensitivity", (int)tap_sensitivity_spin.get_value());
        });
        
        start_on_launch_switch.state_set.connect((state) => {
            settings.set_boolean("start-on-launch", state);
            return false;
        });
        
        keep_on_top_switch.state_set.connect((state) => {
            settings.set_boolean("keep-on-top", state);
            // TODO: Apply the setting immediately when API is fixed
            return false;
        });
        
        // Visual settings
        theme_dropdown.notify["selected"].connect(() => {
            settings.set_int("theme", (int)theme_dropdown.get_selected());
            update_theme();
        });
        
        show_beat_numbers_switch.state_set.connect((state) => {
            settings.set_boolean("show-beat-numbers", state);
            return false;
        });
        
        flash_on_beat_switch.state_set.connect((state) => {
            settings.set_boolean("flash-on-beat", state);
            return false;
        });
        
        downbeat_color_switch.state_set.connect((state) => {
            settings.set_boolean("downbeat-color", state);
            return false;
        });
    }
    
    /**
     * Choose a custom sound file.
     * 
     * @param is_high_sound Whether this is for the high (accent) sound or low sound
     */
    private void choose_sound_file(bool is_high_sound) {
        // TODO: Implement modern file chooser API
        warning(_("File chooser needs modern GTK4 implementation"));
        /*
        var file_chooser = new FileChooserDialog(
            is_high_sound ? _("Choose High Sound") : _("Choose Low Sound"),
            this,
            FileChooserAction.OPEN,
            _("Cancel"), ResponseType.CANCEL,
            _("Open"), ResponseType.ACCEPT
        );
        
        // Add audio file filters
        var filter = new FileFilter();
        filter.set_name(_("Audio Files"));
        filter.add_mime_type("audio/wav");
        filter.add_mime_type("audio/x-wav");
        filter.add_mime_type("audio/ogg");
        filter.add_mime_type("audio/mpeg");
        filter.add_mime_type("audio/mp3");
        file_chooser.add_filter(filter);
        
        // Show the dialog
        file_chooser.show();
        
        // Handle response
        file_chooser.response.connect((response) => {
            if (response == ResponseType.ACCEPT) {
                string path = file_chooser.get_file().get_path();
                
                if (is_high_sound) {
                    high_sound_path = path;
                    settings.set_string("high-sound-path", path);
                    update_sound_button_label(high_sound_button, path);
                } else {
                    low_sound_path = path;
                    settings.set_string("low-sound-path", path);
                    update_sound_button_label(low_sound_button, path);
                }
                
                // Test play the sound
                test_play_sound(path);
            }
            
            file_chooser.destroy();
        });
        */
    }
    
    /**
     * Update a sound button label with filename.
     */
    private void update_sound_button_label(Button button, string path) {
        // Extract filename from path
        string filename = Path.get_basename(path);
        if (filename.length > 20) {
            filename = filename.substring(0, 17) + "...";
        }
        button.set_label(filename);
    }
    
    /**
     * Test play a sound file.
     */
    private void test_play_sound(string path) {
        // Create a simple pipeline to play the sound
        try {
            string pipeline_str = "playbin uri=file://%s".printf(path);
            dynamic Gst.Element pipeline = Gst.parse_launch(pipeline_str);
            
            // Start playing
            pipeline.set_state(Gst.State.PLAYING);
            
            // Stop after 1 second
            Timeout.add(1000, () => {
                pipeline.set_state(Gst.State.NULL);
                return false;
            });
        } catch (Error e) {
            warning("Failed to play test sound: %s", e.message);
        }
    }
    
    /**
     * Update application theme based on settings.
     */
    private void update_theme() {
        var style_manager = Adw.StyleManager.get_default();
        
        switch (theme_dropdown.get_selected()) {
            case 0: // Auto
                style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
                break;
            case 1: // Light
                style_manager.color_scheme = Adw.ColorScheme.FORCE_LIGHT;
                break;
            case 2: // Dark
                style_manager.color_scheme = Adw.ColorScheme.FORCE_DARK;
                break;
        }
    }
}
