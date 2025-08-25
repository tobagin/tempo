/**
 * Preferences dialog for the Tempo metronome application.
 * 
 * This class handles user preferences and settings for the application,
 * including audio settings, sound customization, and visual preferences.
 */

using Gtk;
using Adw;
using Gst;

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/tempo/Devel/ui/preferences_dialog.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/tempo/ui/preferences_dialog.ui")]
#endif
public class PreferencesDialog : Adw.PreferencesDialog {
    
    // UI Elements from Blueprint template - Audio Settings
    [GtkChild] private unowned Scale volume_scale;
    [GtkChild] private unowned Scale accent_volume_scale;
    [GtkChild] private unowned Switch custom_sounds_switch;
    [GtkChild] private unowned Adw.ActionRow high_sound_row;
    [GtkChild] private unowned Button high_sound_button;
    [GtkChild] private unowned Adw.ActionRow low_sound_row;
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
        settings = new GLib.Settings(Config.APP_ID);
        
        // Load initial settings
        load_settings();
        
        // Connect signals
        connect_signals();
        
        // Listen for external settings changes
        settings.changed.connect(on_external_settings_changed);
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
        
        // Update sound picker sensitivity based on custom sounds setting
        update_custom_sounds_sensitivity();
        
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
            update_custom_sounds_sensitivity();
            return false; // Let the switch handle the state change
        });
        
        high_sound_button.clicked.connect(() => {
            choose_sound_file(true);
        });
        
        low_sound_button.clicked.connect(() => {
            choose_sound_file(false);
        });
        
        // Add right-click context menu for clearing sounds
        setup_sound_button_context_menu(high_sound_button, true);
        setup_sound_button_context_menu(low_sound_button, false);
        
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
     * Handle external settings changes (e.g., from another instance or gsettings command).
     */
    private void on_external_settings_changed(string key) {
        switch (key) {
            case "high-sound-path":
                high_sound_path = settings.get_string("high-sound-path");
                update_sound_button_label(high_sound_button, high_sound_path);
                break;
            case "low-sound-path":
                low_sound_path = settings.get_string("low-sound-path");
                update_sound_button_label(low_sound_button, low_sound_path);
                break;
            case "use-custom-sounds":
                custom_sounds_switch.set_active(settings.get_boolean("use-custom-sounds"));
                update_custom_sounds_sensitivity();
                break;
        }
    }
    
    /**
     * Update the sensitivity of custom sound picker rows based on the switch state.
     */
    private void update_custom_sounds_sensitivity() {
        bool use_custom = custom_sounds_switch.get_active();
        high_sound_row.set_sensitive(use_custom);
        low_sound_row.set_sensitive(use_custom);
    }
    
    /**
     * Choose a custom sound file.
     * 
     * @param is_high_sound Whether this is for the high (accent) sound or low sound
     */
    private void choose_sound_file(bool is_high_sound) {
        var file_dialog = new Gtk.FileDialog();
        
        // Set dialog title
        file_dialog.title = is_high_sound ? _("Choose High Sound") : _("Choose Low Sound");
        
        // Create audio file filter
        var audio_filter = new Gtk.FileFilter();
        audio_filter.name = _("Audio Files");
        audio_filter.add_mime_type("audio/wav");
        audio_filter.add_mime_type("audio/x-wav");
        audio_filter.add_mime_type("audio/ogg");
        audio_filter.add_mime_type("audio/mpeg");
        audio_filter.add_mime_type("audio/mp3");
        audio_filter.add_mime_type("audio/flac");
        audio_filter.add_mime_type("audio/x-flac");
        audio_filter.add_mime_type("audio/aac");
        audio_filter.add_mime_type("audio/x-aac");
        
        // Create list model for filters
        var filter_list = new GLib.ListStore(typeof(Gtk.FileFilter));
        filter_list.append(audio_filter);
        
        // Add "All Files" filter as fallback
        var all_filter = new Gtk.FileFilter();
        all_filter.name = _("All Files");
        all_filter.add_pattern("*");
        filter_list.append(all_filter);
        
        file_dialog.filters = filter_list;
        file_dialog.default_filter = audio_filter;
        
        // Show the dialog asynchronously  
        file_dialog.open.begin(this.get_root() as Gtk.Window, null, (obj, res) => {
            try {
                var file = file_dialog.open.end(res);
                if (file != null) {
                    string path = file.get_path();
                    
                    // Validate that the file exists and is readable
                    if (!FileUtils.test(path, FileTest.EXISTS)) {
                        warning("Selected file does not exist: %s", path);
                        return;
                    }
                    
                    if (!FileUtils.test(path, FileTest.IS_REGULAR)) {
                        warning("Selected path is not a regular file: %s", path);
                        return;
                    }
                    
                    // Save the path and update UI
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
            } catch (Error e) {
                // User cancelled or other error occurred
                if (!(e is GLib.IOError.CANCELLED)) {
                    warning("Failed to open file dialog: %s", e.message);
                }
            }
        });
    }
    
    /**
     * Update a sound button label with filename.
     */
    private void update_sound_button_label(Button button, string path) {
        if (path == null || path == "") {
            button.set_label(_("Choose File..."));
            return;
        }
        
        // Extract filename from path
        string filename = Path.get_basename(path);
        if (filename.length > 20) {
            filename = filename.substring(0, 17) + "...";
        }
        button.set_label(filename);
    }
    
    /**
     * Reset a custom sound to default by clearing the path.
     */
    private void reset_custom_sound(bool is_high_sound) {
        if (is_high_sound) {
            high_sound_path = "";
            settings.set_string("high-sound-path", "");
            update_sound_button_label(high_sound_button, "");
        } else {
            low_sound_path = "";
            settings.set_string("low-sound-path", "");
            update_sound_button_label(low_sound_button, "");
        }
    }
    
    /**
     * Setup context menu for sound buttons to allow clearing custom sounds.
     */
    private void setup_sound_button_context_menu(Button button, bool is_high_sound) {
        var gesture = new Gtk.GestureClick();
        gesture.set_button(3); // Right mouse button
        
        gesture.pressed.connect((n_press, x, y) => {
            // Only show context menu if a custom sound is set
            string current_path = is_high_sound ? high_sound_path : low_sound_path;
            if (current_path != null && current_path != "") {
                show_sound_context_menu(button, is_high_sound, x, y);
            }
        });
        
        button.add_controller(gesture);
    }
    
    /**
     * Show context menu for sound button.
     */
    private void show_sound_context_menu(Button button, bool is_high_sound, double x, double y) {
        var popover = new Gtk.Popover();
        popover.set_parent(button);
        popover.set_position(Gtk.PositionType.BOTTOM);
        
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.add_css_class("menu");
        
        var clear_button = new Gtk.Button.with_label(_("Clear Custom Sound"));
        clear_button.add_css_class("flat");
        clear_button.clicked.connect(() => {
            reset_custom_sound(is_high_sound);
            popover.popdown();
        });
        
        box.append(clear_button);
        popover.set_child(box);
        popover.popup();
    }
    
    /**
     * Test play a sound file.
     */
    private void test_play_sound(string path) {
        // Create a simple pipeline to play the sound
        try {
            var pipeline = Gst.ElementFactory.make("playbin", "test-player");
            if (pipeline == null) {
                warning("Failed to create playbin for test sound");
                return;
            }
            
            // Set the file URI
            pipeline.set("uri", "file://" + path);
            
            // Set a reasonable volume
            pipeline.set("volume", 0.8);
            
            // Start playing
            var ret = pipeline.set_state(Gst.State.PLAYING);
            if (ret == Gst.StateChangeReturn.FAILURE) {
                warning("Failed to start playing test sound: %s", path);
                return;
            }
            
            // Stop after 1 second to avoid playing the whole file
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
