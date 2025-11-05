namespace Tempo {
    /**
     * Factory class for creating MutePattern instances from GSettings.
     *
     * Reads mute-related settings and instantiates the appropriate pattern class.
     */
    public class MutePatternFactory : GLib.Object {
        /**
         * Create a MutePattern from GSettings configuration.
         *
         * @param settings The GSettings instance to read from
         * @return A MutePattern instance, or null if pattern type is "none"
         */
        public static Tempo.MutePattern? create_from_settings(GLib.Settings settings) {
            string pattern_type = settings.get_string("mute-pattern-type");

            switch (pattern_type) {
                case "every-nth":
                    int interval = settings.get_int("mute-interval");
                    return new EveryNthPattern() { interval = interval };

                case "random":
                    double percentage = settings.get_double("mute-percentage");
                    return new RandomPercentagePattern(percentage);

                case "specific":
                    string beats_str = settings.get_string("mute-specific-beats");
                    var beats = parse_beat_list(beats_str);
                    var pattern = new SpecificBeatsPattern();
                    pattern.muted_beats = beats;
                    return pattern;

                case "progressive":
                    double start = settings.get_double("mute-progressive-start");
                    double end = settings.get_double("mute-progressive-end");
                    int interval = settings.get_int("mute-progressive-interval");
                    return new ProgressivePattern() {
                        start_percentage = start,
                        end_percentage = end,
                        bars_interval = interval
                    };

                default:
                    return null;
            }
        }

        /**
         * Parse a comma-separated list of beat numbers.
         *
         * @param beats_str Comma-separated beat numbers (e.g., "2,4")
         * @return ArrayList of beat numbers
         */
        private static Gee.ArrayList<int> parse_beat_list(string beats_str) {
            var beats = new Gee.ArrayList<int>();

            // Split by comma and parse each number
            string[] parts = beats_str.split(",");
            foreach (string part in parts) {
                string trimmed = part.strip();
                if (trimmed.length > 0) {
                    int beat = int.parse(trimmed);
                    // Only add valid beat numbers (1-16)
                    if (beat >= 1 && beat <= 16) {
                        beats.add(beat);
                    }
                }
            }

            return beats;
        }
    }
}
