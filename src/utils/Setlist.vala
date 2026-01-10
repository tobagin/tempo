/* Setlist.vala
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

using GLib;
using Json;
using Gee;

/**
 * Error domain for setlist-related operations.
 */
public errordomain SetlistError {
    INVALID_NAME,
    DUPLICATE_NAME,
    NOT_FOUND,
    FILE_IO_ERROR,
    PARSE_ERROR
}

/**
 * Data class representing a Setlist (a collection of presets).
 */
public class Setlist : GLib.Object {
    public string id { get; set; }
    public string name { get; set; }
    public string description { get; set; }
    public int64 created_at { get; set; }
    public int64 modified_at { get; set; }
    public Gee.ArrayList<string> preset_ids { get; set; }

    /**
     * Constructor for a new Setlist.
     */
    public Setlist(string name = "", string description = "") {
        this.id = Uuid.string_random();
        this.name = name;
        this.description = description;
        this.created_at = GLib.get_real_time() / 1000000;
        this.modified_at = this.created_at;
        this.preset_ids = new Gee.ArrayList<string>();
    }

    /**
     * Converts the setlist to a JSON node for serialization.
     */
    public Json.Node to_json() {
        var builder = new Json.Builder();
        builder.begin_object();
        
        builder.set_member_name("id");
        builder.add_string_value(id);
        
        builder.set_member_name("name");
        builder.add_string_value(name);
        
        builder.set_member_name("description");
        builder.add_string_value(description);
        
        builder.set_member_name("created_at");
        builder.add_int_value(created_at);
        
        builder.set_member_name("modified_at");
        builder.add_int_value(modified_at);
        
        builder.set_member_name("preset_ids");
        builder.begin_array();
        foreach (var preset_id in preset_ids) {
            builder.add_string_value(preset_id);
        }
        builder.end_array();
        
        builder.end_object();
        return builder.get_root();
    }

    /**
     * Creates a Setlist from a JSON node.
     */
    public static Setlist from_json(Json.Node node) throws SetlistError {
        if (node.get_node_type() != Json.NodeType.OBJECT) {
            throw new SetlistError.PARSE_ERROR("Invalid JSON node type for Setlist");
        }

        var obj = node.get_object();
        var setlist = new Setlist();
        
        if (obj.has_member("id")) setlist.id = obj.get_string_member("id");
        if (obj.has_member("name")) setlist.name = obj.get_string_member("name");
        if (obj.has_member("description")) setlist.description = obj.get_string_member("description");
        if (obj.has_member("created_at")) setlist.created_at = obj.get_int_member("created_at");
        if (obj.has_member("modified_at")) setlist.modified_at = obj.get_int_member("modified_at");
        
        if (obj.has_member("preset_ids")) {
            var array = obj.get_array_member("preset_ids");
            array.foreach_element((a, i, e) => {
                setlist.preset_ids.add(e.get_string());
            });
        }
        
        return setlist;
    }
}
