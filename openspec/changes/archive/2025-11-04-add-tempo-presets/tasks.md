# Implementation Tasks

## Phase 1: Core Data Structures

### Task 1: Create Preset class
- [x] Create `src/utils/Preset.vala` with class definition
- [x] Define all properties: id, name, description, timestamps, schema_version
- [x] Define core metronome properties: tempo, time_sig_numerator, time_sig_denominator
- [x] Define optional feature properties: subdivision_*, trainer_*, with nullable types
- [x] Define audio properties: click_volume, accent_volume, sound_types
- [x] Define visual properties: show_beat_numbers, flash_on_beat, downbeat_color
- [x] Add constructor with default values
- [x] Add to `src/utils/meson.build`

**Validation**: File compiles, Preset objects can be instantiated

**Dependencies**: None

---

### Task 2: Implement Preset JSON serialization
- [x] Add `to_json() -> Json.Node` method to Preset
- [x] Use Json.Builder to construct JSON object
- [x] Include all properties (skip null optional properties)
- [x] Format timestamps as int64
- [x] Ensure valid JSON structure

**Validation**:
- Create preset, call to_json(), verify JSON structure
- Null optional properties not included in output

**Dependencies**: Task 1

---

### Task 3: Implement Preset JSON deserialization
- [x] Add `from_json(Json.Node node) -> Preset` static method
- [x] Parse JSON object using Json.Reader
- [x] Extract all required properties
- [x] Handle optional properties gracefully (null if missing)
- [x] Throw PresetError.PARSE_ERROR on invalid JSON
- [x] Validate data types match expected

**Validation**:
- Round-trip test: preset.to_json().from_json() == original preset
- Invalid JSON throws appropriate error
- Missing optional fields → null values

**Dependencies**: Task 2

---

## Phase 2: Preset Manager

### Task 4: Create PresetManager class skeleton
- [x] Create `src/utils/PresetManager.vala`
- [x] Define PresetManager class extending GLib.Object
- [x] Add private ArrayList<Preset> for storage
- [x] Add file_path property (~/config/tempo/presets.json)
- [x] Define PresetError errordomain
- [x] Define PresetSortOrder enum
- [x] Define signal declarations: preset_added, preset_updated, preset_deleted, presets_loaded
- [x] Add to `src/utils/meson.build`

**Validation**: File compiles, PresetManager can be instantiated

**Dependencies**: Task 1

---

### Task 5: Implement preset CRUD operations
- [x] Implement `add_preset(Preset preset) -> bool`
  - Validate name unique
  - Check max limit (100)
  - Add to ArrayList
  - Return true on success
- [x] Implement `get_preset(string id) -> Preset?`
  - Search ArrayList by ID
  - Return preset or null
- [x] Implement `get_all_presets() -> List<Preset>`
  - Return copy of presets list
- [x] Implement `update_preset(Preset preset) -> bool`
  - Find by ID, replace with updated preset
- [x] Implement `delete_preset(string id) -> bool`
  - Remove from ArrayList by ID
- [x] Implement `rename_preset(string id, string new_name) -> bool`
  - Validate new name unique
  - Update preset name
- [x] Implement `duplicate_preset(string id) -> Preset?`
  - Create copy with new ID, "(Copy)" suffix

**Validation**:
- Add/get/update/delete all work correctly
- Edge cases handled (not found, duplicates)

**Dependencies**: Task 4

---

### Task 6: Implement preset file I/O
- [x] Implement `save_presets() -> bool`
  - Serialize all presets to JSON array
  - Write to presets_file_path
  - Create parent directory if doesn't exist
  - Handle IOException
- [x] Implement `load_presets() -> bool`
  - Check if file exists
  - Parse JSON file
  - Deserialize each preset
  - Handle parse errors gracefully
  - If file corrupted: backup and start fresh
- [x] Call load_presets() in constructor

**Validation**:
- Save creates valid JSON file
- Load restores presets correctly
- Corrupted file handled without crash

**Dependencies**: Task 3, Task 5

---

