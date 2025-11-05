# tempo-presets Specification

## Purpose
Enable musicians to save complete metronome configurations as named presets and instantly recall them, eliminating repetitive setup when switching between different practice pieces or exercises.

## ADDED Requirements

### Requirement: Preset Creation from Current Settings
The system SHALL allow users to save the current metronome configuration as a named preset.

#### Scenario: Save preset with basic settings
- **WHEN** metronome configured with tempo 120 BPM and 4/4 time
- **AND** user clicks "Save Preset" button
- **AND** enters name "Practice Tempo"
- **THEN** create preset containing:
  - Tempo: 120 BPM
  - Time signature: 4/4
  - All audio settings (volumes, sound types)
  - All visual settings (beat numbers, flash, colors)
- **AND** save to presets.json file
- **AND** show toast "Preset 'Practice Tempo' saved"

#### Scenario: Save preset with subdivisions enabled
- **WHEN** subdivisions set to "Eighth Notes" with volume 0.5
- **AND** user saves preset
- **THEN** preset includes subdivision mode, volume, and sound type
- **WHEN** subdivisions feature not implemented
- **THEN** preset saves null for subdivision fields

#### Scenario: Save preset with tempo trainer configured
- **WHEN** trainer set to 60→120 BPM, +5 every 8 bars
- **AND** user saves preset
- **THEN** preset includes all trainer configuration
- **WHEN** trainer feature not implemented
- **THEN** preset saves null for trainer fields

#### Scenario: Preset assigned unique ID
- **WHEN** preset created
- **THEN** generate unique UUID for preset.id
- **AND** set created_at to current timestamp
- **AND** set last_used_at to current timestamp
- **AND** set schema_version to 1

### Requirement: Preset Loading and Application
The system SHALL apply all saved settings when loading a preset.

#### Scenario: Load preset applies all settings
- **WHEN** user selects preset "Bach Invention #1"
- **AND** preset contains tempo 80 BPM, 3/4 time, eighth note subdivisions
- **THEN** apply tempo → metronome.set_tempo(80)
- **AND** apply time signature → 3/4
- **AND** apply subdivision mode → Eighth Notes
- **AND** apply all audio and visual settings
- **AND** update UI to reflect new settings
- **AND** update preset.last_used_at timestamp

#### Scenario: Load preset with missing features
- **WHEN** preset contains tempo trainer configuration
- **AND** tempo trainer feature not implemented/installed
- **THEN** apply available settings (tempo, time signature, etc.)
- **AND** skip trainer settings gracefully
- **AND** show warning toast "Some settings not applied (missing features)"
- **AND** log info message about skipped settings

#### Scenario: Quick-load from dropdown
- **WHEN** user selects preset from quick-load dropdown in main window
- **THEN** apply preset settings immediately
- **AND** close dropdown
- **AND** show toast "Loaded 'Bach Invention #1'"
- **AND** preset moves to top of "recent" list

### Requirement: Preset Name Validation
The system SHALL validate preset names and enforce uniqueness.

#### Scenario: Unique name accepted
- **WHEN** user enters preset name "Warm-up Routine"
- **AND** no existing preset has this name
- **THEN** accept name
- **AND** create preset successfully

#### Scenario: Duplicate name rejected
- **WHEN** user enters preset name "Practice Tempo"
- **AND** preset with this name already exists
- **THEN** show error "Preset name already exists"
- **AND** offer options: "Overwrite", "Rename", "Cancel"
- **WHEN** user chooses "Rename"
- **THEN** suggest "Practice Tempo (2)"

#### Scenario: Empty name rejected
- **WHEN** user attempts to save preset with empty name
- **THEN** show error "Preset name cannot be empty"
- **AND** focus name input field
- **AND** prevent preset creation

#### Scenario: Name with invalid characters
- **WHEN** user enters name with special characters "/\:*?"
- **THEN** show warning "Special characters not recommended"
- **AND** allow user to proceed or edit
- **OR** automatically sanitize by removing/replacing invalid characters

### Requirement: Preset Manager Dialog Interface
The system SHALL provide a comprehensive dialog for managing all presets.

#### Scenario: Open preset manager shows all presets
- **WHEN** user opens preset manager dialog
- **THEN** display list of all presets sorted alphabetically
- **AND** show preset count: "X presets"
- **AND** each list item shows: name, tempo, time signature
- **AND** select first preset by default

#### Scenario: Preset details displayed on selection
- **WHEN** user clicks preset in list
- **THEN** display details panel showing:
  - Name and description
  - Tempo (BPM)
  - Time signature
  - Subdivisions (if present)
  - Tempo trainer config (if present)
  - Created date
  - Last used date
