/**
 * Main window for the Tempo metronome application.
 * 
 * This class uses the Blueprint UI template for a professional interface.
 */

using Gtk;
using Adw;

/**
 * Metronome operation modes
 */
public enum MetronomeMode {
    SIMPLE_BEATS,    // Standard metronome with subdivisions
    PATTERN          // Rhythm pattern playback
}

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/tempo/Devel/ui/main_window.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/tempo/ui/main_window.ui")]
#endif
public class TempoWindow : Adw.ApplicationWindow {
    
    // UI Elements from Blueprint template
    [GtkChild] private unowned Adw.ViewStack view_stack;
    [GtkChild] private unowned Adw.ViewSwitcherBar view_switcher_bar;

    // Metronome tab widgets
    [GtkChild] private unowned Label tempo_label;
    [GtkChild] private unowned SpinButton tempo_spin;
    [GtkChild] private unowned Scale tempo_scale;
    [GtkChild] private unowned SpinButton beats_spin;
    [GtkChild] private unowned DropDown beat_value_dropdown;
    [GtkChild] private unowned DropDown subdivision_dropdown;
    [GtkChild] private unowned DrawingArea beat_indicator;
    [GtkChild] private unowned Button play_button;
    [GtkChild] private unowned Button tap_button;
    [GtkChild] private unowned Box timer_box;
    [GtkChild] private unowned Label timer_display;
    [GtkChild] private unowned Label auto_stop_progress;

    // Patterns tab widgets
    [GtkChild] private unowned Label patterns_tempo_label;
    [GtkChild] private unowned Scale patterns_tempo_scale;
    [GtkChild] private unowned DropDown pattern_dropdown;
    [GtkChild] private unowned Button pattern_edit_button;
    [GtkChild] private unowned Label pattern_info_label;
    [GtkChild] private unowned DrawingArea patterns_beat_indicator;
    [GtkChild] private unowned Button patterns_play_button;

    // Trainer tab widgets
    [GtkChild] private unowned SpinButton trainer_start_spin;
    [GtkChild] private unowned SpinButton trainer_target_spin;
    [GtkChild] private unowned SpinButton trainer_increment_spin;
    [GtkChild] private unowned SpinButton trainer_interval_spin;
    [GtkChild] private unowned DropDown trainer_interval_type;
    [GtkChild] private unowned Label trainer_status_label;
    [GtkChild] private unowned DrawingArea trainer_beat_indicator;
    [GtkChild] private unowned Button trainer_play_button;

    // Setlists tab widgets
    [GtkChild] private unowned Box setlist_nav_box;
    [GtkChild] private unowned Button prev_setlist_button;
    [GtkChild] private unowned Label setlist_pos_label;
    [GtkChild] private unowned Button next_setlist_button;
    [GtkChild] private unowned Label active_setlist_name;
    [GtkChild] private unowned ListBox active_setlist_presets;
    [GtkChild] private unowned Button manage_setlists_button;

    // Engine components
    private MetronomeEngine metronome_engine;
    private TapTempo tap_tempo;
    private PracticeTimer practice_timer;
    private TempoTrainer tempo_trainer;

    // Pattern components
    private Tempo.PatternLibrary pattern_library;
    private Tempo.PatternEngine pattern_engine;
    private Gtk.StringList pattern_model;
    private MetronomeMode current_mode = MetronomeMode.SIMPLE_BEATS;

    // Preset manager
    private PresetManager preset_manager;

    // Preferences dialog
    private PreferencesDialog? preferences_dialog = null;

    // Keyboard shortcuts dialog

    // Preset manager dialog
    private PresetManagerDialog? preset_manager_dialog = null;

    // Setlist manager
    private SetlistManager setlist_manager;
    private SetlistManagerDialog? setlist_manager_dialog = null;
    private Setlist? active_setlist = null;
    private int active_setlist_index = -1;

    // Settings for visual preferences
    private GLib.Settings settings;

    // Beat indicator state
    private bool beat_active = false;
    private bool is_downbeat = false;
    private bool is_muted = false;
    private int current_beat_number = 1;

    // Frame rate limiting for beat indicator (60 FPS = ~16.67ms per frame)
    private const uint FRAME_INTERVAL_MS = 17; // ~60 FPS
    private uint last_draw_time = 0;
    private bool redraw_pending = false;

    // Visual-only mode state
    private bool visual_only_mode = false;

    // Visual mode system
    private VisualMode current_visual_mode;
    private int64 beat_start_time = 0;
    private double animation_progress = 0.0;
    private uint animation_timer_id = 0;

    // Independent tempo for each view
    private int metronome_view_tempo = 120;
    private int patterns_view_tempo = 120;
    private string? current_view = null;