### Task 7: Implement name validation and utilities
- [x] Implement `validate_preset_name(string name) -> bool`
  - Check not empty
  - Check no path separators (/, \, :)
  - Check name unique in existing presets
- [x] Implement `generate_unique_name(string base) -> string`
  - Append "(2)", "(3)", etc. until unique
- [x] Implement `search_presets(string query) -> List<Preset>`
  - Filter by name (case-insensitive contains)
- [x] Implement `sort_presets(PresetSortOrder order)`
  - Sort ArrayList by specified order
  - NAME_ASC, NAME_DESC, CREATED_DATE, LAST_USED, TEMPO

**Validation**:
- Validation catches invalid names
- Unique name generation works
- Search filters correctly
- Sorting works for all orders

**Dependencies**: Task 5

---

### Task 8: Implement preset creation from current settings
- [x] Add method: `create_from_current_settings(string name, string desc) -> Preset`
- [x] Create new Preset object
- [x] Generate UUID for id
- [x] Read all GSettings values
- [x] Set core settings: tempo, time signature
- [x] Check if subdivision settings exist, read if so
- [x] Check if trainer settings exist, read if so
- [x] Set audio and visual settings
- [x] Set timestamps (created_at, last_used_at)
- [x] Return populated preset

**Validation**:
- Created preset contains all current settings
- Optional features handled correctly (null if not present)

**Dependencies**: Task 1, Task 5

---

### Task 9: Implement preset application to settings
- [x] Add method: `apply_preset(string id) -> bool`
- [x] Get preset by ID
- [x] Apply core settings to GSettings: tempo, time signature
- [x] If preset has subdivision settings and feature exists: apply them
- [x] If preset has trainer settings and feature exists: apply them
- [x] Apply audio and visual settings
- [x] Update preset.last_used_at timestamp
- [x] Save presets.json
- [x] Return true on success

**Validation**:
- All applicable settings applied correctly
- Missing features handled gracefully
- Settings propagate to MetronomeEngine and UI

**Dependencies**: Task 5, Task 8

---

## Phase 3: Import/Export

### Task 10: Implement preset export
- [ ] Implement `export_presets(string file_path) -> bool`
  - Serialize all presets to JSON
  - Write to specified file
  - Handle IOException
- [x] Implement `export_preset(string id, string file_path) -> bool`
  - Get single preset by ID
  - Serialize to JSON (array with one item)
  - Write to file

**Validation**:
- Exported JSON file valid and human-readable
- File can be reimported

**Dependencies**: Task 2, Task 6

---

### Task 11: Implement preset import
- [x] Implement `import_presets(string file_path, bool merge) -> int`
  - Parse JSON file
  - Validate format (version, presets array)
  - Check schema_version, migrate if needed
  - If merge=true: add to existing presets, handle name conflicts
  - If merge=false: replace existing presets (after confirmation)
  - Save to presets.json
  - Return count of imported presets
- [x] Implement `migrate_preset_v1_to_v2()` placeholder for future
  - Currently just returns preset as-is

**Validation**:
- Valid preset file imports successfully
- Merge adds without duplicates
- Replace clears and adds
- Name conflicts resolved

**Dependencies**: Task 3, Task 6

---

## Phase 4: Preset Manager Dialog UI

### Task 12: Create PresetManagerDialog Blueprint
- [ ] Create `data/ui/preset_manager_dialog.blp`
- [x] Define AdwDialog with title "Tempo Presets"
- [x] Add search entry at top
- [x] Add "+ New" button
- [x] Create two-pane layout:
  - Left: ListView for presets with ID "preset-list-view"
  - Right: Detail panel with ID "preset-detail-panel"
- [x] Detail panel contains:
  - Name label
  - Description label
  - Settings labels (tempo, time sig, subdivisions, trainer)
  - Timestamps (created, last used)
  - Action buttons: Load, Rename, Duplicate, Delete
- [x] Bottom bar with: Import, Export, Export All, Close buttons

**Validation**: Blueprint compiles, dialog appears

