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

    // Reference to metronome engine to check audio availability
    private MetronomeEngine? engine = null;
    
    // File paths for custom sounds
    private string? high_sound_path = null;
    private string? low_sound_path = null;

    // Debounce timers for settings changes
    private uint volume_debounce_timer = 0;
    private uint accent_volume_debounce_timer = 0;
    
    /**
     * Create a new preferences dialog.
     *
     * @param metronome_engine Optional reference to check audio availability
     */
    public PreferencesDialog(MetronomeEngine? metronome_engine = null) {
        GLib.Object();

        // Store engine reference
        this.engine = metronome_engine;

        // Initialize settings
        settings = new GLib.Settings(Config.APP_ID);

        // Load initial settings
        load_settings();

        // Connect signals
        connect_signals();

        // Listen for external settings changes
        settings.changed.connect(on_external_settings_changed);

        // Check if audio is available and disable audio settings if not
        check_audio_availability();
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
        // Audio settings with debouncing
        volume_scale.value_changed.connect(() => {
            debounce_volume_change();
        });

        accent_volume_scale.value_changed.connect(() => {
            debounce_accent_volume_change();
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
     * Check audio system availability and disable audio settings if unavailable.
     */
    private void check_audio_availability() {
        if (engine != null && !engine.is_audio_available()) {
            // Disable all audio-related controls
            volume_scale.set_sensitive(false);
            accent_volume_scale.set_sensitive(false);
            custom_sounds_switch.set_sensitive(false);
            high_sound_row.set_sensitive(false);
            low_sound_row.set_sensitive(false);

            message("Audio system unavailable - audio settings disabled");
        }
    }
    
    /**
     * Debounce volume scale changes to prevent rapid GSettings writes.
     */
    private void debounce_volume_change() {
        if (volume_debounce_timer != 0) {
            Source.remove(volume_debounce_timer);
        }

        volume_debounce_timer = Timeout.add(100, () => {
            settings.set_double("click-volume", volume_scale.get_value());
            volume_debounce_timer = 0;
            return false;
        });
    }

    /**
     * Debounce accent volume scale changes to prevent rapid GSettings writes.
     */
    private void debounce_accent_volume_change() {
        if (accent_volume_debounce_timer != 0) {
            Source.remove(accent_volume_debounce_timer);
        }

        accent_volume_debounce_timer = Timeout.add(100, () => {
            settings.set_double("accent-volume", accent_volume_scale.get_value());
            accent_volume_debounce_timer = 0;
            return false;
        });
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
                    // Validate the selected file
                    string? error_message = validate_audio_file(file);
                    if (error_message != null) {
                        show_error_dialog(_("Invalid Audio File"), error_message);
                        return;
                    }

                    string path = file.get_path();

                    // Test if GStreamer can actually load the file before saving
                    test_and_save_sound(path, is_high_sound);
                }
            } catch (Error e) {
                // User cancelled or other error occurred
                if (!(e is GLib.IOError.CANCELLED)) {
                    show_error_dialog(_("File Selection Error"),
                        _("Failed to open file: %s").printf(e.message));
                }
            }
        });
    }

    /**
     * Validate an audio file for security and format requirements.
     *
     * @param file The GLib.File to validate
     * @return Error message if validation fails, null if valid
     */
    private string? validate_audio_file(GLib.File file) {
        try {
            string path = file.get_path();

            // Validate path length (4096 character limit)
            const int MAX_PATH_LENGTH = 4096;
            if (path.length > MAX_PATH_LENGTH) {
                return _("File path too long: %d characters exceeds %d limit").printf(
                    path.length, MAX_PATH_LENGTH
                );
            }

            // Check if file exists and is a regular file (not directory or symlink to directory)
            var file_type = file.query_file_type(FileQueryInfoFlags.NONE);
            if (file_type != FileType.REGULAR) {
                return _("Path is not a regular file");
            }

            // Query file info for size and MIME type
            FileInfo info = file.query_info("standard::size,standard::content-type",
                                           FileQueryInfoFlags.NONE);

            // Validate file size (10MB limit)
            int64 size = info.get_size();
            const int64 MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
            if (size > MAX_FILE_SIZE) {
                return _("File too large: %s exceeds 10MB limit").printf(
                    format_size((uint64)size)
                );
            }

            // Validate MIME type against allowlist
            string? mime_type = info.get_content_type();
            if (mime_type != null) {
                string[] allowed_types = {
                    "audio/wav", "audio/x-wav", "audio/vnd.wave",
                    "audio/mpeg", "audio/mp3", "audio/x-mpeg",
                    "audio/ogg", "audio/x-vorbis+ogg", "audio/x-ogg",
                    "audio/flac", "audio/x-flac"
                };

                bool valid_format = false;
                foreach (string allowed in allowed_types) {
                    if (mime_type == allowed) {
                        valid_format = true;
                        break;
                    }
                }

                if (!valid_format) {
                    return _("Unsupported audio format: %s\nPlease use WAV, MP3, OGG, or FLAC").printf(
                        mime_type
                    );
                }
            }

            return null; // Validation passed

        } catch (Error e) {
            return _("Failed to validate file: %s").printf(e.message);
        }
    }

    /**
     * Show an error alert dialog for file validation failures.
     *
     * @param title The error title
     * @param message The error message to display
     */
    private void show_error_dialog(string title, string message) {
        var dialog = new Adw.AlertDialog(title, message);
        dialog.add_response("ok", _("OK"));
        dialog.set_response_appearance("ok", Adw.ResponseAppearance.DEFAULT);
        dialog.set_default_response("ok");
        dialog.set_close_response("ok");

        dialog.present(this);
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
     * Test if audio file can be loaded by GStreamer and save if successful.
     *
     * @param path The file path to test and save
     * @param is_high_sound Whether this is for high (accent) or low sound
     */
    private void test_and_save_sound(string path, bool is_high_sound) {
        // Create a simple pipeline to test the sound
        try {
            var pipeline = Gst.ElementFactory.make("playbin", "test-player");
            if (pipeline == null) {
                warning("Failed to create playbin for test sound");
                show_error_dialog(_("Audio System Error"),
                    _("Failed to create audio player. The audio system may not be properly initialized."));
                return;
            }

            // Set the file URI using safe File.get_uri() method
            var file = GLib.File.new_for_path(path);
            pipeline.set("uri", file.get_uri());

            // Set a reasonable volume
            pipeline.set("volume", 0.8);

            // Track loading state
            bool load_failed = false;
            bool load_succeeded = false;

            // Listen for state change to detect loading success/failure
            Gst.Bus bus = pipeline.get_bus();
            bus.add_watch(0, (bus, message) => {
                switch (message.type) {
                    case Gst.MessageType.ERROR:
                        GLib.Error err;
                        string debug;
                        message.parse_error(out err, out debug);
                        load_failed = true;
                        pipeline.set_state(Gst.State.NULL);

                        // Show error dialog on main thread
                        string filename = Path.get_basename(path);
                        string error_msg = err.message;
                        Idle.add(() => {
                            show_error_dialog(_("Invalid Audio File"),
                                _("The file '%s' cannot be loaded.\n\nReason: %s\n\nPlease select a valid audio file (WAV, MP3, OGG, or FLAC).").printf(filename, error_msg));
                            return false;
                        });
                        warning("GStreamer error loading file: %s - %s", path, err.message);
                        return false;

                    case Gst.MessageType.STATE_CHANGED:
                        if (message.src == pipeline) {
                            Gst.State old_state, new_state, pending;
                            message.parse_state_changed(out old_state, out new_state, out pending);
                            if (new_state == Gst.State.PLAYING && !load_succeeded) {
                                load_succeeded = true;

                                // File loaded successfully! Save to settings on main thread
                                Idle.add(() => {
                                    if (is_high_sound) {
                                        high_sound_path = path;
                                        settings.set_string("high-sound-path", path);
                                        update_sound_button_label(high_sound_button, path);
                                    } else {
                                        low_sound_path = path;
                                        settings.set_string("low-sound-path", path);
                                        update_sound_button_label(low_sound_button, path);
                                    }
                                    return false;
                                });

                                // Stop after 1 second
                                Timeout.add(1000, () => {
                                    pipeline.set_state(Gst.State.NULL);
                                    return false;
                                });
                            }
                        }
                        break;
                }
                return true;
            });

            // Set a 5-second timeout for loading
            Timeout.add(5000, () => {
                if (!load_succeeded && !load_failed) {
                    load_failed = true;
                    pipeline.set_state(Gst.State.NULL);
                    string filename = Path.get_basename(path);
                    show_error_dialog(_("Audio Loading Timeout"),
                        _("The file '%s' took too long to load.\n\nThis usually means the file is corrupted or in an unsupported format.").printf(filename));
                    warning("Audio file loading timed out: %s", path);
                }
                return false;
            });

            // Start playing
            var ret = pipeline.set_state(Gst.State.PLAYING);
            if (ret == Gst.StateChangeReturn.FAILURE) {
                warning("Failed to start playing test sound: %s", path);
                string filename = Path.get_basename(path);
                show_error_dialog(_("Audio Playback Failed"),
                    _("The file '%s' could not be played.\n\nThe format may not be supported by your audio system.").printf(filename));
                return;
            }

        } catch (Error e) {
            warning("Failed to test audio file: %s", e.message);
            show_error_dialog(_("Audio Test Error"),
                _("An unexpected error occurred while testing the audio file:\n\n%s").printf(e.message));
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
