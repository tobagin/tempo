/* PresetManagerDialog.vala
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


#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/tempo/Devel/preset_manager_dialog.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/tempo/preset_manager_dialog.ui")]
#endif
public class PresetManagerDialog : Adw.Dialog {
        [GtkChild]
        private unowned Gtk.SearchEntry search_entry;
        [GtkChild]
        private unowned Adw.SplitButton new_preset_button;
        [GtkChild]
        private unowned Gtk.ListBox preset_list;
        [GtkChild]
        private unowned Gtk.Label empty_state_label;
        [GtkChild]
        private unowned Gtk.Box detail_box;
        [GtkChild]
        private unowned Gtk.Label preset_name_label;
        [GtkChild]
        private unowned Gtk.Label preset_tempo_label;
        [GtkChild]
        private unowned Gtk.Label preset_time_sig_label;
        [GtkChild]
        private unowned Gtk.Label preset_description_label;
        [GtkChild]
        private unowned Gtk.Button load_button;
        [GtkChild]
        private unowned Gtk.Button rename_button;
        [GtkChild]
        private unowned Gtk.Button duplicate_button;
        [GtkChild]
        private unowned Gtk.Button delete_button;

        private PresetManager preset_manager;
        private Preset? selected_preset = null;
        private Gtk.Window parent_window;

        // Actions for import/export
        private SimpleAction import_action;
        private SimpleAction export_action;
        private SimpleAction export_all_action;

        public signal void preset_loaded(Preset preset);

        public PresetManagerDialog(Gtk.Window parent, PresetManager manager) {
            this.parent_window = parent;
            this.preset_manager = manager;

            setup_signals();
            populate_preset_list();

            // Connect to preset manager signals
            preset_manager.preset_added.connect(() => {
                populate_preset_list();
            });

            preset_manager.preset_updated.connect(() => {
                populate_preset_list();
                if (selected_preset != null) {
                    update_detail_panel();
                }
            });

            preset_manager.preset_deleted.connect((id) => {
                if (selected_preset != null && selected_preset.id == id) {
                    selected_preset = null;
                    update_detail_panel();
                }
                populate_preset_list();
            });
        }

        private void setup_signals() {
            search_entry.search_changed.connect(on_search_changed);
            new_preset_button.clicked.connect(on_new_preset_clicked);
            preset_list.row_selected.connect(on_preset_selected);
            load_button.clicked.connect(on_load_clicked);
            rename_button.clicked.connect(on_rename_clicked);
            duplicate_button.clicked.connect(on_duplicate_clicked);
            delete_button.clicked.connect(on_delete_clicked);

            // Create and add actions for import/export
            var action_group = new SimpleActionGroup();

            import_action = new SimpleAction("import", null);
            import_action.activate.connect(() => on_import_clicked());
            action_group.add_action(import_action);

            export_action = new SimpleAction("export", null);
            export_action.activate.connect(() => on_export_clicked());
            export_action.set_enabled(false);
            action_group.add_action(export_action);

            export_all_action = new SimpleAction("export-all", null);
            export_all_action.activate.connect(() => on_export_all_clicked());
            export_all_action.set_enabled(false);
            action_group.add_action(export_all_action);

            this.insert_action_group("preset", action_group);
        }

        private void populate_preset_list() {
            // Clear existing rows
            Gtk.ListBoxRow? row = preset_list.get_row_at_index(0);
            while (row != null) {
                preset_list.remove(row);
                row = preset_list.get_row_at_index(0);
            }

            var presets = preset_manager.get_all_presets();
            var search_text = search_entry.text.strip().down();

            // Filter by search if needed
            var filtered_presets = new Gee.ArrayList<Preset>();
            foreach (var preset in presets) {
                if (search_text.length == 0 ||
                    preset.name.down().contains(search_text) ||
                    preset.description.down().contains(search_text)) {
                    filtered_presets.add(preset);
                }
            }

            // Show/hide empty state
            empty_state_label.visible = filtered_presets.size == 0;

            // Add rows
            foreach (var preset in filtered_presets) {
                var preset_row = create_preset_row(preset);
                preset_list.append(preset_row);
            }

            // Update action states
            export_all_action.set_enabled(presets.size > 0);
        }

        private Gtk.ListBoxRow create_preset_row(Preset preset) {
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 4);
            box.margin_start = 12;
            box.margin_end = 12;
            box.margin_top = 8;
            box.margin_bottom = 8;

            var name_label = new Gtk.Label(preset.name);
            name_label.halign = Gtk.Align.START;
            name_label.add_css_class("heading");
            box.append(name_label);

            var info_label = new Gtk.Label("%d BPM, %d/%d".printf(
                preset.tempo,
                preset.time_sig_numerator,
                preset.time_sig_denominator
            ));
            info_label.halign = Gtk.Align.START;
            info_label.add_css_class("caption");
            info_label.add_css_class("dim-label");
            box.append(info_label);

            var row = new Gtk.ListBoxRow();
            row.child = box;
            row.set_data("preset_id", preset.id);

            return row;
        }

        private void on_search_changed() {
            populate_preset_list();
        }

        private void on_preset_selected(Gtk.ListBoxRow? row) {
            if (row == null) {
                selected_preset = null;
                update_detail_panel();
                return;
            }

            var preset_id = (string?)row.get_data<string>("preset_id");
            if (preset_id != null) {
                selected_preset = preset_manager.get_preset(preset_id);
                update_detail_panel();
            }
        }

        private void update_detail_panel() {
            bool has_selection = selected_preset != null;

            load_button.sensitive = has_selection;
            rename_button.sensitive = has_selection;
            duplicate_button.sensitive = has_selection;
            delete_button.sensitive = has_selection;
            export_action.set_enabled(has_selection);

            if (selected_preset == null) {
                preset_name_label.label = "—";
                preset_tempo_label.label = "—";
                preset_time_sig_label.label = "—";
                preset_description_label.label = "—";
                return;
            }

            preset_name_label.label = selected_preset.name;
            preset_tempo_label.label = "%d BPM".printf(selected_preset.tempo);
            preset_time_sig_label.label = "%d/%d".printf(
                selected_preset.time_sig_numerator,
                selected_preset.time_sig_denominator
            );
            preset_description_label.label = selected_preset.description.length > 0
                ? selected_preset.description : "—";
        }

        private void on_new_preset_clicked() {
            show_save_preset_dialog();
        }

        private void on_load_clicked() {
            if (selected_preset == null) return;

            try {
                preset_manager.apply_preset(selected_preset.id);
                preset_loaded(selected_preset);
                show_toast("Loaded preset '%s'".printf(selected_preset.name));
            } catch (PresetError e) {
                show_error_dialog("Failed to load preset", e.message);
            }
        }

        private void on_rename_clicked() {
            if (selected_preset == null) return;

            var entry = new Gtk.Entry();
            entry.text = selected_preset.name;
            entry.width_chars = 30;

            var dialog = new Adw.AlertDialog(
                "Rename Preset",
                "Enter a new name for this preset:"
            );
            dialog.set_extra_child(entry);
            dialog.add_response("cancel", "Cancel");
            dialog.add_response("rename", "Rename");
            dialog.set_response_appearance("rename", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response("rename");

            dialog.response.connect((response_id) => {
                if (response_id == "rename") {
                    var new_name = entry.text.strip();
                    if (new_name.length > 0) {
                        try {
                            preset_manager.rename_preset(selected_preset.id, new_name);
                            show_toast("Preset renamed");
                        } catch (PresetError e) {
                            show_error_dialog("Failed to rename preset", e.message);
                        }
                    }
                }
            });

            dialog.present(this.parent_window);
        }

        private void on_duplicate_clicked() {
            if (selected_preset == null) return;

            try {
                var duplicate = preset_manager.duplicate_preset(selected_preset.id);
                if (duplicate != null) {
                    show_toast("Preset duplicated");
                    populate_preset_list();
                }
            } catch (PresetError e) {
                show_error_dialog("Failed to duplicate preset", e.message);
            }
        }

        private void on_delete_clicked() {
            if (selected_preset == null) return;

            var dialog = new Adw.AlertDialog(
                "Delete Preset?",
                "Are you sure you want to delete '%s'? This cannot be undone.".printf(selected_preset.name)
            );
            dialog.add_response("cancel", "Cancel");
            dialog.add_response("delete", "Delete");
            dialog.set_response_appearance("delete", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.set_default_response("cancel");

            dialog.response.connect((response_id) => {
                if (response_id == "delete") {
                    try {
                        preset_manager.delete_preset(selected_preset.id);
                        show_toast("Preset deleted");
                        selected_preset = null;
                        update_detail_panel();
                    } catch (PresetError e) {
                        show_error_dialog("Failed to delete preset", e.message);
                    }
                }
            });

            dialog.present(this.parent_window);
        }

        private void on_import_clicked() {
            var file_dialog = new Gtk.FileDialog();
            file_dialog.title = "Import Presets";

            var filter = new Gtk.FileFilter();
            filter.name = "JSON Files";
            filter.add_pattern("*.json");

            var filters = new ListStore(typeof(Gtk.FileFilter));
            filters.append(filter);
            file_dialog.filters = filters;

            file_dialog.open.begin(this.parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end(res);
                    if (file != null) {
                        import_from_file(file.get_path());
                    }
                } catch (Error e) {
                    // User cancelled
                }
            });
        }

        private void import_from_file(string file_path) {
            var dialog = new Adw.AlertDialog(
                "Import Mode",
                "Do you want to merge imported presets with existing ones, or replace all presets?"
            );
            dialog.add_response("cancel", "Cancel");
            dialog.add_response("merge", "Merge");
            dialog.add_response("replace", "Replace");
            dialog.set_response_appearance("replace", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.set_default_response("merge");

            dialog.response.connect((response_id) => {
                if (response_id == "cancel") return;

                bool merge = response_id == "merge";
                try {
                    int count = preset_manager.import_presets(file_path, merge);
                    show_toast("Imported %d preset(s)".printf(count));
                    populate_preset_list();
                } catch (PresetError e) {
                    show_error_dialog("Failed to import presets", e.message);
                }
            });

            dialog.present(this.parent_window);
        }

        private void on_export_clicked() {
            if (selected_preset == null) return;

            var file_dialog = new Gtk.FileDialog();
            file_dialog.title = "Export Preset";
            file_dialog.initial_name = "%s.json".printf(selected_preset.name);

            file_dialog.save.begin(this.parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.save.end(res);
                    if (file != null) {
                        preset_manager.export_preset(selected_preset.id, file.get_path());
                        show_toast("Preset exported");
                    }
                } catch (Error e) {
                    if (!(e is Gtk.DialogError.DISMISSED)) {
                        show_error_dialog("Failed to export preset", e.message);
                    }
                }
            });
        }

        private void on_export_all_clicked() {
            var file_dialog = new Gtk.FileDialog();
            file_dialog.title = "Export All Presets";
            var timestamp = new DateTime.now_local().format("%Y%m%d");
            file_dialog.initial_name = "tempo-presets-%s.json".printf(timestamp);

            file_dialog.save.begin(this.parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.save.end(res);
                    if (file != null) {
                        preset_manager.export_presets(file.get_path());
                        var count = preset_manager.get_all_presets().size;
                        show_toast("Exported %d preset(s)".printf(count));
                    }
                } catch (Error e) {
                    if (!(e is Gtk.DialogError.DISMISSED)) {
                        show_error_dialog("Failed to export presets", e.message);
                    }
                }
            });
        }

        private void show_save_preset_dialog() {
            var name_entry = new Gtk.Entry();
            name_entry.placeholder_text = "Preset name";
            name_entry.width_chars = 30;

            var desc_entry = new Gtk.Entry();
            desc_entry.placeholder_text = "Description (optional)";
            desc_entry.width_chars = 30;

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            box.append(name_entry);
            box.append(desc_entry);

            var settings = new GLib.Settings(Config.APP_ID);
            var info_label = new Gtk.Label("This preset will save:\n• Tempo: %d BPM\n• Time Signature: %d/%d\n• Audio & Visual Settings".printf(
                settings.get_int("tempo"),
                settings.get_int("time-signature-numerator"),
                settings.get_int("time-signature-denominator")
            ));
            info_label.add_css_class("caption");
            info_label.add_css_class("dim-label");
            info_label.justify = Gtk.Justification.LEFT;
            box.append(info_label);

            var dialog = new Adw.AlertDialog(
                "Save Preset",
                "Enter a name for this preset:"
            );
            dialog.set_extra_child(box);
            dialog.add_response("cancel", "Cancel");
            dialog.add_response("save", "Save");
            dialog.set_response_appearance("save", Adw.ResponseAppearance.SUGGESTED);
            dialog.set_default_response("save");

            dialog.response.connect((response_id) => {
                if (response_id == "save") {
                    var name = name_entry.text.strip();
                    var description = desc_entry.text.strip();

                    if (name.length == 0) {
                        show_error_dialog("Invalid Name", "Preset name cannot be empty.");
                        return;
                    }

                    try {
                        var preset = preset_manager.create_from_current_settings(name, description);
                        preset_manager.add_preset(preset);
                        show_toast("Preset '%s' saved".printf(name));
                        populate_preset_list();
                    } catch (PresetError e) {
                        show_error_dialog("Failed to save preset", e.message);
                    }
                }
            });

            dialog.present(this.parent_window);
        }

        private void show_toast(string message) {
            var toast = new Adw.Toast(message);
            toast.timeout = 2;

            // Try to show toast on parent window if it's an AdwApplicationWindow
            if (parent_window is Adw.ApplicationWindow) {
                var adw_window = (Adw.ApplicationWindow) parent_window;
                var overlay = adw_window.content as Adw.ToastOverlay;
                if (overlay != null) {
                    overlay.add_toast(toast);
                }
            }
        }

        private void show_error_dialog(string title, string message) {
            var dialog = new Adw.AlertDialog(title, message);
            dialog.add_response("ok", "OK");
            dialog.set_default_response("ok");
            dialog.present(this.parent_window);
        }
    }