**Dependencies**: None (parallelizable with Phase 1-3)

---

### Task 13: Create PresetManagerDialog Vala class
- [x] Create `src/dialogs/PresetManagerDialog.vala`
- [x] Extend Adw.Dialog
- [x] Add template annotations for widgets
- [x] Add PresetManager member variable
- [x] Implement constructor: takes PresetManager parameter
- [x] Bind template children: list view, detail panel, search entry, buttons
- [x] Add to `src/dialogs/meson.build`

**Validation**: Dialog class compiles, can be instantiated

**Dependencies**: Task 12

---

### Task 14: Implement preset list population
- [x] Create ListStore for presets
- [x] Implement `populate_list()` method
  - Get all presets from PresetManager
  - Create list items showing: name, tempo, time signature
  - Bind to ListView
- [x] Connect to preset_added/deleted signals
  - Refresh list when presets change
- [x] Implement selection handling
  - On row selected: show details in right panel

**Validation**:
- List shows all presets
- Selecting preset shows details
- List updates on add/delete

**Dependencies**: Task 13, Task 5

---

### Task 15: Implement search functionality
- [x] Connect search entry "search-changed" signal
- [x] Implement `on_search_changed()` handler
  - Get search query
  - Filter presets using PresetManager.search_presets()
  - Update list to show only matches
  - Update count label: "X of Y presets"
- [x] Clear search resets to all presets

**Validation**: Search filters list correctly, count updates

**Dependencies**: Task 14, Task 7

---

### Task 16: Implement preset actions in dialog
- [x] Connect "Load" button to `on_load_clicked()`
  - Get selected preset ID
  - Call PresetManager.apply_preset()
  - Show toast "Loaded [name]"
  - Close dialog (optional: setting to stay open)
- [x] Connect "Rename" button to `on_rename_clicked()`
  - Show rename dialog with current name
  - Validate new name
  - Call PresetManager.rename_preset()
  - Refresh list
- [x] Connect "Duplicate" button to `on_duplicate_clicked()`
  - Call PresetManager.duplicate_preset()
  - Select duplicated preset in list
- [x] Connect "Delete" button to `on_delete_clicked()`
  - Show confirmation dialog
  - Call PresetManager.delete_preset()
  - Select next preset in list

**Validation**: All CRUD operations work from dialog

**Dependencies**: Task 14, Task 5, Task 9

---

### Task 17: Implement import/export UI in dialog
- [x] Connect "Import" button to `on_import_clicked()`
  - Show file chooser dialog (open)
  - On file selected: show "Merge or Replace?" dialog
  - Call PresetManager.import_presets()
  - Refresh list
  - Show toast: "Imported X presets"
- [x] Connect "Export All" button to `on_export_all_clicked()`
  - Show file chooser dialog (save)
  - Default filename: tempo-presets-YYYYMMDD.json
  - Call PresetManager.export_presets()
  - Show toast: "Exported X presets"
- [x] Connect "Export" button (single preset) to `on_export_clicked()`
  - Show file chooser
  - Call PresetManager.export_preset()

**Validation**: Import and export work correctly from UI

**Dependencies**: Task 16, Task 10, Task 11

---

### Task 18: Implement sorting in preset manager
- [x] Add sort dropdown to dialog toolbar
- [x] Options: Name (A-Z), Name (Z-A), Last Used, Created Date, Tempo
- [x] Connect to `on_sort_changed()`
  - Call PresetManager.sort_presets()
  - Refresh list
- [x] Remember sort preference in GSettings

**Validation**: Sorting changes list order correctly

**Dependencies**: Task 14, Task 7

---

## Phase 5: Quick-Load Integration (Main Window)

### Task 19: Add preset dropdown to main window Blueprint
- [ ] Open `data/ui/main_window.blp`
- [ ] Add horizontal box below tempo controls
- [x] Add Label: "Presets:"
- [x] Add AdwComboRow with ID "preset-quick-load-combo"
- [x] Add Button: "Save Preset" (💾 icon) with ID "save-preset-button"
- [x] Add Button: "Manage" (⚙️ icon) with ID "manage-presets-button"
- [x] Make section collapsible/hideable