    public TempoWindow(Adw.Application app) {
        Object(application: app);
        
        // Initialize settings
        settings = new GLib.Settings(Config.APP_ID);

        // Initialize engines
        metronome_engine = new MetronomeEngine();
        tap_tempo = new TapTempo();
        practice_timer = new PracticeTimer(settings);
        tempo_trainer = new TempoTrainer();

        // Initialize pattern system
        pattern_library = new Tempo.PatternLibrary();
        pattern_engine = new Tempo.PatternEngine();

        // Initialize preset manager
        preset_manager = new PresetManager();

        // Initialize setlist manager
        setlist_manager = new SetlistManager();

        // Initialize visual mode
        initialize_visual_mode();

        // Connect timer to metronome engine
        metronome_engine.set_practice_timer(practice_timer);

        // Connect tempo trainer to metronome
        metronome_engine.beat_occurred.connect(on_trainer_beat_occurred);
        tempo_trainer.tempo_should_change.connect(on_trainer_tempo_change);
        tempo_trainer.target_reached.connect(on_trainer_target_reached);
        tempo_trainer.progression_updated.connect(on_trainer_progression_updated);

        setup_ui();
        connect_signals();
        setup_tempo_trainer_ui();

        // Listen for settings changes to update visuals
        settings.changed.connect(on_settings_changed);

        // Listen for audio system failures
        metronome_engine.audio_system_failed.connect(on_audio_system_failed);
        
        // Apply initial settings when window is mapped
        this.map.connect(() => {
            apply_keep_on_top_setting();
            apply_start_on_launch_setting();
        });
    }
    
    private void setup_ui() {
        // Load CSS styles using modern approach
        var css_provider = new CssProvider();
        css_provider.load_from_resource(Config.RESOURCE_PATH + "/style.css");

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
        update_subdivision_display();
        initialize_pattern_dropdown();

        // Load mute pattern from settings
        load_mute_pattern();

        // Load saved pattern from settings
        load_active_pattern();

        // Setup beat indicator drawing for all tabs
        beat_indicator.set_draw_func(draw_beat_indicator);
        patterns_beat_indicator.set_draw_func(draw_beat_indicator);
        trainer_beat_indicator.set_draw_func(draw_beat_indicator);

        // Initialize current view and independent tempo values
        current_view = view_stack.get_visible_child_name();
        metronome_view_tempo = metronome_engine.bpm;
        patterns_view_tempo = metronome_engine.bpm;
    }
    
