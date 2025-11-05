/* PatternEngine.vala
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

using GLib;
using Gst;

namespace Tempo {

    /**
     * Pattern playback engine with high-precision timing.
     *
     * Plays rhythm patterns with sub-millisecond accuracy using absolute time
     * references to prevent drift. Supports multiple accent levels and sound types.
     */
    public class PatternEngine : GLib.Object {

        // Properties
        public RhythmPattern? active_pattern { get; set; default = null; }
        public bool is_running { get; private set; default = false; }
        public int current_beat { get; private set; default = 0; }
        public int bpm { get; set; default = 120; }
        public int subdivisions_per_beat { get; set; default = 4; }

        // Signals
        public signal void step_occurred(PatternStep step, int beat_number);
        public signal void pattern_loop_completed();
        public signal void audio_system_failed(string error_message);

        // Private timing state
        private uint timeout_id = 0;
        private int64 next_step_time = 0;
        private int pattern_position = 0; // Current step index within the pattern
        private double beat_duration = 0.5; // Seconds per beat

        // Audio players for different accent levels
        private Gst.Element? strong_player = null;
        private Gst.Element? regular_player = null;
        private Gst.Element? ghost_player = null;
        private bool audio_initialized = false;

        // Settings reference
        private GLib.Settings? settings = null;

        // Sorted list of steps for playback
        private Gee.ArrayList<PatternStep>? sorted_steps = null;

        /**
         * Creates a new PatternEngine with default settings.
         */
        public PatternEngine() {
            // Connect property change notifications
            this.notify["bpm"].connect(() => {
                this.beat_duration = calculate_beat_duration();
                // If running, adjust timing for new BPM
                if (is_running) {
                    adjust_timing_for_bpm_change();
                }
            });

            this.notify["active_pattern"].connect(() => {
                if (active_pattern != null) {
                    prepare_pattern_for_playback();
                }
            });

            // Initialize beat duration
            this.beat_duration = calculate_beat_duration();

            // Initialize audio
            initialize_audio();
        }

        /**
         * Start pattern playback.
         */
        public void start() {
            if (is_running) {
                return; // Already running
            }

            if (active_pattern == null) {
                warning("Cannot start pattern engine: no active pattern");
                return;
            }

            if (!audio_initialized) {
                warning("Cannot start pattern engine: audio not initialized");
                return;
            }

            is_running = true;
            current_beat = 0;
            pattern_position = 0;

            // Initialize timing
            beat_duration = calculate_beat_duration();
            next_step_time = GLib.get_monotonic_time();

            // Start the timing loop
            schedule_next_step();
        }

        /**
         * Stop pattern playback.
         */
        public void stop() {
            if (!is_running) {
                return;
            }

            is_running = false;

            // Cancel pending timeout
            if (timeout_id != 0) {
                Source.remove(timeout_id);
                timeout_id = 0;
            }

            // Reset state
            current_beat = 0;
            pattern_position = 0;
        }

        /**
         * Set the active pattern and prepare for playback.
         */
        public void set_pattern(RhythmPattern? pattern) {
            bool was_running = is_running;

            if (was_running) {
                stop();
            }

            active_pattern = pattern;

            if (pattern != null) {
                prepare_pattern_for_playback();
                load_sounds_for_pattern(pattern);
            }

            if (was_running && pattern != null) {
                start();
            }
        }

        /**
         * Prepare pattern for playback by sorting steps by time.
         */
        private void prepare_pattern_for_playback() {
            if (active_pattern == null) {
                sorted_steps = null;
                return;
            }

            // Get all steps and sort by beat then subdivision
            sorted_steps = new Gee.ArrayList<PatternStep>();
            sorted_steps.add_all(active_pattern.get_steps());

            sorted_steps.sort((a, b) => {
                if (a.beat != b.beat) {
                    return a.beat - b.beat;
                }
                return a.subdivision - b.subdivision;
            });

            debug("Pattern prepared: %s with %d steps",
                  active_pattern.name, sorted_steps.size);
        }

        /**
         * Schedule the next pattern step.
         */
        private void schedule_next_step() {
            if (!is_running || sorted_steps == null || sorted_steps.size == 0) {
                return;
            }

            int64 current_time = GLib.get_monotonic_time();
            int64 wait_time_us = next_step_time - current_time;

            // Check if we're too far behind (e.g., after system sleep)
            if (wait_time_us < -((int64)(beat_duration * 1000000))) {
                // Reset timing to current time
                next_step_time = current_time + (int64)(beat_duration * 1000000 / subdivisions_per_beat);
                wait_time_us = (int64)(beat_duration * 1000000 / subdivisions_per_beat);
            }

            // Convert microseconds to milliseconds for GLib.Timeout
            uint wait_time_ms = (uint)int64.max(1, wait_time_us / 1000);

            timeout_id = Timeout.add(wait_time_ms, () => {
                return on_step_timeout();
            });
        }

        /**
         * Handle step timeout - play step sound and schedule next step.
         *
         * @return false to remove the timeout source
         */
        private bool on_step_timeout() {
            if (!is_running || sorted_steps == null || active_pattern == null) {
                timeout_id = 0;
                return false;
            }

            // Get current step
            var step = sorted_steps.get(pattern_position);

            // Play sound for this step
            play_step_sound(step);

            // Update current beat based on step
            int step_beat = step.beat;
            if (step.subdivision == 0) {
                current_beat = step_beat + 1; // 1-based beat number
            }

            // Emit signal
            step_occurred(step, current_beat);

            // Advance to next step
            pattern_position++;

            // Check if we've completed the pattern
            if (pattern_position >= sorted_steps.size) {
                pattern_position = 0;
                pattern_loop_completed();
            }

            // Calculate next step time
            var next_step = sorted_steps.get(pattern_position);
            double next_step_time_offset = next_step.calculate_time_ms(bpm, subdivisions_per_beat);

            // If we wrapped around, add pattern length
            if (pattern_position == 0) {
                double pattern_length_ms = active_pattern.length_beats * (60000.0 / bpm);
                next_step_time += (int64)(pattern_length_ms * 1000);
            } else {
                // Calculate time from current step to next step
                double current_step_time = step.calculate_time_ms(bpm, subdivisions_per_beat);
                double time_diff_ms = next_step_time_offset - current_step_time;
                next_step_time += (int64)(time_diff_ms * 1000);
            }

            // Schedule next step
            schedule_next_step();

            // Remove this timeout (we created a new one)
            timeout_id = 0;
            return false;
        }

        /**
         * Play sound for a pattern step with appropriate accent level.
         */
        private void play_step_sound(PatternStep step) {
            if (!audio_initialized) {
                return;
            }

            Gst.Element? player = null;

            // Select player based on accent level
            switch (step.accent) {
                case AccentLevel.STRONG:
                    player = strong_player;
                    break;
                case AccentLevel.REGULAR:
                    player = regular_player;
                    break;
                case AccentLevel.GHOST:
                    player = ghost_player;
                    break;
            }

            if (player == null) {
                return;
            }

            // Reset player and play
            player.set_state(Gst.State.NULL);
            player.set_state(Gst.State.PLAYING);
        }

        /**
         * Calculate beat duration in seconds based on BPM.
         */
        private double calculate_beat_duration() {
            return 60.0 / (double)bpm;
        }

        /**
         * Adjust timing when BPM changes during playback.
         */
        private void adjust_timing_for_bpm_change() {
            if (!is_running || active_pattern == null || sorted_steps == null) {
                return;
            }

            // Recalculate next step time based on new BPM
            // Keep the same position in the pattern, just adjust timing
            int64 current_time = GLib.get_monotonic_time();

            // Get current step
            var current_step = sorted_steps.get(pattern_position);

            // Calculate time to next step with new BPM
            var next_step = sorted_steps.get((pattern_position + 1) % sorted_steps.size);
            double current_step_time = current_step.calculate_time_ms(bpm, subdivisions_per_beat);
            double next_step_time_offset = next_step.calculate_time_ms(bpm, subdivisions_per_beat);

            double time_diff_ms;
            if (pattern_position + 1 >= sorted_steps.size) {
                // Wrapping around to start
                double pattern_length_ms = active_pattern.length_beats * (60000.0 / bpm);
                time_diff_ms = pattern_length_ms - current_step_time + next_step_time_offset;
            } else {
                time_diff_ms = next_step_time_offset - current_step_time;
            }

            next_step_time = current_time + (int64)(time_diff_ms * 1000);

            debug("Adjusted timing for BPM change to %d", bpm);
        }

        /**
         * Initialize audio system.
         */
        private void initialize_audio() {
            try {
                settings = new GLib.Settings(Config.APP_ID);

                // Create audio players for different accent levels
                bool success = create_audio_players();
                if (success) {
                    audio_initialized = true;
                } else {
                    audio_system_failed("Failed to create audio players for pattern engine.");
                }
            } catch (Error e) {
                warning("Failed to initialize pattern engine audio: %s", e.message);
                audio_system_failed("Pattern engine audio initialization failed: %s".printf(e.message));
            }
        }

        /**
         * Create GStreamer playback elements for accent levels.
         *
         * @return true if successful, false otherwise
         */
        private bool create_audio_players() {
            try {
                // Create players for each accent level
                strong_player = Gst.ElementFactory.make("playbin", "pattern_strong_player");
                regular_player = Gst.ElementFactory.make("playbin", "pattern_regular_player");
                ghost_player = Gst.ElementFactory.make("playbin", "pattern_ghost_player");

                if (strong_player == null || regular_player == null || ghost_player == null) {
                    warning("Failed to create GStreamer playbin elements for pattern engine");
                    return false;
                }

                // Set default sound URIs
                string app_data_dir = "/app/share/tempo/sounds";
                var high_file = GLib.File.new_for_path(app_data_dir + "/high.wav");
                var low_file = GLib.File.new_for_path(app_data_dir + "/low.wav");

                strong_player.set("uri", high_file.get_uri());
                regular_player.set("uri", high_file.get_uri());
                ghost_player.set("uri", low_file.get_uri());

                // Set volumes for different accent levels
                strong_player.set("volume", 1.0);
                regular_player.set("volume", 0.7);
                ghost_player.set("volume", 0.3);

                return true;

            } catch (Error e) {
                warning("Error creating pattern audio players: %s", e.message);
                return false;
            }
        }

        /**
         * Load sounds for a pattern based on sound types.
         */
        private void load_sounds_for_pattern(RhythmPattern pattern) {
            if (!audio_initialized || settings == null) {
                return;
            }

            // Build URIs for high and low sounds
            string app_data_dir = "/app/share/tempo/sounds";
            string high_file_name = "high.wav";
            string low_file_name = "low.wav";

            // Check if custom sounds are enabled
            bool use_custom = settings.get_boolean("use-custom-sounds");

            if (use_custom) {
                // Use custom sounds from settings
                string custom_high = settings.get_string("high-sound-path");
                string custom_low = settings.get_string("low-sound-path");

                if (custom_high.length > 0 && custom_low.length > 0) {
                    var high_file = GLib.File.new_for_path(custom_high);
                    var low_file = GLib.File.new_for_path(custom_low);
                    string high_uri = high_file.get_uri();
                    string low_uri = low_file.get_uri();

                    // Analyze pattern and set URIs
                    set_player_uris_from_pattern(pattern, high_uri, low_uri);
                    return;
                }
            }

            // Use built-in sounds based on high-sound-type setting
            string sound_type = settings.get_string("high-sound-type");

            switch (sound_type) {
                case "woodblock":
                    high_file_name = "woodblock-high.wav";
                    low_file_name = "woodblock-low.wav";
                    break;
                case "metal":
                    high_file_name = "metal-high.wav";
                    low_file_name = "metal-low.wav";
                    break;
                case "digital":
                    high_file_name = "digital-high.wav";
                    low_file_name = "digital-low.wav";
                    break;
                default:
                    high_file_name = "high.wav";
                    low_file_name = "low.wav";
                    break;
            }

            var high_file = GLib.File.new_for_path(app_data_dir + "/" + high_file_name);
            var low_file = GLib.File.new_for_path(app_data_dir + "/" + low_file_name);
            string high_uri = high_file.get_uri();
            string low_uri = low_file.get_uri();

            // Analyze pattern and set URIs
            set_player_uris_from_pattern(pattern, high_uri, low_uri);
        }

        /**
         * Set player URIs based on pattern sound requirements.
         */
        private void set_player_uris_from_pattern(RhythmPattern pattern, string high_uri, string low_uri) {

            // Analyze pattern to determine which sounds are needed
            bool needs_high = false;
            bool needs_low = false;

            foreach (var step in pattern.get_steps()) {
                if (step.sound_type == "high") {
                    needs_high = true;
                } else if (step.sound_type == "low") {
                    needs_low = true;
                }
            }

            // Set URIs on players based on what's needed
            // Strong accent typically uses high sound
            if (needs_high && strong_player != null) {
                strong_player.set("uri", high_uri);
            }

            // Regular and ghost can use either
            if (regular_player != null) {
                regular_player.set("uri", needs_high ? high_uri : low_uri);
            }

            if (ghost_player != null) {
                ghost_player.set("uri", needs_low ? low_uri : high_uri);
            }

            debug("Loaded sounds for pattern: %s", pattern.name);
        }

        /**
         * Check if audio system is available.
         *
         * @return true if audio is initialized and working
         */
        public bool is_audio_available() {
            return audio_initialized;
        }

        /**
         * Get current pattern information.
         */
        public HashTable<string, Variant> get_pattern_info() {
            var info = new HashTable<string, Variant>(str_hash, str_equal);

            if (active_pattern != null) {
                info["pattern_name"] = new Variant.string(active_pattern.name);
                info["pattern_length"] = new Variant.int32(active_pattern.length_beats);
                info["current_beat"] = new Variant.int32(current_beat);
                info["beat_in_pattern"] = new Variant.string("%d/%d".printf(
                    current_beat, active_pattern.length_beats));
            } else {
                info["pattern_name"] = new Variant.string("");
                info["pattern_length"] = new Variant.int32(0);
                info["current_beat"] = new Variant.int32(0);
                info["beat_in_pattern"] = new Variant.string("0/0");
            }

            info["is_running"] = new Variant.boolean(is_running);
            info["bpm"] = new Variant.int32(bpm);

            return info;
        }
    }
}
