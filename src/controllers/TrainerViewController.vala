/* TrainerViewController.vala
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
 * Controller for the Trainer tab
 * Handles tempo trainer controls and progression
 */
public class TrainerViewController : GLib.Object {

    // UI widgets
    private unowned SpinButton trainer_start_spin;
    private unowned SpinButton trainer_target_spin;
    private unowned SpinButton trainer_increment_spin;
    private unowned SpinButton trainer_interval_spin;
    private unowned DropDown trainer_interval_type;
    private unowned Label trainer_status_label;
    private unowned Button play_button;

    // Trainer engine
    private TempoTrainer tempo_trainer;
    private GLib.Settings settings;

    // Signals
    public signal void play_requested();
    public signal void stop_requested();
    public signal void tempo_change_requested(int new_tempo);

    public TrainerViewController(
        SpinButton trainer_start_spin,
        SpinButton trainer_target_spin,
        SpinButton trainer_increment_spin,
        SpinButton trainer_interval_spin,
        DropDown trainer_interval_type,
        Label trainer_status_label,
        Button play_button,
        TempoTrainer trainer,
        GLib.Settings settings
    ) {
        this.trainer_start_spin = trainer_start_spin;
        this.trainer_target_spin = trainer_target_spin;
        this.trainer_increment_spin = trainer_increment_spin;
        this.trainer_interval_spin = trainer_interval_spin;
        this.trainer_interval_type = trainer_interval_type;
        this.trainer_status_label = trainer_status_label;
        this.play_button = play_button;
        this.tempo_trainer = trainer;
        this.settings = settings;

        load_settings();
        connect_signals();
    }

    private void load_settings() {
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
    }

    private void connect_signals() {
        // UI control signals
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

        // Play button
        play_button.clicked.connect(on_play_clicked);

        // Trainer engine signals
        tempo_trainer.tempo_should_change.connect(on_tempo_change);
        tempo_trainer.target_reached.connect(on_target_reached);
        tempo_trainer.progression_updated.connect(on_progression_updated);
    }

    private void on_play_clicked() {
        if (tempo_trainer.is_active) {
            stop_requested();
        } else {
            play_requested();
        }
    }

    public void on_beat_occurred(int beat_num, int beats_per_bar) {
        if (tempo_trainer.is_active) {
            tempo_trainer.on_beat_occurred(beat_num, beats_per_bar);
        }
    }

    private void on_tempo_change(int new_tempo) {
        tempo_change_requested(new_tempo);
    }

    private void on_target_reached() {
        trainer_status_label.label = _("Target reached!");
        trainer_status_label.visible = true;

        if (tempo_trainer.auto_stop_at_target) {
            stop_requested();
        }
    }

    private void on_progression_updated(int current, int target, int remaining) {
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

    public void start() {
        tempo_trainer.start();
    }

    public void pause() {
        tempo_trainer.pause();
    }

    public TempoTrainer get_trainer() {
        return tempo_trainer;
    }
}
