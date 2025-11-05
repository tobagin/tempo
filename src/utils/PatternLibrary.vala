/* PatternLibrary.vala
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
     * Manages rhythm pattern library - both built-in and user patterns
     */
    public class PatternLibrary : GLib.Object {
        private const int MAX_USER_PATTERNS = 100;
        private const string USER_PATTERNS_DIR = "patterns";

        private Gee.HashMap<string, RhythmPattern> built_in_patterns;
        private Gee.HashMap<string, RhythmPattern> user_patterns;

        public signal void patterns_changed();

        public PatternLibrary() {
            built_in_patterns = new Gee.HashMap<string, RhythmPattern>();
            user_patterns = new Gee.HashMap<string, RhythmPattern>();
        }

        /**
         * Load all built-in patterns from gresource
         */
        public void load_built_in_patterns() throws Error {
            built_in_patterns.clear();

            // List of built-in pattern files to load
            string[] pattern_files = {
                "son-clave-32.json",
                "son-clave-23.json",
                "rumba-clave.json",
                "bossa-nova.json",
                "swing-ride.json",
                "backbeat.json"
            };

            foreach (var filename in pattern_files) {
                try {
                    // Use Config.RESOURCE_PATH to support both dev and prod builds
                    string resource_path = Config.RESOURCE_PATH + "/patterns/" + filename;
                    var pattern = RhythmPattern.from_resource(resource_path);

                    if (pattern != null) {
                        built_in_patterns.set(pattern.name, pattern);
                        debug("Loaded built-in pattern: %s", pattern.name);
                    }
                } catch (Error e) {
                    warning("Failed to load built-in pattern %s: %s", filename, e.message);
                }
            }

            patterns_changed();
        }

        /**
         * Load user patterns from config directory
         */
        public void load_user_patterns() throws Error {
            user_patterns.clear();

            var config_dir = get_user_patterns_directory();
            var patterns_dir = GLib.File.new_for_path(config_dir);

            // Create directory if it doesn't exist
            if (!patterns_dir.query_exists()) {
                try {
                    patterns_dir.make_directory_with_parents();
                    debug("Created user patterns directory: %s", config_dir);
                } catch (Error e) {
                    warning("Failed to create patterns directory: %s", e.message);
                    return;
                }
            }

            // List all JSON files in the directory
            try {
                var enumerator = patterns_dir.enumerate_children(
                    FileAttribute.STANDARD_NAME,
                    FileQueryInfoFlags.NONE
                );

                FileInfo? file_info;
                while ((file_info = enumerator.next_file()) != null) {
                    string filename = file_info.get_name();

                    if (filename.has_suffix(".json")) {
                        string file_path = Path.build_filename(config_dir, filename);

                        try {
                            var pattern = RhythmPattern.from_json_file(file_path);

                            if (pattern != null) {
                                // Handle duplicate names
                                string pattern_name = pattern.name;
                                int suffix = 2;
                                while (user_patterns.has_key(pattern_name) ||
                                       built_in_patterns.has_key(pattern_name)) {
                                    pattern_name = @"$(pattern.name) ($(suffix))";
                                    suffix++;
                                }

                                if (pattern_name != pattern.name) {
                                    pattern.name = pattern_name;
                                }

                                user_patterns.set(pattern.name, pattern);
                                debug("Loaded user pattern: %s", pattern.name);
                            }
                        } catch (Error e) {
                            warning("Failed to load user pattern %s: %s", filename, e.message);
                            continue;
                        }
                    }
                }
            } catch (Error e) {
                warning("Failed to enumerate user patterns: %s", e.message);
            }

            patterns_changed();
        }

        /**
         * Get all patterns (built-in first, then user patterns)
         */
        public Gee.ArrayList<RhythmPattern> get_all_patterns() {
            var result = new Gee.ArrayList<RhythmPattern>();

            // Add built-in patterns first (sorted by name)
            var built_in_list = new Gee.ArrayList<RhythmPattern>();
            built_in_list.add_all(built_in_patterns.values);
            built_in_list.sort((a, b) => {
                return strcmp(a.name, b.name);
            });
            result.add_all(built_in_list);

            // Add user patterns (sorted by name)
            var user_list = new Gee.ArrayList<RhythmPattern>();
            user_list.add_all(user_patterns.values);
            user_list.sort((a, b) => {
                return strcmp(a.name, b.name);
            });
            result.add_all(user_list);

            return result;
        }

        /**
         * Get a pattern by name
         */
        public RhythmPattern? get_pattern(string name) {
            if (built_in_patterns.has_key(name)) {
                return built_in_patterns.get(name);
            }

            if (user_patterns.has_key(name)) {
                return user_patterns.get(name);
            }

            return null;
        }

        /**
         * Check if a pattern exists
         */
        public bool has_pattern(string name) {
            return built_in_patterns.has_key(name) || user_patterns.has_key(name);
        }

        /**
         * Check if a pattern is built-in
         */
        public bool is_built_in(string name) {
            return built_in_patterns.has_key(name);
        }

        /**
         * Save a user pattern
         */
        public void save_user_pattern(RhythmPattern pattern) throws Error {
            // Enforce pattern limit
            if (!user_patterns.has_key(pattern.name) &&
                user_patterns.size >= MAX_USER_PATTERNS) {
                throw new IOError.NO_SPACE(
                    @"Maximum number of user patterns ($(MAX_USER_PATTERNS)) reached"
                );
            }

            // Don't allow overwriting built-in patterns
            if (built_in_patterns.has_key(pattern.name)) {
                throw new IOError.EXISTS(
                    @"Cannot overwrite built-in pattern: $(pattern.name)"
                );
            }

            var config_dir = get_user_patterns_directory();
            var patterns_dir = GLib.File.new_for_path(config_dir);

            // Create directory if it doesn't exist
            if (!patterns_dir.query_exists()) {
                patterns_dir.make_directory_with_parents();
            }

            // Generate safe filename from pattern name
            string safe_filename = generate_safe_filename(pattern.name);
            string file_path = Path.build_filename(config_dir, @"$(safe_filename).json");

            // Save pattern to file
            pattern.to_json_file(file_path);

            // Update in-memory collection
            user_patterns.set(pattern.name, pattern);

            debug("Saved user pattern: %s to %s", pattern.name, file_path);
            patterns_changed();
        }

        /**
         * Delete a user pattern
         */
        public void delete_user_pattern(string name) throws Error {
            // Can't delete built-in patterns
            if (built_in_patterns.has_key(name)) {
                throw new IOError.INVALID_ARGUMENT(
                    @"Cannot delete built-in pattern: $(name)"
                );
            }

            if (!user_patterns.has_key(name)) {
                throw new IOError.NOT_FOUND(
                    @"User pattern not found: $(name)"
                );
            }

            var config_dir = get_user_patterns_directory();

            // Find the file for this pattern
            var patterns_dir = GLib.File.new_for_path(config_dir);
            var enumerator = patterns_dir.enumerate_children(
                FileAttribute.STANDARD_NAME,
                FileQueryInfoFlags.NONE
            );

            FileInfo? file_info;
            while ((file_info = enumerator.next_file()) != null) {
                string filename = file_info.get_name();

                if (filename.has_suffix(".json")) {
                    string file_path = Path.build_filename(config_dir, filename);

                    try {
                        var pattern = RhythmPattern.from_json_file(file_path);
                        if (pattern != null && pattern.name == name) {
                            // Delete the file
                            var file = GLib.File.new_for_path(file_path);
                            file.delete();

                            // Remove from in-memory collection
                            user_patterns.unset(name);

                            debug("Deleted user pattern: %s", name);
                            patterns_changed();
                            return;
                        }
                    } catch (Error e) {
                        continue;
                    }
                }
            }

            throw new IOError.NOT_FOUND(
                @"Could not find file for pattern: $(name)"
            );
        }

        /**
         * Get the number of user patterns
         */
        public int get_user_pattern_count() {
            return user_patterns.size;
        }

        /**
         * Get the number of built-in patterns
         */
        public int get_built_in_pattern_count() {
            return built_in_patterns.size;
        }

        /**
         * Get the total number of patterns
         */
        public int get_total_pattern_count() {
            return built_in_patterns.size + user_patterns.size;
        }

        /**
         * Get the user patterns directory path
         */
        private string get_user_patterns_directory() {
            // For Flatpak: ~/.var/app/io.github.tobagin.tempo/config/tempo/patterns/
            // For non-Flatpak: ~/.config/tempo/patterns/
            string config_base = Environment.get_user_config_dir();
            return Path.build_filename(config_base, "tempo", USER_PATTERNS_DIR);
        }

        /**
         * Generate a safe filename from a pattern name
         */
        private string generate_safe_filename(string name) {
            // Replace unsafe characters with hyphens
            var safe_name = new StringBuilder();

            foreach (var c in name.to_utf8()) {
                if (c.isalnum() || c == '-' || c == '_') {
                    safe_name.append_c((char) c);
                } else if (c == ' ') {
                    safe_name.append_c('-');
                }
            }

            string result = safe_name.str.down();

            // Ensure the filename is not empty
            if (result.length == 0) {
                result = "pattern";
            }

            // Truncate if too long
            if (result.length > 64) {
                result = result.substring(0, 64);
            }

            return result;
        }

        /**
         * Reload all patterns (useful after external changes)
         */
        public void reload_all() {
            try {
                load_built_in_patterns();
                load_user_patterns();
            } catch (Error e) {
                warning("Failed to reload patterns: %s", e.message);
            }
        }
    }
}