    private void connect_signals() {
        // View switching
        view_stack.notify["visible-child-name"].connect(on_view_changed);

        // Tempo controls
        tempo_spin.value_changed.connect(on_tempo_changed);
        tempo_scale.value_changed.connect(on_tempo_scale_changed);

        // Time signature controls
        beats_spin.value_changed.connect(on_beats_changed);
        beat_value_dropdown.notify["selected"].connect(on_beat_value_changed);

        // Subdivision controls
        subdivision_dropdown.notify["selected"].connect(on_subdivision_changed);

        // Pattern controls
        pattern_dropdown.notify["selected"].connect(on_pattern_changed);
        pattern_edit_button.clicked.connect(on_pattern_edit_clicked);

        // Control buttons (all tabs use same handler)
        play_button.clicked.connect(on_play_clicked);
        patterns_play_button.clicked.connect(on_play_clicked);
        trainer_play_button.clicked.connect(on_play_clicked);
        tap_button.clicked.connect(on_tap_clicked);

        // Setlist controls
        manage_setlists_button.clicked.connect(on_manage_setlists_clicked);
        prev_setlist_button.clicked.connect(on_prev_setlist_clicked);
        next_setlist_button.clicked.connect(on_next_setlist_clicked);
        active_setlist_presets.row_selected.connect(on_setlist_preset_selected);

        // Metronome engine signals
        metronome_engine.beat_occurred.connect(on_beat_occurred);

        // Pattern engine signals
        pattern_engine.step_occurred.connect(on_pattern_step_occurred);
        pattern_engine.pattern_loop_completed.connect(on_pattern_loop_completed);

        // Practice timer signals
        practice_timer.tick.connect(on_timer_tick);
        practice_timer.countdown_completed.connect(on_countdown_completed);
        practice_timer.auto_stop_triggered.connect(on_auto_stop_triggered);

        // Update timer visibility based on settings
        settings.bind("timer-show-in-main-window", timer_box, "visible", SettingsBindFlags.DEFAULT);

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

            // Sync to pattern engine
            pattern_engine.bpm = new_bpm;
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

            // Sync to pattern engine
            pattern_engine.bpm = new_bpm;
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

    private void on_subdivision_changed() {
        // Map dropdown index to subdivision mode
        // 0 = None, 1 = Eighths, 2 = Triplets, 3 = Sixteenths
        int mode_value;
        switch (subdivision_dropdown.selected) {
            case 0: mode_value = 0; break;  // NONE
            case 1: mode_value = 2; break;  // EIGHTH
            case 2: mode_value = 3; break;  // TRIPLET
            case 3: mode_value = 4; break;  // SIXTEENTH
            default: mode_value = 0; break;
        }

        // Update settings (which will update the engine via binding)
        settings.set_int("subdivision-mode", mode_value);
    }

    private void update_subdivision_display() {
        // Get current subdivision mode from settings
        int mode_value = settings.get_int("subdivision-mode");

        // Map mode to dropdown index
        switch (mode_value) {
            case 0: subdivision_dropdown.selected = 0; break;  // NONE
            case 2: subdivision_dropdown.selected = 1; break;  // EIGHTH
            case 3: subdivision_dropdown.selected = 2; break;  // TRIPLET
            case 4: subdivision_dropdown.selected = 3; break;  // SIXTEENTH
            default: subdivision_dropdown.selected = 0; break;
        }
    }

    /**
     * Handle view switching - save current tempo and restore new view's tempo
     */
    private void on_view_changed() {
        var new_view = view_stack.get_visible_child_name();

        // Don't process if metronome is running (view switching is disabled)
        bool is_running = metronome_engine.is_running || pattern_engine.is_running;
        if (is_running) {
            return;
        }

        // Save current view's tempo
        if (current_view != null) {
            switch (current_view) {
                case "metronome":
                    metronome_view_tempo = metronome_engine.bpm;
                    break;
                case "patterns":
                    patterns_view_tempo = metronome_engine.bpm;
                    break;
                // Trainer view uses its own start_tempo/target_tempo, no need to save
            }
        }

        // Restore new view's tempo
        switch (new_view) {
            case "metronome":
                try {
                    metronome_engine.set_tempo(metronome_view_tempo);
                    update_tempo_display();
                } catch (MetronomeError e) {
                    warning("Failed to restore metronome view tempo: %s", e.message);
                }
                break;
            case "patterns":
                try {
                    metronome_engine.set_tempo(patterns_view_tempo);
                    update_tempo_display();
                } catch (MetronomeError e) {
                    warning("Failed to restore patterns view tempo: %s", e.message);
                }
                break;
            case "trainer":
                // Trainer view shows its configured start tempo
                try {
                    metronome_engine.set_tempo(tempo_trainer.start_tempo);
                    update_tempo_display();
                } catch (MetronomeError e) {
                    warning("Failed to set trainer tempo: %s", e.message);
                }
                break;
        }

        current_view = new_view;
    }

    private void on_play_clicked() {
        // Determine which view is active
        var visible_view = view_stack.get_visible_child_name();

        // Check if anything is running
        bool is_running = metronome_engine.is_running || pattern_engine.is_running;

        if (is_running) {
            // Stop everything
            metronome_engine.stop();
            pattern_engine.stop();
            tempo_trainer.pause();
            stop_animation_timer();

            // Update all three buttons to "Start"
            update_play_button(play_button, false);
            update_play_button(patterns_play_button, false);
            update_play_button(trainer_play_button, false);

            // Enable view switching
            view_switcher_bar.sensitive = true;
        } else {
            // Start based on active view
            start_animation_timer();

            if (visible_view == "patterns" && current_mode == MetronomeMode.PATTERN) {
                // Pattern view with active pattern
                pattern_engine.bpm = metronome_engine.bpm;
                pattern_engine.start();
            } else if (visible_view == "trainer") {
                // Trainer view - set tempo to trainer's start tempo
                try {
                    metronome_engine.set_tempo(tempo_trainer.start_tempo);
                    update_tempo_display();
                } catch (MetronomeError e) {
                    warning("Failed to set trainer start tempo: %s", e.message);
                }
                metronome_engine.start();
                tempo_trainer.start();
            } else {
                // Metronome view (default)
                metronome_engine.start();
            }

            // Update all three buttons to "Stop"
            update_play_button(play_button, true);
            update_play_button(patterns_play_button, true);
            update_play_button(trainer_play_button, true);

            // Disable view switching while playing
            view_switcher_bar.sensitive = false;
        }
    }

    /**
     * Update a play button's label and style
     */
    private void update_play_button(Button button, bool is_playing) {
        if (is_playing) {
            button.label = _("Stop");
            button.remove_css_class("suggested-action");
            button.add_css_class("destructive-action");
        } else {
            button.label = _("Start");
            button.add_css_class("suggested-action");
            button.remove_css_class("destructive-action");
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
    
    private void on_beat_occurred(int beat_number, bool downbeat, bool muted) {
        // Update beat indicator state
        beat_active = true;
        is_downbeat = downbeat;
        is_muted = muted;

        // Store the beat number to display (convert to 1-based beat-in-bar)
        var beat_info = metronome_engine.get_beat_info();
        current_beat_number = beat_info["beat_in_bar"].get_int32();

        // Record beat start time for animation progress calculation
        beat_start_time = GLib.get_monotonic_time();

        // Trigger redraw with frame rate limiting
        request_redraw();

        // Reset beat indicator after short delay
        Timeout.add(100, () => {
            beat_active = false;
            request_redraw();
            return false;
        });
    }

    /**
     * Request a redraw with frame rate limiting (60 FPS max).
     */
    private void request_redraw() {
        uint current_time = (uint)(GLib.get_monotonic_time() / 1000); // Convert to milliseconds

        // Check if enough time has passed since last draw
        if (current_time - last_draw_time >= FRAME_INTERVAL_MS) {
            // Redraw all beat indicators (one per tab)
            beat_indicator.queue_draw();
            patterns_beat_indicator.queue_draw();
            trainer_beat_indicator.queue_draw();
            last_draw_time = current_time;
            redraw_pending = false;
        } else if (!redraw_pending) {
            // Schedule a delayed redraw
            redraw_pending = true;
            uint delay = FRAME_INTERVAL_MS - (current_time - last_draw_time);

            Timeout.add(delay, () => {
                // Redraw all beat indicators
                beat_indicator.queue_draw();
                patterns_beat_indicator.queue_draw();
                trainer_beat_indicator.queue_draw();
                last_draw_time = (uint)(GLib.get_monotonic_time() / 1000);
                redraw_pending = false;
                return false;
            });
        }
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
                // F1: Show keyboard shortcuts dialog
                show_keyboard_shortcuts();
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
    
    
    /**
     * Show the preferences dialog.
     */
    public void show_preferences() {
        if (preferences_dialog == null) {
            preferences_dialog = new PreferencesDialog(metronome_engine);
        }
        preferences_dialog.present(this);
    }

    /**
     * Show the keyboard shortcuts dialog.
     */
    public void show_keyboard_shortcuts() {
        KeyboardShortcutsDialog.present(this);
    }

    /**
     * Show the preset manager dialog.
     */
    public void show_preset_manager() {
        preset_manager_dialog = new PresetManagerDialog(this, preset_manager);
        preset_manager_dialog.preset_loaded.connect((preset) => {
            // Preset has been loaded, settings have been applied
            // The UI will update automatically through settings bindings
        });
        preset_manager_dialog.present(this);
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
                // Redraw all beat indicators with new settings
                beat_indicator.queue_draw();
                patterns_beat_indicator.queue_draw();
                trainer_beat_indicator.queue_draw();
                break;
            case "visual-mode":
                // Switch visual mode
                switch_visual_mode(settings.get_string("visual-mode"));
                break;
            case "keep-on-top":
                apply_keep_on_top_setting();
                break;
            case "mute-enabled":
            case "mute-pattern-type":
            case "mute-interval":
            case "mute-percentage":
            case "mute-specific-beats":
            case "mute-progressive-start":
            case "mute-progressive-end":
            case "mute-progressive-interval":
                // Reload mute pattern when any mute setting changes
                load_mute_pattern();
                break;
        }
    }

    /**
     * Load mute pattern from settings and apply to metronome engine.
     */
    private void load_mute_pattern() {
        // Get mute enabled setting
        bool mute_enabled = settings.get_boolean("mute-enabled");
        metronome_engine.mute_enabled = mute_enabled;

        if (mute_enabled) {
            // Create pattern from settings
            var pattern = Tempo.MutePatternFactory.create_from_settings(settings);

            // Apply pattern to engine
            metronome_engine.mute_pattern = pattern;

            if (pattern != null) {
                message("Loaded mute pattern: %s", pattern.get_description());
            }
        } else {
            // Disable muting
            metronome_engine.mute_pattern = null;
        }
    }

    /**
     * Handle audio system initialization failure.
     *
     * @param error_message The error message describing the failure
     */
    private void on_audio_system_failed(string error_message) {
        // Create modal dialog
        var dialog = new Adw.AlertDialog(
            _("Audio System Unavailable"),
            _("The audio system could not be initialized.\n\n%s\n\nYou can continue in visual-only mode where the beat indicator will still work, but no sound will be played.").printf(error_message)
        );

        dialog.add_response("quit", _("Exit Application"));
        dialog.add_response("continue", _("Continue in Visual-Only Mode"));

        dialog.set_response_appearance("continue", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_response_appearance("quit", Adw.ResponseAppearance.DESTRUCTIVE);

        dialog.set_default_response("continue");
        dialog.set_close_response("continue");

        dialog.response.connect((response_id) => {
            if (response_id == "quit") {
                this.close();
            } else {
                // Enable visual-only mode
                enable_visual_only_mode();
            }
        });

        dialog.present(this);
    }

    private void on_manage_setlists_clicked() {
        setlist_manager_dialog = new SetlistManagerDialog(this, setlist_manager, preset_manager);
        setlist_manager_dialog.setlist_activated.connect(on_setlist_activated);
        setlist_manager_dialog.present(this);
    }

    private void on_setlist_activated(Setlist setlist) {
        active_setlist = setlist;
        active_setlist_name.label = setlist.name;
        active_setlist_index = 0;
        
        populate_active_setlist_presets();
        apply_active_setlist_preset();
        
        setlist_nav_box.visible = true;
        update_setlist_nav_ui();

        // Switch to metronome view when a setlist is activated
        view_stack.visible_child_name = "metronome";
    }

    private void populate_active_setlist_presets() {
        Gtk.ListBoxRow? row = active_setlist_presets.get_row_at_index(0);
        while (row != null) {
            active_setlist_presets.remove(row);
            row = active_setlist_presets.get_row_at_index(0);
        }

        if (active_setlist == null) return;

        for (int i = 0; i < active_setlist.preset_ids.size; i++) {
            var preset_id = active_setlist.preset_ids[i];
            var preset = preset_manager.get_preset(preset_id);
            if (preset != null) {
                var preset_row = create_active_setlist_row(preset, i);
                active_setlist_presets.append(preset_row);
            }
        }
    }

    private Gtk.ListBoxRow create_active_setlist_row(Preset preset, int index) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        box.margin_start = box.margin_end = 12;
        box.margin_top = box.margin_bottom = 8;

        var name_label = new Gtk.Label(preset.name);
        name_label.hexpand = true;
        name_label.halign = Gtk.Align.START;
        box.append(name_label);

        var tempo_label = new Gtk.Label("%d BPM".printf(preset.tempo));
        tempo_label.add_css_class("dim-label");
        box.append(tempo_label);

        var row = new Gtk.ListBoxRow();
        row.child = box;
        row.set_data("index", index);
        return row;
    }

    private void on_setlist_preset_selected(Gtk.ListBoxRow? row) {
        if (row == null) return;
        active_setlist_index = (int)row.get_data<int>("index");
        apply_active_setlist_preset();
        update_setlist_nav_ui();
    }

    private void apply_active_setlist_preset() {
        if (active_setlist == null || active_setlist_index < 0 || active_setlist_index >= active_setlist.preset_ids.size) {
            return;
        }

        var preset_id = active_setlist.preset_ids[active_setlist_index];
        try {
            preset_manager.apply_preset(preset_id);
            // Updating UI is handled by settings bindings in PresetManager
            update_tempo_display();
            update_time_signature_display();
            update_subdivision_display();
        } catch (Error e) {
            warning("Failed to apply setlist preset: %s", e.message);
        }
    }

    private void update_setlist_nav_ui() {
        if (active_setlist == null) {
            setlist_nav_box.visible = false;
            return;
        }

        setlist_pos_label.label = "%d / %d".printf(active_setlist_index + 1, active_setlist.preset_ids.size);
        prev_setlist_button.sensitive = active_setlist_index > 0;
        next_setlist_button.sensitive = active_setlist_index < active_setlist.preset_ids.size - 1;

        // Highlight current row in the list
        var row = active_setlist_presets.get_row_at_index(active_setlist_index);
        if (row != null) {
            active_setlist_presets.select_row(row);
        }
    }

    private void on_prev_setlist_clicked() {
        if (active_setlist_index > 0) {
            active_setlist_index--;
            apply_active_setlist_preset();
            update_setlist_nav_ui();
        }
    }

    private void on_next_setlist_clicked() {
        if (active_setlist == null) return;
        if (active_setlist_index < active_setlist.preset_ids.size - 1) {
            active_setlist_index++;
            apply_active_setlist_preset();
            update_setlist_nav_ui();
        }
    }

    /**
     * Enable visual-only mode when audio system is unavailable.
     */
    private void enable_visual_only_mode() {
        visual_only_mode = true;

        // Show info banner about visual-only mode
        var toast = new Adw.Toast(_("Running in visual-only mode"));
        toast.timeout = 5;

        // Note: Toast needs to be added to a ToastOverlay in the UI hierarchy
        // For now, we'll just log it
        message("Audio system unavailable - running in visual-only mode");

        // Audio controls would be disabled here if they were exposed in the UI
        // Currently audio settings are in PreferencesDialog which will handle
        // this separately by checking metronome_engine.is_audio_available()
    }
    
    /**
     * Apply the keep-on-top window setting.
     * Note: GTK4 doesn't expose set_keep_above in the public API.
     * This is a placeholder for future implementation.
     */
    private void apply_keep_on_top_setting() {
        bool keep_on_top = settings.get_boolean("keep-on-top");
        
        // TODO: GTK4 doesn't currently expose window keep-above functionality
        // in the public API. This would need to be implemented at the 
        // compositor/window manager level or using platform-specific code.
        warning("Keep-on-top functionality not available in GTK4 public API");
    }
    
    /**
     * Apply the start-on-launch setting by starting metronome if enabled.
     */
    private void apply_start_on_launch_setting() {
        bool start_on_launch = settings.get_boolean("start-on-launch");
        
        if (start_on_launch && !metronome_engine.is_running) {
            // Start the metronome automatically
            metronome_engine.start();
            play_button.label = _("Stop");
        }
    }

    /**
     * Initialize visual mode from settings.
     */
    private void initialize_visual_mode() {
        string mode_name = settings.get_string("visual-mode");
        switch_visual_mode(mode_name);
    }

    /**
     * Switch to a different visual mode.
     */
    private void switch_visual_mode(string mode_name) {
        switch (mode_name) {
            case "pendulum":
                current_visual_mode = new PendulumMode(settings);
                break;
            case "bar":
                current_visual_mode = new BarGraphMode(settings);
                break;
            case "ring":
                current_visual_mode = new ProgressRingMode(settings);
                break;
            case "flash":
                current_visual_mode = new MinimalistFlashMode(settings);
                break;
            case "circle":
            default:
                current_visual_mode = new CircleMode(settings);
                break;
        }

        // Redraw all indicators with new mode
        beat_indicator.queue_draw();
        patterns_beat_indicator.queue_draw();
        trainer_beat_indicator.queue_draw();
    }

    /**
     * Calculate animation progress within current beat (0.0-1.0).
     */
    private double calculate_animation_progress() {
        if (beat_start_time == 0 || !metronome_engine.is_running) {
            return 0.0;
        }

        int64 current_time = GLib.get_monotonic_time();
        int64 elapsed = current_time - beat_start_time;

        // Calculate beat duration in microseconds
        double beat_duration_us = 60.0 / metronome_engine.bpm * 1000000.0;

        double progress = elapsed / beat_duration_us;
        return progress.clamp(0.0, 1.0);
    }

    /**
     * Start animation timer for smooth visual updates at 60fps.
     */
    private void start_animation_timer() {
        // Stop existing timer if any
        stop_animation_timer();

        // Start 60fps timer (16ms)
        animation_timer_id = Timeout.add(16, () => {
            if (metronome_engine.is_running || pattern_engine.is_running) {
                animation_progress = calculate_animation_progress();
                beat_indicator.queue_draw();
                patterns_beat_indicator.queue_draw();
                trainer_beat_indicator.queue_draw();
                return true; // Continue timer
            }
            return false; // Stop timer
        });
    }

    /**
     * Stop animation timer.
     */
    private void stop_animation_timer() {
        if (animation_timer_id > 0) {
            Source.remove(animation_timer_id);
            animation_timer_id = 0;
        }
    }

    /**
     * Enhanced beat indicator drawing function using visual modes.
     */
    private void draw_beat_indicator(DrawingArea area, Cairo.Context cr, int width, int height) {
        // Get current beat info
        var beat_info = metronome_engine.get_beat_info();
        var current_beat_in_bar = beat_info["beat_in_bar"].get_int32();

        // Calculate animation progress
        animation_progress = calculate_animation_progress();

        // Delegate drawing to current visual mode
        if (current_visual_mode != null) {
            current_visual_mode.draw(
                cr,
                metronome_engine.is_running ? current_beat_number : 0,
                metronome_engine.beats_per_bar,
                is_downbeat,
                is_muted,
                animation_progress,
                width,
                height
            );
        }
    }

    /**
     * Handle practice timer tick - update display and progress.
     */
    private void on_timer_tick(int64 elapsed, int64 remaining) {
        // Format and display time
        string time_str = format_timer_display(elapsed, remaining);
        timer_display.label = time_str;

        // Update auto-stop progress
        update_auto_stop_progress();
    }

    /**
     * Format timer display based on mode and duration.
     */
    private string format_timer_display(int64 elapsed, int64 remaining) {
        int64 display_time = (practice_timer.mode == TimerMode.COUNTDOWN) ? remaining : elapsed;

        // Convert microseconds to seconds
        int total_seconds = (int)(display_time / 1000000);

        int hours = total_seconds / 3600;
        int minutes = (total_seconds % 3600) / 60;
        int seconds = total_seconds % 60;

        // Use HH:MM:SS for >= 1 hour, otherwise MM:SS
        if (hours > 0) {
            return "%02d:%02d:%02d".printf(hours, minutes, seconds);
        } else {
            return "%02d:%02d".printf(minutes, seconds);
        }
    }

    /**
     * Update auto-stop progress display.
     */
    private void update_auto_stop_progress() {
        if (practice_timer.auto_stop_mode == AutoStopMode.NONE) {
            auto_stop_progress.label = "";
            return;
        }

        string progress_text = "";

        switch (practice_timer.auto_stop_mode) {
            case AutoStopMode.BEATS:
                // Access private beat count through calculation
                progress_text = _("Target: %d beats").printf(practice_timer.auto_stop_value);
                break;

            case AutoStopMode.BARS:
                progress_text = _("Target: %d bars").printf(practice_timer.auto_stop_value);
                break;

            case AutoStopMode.TIME:
                int target_minutes = practice_timer.auto_stop_value;
                progress_text = _("Target: %d minutes").printf(target_minutes);
                break;
        }

        auto_stop_progress.label = progress_text;
    }

    /**
     * Handle countdown completion - show toast notification.
     */
    private void on_countdown_completed() {
        var toast = new Adw.Toast(_("Practice session completed"));
        toast.timeout = 3;

        // Get the toast overlay (assuming we're in an Adw.ApplicationWindow)
        var overlay = this.content as Adw.ToastOverlay;
        if (overlay != null) {
            overlay.add_toast(toast);
        }
    }

    /**
     * Handle auto-stop trigger - show toast with details.
     */
    private void on_auto_stop_triggered() {
        string message = "";

        switch (practice_timer.auto_stop_mode) {
            case AutoStopMode.BEATS:
                message = _("Auto-stop: %d beats completed").printf(practice_timer.auto_stop_value);
                break;

            case AutoStopMode.BARS:
                message = _("Auto-stop: %d bars completed").printf(practice_timer.auto_stop_value);
                break;

            case AutoStopMode.TIME:
                message = _("Auto-stop: %d minutes completed").printf(practice_timer.auto_stop_value);
                break;
        }

        if (message != "") {
            var toast = new Adw.Toast(message);
            toast.timeout = 3;

            var overlay = this.content as Adw.ToastOverlay;
            if (overlay != null) {
                overlay.add_toast(toast);
            }
        }
    }

    // Tempo Trainer handlers
    private void on_trainer_beat_occurred(int beat_num, bool is_downbeat, bool muted) {
        if (!tempo_trainer.is_active) return;

        int beats_per_bar = settings.get_int("time-signature-numerator");
        tempo_trainer.on_beat_occurred(beat_num, beats_per_bar);
    }

    private void on_trainer_tempo_change(int new_tempo) {
        // Update tempo spin button (will trigger metronome update)
        tempo_spin.value = new_tempo;
    }

    private void on_trainer_target_reached() {
        var toast = new Adw.Toast(_("Tempo Trainer: Target reached!"));
        toast.timeout = 3;

        var overlay = this.content as Adw.ToastOverlay;
        if (overlay != null) {
            overlay.add_toast(toast);
        }

        if (tempo_trainer.auto_stop_at_target) {
            metronome_engine.stop();
            play_button.label = _("Start");
            play_button.add_css_class("suggested-action");
            play_button.remove_css_class("destructive-action");
        }
    }

    private void on_trainer_progression_updated(int current, int target, int remaining) {
        if (!tempo_trainer.is_active) {
            trainer_status_label.visible = false;
            return;
        }

        string status = "";
        if (tempo_trainer.interval_type == IntervalType.BARS) {
            int bars_left = tempo_trainer.get_bars_until_next_increment();
            status = _("%d/%d BPM, next in %d bars").printf(current, target, bars_left);
        } else {
            int secs_left = tempo_trainer.get_seconds_until_next_increment();
            status = _("%d/%d BPM, next in %d seconds").printf(current, target, secs_left);
        }

        trainer_status_label.label = status;
        trainer_status_label.visible = true;
    }

    private void setup_tempo_trainer_ui() {
        // Load settings
        tempo_trainer.start_tempo = settings.get_int("trainer-start-tempo");
        tempo_trainer.target_tempo = settings.get_int("trainer-target-tempo");
        tempo_trainer.increment = settings.get_int("trainer-increment");
        tempo_trainer.interval_type = (IntervalType)settings.get_int("trainer-interval-type");
        tempo_trainer.interval_value = settings.get_int("trainer-interval-value");
        tempo_trainer.auto_stop_at_target = settings.get_boolean("trainer-auto-stop");

        // Bind UI to trainer properties
        trainer_start_spin.value = tempo_trainer.start_tempo;
        trainer_target_spin.value = tempo_trainer.target_tempo;
        trainer_increment_spin.value = tempo_trainer.increment;
        trainer_interval_spin.value = tempo_trainer.interval_value;
        trainer_interval_type.selected = (uint)tempo_trainer.interval_type;

        // Connect UI signals
        trainer_start_spin.value_changed.connect(() => {
            tempo_trainer.start_tempo = (int)trainer_start_spin.value;
            settings.set_int("trainer-start-tempo", tempo_trainer.start_tempo);
        });

        trainer_target_spin.value_changed.connect(() => {
            tempo_trainer.target_tempo = (int)trainer_target_spin.value;
            settings.set_int("trainer-target-tempo", tempo_trainer.target_tempo);
        });

        trainer_increment_spin.value_changed.connect(() => {
            tempo_trainer.increment = (int)trainer_increment_spin.value;
            settings.set_int("trainer-increment", tempo_trainer.increment);
        });

        trainer_interval_spin.value_changed.connect(() => {
            tempo_trainer.interval_value = (int)trainer_interval_spin.value;
            settings.set_int("trainer-interval-value", tempo_trainer.interval_value);
        });

        trainer_interval_type.notify["selected"].connect(() => {
            tempo_trainer.interval_type = (IntervalType)trainer_interval_type.selected;
            settings.set_int("trainer-interval-type", (int)tempo_trainer.interval_type);
        });
    }

    // ========== Pattern Methods ==========

    /**
     * Initialize pattern dropdown with available patterns
     */
    private void initialize_pattern_dropdown() {
        // Load patterns from library
        try {
            pattern_library.load_built_in_patterns();
            pattern_library.load_user_patterns();
        } catch (Error e) {
            warning("Failed to load patterns: %s", e.message);
        }

        // Create string list model
        pattern_model = new Gtk.StringList(null);

        // Add "None" as first option
        pattern_model.append(_("None"));

        // Add all patterns
        var patterns = pattern_library.get_all_patterns();
        foreach (var pattern in patterns) {
            pattern_model.append(pattern.name);
        }

        // Set model on dropdown
        pattern_dropdown.model = pattern_model;
        pattern_dropdown.selected = 0; // Select "None" by default
    }

    /**
     * Load active pattern from settings
     */
    private void load_active_pattern() {
        string pattern_name = settings.get_string("active-pattern");

        if (pattern_name.length == 0) {
            return; // No pattern to load
        }

        // Find pattern in dropdown
        for (uint i = 0; i < pattern_model.get_n_items(); i++) {
            var item = pattern_model.get_string(i);
            if (item == pattern_name) {
                pattern_dropdown.selected = i;
                return;
            }
        }

        // Pattern not found, clear setting
        settings.set_string("active-pattern", "");
    }

    /**
     * Handle pattern selection change
     */
    private void on_pattern_changed() {
        uint selected = pattern_dropdown.selected;

        if (selected == 0) {
            // "None" selected - deactivate pattern mode
            deactivate_pattern();
            settings.set_string("active-pattern", "");
            pattern_info_label.label = _("Select a pattern to begin");
            return;
        }

        // Get selected pattern name
        string pattern_name = pattern_model.get_string(selected);
        var pattern = pattern_library.get_pattern(pattern_name);

        if (pattern == null) {
            warning("Pattern not found: %s", pattern_name);
            return;
        }

        // Update info label with pattern description
        pattern_info_label.label = pattern.description;

        // Activate pattern
        activate_pattern(pattern);
        settings.set_string("active-pattern", pattern_name);
    }

    /**
     * Handle pattern edit button click
     */
    private void on_pattern_edit_clicked() {
        // TODO: Open pattern editor dialog
        // For now, just show a placeholder message
        var toast = new Adw.Toast(_("Pattern editor coming soon!"));
        toast.set_timeout(2);

        var overlay = this.content as Adw.ToastOverlay;
        if (overlay != null) {
            overlay.add_toast(toast);
        }
    }

    /**
     * Activate pattern mode
     */
    private void activate_pattern(Tempo.RhythmPattern pattern) {
        // Stop if running
        bool was_running = metronome_engine.is_running;
        if (was_running) {
            metronome_engine.stop();
        }

        // Switch to pattern mode
        current_mode = MetronomeMode.PATTERN;

        // Set pattern on engine
        pattern_engine.set_pattern(pattern);

        // Sync BPM from metronome to pattern engine
        pattern_engine.bpm = metronome_engine.bpm;

        // Enable edit button
        pattern_edit_button.sensitive = true;

        // Restart if was running
        if (was_running) {
            pattern_engine.start();
            play_button.label = _("Stop");
            play_button.remove_css_class("suggested-action");
            play_button.add_css_class("destructive-action");
        }

        debug("Activated pattern mode: %s", pattern.name);
    }

    /**
     * Deactivate pattern mode
     */
    private void deactivate_pattern() {
        // Stop if running
        bool was_running = pattern_engine.is_running;
        if (was_running) {
            pattern_engine.stop();
        }

        // Switch to simple beats mode
        current_mode = MetronomeMode.SIMPLE_BEATS;

        // Disable edit button
        pattern_edit_button.sensitive = false;

        // Restart if was running
        if (was_running) {
            metronome_engine.start();
            play_button.label = _("Stop");
            play_button.remove_css_class("suggested-action");
            play_button.add_css_class("destructive-action");
        }

        debug("Deactivated pattern mode");
    }

    /**
     * Handle pattern step event
     */
    private void on_pattern_step_occurred(Tempo.PatternStep step, int beat_number) {
        // Update beat indicator
        current_beat_number = beat_number;

        // Determine colors based on accent level
        switch (step.accent) {
            case Tempo.AccentLevel.STRONG:
                is_downbeat = true;
                break;
            case Tempo.AccentLevel.REGULAR:
                is_downbeat = false;
                break;
            case Tempo.AccentLevel.GHOST:
                is_downbeat = false;
                break;
        }

        is_muted = false;
        beat_active = true;

        // Start animation
        beat_start_time = GLib.get_monotonic_time();
        animation_progress = 0.0;

        // Redraw beat indicator
        request_redraw();

        // Reset beat indicator after short delay
        Timeout.add(100, () => {
            beat_active = false;
            request_redraw();
            return false;
        });
    }

    /**
     * Handle pattern loop completion
     */
    private void on_pattern_loop_completed() {
        // Could add visual feedback here if desired
        debug("Pattern loop completed");
    }
}
