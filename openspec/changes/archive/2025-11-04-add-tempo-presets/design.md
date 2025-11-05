# Tempo Presets Design

## Architecture Overview

The tempo presets feature adds a flexible preset management system that saves and restores complete metronome configurations. The design uses JSON file storage for easy import/export and schema evolution, with a dedicated manager class handling all preset operations.

## Core Concepts

### What is a Preset?
A preset is a named snapshot of the complete metronome configuration at a given moment, including:
- **Core Settings**: Tempo (BPM), Time Signature
- **Subdivision Settings**: Mode, volume, sound type (if feature implemented)
- **Tempo Trainer Settings**: Start/target/increment/interval config (if feature implemented)
- **Audio Settings**: Click volume, accent volume, sound types
- **Visual Settings**: Beat numbers, flash on beat, downbeat color
- **Metadata**: Preset name, description, creation date, last used date

### Preset Use Cases
1. **Multiple Pieces**: "Bach Invention #1 (Practice)", "Bach Invention #1 (Performance Tempo)"
2. **Exercise Routines**: "Warm-up", "Speed Drills", "Sight Reading"
3. **Different Styles**: "Jazz Swing (120 BPM)", "Classical 3/4", "Odd Meter Practice"
4. **Students**: Teachers can share presets with students

## Core Components

### 1. Preset Data Structure

```vala
public class Preset : GLib.Object {
    // Metadata
    public string id { get; set; }           // UUID for internal identification
    public string name { get; set; }         // User-visible name
    public string description { get; set; }  // Optional description
    public int64 created_at { get; set; }    // Unix timestamp
    public int64 last_used_at { get; set; }  // Unix timestamp
    public int schema_version { get; set; }  // For migration (current: 1)

    // Core metronome settings
    public int tempo { get; set; }                    // BPM
    public int time_sig_numerator { get; set; }       // Beats per measure
    public int time_sig_denominator { get; set; }     // Note value

    // Subdivision settings (optional, null if not implemented)
    public int? subdivision_mode { get; set; }        // 0=None, 2=8ths, 3=Triplets, 4=16ths
    public double? subdivision_volume { get; set; }   // 0.0-1.0
    public string? subdivision_sound_type { get; set; }

    // Tempo trainer settings (optional, null if not implemented)
    public int? trainer_start_tempo { get; set; }
    public int? trainer_target_tempo { get; set; }
    public int? trainer_increment { get; set; }
    public int? trainer_interval_type { get; set; }   // 0=Bars, 1=Seconds
    public int? trainer_interval_value { get; set; }
    public bool? trainer_auto_stop { get; set; }

    // Audio settings
    public double click_volume { get; set; }
    public double accent_volume { get; set; }
    public string high_sound_type { get; set; }       // "default", "woodblock", "metal", "digital"
    public string low_sound_type { get; set; }
    // Note: Custom sound file paths NOT saved (system-specific)

    // Visual settings
    public bool show_beat_numbers { get; set; }
    public bool flash_on_beat { get; set; }
    public bool downbeat_color { get; set; }

    // Serialization
    public Json.Node to_json();
    public static Preset from_json(Json.Node node) throws PresetError;
}
```

### 2. PresetManager Class (`src/utils/PresetManager.vala`)

```vala
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

    // Constructor
    public PresetManager() {
        presets = new Gee.ArrayList<Preset>();
        presets_file_path = Path.build_filename(
            Environment.get_user_config_dir(),
            "tempo",
            "presets.json"
        );
        load_presets();
    }

    // CRUD Operations
    public bool add_preset(Preset preset) throws PresetError;
    public Preset? get_preset(string id);
    public Gee.List<Preset> get_all_presets();
    public bool update_preset(Preset preset) throws PresetError;
    public bool delete_preset(string id) throws PresetError;
    public bool rename_preset(string id, string new_name) throws PresetError;
    public Preset? duplicate_preset(string id) throws PresetError;

    // Persistence
    public bool save_presets() throws PresetError;
    public bool load_presets() throws PresetError;

    // Import/Export
    public bool export_presets(string file_path) throws PresetError;
    public int import_presets(string file_path, bool merge) throws PresetError;
    public bool export_preset(string preset_id, string file_path) throws PresetError;

    // Utilities
    public bool validate_preset_name(string name);
    public string generate_unique_name(string base_name);
    public Gee.List<Preset> search_presets(string query);
    public void sort_presets(PresetSortOrder order);
}

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

public errordomain PresetError {
    INVALID_NAME,
    DUPLICATE_NAME,
    NOT_FOUND,
    MAX_PRESETS_REACHED,
    FILE_IO_ERROR,
    PARSE_ERROR,
    VALIDATION_ERROR
}
```