**Validation**: UI compiles, preset controls appear in main window

**Dependencies**: None (parallelizable)

---

### Task 20: Populate quick-load dropdown
- [x] In `src/windows/MainWindow.vala`: add template children for preset widgets
- [x] Add PresetManager member variable
- [x] Implement `populate_preset_dropdown()`
  - Get recent presets (5 most recent by last_used_at)
  - Add separator
  - Get all presets (sorted alphabetically)
  - Add separator
  - Add "Manage Presets..." option
  - Populate combo row model
- [x] Call on app start and when presets change

**Validation**: Dropdown shows recent + all presets

**Dependencies**: Task 19, Task 5

---

### Task 21: Implement quick-load preset application
- [x] Connect combo row "notify::selected-item" signal
- [x] Implement `on_preset_quick_load()`
  - Get selected preset ID
  - If "Manage Presets..." selected: open dialog, return
  - Call PresetManager.apply_preset()
  - Show toast "Loaded [name]"
  - Move preset to top of recent list

**Validation**:
- Selecting preset applies settings
- Toast appears
- Recent list updates

**Dependencies**: Task 20, Task 9

---

### Task 22: Implement "Save Preset" quick dialog
- [x] Create simple AdwMessageDialog for quick save
- [x] Fields: Name entry, Description entry (optional)
- [x] Show current settings preview (tempo, time sig, etc.)
- [x] Connect "Save Preset" button click to `on_save_preset_quick()`
  - Show dialog
  - On save: create preset from current settings
  - Validate name
  - Add to PresetManager
  - Refresh dropdown
  - Show toast

**Validation**: Quick save creates preset correctly

**Dependencies**: Task 20, Task 8

---

### Task 23: Implement "Manage Presets" button
- [x] Connect button click to `on_manage_presets_clicked()`
  - Create PresetManagerDialog instance
  - Pass PresetManager reference
  - Show dialog modally
  - On dialog close: refresh dropdown (presets may have changed)

**Validation**: Button opens full preset manager dialog

**Dependencies**: Task 20, Task 13

---

## Phase 6: Settings & Persistence

### Task 24: Add preset-related GSettings keys
- [x] Open `data/io.github.tobagin.tempo.gschema.xml.in`
- [x] Add `preset-sort-order` integer key (default: 0 for NAME_ASC)
- [x] Add `preset-quick-load-visible` boolean key (default: true)
- [x] Add `preset-manager-last-selected` string key (default: "")
- [x] Optional: `preset-default-on-startup` string key for default preset

**Validation**: Schema compiles, settings accessible

**Dependencies**: None

---

### Task 25: Implement preset limits
- [ ] In PresetManager.add_preset(): check count
- [ ] If count == 50: show warning dialog (non-blocking)
  - "You have 50 presets. Consider organizing or deleting unused ones."
- [ ] If count >= 100: show error dialog
  - "Maximum 100 presets reached. Delete unused presets to add more."
  - Return false (prevent addition)

**Validation**:
- Warning at 50
- Hard limit at 100

**Dependencies**: Task 5

---

## Phase 7: Validation & Error Handling

### Task 26: Implement comprehensive name validation
- [ ] In validate_preset_name(): check empty
- [ ] Check length (max 100 characters)
- [ ] Check for path separators: / \ : * ? " < > |
- [ ] Check uniqueness against existing presets
- [ ] Return specific error messages for each case

**Validation**: All invalid names rejected with clear errors

**Dependencies**: Task 7

---

### Task 27: Implement file I/O error handling
- [ ] Wrap file operations in try/catch
- [ ] Catch FileError, IOError
- [ ] On save failure:
  - Show error dialog with reason
  - Keep presets in memory
  - Retry on next operation
- [ ] On load failure (corrupted file):
  - Create backup: presets.json.corrupt.TIMESTAMP
  - Start with empty list
  - Show error dialog with backup location

**Validation**: File errors don't crash app, data preserved

