/* TempoTrainer.vala
 *
 * Copyright 2025 Tobagin
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

/**
 * Tempo Trainer - Progressive tempo changes for practice
 *
 * Automatically increases or decreases tempo over time using configurable
 * intervals (bars or seconds) to help musicians build speed gradually.
 */
public class TempoTrainer : GLib.Object {
    // Configuration properties
    public bool enabled { get; set; default = false; }
    public int start_tempo { get; set; default = 60; }
    public int target_tempo { get; set; default = 120; }
    public int increment { get; set; default = 5; }
    public IntervalType interval_type { get; set; default = IntervalType.BARS; }
    public int interval_value { get; set; default = 8; }
    public bool auto_stop_at_target { get; set; default = false; }

    // Runtime state (not persisted)
    public bool is_active { get; private set; default = false; }
    public int current_tempo { get; private set; }
    public int bars_completed { get; private set; default = 0; }
    public int64 seconds_elapsed { get; private set; default = 0; }
    public int increments_completed { get; private set; default = 0; }

    private uint time_tracker_id = 0;

    // Signals
    public signal void tempo_should_change(int new_tempo);
    public signal void target_reached();
    public signal void progression_updated(int current, int target, int remaining);

    /**
     * Start the tempo trainer progression
     */
    public void start() {
        is_active = true;
        current_tempo = start_tempo;
        bars_completed = 0;
        seconds_elapsed = 0;
        increments_completed = 0;

        // Start time-based tracking if needed
        if (interval_type == IntervalType.SECONDS && time_tracker_id == 0) {
            time_tracker_id = GLib.Timeout.add_seconds(1, () => {
                if (is_active) {
                    on_second_elapsed();
                }
                return is_active;
            });
        }

        progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
    }

    /**
     * Pause the tempo trainer (preserves state)
     */
    public void pause() {
        is_active = false;

        // Stop time tracker
        if (time_tracker_id != 0) {
            Source.remove(time_tracker_id);
            time_tracker_id = 0;
        }
    }

    /**
     * Resume the tempo trainer from paused state
     */
    public void resume() {
        is_active = true;

        // Restart time tracker if needed
        if (interval_type == IntervalType.SECONDS && time_tracker_id == 0) {
            time_tracker_id = GLib.Timeout.add_seconds(1, () => {
                if (is_active) {
                    on_second_elapsed();
                }
                return is_active;
            });
        }

        progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
    }

    /**
     * Reset the tempo trainer to initial state
     */
    public void reset() {
        is_active = false;
        current_tempo = start_tempo;
        bars_completed = 0;
        seconds_elapsed = 0;
        increments_completed = 0;

        if (time_tracker_id != 0) {
            Source.remove(time_tracker_id);
            time_tracker_id = 0;
        }

        progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
    }

    /**
     * Called when a beat occurs in the metronome
     */
    public void on_beat_occurred(int beat_num, int beats_per_bar) {
        if (!is_active) return;
        if (interval_type != IntervalType.BARS) return;

        // Check if this is a downbeat (start of new bar)
        bool is_downbeat = (beat_num % beats_per_bar) == 1;
        if (!is_downbeat) return;

        bars_completed++;

        // Check if interval reached
        if (bars_completed >= interval_value) {
            if (!is_target_reached()) {
                int next_tempo = calculate_next_tempo();
                tempo_should_change(next_tempo);
                current_tempo = next_tempo;
                increments_completed++;
                bars_completed = 0;  // Reset counter
            }

            if (is_target_reached()) {
                target_reached();
                if (auto_stop_at_target) {
                    pause();
                }
            }
        }

        // Emit progress update
        progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
    }

    /**
     * Called every second for time-based progression
     */
    private void on_second_elapsed() {
        if (!is_active) return;

        seconds_elapsed++;

        // Check if interval reached
        if (seconds_elapsed >= interval_value) {
            if (!is_target_reached()) {
                int next_tempo = calculate_next_tempo();
                tempo_should_change(next_tempo);
                current_tempo = next_tempo;
                increments_completed++;
                seconds_elapsed = 0;  // Reset counter
            }

            if (is_target_reached()) {
                target_reached();
                if (auto_stop_at_target) {
                    pause();
                }
            }
        }

        // Emit progress update
        progression_updated(current_tempo, target_tempo, calculate_remaining_increments());
    }

    /**
     * Calculate the next tempo value
     */
    private int calculate_next_tempo() {
        int next_tempo = current_tempo + increment;

        // Clamp to target (don't overshoot)
        if (increment > 0) {
            // Ascending: don't exceed target
            next_tempo = int.min(next_tempo, target_tempo);
        } else {
            // Descending: don't go below target
            next_tempo = int.max(next_tempo, target_tempo);
        }

        // Ensure within valid BPM range
        next_tempo = int.max(40, int.min(240, next_tempo));

        return next_tempo;
    }

    /**
     * Check if target tempo has been reached
     */
    private bool is_target_reached() {
        if (increment > 0) {
            return current_tempo >= target_tempo;
        } else {
            return current_tempo <= target_tempo;
        }
    }

    /**
     * Calculate remaining increments to target
     */
    private int calculate_remaining_increments() {
        if (is_target_reached()) return 0;

        int remaining_bpm = (target_tempo - current_tempo).abs();
        int steps = (remaining_bpm + increment.abs() - 1) / increment.abs();
        return steps;
    }

    /**
     * Get progress bars remaining (for bar-based intervals)
     */
    public int get_bars_until_next_increment() {
        if (interval_type != IntervalType.BARS) return 0;
        return interval_value - bars_completed;
    }

    /**
     * Get seconds remaining until next increment (for time-based intervals)
     */
    public int get_seconds_until_next_increment() {
        if (interval_type != IntervalType.SECONDS) return 0;
        return (int)(interval_value - seconds_elapsed);
    }
}

/**
 * Interval types for tempo progression
 */
public enum IntervalType {
    BARS,     // Progress after N bars
    SECONDS   // Progress after N seconds
}
