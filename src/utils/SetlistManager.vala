/* SetlistManager.vala
 *
 * Copyright 2026 Tobagin
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
 * Manages metronome setlists including CRUD operations, persistence, and navigation.
 */
public class SetlistManager : GLib.Object {
    private Gee.ArrayList<Setlist> setlists;
    private string setlists_file_path;

    private const int MAX_SETLISTS = 50;

    // Signals
    public signal void setlist_added(Setlist setlist);
    public signal void setlist_updated(Setlist setlist);
    public signal void setlist_deleted(string setlist_id);
    public signal void setlists_loaded();

    /**
     * Constructor - initializes setlist manager and loads setlists from disk.
     */
    public SetlistManager() {
        setlists = new Gee.ArrayList<Setlist>();
        setlists_file_path = Path.build_filename(
            Environment.get_user_config_dir(),
            "tempo",
            "setlists.json"
        );

        try {
            load_setlists();
        } catch (SetlistError e) {
            warning("Failed to load setlists: %s", e.message);
        }
    }

    /**
     * Add a new setlist to the collection.
     */
    public bool add_setlist(Setlist setlist) throws SetlistError {
        // Validate name
        if (setlist.name.strip().length == 0) {
            throw new SetlistError.INVALID_NAME("Invalid setlist name");
        }

        // Check for duplicate name
        foreach (var existing in setlists) {
            if (existing.name == setlist.name) {
                throw new SetlistError.DUPLICATE_NAME("Setlist with name '%s' already exists".printf(setlist.name));
            }
        }

        // Check max limit
        if (setlists.size >= MAX_SETLISTS) {
            throw new SetlistError.FILE_IO_ERROR("Maximum %d setlists reached".printf(MAX_SETLISTS));
        }

        setlists.add(setlist);

        try {
            save_setlists();
        } catch (SetlistError e) {
            setlists.remove(setlist);
            throw e;
        }

        setlist_added(setlist);
        return true;
    }

    /**
     * Get a setlist by ID.
     */
    public Setlist? get_setlist(string id) {
        foreach (var setlist in setlists) {
            if (setlist.id == id) {
                return setlist;
            }
        }
        return null;
    }

    /**
     * Get all setlists.
     */
    public Gee.List<Setlist> get_all_setlists() {
        var result = new Gee.ArrayList<Setlist>();
        result.add_all(setlists);
        return result;
    }

    /**
     * Update an existing setlist.
     */
    public bool update_setlist(Setlist setlist) throws SetlistError {
        for (int i = 0; i < setlists.size; i++) {
            if (setlists[i].id == setlist.id) {
                // Check if name changed and is unique
                if (setlists[i].name != setlist.name) {
                    foreach (var existing in setlists) {
                        if (existing.id != setlist.id && existing.name == setlist.name) {
                            throw new SetlistError.DUPLICATE_NAME("Setlist with name '%s' already exists".printf(setlist.name));
                        }
                    }
                }

                setlists[i] = setlist;
                save_setlists();
                setlist_updated(setlist);
                return true;
            }
        }

        throw new SetlistError.NOT_FOUND("Setlist not found: %s".printf(setlist.id));
    }

    /**
     * Delete a setlist by ID.
     */
    public bool delete_setlist(string id) throws SetlistError {
        for (int i = 0; i < setlists.size; i++) {
            if (setlists[i].id == id) {
                setlists.remove_at(i);
                save_setlists();
                setlist_deleted(id);
                return true;
            }
        }

        throw new SetlistError.NOT_FOUND("Setlist not found: %s".printf(id));
    }

    /**
     * Save all setlists to disk.
     */
    public bool save_setlists() throws SetlistError {
        try {
            var file = File.new_for_path(setlists_file_path);
            var parent = file.get_parent();
            if (parent != null && !parent.query_exists()) {
                parent.make_directory_with_parents();
            }

            var builder = new Json.Builder();
            builder.begin_object();
            builder.set_member_name("version");
            builder.add_int_value(1);
            builder.set_member_name("setlists");
            builder.begin_array();

            foreach (var setlist in setlists) {
                builder.add_value(setlist.to_json());
            }

            builder.end_array();
            builder.end_object();

            var generator = new Json.Generator();
            generator.set_root(builder.get_root());
            generator.pretty = true;
            generator.indent = 2;
            generator.to_file(setlists_file_path);

            return true;
        } catch (Error e) {
            throw new SetlistError.FILE_IO_ERROR("Failed to save setlists: %s".printf(e.message));
        }
    }

    /**
     * Load setlists from disk.
     */
    public bool load_setlists() throws SetlistError {
        var file = File.new_for_path(setlists_file_path);

        if (!file.query_exists()) {
            setlists.clear();
            setlists_loaded();
            return true;
        }

        try {
            var parser = new Json.Parser();
            parser.load_from_file(setlists_file_path);

            var root = parser.get_root();
            if (root.get_node_type() != Json.NodeType.OBJECT) {
                throw new SetlistError.PARSE_ERROR("Invalid setlist file format");
            }

            var root_obj = root.get_object();
            var setlists_array = root_obj.get_array_member("setlists");
            setlists.clear();

            setlists_array.foreach_element((array, index, element) => {
                try {
                    var setlist = Setlist.from_json(element);
                    setlists.add(setlist);
                } catch (Error e) {
                    warning("Skipping invalid setlist at index %u: %s", index, e.message);
                }
            });

            setlists_loaded();
            return true;

        } catch (Error e) {
            warning("Failed to load setlists: %s", e.message);
            setlists.clear();
            setlists_loaded();
            throw new SetlistError.FILE_IO_ERROR("Setlist file corrupted or unreadable.");
        }
    }
}