### 3. Storage Format (JSON)

**File Location**: `~/.config/tempo/presets.json`

**Format**:
```json
{
  "version": 1,
  "presets": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "Bach Invention #1",
      "description": "Practice tempo for BWV 772",
      "created_at": 1704067200,
      "last_used_at": 1704153600,
      "schema_version": 1,

      "tempo": 80,
      "time_sig_numerator": 4,
      "time_sig_denominator": 4,

      "subdivision_mode": 2,
      "subdivision_volume": 0.5,
      "subdivision_sound_type": "default",

      "trainer_start_tempo": 60,
      "trainer_target_tempo": 120,
      "trainer_increment": 5,
      "trainer_interval_type": 0,
      "trainer_interval_value": 8,
      "trainer_auto_stop": false,

      "click_volume": 0.8,
      "accent_volume": 1.0,
      "high_sound_type": "woodblock",
      "low_sound_type": "woodblock",

      "show_beat_numbers": true,
      "flash_on_beat": true,
      "downbeat_color": true
    },
    {
      "id": "650e8400-e29b-41d4-a716-446655440001",
      "name": "Jazz Swing",
      "description": "Medium swing tempo with triplets",
      "created_at": 1704153600,
      "last_used_at": 1704240000,
      "schema_version": 1,

      "tempo": 120,
      "time_sig_numerator": 4,
      "time_sig_denominator": 4,

      "subdivision_mode": 3,
      "subdivision_volume": 0.4,
      "subdivision_sound_type": "default",

      "click_volume": 0.7,
      "accent_volume": 0.9,
      "high_sound_type": "default",
      "low_sound_type": "default",

      "show_beat_numbers": true,
      "flash_on_beat": true,
      "downbeat_color": true
    }
  ]
}
```

**Why JSON over GSettings?**
- **Easier Export/Import**: Single file contains all presets
- **Schema Evolution**: Versioning allows graceful migration
- **Portability**: Share presets between users/systems
- **Flexibility**: Can add arbitrary metadata without schema changes
- **Debugging**: Human-readable format

### 4. Preset Versioning & Migration

#### Version 1 (Initial)
Current schema as defined above.

#### Future Migration Example (Version 2)
```vala
private Preset migrate_v1_to_v2(Json.Object v1_obj) {
    // Example: v2 adds "favorite" boolean field
    var preset = Preset.from_json_v1(v1_obj);
    preset.schema_version = 2;
    preset.is_favorite = false;  // Default for migrated presets
    return preset;
}

public bool load_presets() throws PresetError {
    // ...parse JSON...
    int file_version = root_obj.get_int_member("version");

    foreach (var preset_node in presets_array) {
        var preset_obj = preset_node.get_object();
        int preset_version = preset_obj.get_int_member("schema_version");

        Preset preset;
        if (preset_version == 1 && CURRENT_SCHEMA_VERSION == 2) {
            preset = migrate_v1_to_v2(preset_obj);
        } else {
            preset = Preset.from_json(preset_node);
        }

        presets.add(preset);
    }
}
```

### 5. Creating Presets from Current State

