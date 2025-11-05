/* PatternViewController.vala
 *
 * Copyright 2025 Tobias Guimarães
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

/**
 * Controller for the Patterns tab
 * Handles pattern selection and management
 */
public class PatternViewController : GLib.Object {

    // UI widgets
    private unowned DropDown pattern_dropdown;
    private unowned Button pattern_edit_button;
    private unowned Label pattern_info_label;
    private unowned Button play_button;

    // Pattern components
    private Tempo.PatternLibrary pattern_library;
    private Tempo.PatternEngine pattern_engine;
    private Gtk.StringList pattern_model;
    private GLib.Settings settings;

    // Current state
    public Tempo.RhythmPattern? active_pattern { get; private set; default = null; }

    // Signals
    public signal void play_requested();
    public signal void stop_requested();
    public signal void pattern_activated(Tempo.RhythmPattern pattern);
    public signal void pattern_deactivated();

    public PatternViewController(
        DropDown pattern_dropdown,
        Button pattern_edit_button,
        Label pattern_info_label,
        Button play_button,
        Tempo.PatternLibrary library,
        Tempo.PatternEngine engine,
        GLib.Settings settings
    ) {
        this.pattern_dropdown = pattern_dropdown;
        this.pattern_edit_button = pattern_edit_button;
        this.pattern_info_label = pattern_info_label;
        this.play_button = play_button;
        this.pattern_library = library;
        this.pattern_engine = engine;
        this.settings = settings;

        initialize_patterns();
        connect_signals();
    }

    private void initialize_patterns() {
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

    private void connect_signals() {
        pattern_dropdown.notify["selected"].connect(on_pattern_changed);
        pattern_edit_button.clicked.connect(on_pattern_edit_clicked);
        play_button.clicked.connect(on_play_clicked);
    }

    public void load_saved_pattern() {
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

    private void on_pattern_edit_clicked() {
        // TODO: Open pattern editor dialog
        // For now, show placeholder
        debug("Pattern editor not yet implemented");
    }

    private void on_play_clicked() {
        if (pattern_engine.is_running) {
            stop_requested();
        } else {
            play_requested();
        }
    }

    private void activate_pattern(Tempo.RhythmPattern pattern) {
        active_pattern = pattern;

        // Set pattern on engine
        pattern_engine.set_pattern(pattern);

        // Enable edit button
        pattern_edit_button.sensitive = true;

        // Notify listeners
        pattern_activated(pattern);

        debug("Activated pattern mode: %s", pattern.name);
    }

    private void deactivate_pattern() {
        active_pattern = null;

        // Disable edit button
        pattern_edit_button.sensitive = false;

        // Notify listeners
        pattern_deactivated();

        debug("Deactivated pattern mode");
    }

    public bool is_pattern_active() {
        return active_pattern != null;
    }

    public Tempo.PatternEngine get_engine() {
        return pattern_engine;
    }

    public void sync_bpm(int bpm) {
        pattern_engine.bpm = bpm;
    }
}