- **AND** enable action buttons: Load, Rename, Duplicate, Delete

#### Scenario: Search filters preset list
- **WHEN** user types "bach" in search box
- **THEN** filter list to show only presets containing "bach" (case-insensitive)
- **AND** update count: "2 of 15 presets"
- **WHEN** search cleared
- **THEN** show all presets again

### Requirement: Preset CRUD Operations
The system SHALL support Create, Read, Update, and Delete operations on presets.

#### Scenario: Create new preset from dialog
- **WHEN** user clicks "+ New" button in preset manager
- **THEN** open save preset dialog
- **AND** pre-fill with current metronome settings
- **AND** focus on name input field
- **WHEN** user saves
- **THEN** add to preset list
- **AND** refresh UI to show new preset

#### Scenario: Rename existing preset
- **WHEN** user selects preset and clicks "Rename"
- **THEN** show rename dialog with current name pre-filled
- **WHEN** user enters new unique name
- **THEN** update preset.name
- **AND** save presets.json
- **AND** refresh list with new name
- **AND** maintain sort order

#### Scenario: Duplicate preset
- **WHEN** user selects preset "Practice Tempo" and clicks "Duplicate"
- **THEN** create copy with name "Practice Tempo (Copy)"
- **AND** copy all settings from original
- **AND** assign new unique ID
- **AND** set created_at to current time
- **AND** add to preset list

#### Scenario: Delete preset with confirmation
- **WHEN** user selects preset and clicks "Delete"
- **THEN** show confirmation dialog: "Delete preset 'Practice Tempo'?"
- **WHEN** user confirms
- **THEN** remove from preset list
- **AND** save presets.json
- **AND** show toast "Preset deleted"
- **AND** select next preset in list

### Requirement: Quick-Load Dropdown Integration
The system SHALL provide quick access to presets from main window.

#### Scenario: Quick-load dropdown shows recent presets
- **WHEN** user clicks preset dropdown in main window
- **THEN** show dropdown with:
  - Section "Recent" with 5 most recently used presets
  - Separator
  - Section "All Presets" (alphabetically sorted)
  - Separator
  - "Manage Presets..." option

#### Scenario: Load preset from quick-load
- **WHEN** user selects preset from dropdown
- **THEN** apply preset settings
- **AND** close dropdown
- **AND** show toast with preset name
- **AND** preset moves to top of recent list

#### Scenario: Open manager from quick-load
- **WHEN** user selects "Manage Presets..." from dropdown
- **THEN** close dropdown
- **AND** open preset manager dialog

### Requirement: Preset File Persistence
The system SHALL persist presets to JSON file and restore on application restart.

#### Scenario: Presets saved to JSON file
- **WHEN** user creates/modifies/deletes preset
- **THEN** write presets to ~/.config/tempo/presets.json
- **AND** format as valid JSON with proper structure
- **AND** include version field for migration

#### Scenario: Presets loaded on app start
- **WHEN** application starts
- **AND** presets.json exists
- **THEN** parse JSON file
- **AND** load all presets into PresetManager
- **AND** populate quick-load dropdown
- **WHEN** file doesn't exist
- **THEN** start with empty preset list
- **AND** create file on first preset save

#### Scenario: Corrupted file handled gracefully
- **WHEN** application starts
- **AND** presets.json is malformed/corrupted
- **THEN** catch parse exception
- **AND** create backup: presets.json.corrupt.TIMESTAMP
- **AND** start with empty preset list
- **AND** show error dialog: "Preset file corrupted, backup saved"
- **AND** application continues normally

### Requirement: Preset Import Functionality
The system SHALL allow importing presets from external JSON files.

#### Scenario: Import presets with merge
- **WHEN** user clicks "Import" in preset manager
- **AND** selects preset file with 5 presets
- **AND** chooses "Merge" option
- **THEN** add imported presets to existing list
- **WHEN** name conflicts exist
- **THEN** rename imported presets: "Name (imported)", "Name (imported 2)"
- **AND** save combined list to presets.json
- **AND** show toast "Imported 5 presets"

#### Scenario: Import presets with replace
- **WHEN** user imports presets
- **AND** chooses "Replace" option
- **THEN** show confirmation: "Replace all existing presets?"
- **WHEN** user confirms
- **THEN** clear existing preset list
- **AND** load imported presets
- **AND** save to presets.json
- **AND** refresh UI

#### Scenario: Import invalid file rejected
- **WHEN** user selects non-JSON file or invalid format
- **THEN** show error "Invalid preset file format"
- **AND** do not modify existing presets
- **AND** log error details for debugging