```vala
public class PresetManager {
    public Preset create_from_current_settings(string name, string description = "") {
        var settings = new GLib.Settings(Config.APP_ID);
        var preset = new Preset();

        // Generate unique ID
        preset.id = Uuid.string_random();
        preset.name = name;
        preset.description = description;
        preset.created_at = get_real_time() / 1000000;
        preset.last_used_at = preset.created_at;
        preset.schema_version = 1;

        // Core settings
        preset.tempo = settings.get_int("tempo");
        preset.time_sig_numerator = settings.get_int("time-signature-numerator");
        preset.time_sig_denominator = settings.get_int("time-signature-denominator");

        // Subdivisions (if exists)
        if (settings_has_key(settings, "subdivision-mode")) {
            preset.subdivision_mode = settings.get_int("subdivision-mode");
            preset.subdivision_volume = settings.get_double("subdivision-volume");
            preset.subdivision_sound_type = settings.get_string("subdivision-sound-type");
        }

        // Tempo trainer (if exists)
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
}
```

### 6. Loading Presets (Applying to Settings)

```vala
public class PresetManager {
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

        // Subdivisions (if preset has them and feature exists)
        if (preset.subdivision_mode != null && settings_has_key(settings, "subdivision-mode")) {
            settings.set_int("subdivision-mode", preset.subdivision_mode);
            settings.set_double("subdivision-volume", preset.subdivision_volume ?? 0.5);
            settings.set_string("subdivision-sound-type", preset.subdivision_sound_type ?? "default");
        }

        // Tempo trainer (if preset has it and feature exists)
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
        preset.last_used_at = get_real_time() / 1000000;
        update_preset(preset);
        save_presets();

        return true;
    }
}
```

## UI Components

### 1. Preset Manager Dialog (`src/dialogs/PresetManagerDialog.vala`)

Full-featured preset management interface.

**Layout**:
```
┌─────────────────────────────────────────────┐
│  Tempo Presets                         [X]  │
├─────────────────────────────────────────────┤
│  [Search...]                     [+ New]    │
├──────────────────────┬──────────────────────┤
│ Preset List          │ Preset Details       │
│                      │                      │
│ • Bach Invention #1  │ Name: Bach...        │
│   80 BPM, 4/4       │ Description: ...     │
│                      │                      │
│ • Jazz Swing         │ Tempo: 80 BPM        │
│   120 BPM, 4/4      │ Time Signature: 4/4  │
│                      │                      │
│ • Warm-up Routine    │ Subdivisions: 8ths   │
│   60→120 BPM        │ Trainer: 60→120 +5   │
│                      │                      │
│                      │ Created: 2024-01-01  │
│                      │ Last Used: 2 days ago│
│                      │                      │
│                      │ [Load] [Rename]      │
│                      │ [Duplicate] [Delete] │
├──────────────────────┴──────────────────────┤
│  [Import] [Export] [Export All]    [Close]  │
└─────────────────────────────────────────────┘
```

**Features**:
- List view with all presets
- Search/filter by name
- Click preset to see details
- Double-click or "Load" button to apply
- Create, Rename, Duplicate, Delete operations
- Import/Export buttons

### 2. Quick-Load Dropdown (Main Window)

Compact preset selector in main window.

**Location**: Below tempo controls, similar to tempo trainer section

**Layout**:
```
┌─────────────────────────┐
│  Tempo: 120 BPM         │
│  [━━━━━━━━━━━━━]        │
│                         │
│  Presets: [Bach Inv. #1 ▼] [💾] [⚙️]│
│                         │
└─────────────────────────┘
```

**Dropdown Contents**:
- Recent presets (5 most recently used)
- --- separator ---
- All presets (alphabetically sorted)
- --- separator ---
- "Manage Presets..." (opens dialog)

**Buttons**:
- [💾] = Save current settings as preset (quick save dialog)
- [⚙️] = Open preset manager dialog

### 3. Save Preset Dialog (Quick Save)

Simple dialog for quickly saving current settings.

