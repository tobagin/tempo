/* MetronomeViewController.vala
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
 * Controller for the Metronome tab
 * Handles tempo, time signature, and subdivision controls
 */
public class MetronomeViewController : GLib.Object {

    // UI widgets
    private unowned Label tempo_label;
    private unowned SpinButton tempo_spin;
    private unowned Scale tempo_scale;
    private unowned SpinButton beats_spin;
    private unowned DropDown beat_value_dropdown;
    private unowned DropDown subdivision_dropdown;
    private unowned Button play_button;
    private unowned Button tap_button;

    // Engine reference
    private MetronomeEngine metronome_engine;
    private TapTempo tap_tempo;
    private GLib.Settings settings;

    // Signals
    public signal void play_requested();
    public signal void stop_requested();

    public MetronomeViewController(
        Label tempo_label,
        SpinButton tempo_spin,
        Scale tempo_scale,
        SpinButton beats_spin,
        DropDown beat_value_dropdown,
        DropDown subdivision_dropdown,
        Button play_button,
        Button tap_button,
        MetronomeEngine engine,
        TapTempo tap_tempo,
        GLib.Settings settings
    ) {
        this.tempo_label = tempo_label;
        this.tempo_spin = tempo_spin;
        this.tempo_scale = tempo_scale;
        this.beats_spin = beats_spin;
        this.beat_value_dropdown = beat_value_dropdown;
        this.subdivision_dropdown = subdivision_dropdown;
        this.play_button = play_button;
        this.tap_button = tap_button;
        this.metronome_engine = engine;
        this.tap_tempo = tap_tempo;
        this.settings = settings;

        connect_signals();
        update_display();
    }

    private void connect_signals() {
        // Tempo controls
        tempo_spin.value_changed.connect(on_tempo_changed);
        tempo_scale.value_changed.connect(on_tempo_scale_changed);

        // Time signature controls
        beats_spin.value_changed.connect(on_beats_changed);
        beat_value_dropdown.notify["selected"].connect(on_beat_value_changed);

        // Subdivision controls
        subdivision_dropdown.notify["selected"].connect(on_subdivision_changed);

        // Buttons
        play_button.clicked.connect(on_play_clicked);
        tap_button.clicked.connect(on_tap_clicked);
    }

    public void update_display() {
        update_tempo_display();
        update_time_signature_display();
        update_subdivision_display();
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

    private void on_tempo_changed() {
        var new_bpm = (int)tempo_spin.value;
        try {
            metronome_engine.set_tempo(new_bpm);
            update_tempo_display();
        } catch (MetronomeError e) {
            warning("Failed to set tempo: %s", e.message);
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
            update_time_signature_display();
        }
    }

    private int get_beat_value_from_dropdown() {
        uint selected = beat_value_dropdown.selected;
        switch (selected) {
            case 0: return 2;
            case 1: return 4;
            case 2: return 8;
            case 3: return 16;
            default: return 4;
        }
    }

    private void on_subdivision_changed() {
        uint selected = subdivision_dropdown.selected;

        // Map dropdown index to subdivision mode
        int mode_value = 0;
        switch (selected) {
            case 0: mode_value = 0; break;  // NONE
            case 1: mode_value = 2; break;  // EIGHTH
            case 2: mode_value = 3; break;  // TRIPLET
            case 3: mode_value = 4; break;  // SIXTEENTH
        }

        // Map dropdown index to subdivision mode enum
        SubdivisionMode mode;
        switch (selected) {
            case 0: mode = SubdivisionMode.NONE; break;
            case 1: mode = SubdivisionMode.EIGHTH; break;
            case 2: mode = SubdivisionMode.TRIPLET; break;
            case 3: mode = SubdivisionMode.SIXTEENTH; break;
            default: mode = SubdivisionMode.NONE; break;
        }

        metronome_engine.subdivision_mode = mode;
        settings.set_int("subdivision-mode", mode_value);
    }

    private void on_play_clicked() {
        if (metronome_engine.is_running) {
            stop_requested();
        } else {
            play_requested();
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

    public int get_current_bpm() {
        return metronome_engine.bpm;
    }
}