#### Scenario: Import with schema migration
- **WHEN** imported presets have schema_version=1
- **AND** current application uses schema_version=2
- **THEN** migrate each preset to v2 format
- **AND** import migrated presets
- **AND** show info "Presets migrated from older version"

### Requirement: Preset Export Functionality
The system SHALL allow exporting presets to external JSON files for backup and sharing.

#### Scenario: Export all presets
- **WHEN** user clicks "Export All" in preset manager
- **AND** selects destination file
- **THEN** serialize all presets to JSON
- **AND** write to selected file
- **AND** show toast "Exported 15 presets to [filename]"

#### Scenario: Export single preset
- **WHEN** user selects preset and clicks "Export"
- **AND** chooses destination file
- **THEN** serialize selected preset to JSON
- **AND** write to file
- **AND** show toast "Exported 'Practice Tempo' to [filename]"

#### Scenario: Export file format valid
- **WHEN** presets exported
- **THEN** JSON file contains:
  - version field (current: 1)
  - presets array with all preset objects
  - valid JSON syntax
  - human-readable formatting (indented)

### Requirement: Preset Sorting and Organization
The system SHALL allow users to sort and organize presets.

#### Scenario: Sort presets by name
- **WHEN** user selects "Sort by Name" in preset manager
- **THEN** sort presets alphabetically A-Z
- **AND** refresh list display
- **AND** remember sort preference

#### Scenario: Sort presets by last used
- **WHEN** user selects "Sort by Last Used"
- **THEN** sort presets with most recently used first
- **AND** show last used date in list

#### Scenario: Sort presets by tempo
- **WHEN** user selects "Sort by Tempo"
- **THEN** sort presets from lowest to highest BPM
- **AND** group similar tempos together

#### Scenario: Sort presets by created date
- **WHEN** user selects "Sort by Created Date"
- **THEN** sort presets with newest first
- **AND** show created date in list

### Requirement: Preset Limit Enforcement
The system SHALL enforce reasonable limits on preset count for performance and usability.

#### Scenario: Warning at 50 presets
- **WHEN** user has 49 presets
- **AND** creates 50th preset
- **THEN** show warning dialog: "You have 50 presets. Consider organizing or deleting unused ones."
- **AND** allow preset creation
- **AND** suggest sorting by last_used to find old presets

#### Scenario: Hard limit at 100 presets
- **WHEN** user has 100 presets
- **AND** attempts to create 101st preset
- **THEN** show error "Maximum 100 presets reached"
- **AND** prevent preset creation
- **AND** suggest deleting unused presets

### Requirement: Preset Validation on Load
The system SHALL validate presets when loading and handle invalid data gracefully.

#### Scenario: Preset with invalid tempo clamped
- **WHEN** preset contains tempo 300 BPM (above max 240)
- **AND** preset loaded
- **THEN** clamp to maximum: 240 BPM
- **AND** log warning: "Preset tempo clamped to valid range"
- **AND** apply clamped value

#### Scenario: Preset with invalid time signature rejected
- **WHEN** preset contains time signature 5/3 (invalid denominator)
- **AND** preset loaded
- **THEN** show error "Invalid time signature in preset"
- **AND** fallback to default 4/4
- **AND** log error details

#### Scenario: Preset with missing required fields
- **WHEN** preset JSON missing tempo field
- **THEN** show error "Preset corrupted (missing fields)"
- **AND** skip loading this preset
- **AND** continue loading other presets
- **AND** log which fields are missing

### Requirement: Preset UI Accessibility
The system SHALL ensure preset features are accessible to all users.

#### Scenario: Preset manager keyboard navigation
- **WHEN** user opens preset manager
- **THEN** focus on search box initially
- **AND** Tab key navigates to preset list
- **AND** Arrow keys navigate preset list
- **AND** Enter key loads selected preset
- **AND** Delete key deletes selected preset (with confirmation)
- **AND** Escape key closes dialog

#### Scenario: Screen reader announces preset details
- **WHEN** user navigates preset list with screen reader
- **THEN** announce: "Bach Invention #1, 80 BPM, 3/4 time, Eighth note subdivisions"
- **WHEN** preset loaded
- **THEN** announce: "Loaded preset Bach Invention #1"
- **WHEN** preset deleted
- **THEN** announce: "Preset deleted"

#### Scenario: High contrast mode supported
- **WHEN** user enables high contrast theme
- **THEN** preset list items have clear borders
- **AND** selected preset clearly highlighted
- **AND** buttons have high contrast colors

### Requirement: Preset Performance
The system SHALL maintain application performance with preset operations.

#### Scenario: Load presets file quickly on startup
- **WHEN** application starts with 50 presets
- **THEN** parse presets.json in < 10ms
- **AND** populate PresetManager
- **AND** no perceptible delay in app startup