```
┌───────────────────────────────┐
│  Save as Preset          [X]  │
├───────────────────────────────┤
│  Name: [____________]         │
│                               │
│  Description (optional):      │
│  [_________________________]  │
│  [_________________________]  │
│                               │
│  This preset will save:       │
│  • Tempo: 120 BPM             │
│  • Time Signature: 4/4        │
│  • Subdivisions: Eighth Notes │
│  • Tempo Trainer: Enabled     │
│  • Audio & Visual Settings    │
│                               │
│        [Cancel]    [Save]     │
└───────────────────────────────┘
```

## Data Flow

### Creating a Preset
```
User clicks "Save Preset" button
    ↓
Show Save Preset Dialog
    ↓
User enters name and description
    ↓
MainWindow calls PresetManager.create_from_current_settings(name, desc)
    ↓
PresetManager reads all GSettings values
    ↓
Creates Preset object with current state
    ↓
Validates preset (name unique, etc.)
    ↓
Adds to presets list
    ↓
Calls save_presets() to write JSON file
    ↓
Emits preset_added signal
    ↓
UI updates (dropdown refreshes)
    ↓
Show toast: "Preset '[name]' saved"
```

### Loading a Preset
```
User selects preset from dropdown or manager
    ↓
MainWindow calls PresetManager.apply_preset(id)
    ↓
PresetManager gets preset by ID
    ↓
Validates preset still exists
    ↓
Applies all settings to GSettings
    ↓
Updates preset last_used_at timestamp
    ↓
Saves presets.json
    ↓
GSettings changes propagate to MetronomeEngine, UI
    ↓
UI updates (tempo display, trainer, subdivisions, etc.)
    ↓
Show toast: "Loaded preset '[name]'"
```

### Import/Export Flow
```
User clicks "Export All" in preset manager
    ↓
Show file chooser dialog (save)
    ↓
User selects destination (e.g., ~/tempo-presets-backup.json)
    ↓
PresetManager serializes all presets to JSON
    ↓
Writes to selected file
    ↓
Show toast: "Exported X presets to [filename]"

User clicks "Import" in preset manager
    ↓
Show file chooser dialog (open)
    ↓
User selects preset file
    ↓
PresetManager parses JSON
    ↓
Validates format and schema version
    ↓
Migrates presets if needed (old schema)
    ↓
Dialog: "Found X presets. Merge or Replace?"
    ↓
If Merge: Add imported presets, rename conflicts
If Replace: Clear existing presets, add imported
    ↓
Save presets.json
    ↓
Refresh UI
    ↓
Show toast: "Imported X presets"
```

## Edge Cases & Error Handling

### Edge Case: Duplicate preset names
**Scenario**: User tries to save preset with existing name
**Handling**:
- Detect duplicate in validate_preset_name()
- Offer options: "Overwrite existing", "Rename new preset", "Cancel"
- If rename: suggest "[Name] (2)", "[Name] (3)", etc.

### Edge Case: Loading preset with missing features
**Scenario**: Preset contains trainer settings but trainer feature not implemented/installed
**Handling**:
- Load what's available (tempo, time signature, etc.)
- Skip missing features gracefully
- Log info: "Preset contains trainer settings but feature not available"
- Show warning in UI: "Some preset settings not applied (missing features)"

### Edge Case: Preset file corrupted
**Scenario**: presets.json file is malformed or unreadable
**Handling**:
- Catch parse exception
- Log error with details
- Create backup of corrupted file: presets.json.corrupt.TIMESTAMP
- Start with empty preset list
- Show error dialog: "Preset file corrupted, starting fresh. Backup saved to..."
- Application continues normally

### Edge Case: Max presets reached
**Scenario**: User tries to create 101st preset
**Handling**:
- Check count in add_preset()
- Show error: "Maximum 100 presets reached. Delete unused presets to add more."
- Suggest sorting by last_used to find old presets

### Edge Case: Preset contains custom sound file paths
**Scenario**: Preset saved on System A (with file /home/userA/mysound.wav), loaded on System B
**Handling**:
- Presets DON'T save custom sound file paths (too system-specific)
- Only save built-in sound types ("woodblock", "metal", etc.)
- Document limitation: "Custom sound files not saved in presets"