**Dependencies**: Task 6

---

### Task 28: Implement preset validation on load
- [ ] In Preset.from_json(): validate all required fields present
- [ ] Clamp tempo to 40-240 range
- [ ] Validate time signature (numerator 1-16, denominator 2/4/8/16)
- [ ] Validate volumes 0.0-1.0
- [ ] If validation fails: throw PresetError with details
- [ ] In PresetManager.load_presets(): catch preset errors
  - Skip invalid presets
  - Log which presets skipped
  - Continue loading valid ones

**Validation**:
- Invalid presets don't break loading
- Valid presets load correctly

**Dependencies**: Task 3

---

### Task 29: Implement import validation
- [ ] In import_presets(): validate JSON structure
  - Check "version" field exists
  - Check "presets" array exists
  - Validate each preset individually
- [ ] Show detailed error if invalid:
  - "Invalid preset file: [specific reason]"
- [ ] Handle schema version mismatches:
  - If older version: migrate
  - If newer version: show error (can't load future presets)

**Validation**: Invalid import files rejected clearly

**Dependencies**: Task 11

---

## Phase 8: Testing

### Task 30: Unit test Preset serialization
- [ ] Test to_json() creates valid JSON
- [ ] Test from_json() parses correctly
- [ ] Test round-trip: preset → JSON → preset
- [ ] Test with all optional fields null
- [ ] Test with all optional fields populated

**Validation**: Serialization works in all cases

**Dependencies**: Task 2, Task 3

---

### Task 31: Unit test PresetManager CRUD
- [ ] Test add_preset() adds to list
- [ ] Test get_preset() retrieves by ID
- [ ] Test update_preset() modifies existing
- [ ] Test delete_preset() removes from list
- [ ] Test name uniqueness validation
- [ ] Test duplicate_preset() creates copy with unique name

**Validation**: All CRUD operations work correctly

**Dependencies**: Task 5

---

### Task 32: Integration test file persistence
- [ ] Create preset, save
- [ ] Read file directly, verify JSON format
- [ ] Delete presets.json, restart PresetManager
- [ ] Verify starts with empty list
- [ ] Add presets, save, create new PresetManager instance
- [ ] Verify presets loaded from file

**Validation**: Persistence works across sessions

**Dependencies**: Task 6

---

### Task 33: Integration test import/export
- [ ] Export presets to file
- [ ] Clear PresetManager
- [ ] Import from file (merge mode)
- [ ] Verify all presets restored
- [ ] Test export single preset
- [ ] Import into PresetManager with existing presets (merge)
- [ ] Verify name conflict resolution

**Validation**: Import/export roundtrip works

**Dependencies**: Task 10, Task 11

---

### Task 34: Integration test UI interactions
- [ ] Open preset manager dialog
- [ ] Create preset via "+ New" button
- [ ] Verify appears in list
- [ ] Select preset, click "Load"
- [ ] Verify settings applied to metronome
- [ ] Rename preset
- [ ] Delete preset with confirmation

**Validation**: All UI operations functional

**Dependencies**: Task 16, Task 17

---

### Task 35: Manual testing checklist
- [ ] Save preset with basic settings (tempo, time sig)
- [ ] Save preset with subdivisions enabled
- [ ] Save preset with tempo trainer configured
- [ ] Load preset from quick-load dropdown
- [ ] Verify all settings applied correctly
- [ ] Open preset manager dialog
- [ ] Search presets by name
- [ ] Sort presets (by name, date, tempo, last used)
- [ ] Rename preset in manager
- [ ] Duplicate preset
- [ ] Delete preset with confirmation
- [ ] Try duplicate name (verify rejection)
- [ ] Export all presets to file
- [ ] Import presets (merge mode)
- [ ] Import presets (replace mode)
- [ ] Test with 50 presets (warning appears)
- [ ] Test with 100 presets (limit enforced)
- [ ] Corrupt presets.json file manually
- [ ] Restart app, verify graceful handling
- [ ] Load preset without subdivisions feature (graceful skip)
- [ ] Recent presets update on load
- [ ] Settings persist across app restart

**Validation**: All manual tests pass

**Dependencies**: All previous implementation tasks

---

### Task 36: Performance testing
- [ ] Load 100 presets, measure startup time
- [ ] Verify < 10ms parse time
- [ ] Apply preset, measure time
- [ ] Verify < 5ms application time
- [ ] Search 100 presets
- [ ] Verify < 10ms filter time
- [ ] Verify no memory leaks over extended use

**Validation**: Performance meets targets

**Dependencies**: Task 35

---

## Phase 9: Documentation & Polish

### Task 37: Code review and cleanup
- [ ] Review all code for project conventions
- [ ] Ensure PascalCase for classes, snake_case for methods
- [ ] Verify no file exceeds 500 lines
- [ ] Add comprehensive comments explaining logic
- [ ] Document JSON format with examples
- [ ] Verify error handling comprehensive
- [ ] Remove debug logging
- [ ] Check all method signatures clear

**Validation**: Code meets project style guidelines

**Dependencies**: All implementation tasks

---

### Task 38: Update CHANGELOG.md
- [x] Add entry under "## [Unreleased]"
- [x] Document feature: "Added Tempo Presets"
- [x] List capabilities:
  - Save/load complete metronome configurations
  - Preset manager dialog
  - Quick-load dropdown
  - Import/export presets
- [x] Note preset file location (~/.config/tempo/presets.json)

**Validation**: CHANGELOG accurate

**Dependencies**: Task 37

---

### Task 39: Update user documentation
- [ ] Add "Presets" section to README.md (if applicable)
- [ ] Explain use case: save configurations for different pieces
- [ ] Document how to save preset
- [ ] Document how to load preset (quick-load and manager)
- [ ] Document import/export for backup/sharing
- [ ] Document preset file format (for advanced users)
- [ ] Add FAQ: "How many presets can I save?" (100 max)

**Validation**: Documentation clear for end users

**Dependencies**: Task 37

---

## Estimated Effort

- **Phase 1 (Data Structures)**: 4-6 hours
- **Phase 2 (Preset Manager)**: 8-12 hours
- **Phase 3 (Import/Export)**: 3-4 hours
- **Phase 4 (Dialog UI)**: 8-12 hours
- **Phase 5 (Quick-Load Integration)**: 4-6 hours
- **Phase 6 (Settings & Persistence)**: 2-3 hours
- **Phase 7 (Validation/Errors)**: 4-6 hours
- **Phase 8 (Testing)**: 10-14 hours
- **Phase 9 (Documentation)**: 2-3 hours

**Total Estimated Effort**: 45-66 hours

## Parallelization Opportunities

These tasks can be worked on in parallel:

- **Track A (Core)**: Phase 1 → Phase 2 → Phase 3 → Integration
- **Track B (UI)**: Phase 4 → Phase 5 → Integration
- **Track C (Settings)**: Phase 6 → Integration
- **Track D (Documentation)**: Can start alongside implementation

## Success Criteria

All tasks completed AND:
- ✅ Users can save current settings as named preset
- ✅ Users can load presets from quick-load dropdown
- ✅ Preset manager dialog provides full CRUD operations
- ✅ Presets persist across app restarts
- ✅ Import/export works for backup and sharing
- ✅ All validation prevents invalid operations
- ✅ Error handling graceful (no crashes)
- ✅ Recent presets tracked correctly
- ✅ Works with all features (subdivisions, trainer, timer)
- ✅ All manual, integration, and unit tests pass
- ✅ Performance targets met (< 10ms load, < 5ms apply)
- ✅ UI clean and intuitive
- ✅ Code follows project conventions
- ✅ Documentation updated

## Dependencies on Other Features

- **None**: This feature is independent
- **Enhances**: Works seamlessly with subdivisions, tempo trainer, practice timer
- **Complements**: Export/Import Settings (Feature #5) - shared infrastructure
- **Foundation for**: Future features could extend presets (categories, cloud sync)
