/* PresetManager.vala
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
     * Manages tempo presets including CRUD operations, persistence, and import/export.
     */
public class PresetManager : GLib.Object {
        private Gee.ArrayList<Preset> presets;
        private string presets_file_path;

        private const int MAX_PRESETS = 100;
        private const int WARN_PRESETS = 50;

        // Signals
        public signal void preset_added(Preset preset);
        public signal void preset_updated(Preset preset);
        public signal void preset_deleted(string preset_id);
        public signal void presets_loaded();

        /**
         * Constructor - initializes preset manager and loads presets from disk.
         */
        public PresetManager() {
            presets = new Gee.ArrayList<Preset>();
            presets_file_path = Path.build_filename(
                Environment.get_user_config_dir(),
                "tempo",
                "presets.json"
            );

            try {
                load_presets();
            } catch (PresetError e) {
                warning("Failed to load presets: %s", e.message);
            }
        }

        /**
         * Add a new preset to the collection.
         *
         * Args:
         *     preset: The preset to add
         *
         * Returns: true if added successfully
         *
         * Throws: PresetError if validation fails or max limit reached
         */
        public bool add_preset(Preset preset) throws PresetError {
            // Validate name
            if (!validate_preset_name(preset.name)) {
                throw new PresetError.INVALID_NAME("Invalid preset name");
            }

            // Check for duplicate name
            foreach (var existing in presets) {
                if (existing.name == preset.name) {
                    throw new PresetError.DUPLICATE_NAME("Preset with name '%s' already exists".printf(preset.name));
                }
            }

            // Check max limit
            if (presets.size >= MAX_PRESETS) {
                throw new PresetError.MAX_PRESETS_REACHED("Maximum %d presets reached".printf(MAX_PRESETS));
            }

            // Warn at threshold (non-blocking)
            if (presets.size == WARN_PRESETS) {
                warning("You have %d presets. Consider organizing or deleting unused ones.", WARN_PRESETS);
            }

            presets.add(preset);

            try {
                save_presets();
            } catch (PresetError e) {
                // Rollback on save failure
                presets.remove(preset);
                throw e;
            }

            preset_added(preset);
            return true;
        }

        /**
         * Get a preset by ID.
         *
         * Args:
         *     id: The preset ID
         *
         * Returns: The preset, or null if not found
         */
        public Preset? get_preset(string id) {
            foreach (var preset in presets) {
                if (preset.id == id) {
                    return preset;
                }
            }
            return null;
        }

        /**
         * Get all presets.
         *
         * Returns: List of all presets
         */
        public Gee.List<Preset> get_all_presets() {
            var result = new Gee.ArrayList<Preset>();
            result.add_all(presets);
            return result;
        }

        /**
         * Update an existing preset.
         *
         * Args:
         *     preset: The preset with updated values
         *
         * Returns: true if updated successfully
         *
         * Throws: PresetError if preset not found or validation fails
         */
        public bool update_preset(Preset preset) throws PresetError {
            for (int i = 0; i < presets.size; i++) {
                if (presets[i].id == preset.id) {
                    // Check if name changed and is unique
                    if (presets[i].name != preset.name) {
                        foreach (var existing in presets) {
                            if (existing.id != preset.id && existing.name == preset.name) {
                                throw new PresetError.DUPLICATE_NAME("Preset with name '%s' already exists".printf(preset.name));
                            }
                        }
                    }

                    presets[i] = preset;
                    save_presets();
                    preset_updated(preset);
                    return true;
                }
            }

            throw new PresetError.NOT_FOUND("Preset not found: %s".printf(preset.id));
        }

        /**
         * Delete a preset by ID.
         *
         * Args:
         *     id: The preset ID
         *
         * Returns: true if deleted successfully
         *
         * Throws: PresetError if preset not found
         */
        public bool delete_preset(string id) throws PresetError {
            for (int i = 0; i < presets.size; i++) {
                if (presets[i].id == id) {
                    presets.remove_at(i);
                    save_presets();
                    preset_deleted(id);
                    return true;
                }
            }

            throw new PresetError.NOT_FOUND("Preset not found: %s".printf(id));
        }