### Error Handling: File I/O failures
**Scenario**: Can't write to presets.json (permissions, disk full)
**Handling**:
- Catch IOException
- Show error dialog: "Failed to save presets: [reason]"
- Keep presets in memory (don't lose them)
- Retry on next save attempt
- Log detailed error for debugging

## Performance Considerations

### Load Performance
- **Initial Load**: Parse JSON once at app startup
- **Preset Count**: 50 presets → ~5KB file, < 10ms parse time
- **Lazy UI**: Populate dropdown only when expanded (not all presets upfront)

### Apply Performance
- **Settings Write**: Applying preset writes ~15-20 GSettings keys
- **Time**: < 5ms for full preset application
- **User Perception**: Instant (no perceptible lag)

### Memory Footprint
- **50 Presets**: ~10KB in memory (Preset objects)
- **100 Presets**: ~20KB in memory
- **Acceptable**: < 50KB for max presets

### Search Performance
- **Linear Search**: Acceptable for < 100 presets
- **Optimization**: If needed, implement Trie or hash index for name search

## Testing Strategy

### Unit Tests
1. **Preset serialization**: to_json() and from_json() round-trip
2. **Name validation**: unique names, invalid characters
3. **PresetManager CRUD**: add, get, update, delete operations
4. **Import/Export**: JSON format validation

### Integration Tests
1. **Create and load**: Save preset, restart app, load preset
2. **Settings application**: Verify all settings applied correctly
3. **File persistence**: Presets survive app restart
4. **Migration**: Load v1 preset in v2 schema

### Manual Testing Checklist
- [ ] Save preset with current settings
- [ ] Load preset, verify all settings applied
- [ ] Rename preset
- [ ] Duplicate preset
- [ ] Delete preset
- [ ] Search presets by name
- [ ] Sort presets (by name, date, tempo)
- [ ] Export all presets to file
- [ ] Import presets from file (merge)
- [ ] Import presets from file (replace)
- [ ] Quick-load dropdown shows recent presets
- [ ] Max presets warning at 50
- [ ] Max presets error at 100
- [ ] Duplicate name handling
- [ ] Preset with subdivisions (if implemented)
- [ ] Preset with trainer config (if implemented)
- [ ] Load preset without subdivisions/trainer features
- [ ] Corrupted JSON file recovery

## Accessibility Considerations

### Keyboard Navigation
- Preset manager list: arrow keys to navigate
- Enter key to load selected preset
- Delete key to delete selected preset (with confirmation)
- Search box: Ctrl+F to focus

### Screen Reader Support
- Preset list announces: "Bach Invention #1, 80 BPM, 4/4 time"
- Actions announce: "Preset loaded", "Preset deleted", etc.
- Dialogs have clear titles and descriptions

### Visual Accessibility
- High contrast mode supported
- Large text mode: preset list scales with system font
- Icons + text labels (not icon-only buttons)

## Future Enhancements
Out of scope for this change:

1. **Preset Categories/Tags**
   - Organize presets: "Practice", "Performance", "Exercises"
   - Filter by tag

2. **Preset Favorites**
   - Star presets for quick access
   - Show favorites at top of list

3. **Preset Sharing Platform**
   - Community preset library
   - Upload/download presets

4. **Smart Presets**
   - Auto-suggest presets based on practice patterns
   - Learn user preferences

5. **Preset History**
   - Track changes to presets over time
   - Undo preset edits

## Migration & Compatibility

### Initial Release
- No migration needed (new feature)
- Empty presets list on first use
- JSON file created on first preset save

### Future Schema Changes
- Preset objects include schema_version field
- File includes global version field
- Migration functions handle version upgrades
- Old presets remain loadable (graceful degradation)

### Backward Compatibility
- If subdivisions/trainer not implemented: presets save null for those fields
- When features added later: existing presets work (missing fields → defaults)
- Preset system is additive (easy to extend)