#### Scenario: Apply preset instantly
- **WHEN** user loads preset
- **THEN** apply all settings in < 5ms
- **AND** UI updates feel instant (< 16ms for 60fps)
- **AND** no lag or stutter

#### Scenario: Search presets quickly
- **WHEN** user searches preset list with 100 presets
- **THEN** filter results in < 10ms
- **AND** update UI immediately
- **AND** typing feels responsive

### Requirement: Preset Error Handling
The system SHALL handle all preset errors gracefully without crashing.

#### Scenario: File write failure handled
- **WHEN** saving presets to file fails (permissions, disk full)
- **THEN** catch IOException
- **AND** show error dialog: "Failed to save presets: [reason]"
- **AND** keep presets in memory (don't lose data)
- **AND** retry on next save attempt
- **AND** application continues running

#### Scenario: Name validation prevents issues
- **WHEN** preset name contains path separators ("preset/../attack")
- **THEN** reject or sanitize name
- **AND** prevent path traversal attacks
- **AND** show error "Invalid characters in preset name"

### Requirement: Preset Integration with Features
The system SHALL correctly save and restore settings for all implemented features.

#### Scenario: Preset with subdivisions
- **WHEN** subdivisions enabled (Sixteenth Notes, volume 0.6)
- **AND** user saves preset
- **THEN** preset stores subdivision_mode=4, subdivision_volume=0.6
- **WHEN** preset loaded
- **THEN** apply subdivision mode and volume
- **AND** subdivisions play correctly

#### Scenario: Preset with tempo trainer
- **WHEN** trainer configured (60→120 BPM, +5 every 8 bars)
- **AND** user saves preset
- **THEN** preset stores all trainer settings
- **WHEN** preset loaded
- **THEN** apply trainer configuration
- **AND** trainer can be enabled to start progression

#### Scenario: Preset without advanced features
- **WHEN** preset created when subdivisions/trainer not installed
- **AND** preset contains only basic settings
- **WHEN** loaded on system with subdivisions/trainer
- **THEN** apply basic settings
- **AND** leave advanced features in default state
- **AND** no errors or warnings

### Requirement: Preset Save Dialog UX
The system SHALL provide clear feedback about what will be saved in a preset.

#### Scenario: Save dialog shows preview
- **WHEN** user clicks "Save Preset" button
- **THEN** open save preset dialog
- **AND** show preview of what will be saved:
  - "Tempo: 120 BPM"
  - "Time Signature: 4/4"
  - "Subdivisions: Eighth Notes"
  - "Tempo Trainer: 60→120 BPM, +5 every 8 bars"
  - "Audio & Visual Settings"
- **AND** user can review before saving

#### Scenario: Description field optional
- **WHEN** user enters name only (no description)
- **THEN** allow saving with empty description
- **WHEN** user enters description
- **THEN** save description with preset
- **AND** show in preset details

### Requirement: Recent Presets Tracking
The system SHALL track recently used presets for quick access.

#### Scenario: Recent presets updated on load
- **WHEN** user loads preset "Bach Invention #1"
- **THEN** update preset.last_used_at to current timestamp
- **AND** move preset to top of recent list
- **AND** recent list maintains max 5 items

#### Scenario: Recent list persists across restarts
- **WHEN** user loads presets A, B, C
- **AND** closes application
- **AND** reopens application
- **THEN** quick-load dropdown shows A, B, C in recent section
- **AND** order preserved (most recent first)

### Requirement: Preset Manager Dialog State
The system SHALL remember preset manager dialog state across sessions.

#### Scenario: Remember last selected preset
- **WHEN** user selects preset "Jazz Swing" in manager
- **AND** closes dialog
- **AND** reopens dialog
- **THEN** "Jazz Swing" still selected
- **AND** details panel shows its info

#### Scenario: Remember sort order
- **WHEN** user sorts by "Last Used"
- **AND** closes dialog
- **AND** reopens dialog
- **THEN** presets still sorted by last used

### Requirement: Preset Conflict Resolution
The system SHALL handle conflicts when importing or duplicating presets.

#### Scenario: Import with name conflicts
- **WHEN** importing presets
- **AND** preset named "Warm-up" already exists locally
- **AND** imported file also has "Warm-up" preset
- **THEN** rename imported preset to "Warm-up (imported)"
- **AND** show info: "1 preset renamed due to conflict"

#### Scenario: Duplicate preset generates unique name
- **WHEN** user duplicates preset "Practice Tempo"
- **THEN** create copy with name "Practice Tempo (Copy)"
- **WHEN** "Practice Tempo (Copy)" already exists
- **THEN** create "Practice Tempo (Copy 2)"
- **AND** continue incrementing until unique name found