        /**
         * Rename a preset.
         *
         * Args:
         *     id: The preset ID
         *     new_name: The new name
         *
         * Returns: true if renamed successfully
         *
         * Throws: PresetError if validation fails or preset not found
         */
        public bool rename_preset(string id, string new_name) throws PresetError {
            if (!validate_preset_name(new_name)) {
                throw new PresetError.INVALID_NAME("Invalid preset name");
            }

            var preset = get_preset(id);
            if (preset == null) {
                throw new PresetError.NOT_FOUND("Preset not found: %s".printf(id));
            }

            // Check for duplicate name (excluding current preset)
            foreach (var existing in presets) {
                if (existing.id != id && existing.name == new_name) {
                    throw new PresetError.DUPLICATE_NAME("Preset with name '%s' already exists".printf(new_name));
                }
            }

            preset.name = new_name;
            save_presets();
            preset_updated(preset);
            return true;
        }

        /**
         * Duplicate a preset with a new ID and unique name.
         *
         * Args:
         *     id: The ID of the preset to duplicate
         *
         * Returns: The new preset, or null on failure
         *
         * Throws: PresetError if preset not found or max limit reached
         */
        public Preset? duplicate_preset(string id) throws PresetError {
            var original = get_preset(id);
            if (original == null) {
                throw new PresetError.NOT_FOUND("Preset not found: %s".printf(id));
            }

            if (presets.size >= MAX_PRESETS) {
                throw new PresetError.MAX_PRESETS_REACHED("Maximum %d presets reached".printf(MAX_PRESETS));
            }

            // Create copy via JSON serialization/deserialization
            var json_node = original.to_json();
            var duplicate = Preset.from_json(json_node);

            // Generate new ID and unique name
            duplicate.id = Uuid.string_random();
            duplicate.name = generate_unique_name(original.name + " (Copy)");
            duplicate.created_at = GLib.get_real_time() / 1000000;
            duplicate.last_used_at = duplicate.created_at;

            presets.add(duplicate);
            save_presets();
            preset_added(duplicate);

            return duplicate;
        }

        /**
         * Save all presets to disk.
         *
         * Returns: true if saved successfully
         *
         * Throws: PresetError.FILE_IO_ERROR on I/O failure
         */
        public bool save_presets() throws PresetError {
            try {
                // Ensure parent directory exists
                var file = File.new_for_path(presets_file_path);
                var parent = file.get_parent();
                if (parent != null && !parent.query_exists()) {
                    parent.make_directory_with_parents();
                }

                // Build JSON structure
                var builder = new Json.Builder();
                builder.begin_object();

                builder.set_member_name("version");
                builder.add_int_value(1);

                builder.set_member_name("presets");
                builder.begin_array();

                foreach (var preset in presets) {
                    builder.add_value(preset.to_json());
                }

                builder.end_array();
                builder.end_object();

                // Generate and save JSON
                var generator = new Json.Generator();
                generator.set_root(builder.get_root());
                generator.pretty = true;
                generator.indent = 2;

                generator.to_file(presets_file_path);

                return true;
            } catch (Error e) {
                throw new PresetError.FILE_IO_ERROR("Failed to save presets: %s".printf(e.message));
            }
        }

        /**
         * Load presets from disk.
         *
         * Returns: true if loaded successfully
         *
         * Throws: PresetError on parse or I/O failure
         */
        public bool load_presets() throws PresetError {
            var file = File.new_for_path(presets_file_path);

            // If file doesn't exist, start with empty list
            if (!file.query_exists()) {
                presets.clear();
                presets_loaded();
                return true;
            }

            try {
                var parser = new Json.Parser();
                parser.load_from_file(presets_file_path);

                var root = parser.get_root();
                if (root.get_node_type() != Json.NodeType.OBJECT) {
                    throw new PresetError.PARSE_ERROR("Invalid preset file format");
                }

                var root_obj = root.get_object();

                // Validate structure
                if (!root_obj.has_member("version") || !root_obj.has_member("presets")) {
                    throw new PresetError.PARSE_ERROR("Missing required fields in preset file");
                }

                var presets_array = root_obj.get_array_member("presets");
                presets.clear();

                // Parse each preset
                presets_array.foreach_element((array, index, element) => {
                    try {
                        var preset = Preset.from_json(element);
                        presets.add(preset);
                    } catch (PresetError e) {
                        warning("Skipping invalid preset at index %u: %s", index, e.message);
                    }
                });

                presets_loaded();
                return true;

            } catch (Error e) {
                // Handle corrupted file
                warning("Failed to load presets: %s", e.message);

                // Create backup of corrupted file
                var timestamp = new DateTime.now_local().format("%Y%m%d_%H%M%S");
                var backup_path = "%s.corrupt.%s".printf(presets_file_path, timestamp);

                try {
                    var backup_file = File.new_for_path(backup_path);
                    file.copy(backup_file, FileCopyFlags.OVERWRITE);
                    warning("Corrupted preset file backed up to: %s", backup_path);
                } catch (Error backup_error) {
                    warning("Failed to backup corrupted file: %s", backup_error.message);
                }

                // Start fresh
                presets.clear();
                presets_loaded();

                throw new PresetError.FILE_IO_ERROR("Preset file corrupted, starting fresh. Backup: %s".printf(backup_path));
            }
        }

