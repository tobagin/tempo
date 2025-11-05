# Add Rhythm Patterns and Cycles

## Why
Currently, Tempo plays simple metronomic beats with optional subdivisions. Musicians practicing specific genres (Latin, jazz, samba, etc.) need to work with pre-programmed rhythmic patterns beyond basic beats. Adding rhythm patterns enables genre-specific practice, introduces rhythmic training capabilities, and positions Tempo as a comprehensive practice tool rather than just a basic metronome.

## What Changes
- Add rhythm pattern library with common patterns (Son Clave, Rumba Clave, Bossa Nova, Samba)
- Implement pattern sequencer engine that schedules accents and notes per pattern definition
- Add pattern editor dialog for creating and modifying custom patterns
- Pattern storage system using JSON files for built-in and user patterns
- UI controls in main window to select and activate patterns
- Pattern playback replaces simple beat mode when active
- Each pattern can specify different sounds per step (accent, regular, ghost note)

## Impact
- **Affected specs**: New `rhythm-patterns` spec
- **Related specs**: `audio-playback` (pattern playback integration), `subdivisions` (patterns may use subdivision-level timing)
- **Affected code**:
  - `src/utils/RhythmPattern.vala` - NEW: Pattern data structure and JSON serialization
  - `src/utils/PatternEngine.vala` - NEW: Pattern playback engine extending MetronomeEngine
  - `src/dialogs/PatternEditorDialog.vala` - NEW: Pattern creation/editing UI
  - `data/ui/pattern_editor_dialog.blp` - NEW: Pattern editor UI markup
  - `src/utils/MetronomeEngine.vala` - Integration point for pattern engine
  - `src/windows/MainWindow.vala` - Pattern selection UI and mode switching
  - `data/ui/main_window.blp` - Pattern selector dropdown/button
  - `data/patterns/` - NEW: Directory for built-in pattern JSON files
  - `data/io.github.tobagin.tempo.gschema.xml.in` - Pattern settings (last used, custom patterns dir)
  - `data/io.github.tobagin.tempo.gresource.xml.in` - Bundle built-in pattern files
  - `meson.build` - Install pattern files and compile new Vala classes

## Design Decisions
- **Pattern format**: JSON for readability and external editability
- **Architecture**: Separate PatternEngine class rather than embedding in MetronomeEngine to maintain single responsibility
- **Editor complexity**: Grid-based sequencer (medium complexity) rather than piano roll (high complexity)
- **Sound assignment**: Per-step sound selection from available sound types
- **Pattern length**: Support variable-length patterns (1-32 beats typical, up to 64 for complex cycles)

## Dependencies
- Depends on `audio-playback` spec for multi-sound playback
- Recommended after `subdivisions` feature (#1) for fine-grained pattern timing
- Recommended after `sound-type-selection` feature for varied sounds per step

## Migration & Compatibility
- Default behavior unchanged (no pattern = standard metronome)
- Pattern mode is opt-in via UI selection
- Built-in patterns bundled in resources, user patterns in config directory
- Settings: Add `active-pattern` (string, empty = none) and `last-used-pattern` keys
