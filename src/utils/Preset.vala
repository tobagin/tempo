/* Preset.vala
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
     * Represents a saved metronome configuration preset.
     *
     * A preset captures the complete state of the metronome including tempo,
     * time signature, subdivisions, trainer config, and audio/visual settings.
     */
public class Preset : GLib.Object {
        // Metadata
        public string id { get; set; }
        public string name { get; set; }
        public string description { get; set; }
        public int64 created_at { get; set; }
        public int64 last_used_at { get; set; }
        public int schema_version { get; set; }

        // Core metronome settings
        public int tempo { get; set; }
        public int time_sig_numerator { get; set; }
        public int time_sig_denominator { get; set; }

        // Subdivision settings (optional, null if not configured)
        public int? subdivision_mode { get; set; }
        public double? subdivision_volume { get; set; }
        public string? subdivision_sound_type { get; set; }

        // Tempo trainer settings (optional, null if not configured)
        public int? trainer_start_tempo { get; set; }
        public int? trainer_target_tempo { get; set; }
        public int? trainer_increment { get; set; }
        public int? trainer_interval_type { get; set; }
        public int? trainer_interval_value { get; set; }
        public bool? trainer_auto_stop { get; set; }

        // Audio settings
        public double click_volume { get; set; }
        public double accent_volume { get; set; }
        public string high_sound_type { get; set; }
        public string low_sound_type { get; set; }

        // Visual settings
        public bool show_beat_numbers { get; set; }
        public bool flash_on_beat { get; set; }
        public bool downbeat_color { get; set; }

        /**
         * Constructor with default values.
         */
        public Preset() {
            this.id = Uuid.string_random();
            this.name = "";
            this.description = "";
            this.created_at = GLib.get_real_time() / 1000000;
            this.last_used_at = this.created_at;
            this.schema_version = 1;

            // Core defaults
            this.tempo = 120;
            this.time_sig_numerator = 4;
            this.time_sig_denominator = 4;

            // Optional features default to null
            this.subdivision_mode = null;
            this.subdivision_volume = null;
            this.subdivision_sound_type = null;

            this.trainer_start_tempo = null;
            this.trainer_target_tempo = null;
            this.trainer_increment = null;
            this.trainer_interval_type = null;
            this.trainer_interval_value = null;
            this.trainer_auto_stop = null;

            // Audio defaults
            this.click_volume = 0.8;
            this.accent_volume = 1.0;
            this.high_sound_type = "woodblock";
            this.low_sound_type = "woodblock";

            // Visual defaults
            this.show_beat_numbers = true;
            this.flash_on_beat = true;
            this.downbeat_color = true;
        }

        /**
         * Serialize this preset to JSON format.
         *
         * Returns: A Json.Node containing the serialized preset
         */
        public Json.Node to_json() {
            var builder = new Json.Builder();
            builder.begin_object();

            // Metadata
            builder.set_member_name("id");
            builder.add_string_value(this.id);

            builder.set_member_name("name");
            builder.add_string_value(this.name);

            builder.set_member_name("description");
            builder.add_string_value(this.description);

            builder.set_member_name("created_at");
            builder.add_int_value(this.created_at);

            builder.set_member_name("last_used_at");
            builder.add_int_value(this.last_used_at);

            builder.set_member_name("schema_version");
            builder.add_int_value(this.schema_version);

            // Core settings
            builder.set_member_name("tempo");
            builder.add_int_value(this.tempo);

            builder.set_member_name("time_sig_numerator");
            builder.add_int_value(this.time_sig_numerator);

            builder.set_member_name("time_sig_denominator");
            builder.add_int_value(this.time_sig_denominator);

            // Subdivision settings (only add if not null)
            if (this.subdivision_mode != null) {
                builder.set_member_name("subdivision_mode");
                builder.add_int_value(this.subdivision_mode);
            }

            if (this.subdivision_volume != null) {
                builder.set_member_name("subdivision_volume");
                builder.add_double_value(this.subdivision_volume);
            }

            if (this.subdivision_sound_type != null) {
                builder.set_member_name("subdivision_sound_type");
                builder.add_string_value(this.subdivision_sound_type);
            }

            // Tempo trainer settings (only add if not null)
            if (this.trainer_start_tempo != null) {
                builder.set_member_name("trainer_start_tempo");
                builder.add_int_value(this.trainer_start_tempo);
            }

            if (this.trainer_target_tempo != null) {
                builder.set_member_name("trainer_target_tempo");
                builder.add_int_value(this.trainer_target_tempo);
            }

            if (this.trainer_increment != null) {
                builder.set_member_name("trainer_increment");
                builder.add_int_value(this.trainer_increment);
            }

            if (this.trainer_interval_type != null) {
                builder.set_member_name("trainer_interval_type");
                builder.add_int_value(this.trainer_interval_type);
            }

            if (this.trainer_interval_value != null) {
                builder.set_member_name("trainer_interval_value");
                builder.add_int_value(this.trainer_interval_value);
            }

            if (this.trainer_auto_stop != null) {
                builder.set_member_name("trainer_auto_stop");
                builder.add_boolean_value(this.trainer_auto_stop);
            }

            // Audio settings
            builder.set_member_name("click_volume");
            builder.add_double_value(this.click_volume);

            builder.set_member_name("accent_volume");
            builder.add_double_value(this.accent_volume);

            builder.set_member_name("high_sound_type");
            builder.add_string_value(this.high_sound_type);

            builder.set_member_name("low_sound_type");
            builder.add_string_value(this.low_sound_type);

            // Visual settings
            builder.set_member_name("show_beat_numbers");
            builder.add_boolean_value(this.show_beat_numbers);

            builder.set_member_name("flash_on_beat");
            builder.add_boolean_value(this.flash_on_beat);

            builder.set_member_name("downbeat_color");
            builder.add_boolean_value(this.downbeat_color);

            builder.end_object();

            return builder.get_root();
        }