        /**
         * Export all presets to a file.
         *
         * Args:
         *     file_path: Path to export file
         *
         * Returns: true if exported successfully
         *
         * Throws: PresetError.FILE_IO_ERROR on failure
         */
        public bool export_presets(string file_path) throws PresetError {
            try {
                var builder = new Json.Builder();
                builder.begin_object();

                builder.set_member_name("version");
                builder.add_int_value(1);

                builder.set_member_name("presets");
                builder.begin_array();

                foreach (var preset in presets) {
                    builder.add_value(preset.to_json());
                }

                builder.end_array();
                builder.end_object();

                var generator = new Json.Generator();
                generator.set_root(builder.get_root());
                generator.pretty = true;
                generator.indent = 2;

                generator.to_file(file_path);
                return true;

            } catch (Error e) {
                throw new PresetError.FILE_IO_ERROR("Failed to export presets: %s".printf(e.message));
            }
        }

        /**
         * Export a single preset to a file.
         *
         * Args:
         *     preset_id: ID of preset to export
         *     file_path: Path to export file
         *
         * Returns: true if exported successfully
         *
         * Throws: PresetError if preset not found or I/O fails
         */
        public bool export_preset(string preset_id, string file_path) throws PresetError {
            var preset = get_preset(preset_id);
            if (preset == null) {
                throw new PresetError.NOT_FOUND("Preset not found: %s".printf(preset_id));
            }

            try {
                var builder = new Json.Builder();
                builder.begin_object();

                builder.set_member_name("version");
                builder.add_int_value(1);

                builder.set_member_name("presets");
                builder.begin_array();
                builder.add_value(preset.to_json());
                builder.end_array();

                builder.end_object();

                var generator = new Json.Generator();
                generator.set_root(builder.get_root());
                generator.pretty = true;
                generator.indent = 2;

                generator.to_file(file_path);
                return true;

            } catch (Error e) {
                throw new PresetError.FILE_IO_ERROR("Failed to export preset: %s".printf(e.message));
            }
        }

        /**
         * Import presets from a file.
         *
         * Args:
         *     file_path: Path to import file
         *     merge: If true, merge with existing; if false, replace all
         *
         * Returns: Number of presets imported
         *
         * Throws: PresetError on validation or I/O failure
         */
        public int import_presets(string file_path, bool merge) throws PresetError {
            try {
                var parser = new Json.Parser();
                parser.load_from_file(file_path);

                var root = parser.get_root();
                if (root.get_node_type() != Json.NodeType.OBJECT) {
                    throw new PresetError.PARSE_ERROR("Invalid import file format");
                }

                var root_obj = root.get_object();

                if (!root_obj.has_member("version") || !root_obj.has_member("presets")) {
                    throw new PresetError.PARSE_ERROR("Missing required fields in import file");
                }

                var import_presets_array = root_obj.get_array_member("presets");
                var imported = new Gee.ArrayList<Preset>();

                // Parse imported presets
                import_presets_array.foreach_element((array, index, element) => {
                    try {
                        var preset = Preset.from_json(element);
                        imported.add(preset);
                    } catch (PresetError e) {
                        warning("Skipping invalid preset at index %u: %s", index, e.message);
                    }
                });

                if (!merge) {
                    // Replace mode: clear existing presets
                    presets.clear();
                }

                // Add imported presets, handling name conflicts
                int added_count = 0;
                foreach (var preset in imported) {
                    // Ensure unique name
                    preset.name = generate_unique_name(preset.name);

                    if (presets.size < MAX_PRESETS) {
                        presets.add(preset);
                        added_count++;
                        preset_added(preset);
                    } else {
                        warning("Max presets reached, skipping: %s", preset.name);
                        break;
                    }
                }

                save_presets();
                return added_count;

            } catch (Error e) {
                throw new PresetError.FILE_IO_ERROR("Failed to import presets: %s".printf(e.message));
            }
        }

