/* SetlistManagerDialog.vala
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

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/tempo/Devel/setlist_manager_dialog.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/tempo/setlist_manager_dialog.ui")]
#endif
public class SetlistManagerDialog : Adw.Dialog {
    [GtkChild]
    private unowned Gtk.ListBox setlist_list;
    [GtkChild]
    private unowned Gtk.ListBox setlist_presets_list;
    [GtkChild]
    private unowned Gtk.Button add_setlist_button;
    [GtkChild]
    private unowned Gtk.Button activate_button;
    [GtkChild]
    private unowned Gtk.Button edit_name_button;
    [GtkChild]
    private unowned Gtk.Button delete_setlist_button;
    [GtkChild]
    private unowned Gtk.Button add_preset_to_setlist_button;

    private SetlistManager setlist_manager;
    private PresetManager preset_manager;
    private Setlist? selected_setlist = null;
    private Gtk.Window parent_window;

    public signal void setlist_activated(Setlist setlist);

    public SetlistManagerDialog(Gtk.Window parent, SetlistManager setlist_mgr, PresetManager preset_mgr) {
        this.parent_window = parent;
        this.setlist_manager = setlist_mgr;
        this.preset_manager = preset_mgr;

        setup_signals();
        populate_setlist_list();
    }

    private void setup_signals() {
        add_setlist_button.clicked.connect(on_add_setlist_clicked);
        setlist_list.row_selected.connect(on_setlist_selected);
        activate_button.clicked.connect(on_activate_clicked);
        edit_name_button.clicked.connect(on_edit_name_clicked);
        delete_setlist_button.clicked.connect(on_delete_clicked);
        add_preset_to_setlist_button.clicked.connect(on_add_preset_clicked);
    }

    private void populate_setlist_list() {
        Gtk.ListBoxRow? row = setlist_list.get_row_at_index(0);
        while (row != null) {
            setlist_list.remove(row);
            row = setlist_list.get_row_at_index(0);
        }

        var all_setlists = setlist_manager.get_all_setlists();
        foreach (var setlist in all_setlists) {
            var setlist_row = create_setlist_row(setlist);
            setlist_list.append(setlist_row);
        }
    }

    private Gtk.ListBoxRow create_setlist_row(Setlist setlist) {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
        box.margin_start = box.margin_end = 12;
        box.margin_top = box.margin_bottom = 8;

        var name_label = new Gtk.Label(setlist.name);
        name_label.halign = Gtk.Align.START;
        name_label.add_css_class("heading");
        box.append(name_label);

        var count_label = new Gtk.Label(_("%d Presets").printf(setlist.preset_ids.size));
        count_label.halign = Gtk.Align.START;
        count_label.add_css_class("caption");
        count_label.add_css_class("dim-label");
        box.append(count_label);

        var row = new Gtk.ListBoxRow();
        row.child = box;
        row.set_data("setlist_id", setlist.id);
        return row;
    }

    private void on_setlist_selected(Gtk.ListBoxRow? row) {
        if (row == null) {
            selected_setlist = null;
            update_ui();
            return;
        }

        var id = (string?)row.get_data<string>("setlist_id");
        selected_setlist = setlist_manager.get_setlist(id);
        update_ui();
        populate_presets_list();
    }

    private void update_ui() {
        bool has_selection = selected_setlist != null;
        activate_button.sensitive = has_selection && selected_setlist.preset_ids.size > 0;
        edit_name_button.sensitive = has_selection;
        delete_setlist_button.sensitive = has_selection;
        add_preset_to_setlist_button.sensitive = has_selection;
    }

    private void populate_presets_list() {
        Gtk.ListBoxRow? row = setlist_presets_list.get_row_at_index(0);
        while (row != null) {
            setlist_presets_list.remove(row);
            row = setlist_presets_list.get_row_at_index(0);
        }

        if (selected_setlist == null) return;

        foreach (var preset_id in selected_setlist.preset_ids) {
            var preset = preset_manager.get_preset(preset_id);
            if (preset != null) {
                var preset_row = create_preset_row(preset);
                setlist_presets_list.append(preset_row);
            }
        }
    }

    private Gtk.ListBoxRow create_preset_row(Preset preset) {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
        box.margin_start = box.margin_end = 12;
        box.margin_top = box.margin_bottom = 8;

        var name_label = new Gtk.Label(preset.name);
        name_label.hexpand = true;
        name_label.halign = Gtk.Align.START;
        box.append(name_label);

        var delete_btn = new Gtk.Button.from_icon_name("user-trash-symbolic");
        delete_btn.add_css_class("flat");
        delete_btn.add_css_class("circular");
        delete_btn.clicked.connect(() => on_remove_preset_from_setlist(preset.id));
        box.append(delete_btn);

        var row = new Gtk.ListBoxRow();
        row.child = box;
        row.activatable = false;
        return row;
    }

    private void on_add_setlist_clicked() {
        var entry = new Gtk.Entry();
        entry.placeholder_text = _("Setlist Name");
        entry.width_chars = 30;

        var dialog = new Adw.AlertDialog(_("New Setlist"), _("Enter a name for the new setlist:"));
        dialog.set_extra_child(entry);
        dialog.add_response("cancel", _("Cancel"));
        dialog.add_response("create", _("Create"));
        dialog.set_response_appearance("create", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_default_response("create");

        dialog.response.connect((response_id) => {
            if (response_id == "create") {
                var name = entry.text.strip();
                if (name.length > 0) {
                    var setlist = new Setlist();
                    setlist.name = name;
                    try {
                        setlist_manager.add_setlist(setlist);
                        populate_setlist_list();
                    } catch (Error e) {
                        show_error(e.message);
                    }
                }
            }
        });
        dialog.present(this.parent_window);
    }

    private void on_activate_clicked() {
        if (selected_setlist != null) {
            setlist_activated(selected_setlist);
            this.close();
        }
    }

    private void on_edit_name_clicked() {
        if (selected_setlist == null) return;

        var entry = new Gtk.Entry();
        entry.text = selected_setlist.name;
        entry.width_chars = 30;

        var dialog = new Adw.AlertDialog(_("Rename Setlist"), _("Enter a new name:"));
        dialog.set_extra_child(entry);
        dialog.add_response("cancel", _("Cancel"));
        dialog.add_response("rename", _("Rename"));
        dialog.set_response_appearance("rename", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_default_response("rename");

        dialog.response.connect((response_id) => {
            if (response_id == "rename") {
                var name = entry.text.strip();
                if (name.length > 0) {
                    selected_setlist.name = name;
                    try {
                        setlist_manager.update_setlist(selected_setlist);
                        populate_setlist_list();
                    } catch (Error e) {
                        show_error(e.message);
                    }
                }
            }
        });
        dialog.present(this.parent_window);
    }

    private void on_delete_clicked() {
        if (selected_setlist == null) return;

        var dialog = new Adw.AlertDialog(_("Delete Setlist?"), _("Are you sure you want to delete '%s'?").printf(selected_setlist.name));
        dialog.add_response("cancel", _("Cancel"));
        dialog.add_response("delete", _("Delete"));
        dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.set_default_response("cancel");

        dialog.response.connect((response_id) => {
            if (response_id == "delete") {
                try {
                    setlist_manager.delete_setlist(selected_setlist.id);
                    selected_setlist = null;
                    populate_setlist_list();
                    update_ui();
                    populate_presets_list();
                } catch (Error e) {
                    show_error(e.message);
                }
            }
        });
        dialog.present(this.parent_window);
    }

    private void on_add_preset_clicked() {
        if (selected_setlist == null) return;

        var presets = preset_manager.get_all_presets();
        if (presets.size == 0) {
            show_error(_("You don't have any presets. Create some first!"));
            return;
        }

        var list = new Gtk.ListBox();
        list.add_css_class("boxed-list");
        list.selection_mode = Gtk.SelectionMode.SINGLE;

        foreach (var preset in presets) {
            var label = new Gtk.Label(preset.name);
            label.margin_top = label.margin_bottom = 8;
            var row = new Gtk.ListBoxRow();
            row.child = label;
            row.set_data("preset_id", preset.id);
            list.append(row);
        }

        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_child(list);
        scrolled.height_request = 300;

        var dialog = new Adw.AlertDialog(_("Add Preset to Setlist"), _("Select a preset to add:"));
        dialog.set_extra_child(scrolled);
        dialog.add_response("cancel", _("Cancel"));
        dialog.add_response("add", _("Add"));
        dialog.set_response_appearance("add", Adw.ResponseAppearance.SUGGESTED);
        dialog.set_default_response("add");

        dialog.response.connect((response_id) => {
            if (response_id == "add") {
                var row = list.get_selected_row();
                if (row != null) {
                    var preset_id = (string)row.get_data<string>("preset_id");
                    selected_setlist.preset_ids.add(preset_id);
                    try {
                        setlist_manager.update_setlist(selected_setlist);
                        populate_presets_list();
                        update_ui();
                    } catch (Error e) {
                        show_error(e.message);
                    }
                }
            }
        });
        dialog.present(this.parent_window);
    }

    private void on_remove_preset_from_setlist(string preset_id) {
        if (selected_setlist == null) return;
        selected_setlist.preset_ids.remove(preset_id);
        try {
            setlist_manager.update_setlist(selected_setlist);
            populate_presets_list();
            update_ui();
        } catch (Error e) {
            show_error(e.message);
        }
    }

    private void show_error(string message) {
        var dialog = new Adw.AlertDialog(_("Error"), message);
        dialog.add_response("ok", _("OK"));
        dialog.present(this.parent_window);
    }
}