        /**
         * Deserialize a preset from JSON format.
         *
         * Args:
         *     node: The JSON node to deserialize
         *
         * Returns: A Preset object
         *
         * Throws: PresetError.PARSE_ERROR if JSON is invalid
         */
        public static Preset from_json(Json.Node node) throws PresetError {
            if (node.get_node_type() != Json.NodeType.OBJECT) {
                throw new PresetError.PARSE_ERROR("Expected JSON object");
            }

            var obj = node.get_object();
            var preset = new Preset();

            // Parse metadata (required fields)
            if (!obj.has_member("id")) {
                throw new PresetError.PARSE_ERROR("Missing required field: id");
            }
            preset.id = obj.get_string_member("id");

            if (!obj.has_member("name")) {
                throw new PresetError.PARSE_ERROR("Missing required field: name");
            }
            preset.name = obj.get_string_member("name");

            preset.description = obj.has_member("description")
                ? obj.get_string_member("description") : "";

            preset.created_at = obj.has_member("created_at")
                ? obj.get_int_member("created_at") : GLib.get_real_time() / 1000000;

            preset.last_used_at = obj.has_member("last_used_at")
                ? obj.get_int_member("last_used_at") : preset.created_at;

            preset.schema_version = obj.has_member("schema_version")
                ? (int)obj.get_int_member("schema_version") : 1;

            // Parse core settings (required)
            if (!obj.has_member("tempo")) {
                throw new PresetError.PARSE_ERROR("Missing required field: tempo");
            }
            preset.tempo = (int)obj.get_int_member("tempo");

            if (!obj.has_member("time_sig_numerator")) {
                throw new PresetError.PARSE_ERROR("Missing required field: time_sig_numerator");
            }
            preset.time_sig_numerator = (int)obj.get_int_member("time_sig_numerator");

            if (!obj.has_member("time_sig_denominator")) {
                throw new PresetError.PARSE_ERROR("Missing required field: time_sig_denominator");
            }
            preset.time_sig_denominator = (int)obj.get_int_member("time_sig_denominator");

            // Parse subdivision settings (optional)
            if (obj.has_member("subdivision_mode")) {
                preset.subdivision_mode = (int)obj.get_int_member("subdivision_mode");
            }

            if (obj.has_member("subdivision_volume")) {
                preset.subdivision_volume = obj.get_double_member("subdivision_volume");
            }

            if (obj.has_member("subdivision_sound_type")) {
                preset.subdivision_sound_type = obj.get_string_member("subdivision_sound_type");
            }

            // Parse trainer settings (optional)
            if (obj.has_member("trainer_start_tempo")) {
                preset.trainer_start_tempo = (int)obj.get_int_member("trainer_start_tempo");
            }

            if (obj.has_member("trainer_target_tempo")) {
                preset.trainer_target_tempo = (int)obj.get_int_member("trainer_target_tempo");
            }

            if (obj.has_member("trainer_increment")) {
                preset.trainer_increment = (int)obj.get_int_member("trainer_increment");
            }

            if (obj.has_member("trainer_interval_type")) {
                preset.trainer_interval_type = (int)obj.get_int_member("trainer_interval_type");
            }

            if (obj.has_member("trainer_interval_value")) {
                preset.trainer_interval_value = (int)obj.get_int_member("trainer_interval_value");
            }

            if (obj.has_member("trainer_auto_stop")) {
                preset.trainer_auto_stop = obj.get_boolean_member("trainer_auto_stop");
            }

            // Parse audio settings
            preset.click_volume = obj.has_member("click_volume")
                ? obj.get_double_member("click_volume") : 0.8;

            preset.accent_volume = obj.has_member("accent_volume")
                ? obj.get_double_member("accent_volume") : 1.0;

            preset.high_sound_type = obj.has_member("high_sound_type")
                ? obj.get_string_member("high_sound_type") : "woodblock";

            preset.low_sound_type = obj.has_member("low_sound_type")
                ? obj.get_string_member("low_sound_type") : "woodblock";

            // Parse visual settings
            preset.show_beat_numbers = obj.has_member("show_beat_numbers")
                ? obj.get_boolean_member("show_beat_numbers") : true;

            preset.flash_on_beat = obj.has_member("flash_on_beat")
                ? obj.get_boolean_member("flash_on_beat") : true;

            preset.downbeat_color = obj.has_member("downbeat_color")
                ? obj.get_boolean_member("downbeat_color") : true;

            return preset;
        }
    }

    /**
     * Error domain for preset operations.
     */
public errordomain PresetError {
        INVALID_NAME,
        DUPLICATE_NAME,
        NOT_FOUND,
        MAX_PRESETS_REACHED,
        FILE_IO_ERROR,
        PARSE_ERROR,
        VALIDATION_ERROR
    }