        /**
         * Validate a preset name.
         *
         * Args:
         *     name: The name to validate
         *
         * Returns: true if name is valid
         */
        public bool validate_preset_name(string name) {
            // Check not empty
            if (name.strip().length == 0) {
                return false;
            }

            // Check length
            if (name.length > 100) {
                return false;
            }

            // Check for invalid characters (path separators and other forbidden chars)
            if (name.contains("/") || name.contains("\\") || name.contains(":") ||
                name.contains("*") || name.contains("?") || name.contains("\"") ||
                name.contains("<") || name.contains(">") || name.contains("|")) {
                return false;
            }

            return true;
        }

        /**
         * Generate a unique preset name based on a base name.
         *
         * Args:
         *     base_name: The base name
         *
         * Returns: A unique name (appends " (2)", " (3)", etc. if needed)
         */
        public string generate_unique_name(string base_name) {
            string candidate = base_name;
            int counter = 2;

            while (true) {
                bool exists = false;
                foreach (var preset in presets) {
                    if (preset.name == candidate) {
                        exists = true;
                        break;
                    }
                }

                if (!exists) {
                    return candidate;
                }

                candidate = "%s (%d)".printf(base_name, counter);
                counter++;
            }
        }

        /**
         * Search presets by name (case-insensitive).
         *
         * Args:
         *     query: The search query
         *
         * Returns: List of matching presets
         */
        public Gee.List<Preset> search_presets(string query) {
            var results = new Gee.ArrayList<Preset>();
            var query_lower = query.down();

            foreach (var preset in presets) {
                if (preset.name.down().contains(query_lower) ||
                    preset.description.down().contains(query_lower)) {
                    results.add(preset);
                }
            }

            return results;
        }

        /**
         * Sort presets by specified order.
         *
         * Args:
         *     order: The sort order
         */
        public void sort_presets(PresetSortOrder order) {
            switch (order) {
                case PresetSortOrder.NAME_ASC:
                    presets.sort((a, b) => strcmp(a.name, b.name));
                    break;
                case PresetSortOrder.NAME_DESC:
                    presets.sort((a, b) => strcmp(b.name, a.name));
                    break;
                case PresetSortOrder.CREATED_DATE_ASC:
                    presets.sort((a, b) => (int)(a.created_at - b.created_at));
                    break;
                case PresetSortOrder.CREATED_DATE_DESC:
                    presets.sort((a, b) => (int)(b.created_at - a.created_at));
                    break;
                case PresetSortOrder.LAST_USED_ASC:
                    presets.sort((a, b) => (int)(a.last_used_at - b.last_used_at));
                    break;
                case PresetSortOrder.LAST_USED_DESC:
                    presets.sort((a, b) => (int)(b.last_used_at - a.last_used_at));
                    break;
                case PresetSortOrder.TEMPO_ASC:
                    presets.sort((a, b) => a.tempo - b.tempo);
                    break;
                case PresetSortOrder.TEMPO_DESC:
                    presets.sort((a, b) => b.tempo - a.tempo);
                    break;
            }
        }

