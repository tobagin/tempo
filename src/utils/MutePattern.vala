namespace Tempo {
    /**
     * Interface for mute patterns that determine which beats to silence.
     *
     * Mute patterns are used to selectively suppress audio playback while
     * maintaining visual feedback, helping musicians develop internal timing.
     */
    public interface MutePattern : GLib.Object {
        /**
         * Determine if a beat should be muted (silent).
         *
         * @param beat_number Current beat number (1-indexed)
         * @param beats_per_bar Beats per measure
         * @return true if beat should be muted (silent)
         */
        public abstract bool should_mute_beat(int beat_number, int beats_per_bar);

        /**
         * Reset pattern state (for patterns with internal state like progressive).
         */
        public abstract void reset();

        /**
         * Get human-readable description of pattern.
         *
         * @return Description string
         */
        public abstract string get_description();
    }

    /**
     * Mute every Nth beat.
     *
     * Examples:
     * - interval=2: Mutes beats 2, 4, 6, 8... (every other beat)
     * - interval=3: Mutes beats 3, 6, 9, 12... (every third beat)
     */
    public class EveryNthPattern : GLib.Object, MutePattern {
        public int interval { get; set; default = 2; }

        public bool should_mute_beat(int beat_number, int beats_per_bar) {
            return (beat_number % interval) == 0;
        }

        public void reset() {
            // No state to reset
        }

        public string get_description() {
            return "Every %d beats muted".printf(interval);
        }
    }

    /**
     * Mute a random percentage of beats.
     *
     * Uses pseudo-random number generation with optional seed for reproducibility.
     * The percentage determines the probability that any given beat will be muted.
     */
    public class RandomPercentagePattern : GLib.Object, MutePattern {
        public double percentage { get; set; default = 0.5; }
        private GLib.Rand random;
        private uint32 seed;

        public RandomPercentagePattern(double percentage = 0.5, uint32? seed = null) {
            this.percentage = percentage;
            this.seed = seed ?? (uint32)GLib.get_real_time();
            this.random = new GLib.Rand.with_seed(this.seed);
        }

        public bool should_mute_beat(int beat_number, int beats_per_bar) {
            return random.next_double() < percentage;
        }

        public void reset() {
            // Reset to initial seed for reproducibility
            random.set_seed(seed);
        }

        public string get_description() {
            return "%.0f%% random muting".printf(percentage * 100);
        }
    }

    /**
     * Mute specific beats within each bar.
     *
     * Example: muted_beats=[2,4] in 4/4 time mutes beats 2 and 4 of each measure.
     */
    public class SpecificBeatsPattern : GLib.Object, MutePattern {
        public Gee.ArrayList<int> muted_beats { get; set; }

        public SpecificBeatsPattern() {
            muted_beats = new Gee.ArrayList<int>();
        }

        public bool should_mute_beat(int beat_number, int beats_per_bar) {
            // Convert absolute beat number to beat within bar (1-indexed)
            int beat_in_bar = ((beat_number - 1) % beats_per_bar) + 1;
            return beat_in_bar in muted_beats;
        }

        public void reset() {
            // No state to reset
        }

        public string get_description() {
            if (muted_beats.size == 0) {
                return "No beats muted";
            }

            var beat_strings = new string[muted_beats.size];
            for (int i = 0; i < muted_beats.size; i++) {
                beat_strings[i] = muted_beats[i].to_string();
            }

            return "Beats %s muted".printf(string.joinv(", ", beat_strings));
        }
    }

    /**
     * Progressively increase mute percentage over time.
     *
     * Starts at start_percentage and gradually increases to end_percentage,
     * incrementing every bars_interval bars. Useful for building confidence gradually.
     */
    public class ProgressivePattern : GLib.Object, MutePattern {
        public double start_percentage { get; set; default = 0.0; }
        public double end_percentage { get; set; default = 0.75; }
        public int bars_interval { get; set; default = 16; }

        private int bars_elapsed = 0;
        private double current_percentage = 0.0;
        private GLib.Rand random;

        public ProgressivePattern() {
            reset();
        }

        public bool should_mute_beat(int beat_number, int beats_per_bar) {
            // Update percentage when starting a new bar (beat 1)
            int beat_in_bar = ((beat_number - 1) % beats_per_bar) + 1;
            if (beat_in_bar == 1 && beat_number > 1) {
                bars_elapsed++;

                // Increase percentage at specified intervals
                if (bars_elapsed > 0 && bars_elapsed % bars_interval == 0) {
                    // Calculate how many increments we should have
                    int increments = bars_elapsed / bars_interval;

                    // Linear interpolation between start and end
                    current_percentage = start_percentage +
                        (end_percentage - start_percentage) *
                        double.min((double)increments * bars_interval / 100.0, 1.0);

                    // Ensure we don't exceed end percentage
                    current_percentage = double.min(current_percentage, end_percentage);
                }
            }

            // Use random muting at current percentage
            return random.next_double() < current_percentage;
        }

        public void reset() {
            bars_elapsed = 0;
            current_percentage = start_percentage;
            random = new GLib.Rand();
        }

        public string get_description() {
            return "Progressive: %.0f%% → %.0f%%".printf(
                start_percentage * 100,
                end_percentage * 100
            );
        }
    }
}
