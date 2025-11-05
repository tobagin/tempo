/* RhythmPattern.vala
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

namespace Tempo {

    /**
     * Accent level for pattern steps
     */
    public enum AccentLevel {
        GHOST,      // Very soft (volume 0.3)
        REGULAR,    // Normal (volume 0.7)
        STRONG;     // Accented (volume 1.0)

        public static AccentLevel from_string(string str) {
            switch (str.down()) {
                case "ghost":
                    return GHOST;
                case "regular":
                    return REGULAR;
                case "strong":
                    return STRONG;
                default:
                    return REGULAR;
            }
        }

        public string to_string() {
            switch (this) {
                case GHOST:
                    return "ghost";
                case REGULAR:
                    return "regular";
                case STRONG:
                    return "strong";
                default:
                    return "regular";
            }
        }

        public double get_volume() {
            switch (this) {
                case GHOST:
                    return 0.3;
                case REGULAR:
                    return 0.7;
                case STRONG:
                    return 1.0;
                default:
                    return 0.7;
            }
        }
    }

    /**
     * A single step in a rhythm pattern
     */
    public class PatternStep : GLib.Object {
        public int beat { get; set; }
        public int subdivision { get; set; }
        public AccentLevel accent { get; set; }
        public string sound_type { get; set; }

        public PatternStep(int beat, int subdivision, AccentLevel accent, string sound_type) {
            this.beat = beat;
            this.subdivision = subdivision;
            this.accent = accent;
            this.sound_type = sound_type;
        }

        /**
         * Create a PatternStep from a JSON object
         */
        public static PatternStep? from_json(Json.Object obj) {
            try {
                int beat = (int) obj.get_int_member("beat");
                int subdivision = obj.has_member("subdivision") ? (int) obj.get_int_member("subdivision") : 0;
                string accent_str = obj.has_member("accent") ? obj.get_string_member("accent") : "regular";
                string sound_type = obj.has_member("sound") ? obj.get_string_member("sound") : "high";

                var accent = AccentLevel.from_string(accent_str);
                return new PatternStep(beat, subdivision, accent, sound_type);
            } catch (Error e) {
                warning("Failed to parse PatternStep from JSON: %s", e.message);
                return null;
            }
        }

        /**
         * Convert this step to a JSON object
         */
        public Json.Object to_json() {
            var obj = new Json.Object();
            obj.set_int_member("beat", beat);
            obj.set_int_member("subdivision", subdivision);
            obj.set_string_member("accent", accent.to_string());
            obj.set_string_member("sound", sound_type);
            return obj;
        }

        /**
         * Calculate the absolute time position of this step in milliseconds
         * from the start of the pattern
         */
        public double calculate_time_ms(int bpm, int subdivisions_per_beat) {
            double beat_duration_ms = 60000.0 / bpm;
            double subdivision_duration_ms = beat_duration_ms / subdivisions_per_beat;
            return (beat * beat_duration_ms) + (subdivision * subdivision_duration_ms);
        }
    }

    /**
     * A rhythm pattern containing a sequence of steps
     */
    public class RhythmPattern : GLib.Object {
        public string name { get; set; }
        public string description { get; set; }
        public int length_beats { get; set; }
        public int time_signature_numerator { get; set; default = 4; }
        public int time_signature_denominator { get; set; default = 4; }

        private Gee.ArrayList<PatternStep> steps;

        public RhythmPattern(string name, string description = "") {
            this.name = name;
            this.description = description;
            this.length_beats = 4;
            this.steps = new Gee.ArrayList<PatternStep>();
        }

        /**
         * Add a step to the pattern
         */
        public void add_step(PatternStep step) {
            steps.add(step);
        }

        /**
         * Remove a step from the pattern
         */
        public void remove_step(PatternStep step) {
            steps.remove(step);
        }

        /**
         * Clear all steps from the pattern
         */
        public void clear_steps() {
            steps.clear();
        }

        /**
         * Get all steps in the pattern
         */
        public Gee.ArrayList<PatternStep> get_steps() {
            return steps;
        }

        /**
         * Get steps at a specific beat
         */
        public Gee.ArrayList<PatternStep> get_steps_at_beat(int beat) {
            var result = new Gee.ArrayList<PatternStep>();
            foreach (var step in steps) {
                if (step.beat == beat) {
                    result.add(step);
                }
            }
            return result;
        }

        /**
         * Get the total number of steps in the pattern
         */
        public int get_step_count() {
            return steps.size;
        }

        /**
         * Load a pattern from a JSON file
         */
        public static RhythmPattern? from_json_file(string path) throws Error {
            var parser = new Json.Parser();
            parser.load_from_file(path);

            var root = parser.get_root();
            if (root == null || root.get_node_type() != Json.NodeType.OBJECT) {
                throw new IOError.INVALID_DATA("Invalid JSON format");
            }

            var obj = root.get_object();
            return from_json_object(obj);
        }

        /**
         * Load a pattern from a JSON string
         */
        public static RhythmPattern? from_json_string(string json) throws Error {
            var parser = new Json.Parser();
            parser.load_from_data(json);

            var root = parser.get_root();
            if (root == null || root.get_node_type() != Json.NodeType.OBJECT) {
                throw new IOError.INVALID_DATA("Invalid JSON format");
            }

            var obj = root.get_object();
            return from_json_object(obj);
        }

        /**
         * Load a pattern from a gresource
         */
        public static RhythmPattern? from_resource(string resource_path) throws Error {
            var bytes = GLib.resources_lookup_data(resource_path, GLib.ResourceLookupFlags.NONE);
            var json_string = (string) bytes.get_data();
            return from_json_string(json_string);
        }

        /**
         * Parse a RhythmPattern from a JSON object
         */
        private static RhythmPattern? from_json_object(Json.Object obj) throws Error {
            if (!obj.has_member("name") || !obj.has_member("length_beats")) {
                throw new IOError.INVALID_DATA("Missing required fields: name or length_beats");
            }

            string name = obj.get_string_member("name");
            string description = obj.has_member("description") ? obj.get_string_member("description") : "";
            int length_beats = (int) obj.get_int_member("length_beats");

            var pattern = new RhythmPattern(name, description);
            pattern.length_beats = length_beats;

            // Parse time signature if present
            if (obj.has_member("time_signature")) {
                string time_sig = obj.get_string_member("time_signature");
                string[] parts = time_sig.split("/");
                if (parts.length == 2) {
                    pattern.time_signature_numerator = int.parse(parts[0]);
                    pattern.time_signature_denominator = int.parse(parts[1]);
                }
            }

            // Parse steps
            if (obj.has_member("steps")) {
                var steps_array = obj.get_array_member("steps");
                for (uint i = 0; i < steps_array.get_length(); i++) {
                    var step_obj = steps_array.get_object_element(i);
                    var step = PatternStep.from_json(step_obj);
                    if (step != null) {
                        pattern.add_step(step);
                    }
                }
            }

            return pattern;
        }

        /**
         * Save the pattern to a JSON file
         */
        public void to_json_file(string path) throws Error {
            var generator = new Json.Generator();
            generator.set_root(to_json_node());
            generator.set_pretty(true);
            generator.to_file(path);
        }

        /**
         * Convert the pattern to a JSON string
         */
        public string to_json_string() {
            var generator = new Json.Generator();
            generator.set_root(to_json_node());
            generator.set_pretty(true);
            size_t length;
            return generator.to_data(out length);
        }

        /**
         * Convert the pattern to a JSON node
         */
        private Json.Node to_json_node() {
            var obj = new Json.Object();
            obj.set_string_member("name", name);
            obj.set_string_member("description", description);
            obj.set_int_member("length_beats", length_beats);
            obj.set_string_member("time_signature",
                @"$(time_signature_numerator)/$(time_signature_denominator)");

            var steps_array = new Json.Array();
            foreach (var step in steps) {
                steps_array.add_object_element(step.to_json());
            }
            obj.set_array_member("steps", steps_array);

            var node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(obj);
            return node;
        }

        /**
         * Clone this pattern
         */
        public RhythmPattern clone() {
            var cloned = new RhythmPattern(name, description);
            cloned.length_beats = length_beats;
            cloned.time_signature_numerator = time_signature_numerator;
            cloned.time_signature_denominator = time_signature_denominator;

            foreach (var step in steps) {
                cloned.add_step(new PatternStep(step.beat, step.subdivision,
                                               step.accent, step.sound_type));
            }

            return cloned;
        }
    }
}