        /**
         * Create a preset from current GSettings values.
         *
         * Args:
         *     name: The preset name
         *     description: Optional description
         *
         * Returns: A new preset containing current settings
         */
        public Preset create_from_current_settings(string name, string description = "") {
            var settings = new GLib.Settings(Config.APP_ID);
            var preset = new Preset();

            // Metadata
            preset.id = Uuid.string_random();
            preset.name = name;
            preset.description = description;
            preset.created_at = GLib.get_real_time() / 1000000;
            preset.last_used_at = preset.created_at;
            preset.schema_version = 1;

            // Core settings
            preset.tempo = settings.get_int("tempo");
            preset.time_sig_numerator = settings.get_int("time-signature-numerator");
            preset.time_sig_denominator = settings.get_int("time-signature-denominator");

            // Subdivisions (check if keys exist in schema)
            if (settings_has_key(settings, "subdivision-mode")) {
                preset.subdivision_mode = settings.get_int("subdivision-mode");
                preset.subdivision_volume = settings.get_double("subdivision-volume");
                preset.subdivision_sound_type = settings.get_string("subdivision-sound-type");
            }

            // Tempo trainer (check if keys exist)
            if (settings_has_key(settings, "trainer-start-tempo")) {
                preset.trainer_start_tempo = settings.get_int("trainer-start-tempo");
                preset.trainer_target_tempo = settings.get_int("trainer-target-tempo");
                preset.trainer_increment = settings.get_int("trainer-increment");
                preset.trainer_interval_type = settings.get_int("trainer-interval-type");
                preset.trainer_interval_value = settings.get_int("trainer-interval-value");
                preset.trainer_auto_stop = settings.get_boolean("trainer-auto-stop");
            }

            // Audio settings
            preset.click_volume = settings.get_double("click-volume");
            preset.accent_volume = settings.get_double("accent-volume");
            preset.high_sound_type = settings.get_string("high-sound-type");
            preset.low_sound_type = settings.get_string("low-sound-type");

            // Visual settings
            preset.show_beat_numbers = settings.get_boolean("show-beat-numbers");
            preset.flash_on_beat = settings.get_boolean("flash-on-beat");
            preset.downbeat_color = settings.get_boolean("downbeat-color");

            return preset;
        }

        /**
         * Apply a preset to current GSettings.
         *
         * Args:
         *     preset_id: The ID of the preset to apply
         *
         * Returns: true if applied successfully
         *
         * Throws: PresetError.NOT_FOUND if preset doesn't exist
         */
        public bool apply_preset(string preset_id) throws PresetError {
            var preset = get_preset(preset_id);
            if (preset == null) {
                throw new PresetError.NOT_FOUND("Preset not found: %s".printf(preset_id));
            }

            var settings = new GLib.Settings(Config.APP_ID);

            // Core settings
            settings.set_int("tempo", preset.tempo);
            settings.set_int("time-signature-numerator", preset.time_sig_numerator);
            settings.set_int("time-signature-denominator", preset.time_sig_denominator);

            // Subdivisions (only if preset has them and feature exists)
            if (preset.subdivision_mode != null && settings_has_key(settings, "subdivision-mode")) {
                settings.set_int("subdivision-mode", preset.subdivision_mode);
                settings.set_double("subdivision-volume", preset.subdivision_volume ?? 0.5);
                settings.set_string("subdivision-sound-type", preset.subdivision_sound_type ?? "default");
            }

            // Tempo trainer (only if preset has it and feature exists)
            if (preset.trainer_start_tempo != null && settings_has_key(settings, "trainer-start-tempo")) {
                settings.set_int("trainer-start-tempo", preset.trainer_start_tempo);
                settings.set_int("trainer-target-tempo", preset.trainer_target_tempo ?? 120);
                settings.set_int("trainer-increment", preset.trainer_increment ?? 5);
                settings.set_int("trainer-interval-type", preset.trainer_interval_type ?? 0);
                settings.set_int("trainer-interval-value", preset.trainer_interval_value ?? 8);
                settings.set_boolean("trainer-auto-stop", preset.trainer_auto_stop ?? false);
            }

            // Audio settings
            settings.set_double("click-volume", preset.click_volume);
            settings.set_double("accent-volume", preset.accent_volume);
            settings.set_string("high-sound-type", preset.high_sound_type);
            settings.set_string("low-sound-type", preset.low_sound_type);

            // Visual settings
            settings.set_boolean("show-beat-numbers", preset.show_beat_numbers);
            settings.set_boolean("flash-on-beat", preset.flash_on_beat);
            settings.set_boolean("downbeat-color", preset.downbeat_color);

            // Update last_used timestamp
            preset.last_used_at = GLib.get_real_time() / 1000000;
            update_preset(preset);

            return true;
        }

        /**
         * Helper function to check if a GSettings key exists.
         */
        private bool settings_has_key(GLib.Settings settings, string key) {
            var schema = settings.settings_schema;
            return schema != null && schema.has_key(key);
        }
    }

    /**
     * Preset sort order options.
     */
public enum PresetSortOrder {
        NAME_ASC,
        NAME_DESC,
        CREATED_DATE_ASC,
        CREATED_DATE_DESC,
        LAST_USED_ASC,
        LAST_USED_DESC,
        TEMPO_ASC,
        TEMPO_DESC
    }
