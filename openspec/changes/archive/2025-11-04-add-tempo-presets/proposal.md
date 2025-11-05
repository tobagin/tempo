# Add Tempo Presets

## Overview
Add a comprehensive preset system to Tempo, enabling musicians to save and instantly recall complete metronome configurations with custom names. This eliminates repetitive setup when switching between different practice pieces or exercises, dramatically improving workflow efficiency.

## Motivation
Musicians frequently practice multiple pieces or exercises that require different metronome settings. Currently, switching between these requires:
- Manually adjusting tempo every time
- Remembering and re-entering time signatures
- Reconfiguring subdivisions, trainer settings, volumes
- Mental overhead tracking "which settings for which piece"

A preset system solves this by:
- Saving complete configurations with descriptive names ("Beethoven Op. 27", "Jazz Etude #5", "Warm-up Routine")
- One-click switching between pieces
- Organizing practice sessions more efficiently
- Reducing cognitive load during practice

According to TODO.md, this is a **high priority feature** (⭐⭐⭐⭐) with **Medium Complexity** and **High User Impact**, representing a massive workflow improvement for practicing musicians.

## Goals
1. **Save Configurations**: Store complete metronome state as named presets
2. **Quick Recall**: Load presets with one click from main window or dialog
3. **Preset Management**: Create, rename, delete, duplicate presets
4. **Rich Metadata**: Each preset stores tempo, time signature, subdivisions, trainer config, volumes
5. **Organize Presets**: Sort/filter presets, optional categories/tags
6. **Import/Export**: Backup presets or share with other musicians
7. **Default Preset**: Optionally set a preset to load on app startup

## Non-Goals
- Cloud sync or sharing platform (local storage only)
- Collaborative preset libraries
- Preset version control or history
- Automatic preset suggestions based on practice patterns
- Integration with sheet music files (MIDI, MusicXML)
- Preset scheduling (e.g., "use this preset on Mondays")

## Success Criteria
- Musicians can save current metronome configuration as a named preset
- Presets appear in quick-load dropdown in main window
- Loading a preset applies all saved settings instantly
- Preset manager dialog allows full CRUD operations (Create, Read, Update, Delete)
- Presets persist across app restarts
- Import/export allows backup and sharing
- UI remains clean and unobtrusive
- Works correctly with all features (subdivisions, tempo trainer, practice timer)

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Preset list grows large, clutters UI | Implement search/filter, limit quick-load dropdown to favorites or recent |
| Settings schema changes break presets | Version presets, implement migration logic for schema updates |
| Conflicting preset names | Enforce unique names, suggest alternatives on conflict |
| User confusion about what's saved | Clear UI showing exactly what preset contains |
| Storage corruption loses all presets | Regular validation, backup on export, graceful degradation |
| Performance with many presets (100+) | Lazy loading, efficient JSON parsing, indexed storage |

## Open Questions
- [x] What settings should presets save? → All core metronome settings (tempo, time sig, subdivisions, trainer, volumes)
- [x] Storage format: GSettings or JSON file? → JSON file for flexibility, easier export/import, schema evolution
- [x] Should presets include practice timer state? → No, timer is session-specific (state not saved, only config if desired)
- [x] Maximum number of presets? → Soft limit: warn at 50, hard limit: 100 (UI/performance considerations)
- [x] Should presets store audio file paths? → Yes, but validate on load (file may not exist on different systems)
- [x] Quick-load dropdown location? → Below tempo controls in main window, collapsible like trainer
- [x] Default preset behavior? → Optional setting: "Load [preset] on startup" or "Remember last used"

## Dependencies
- No hard dependencies on other features
- **Enhances**: If subdivisions/trainer implemented, presets save those configs
- **Complements**: Import/Export Settings (Feature #5) - presets are a form of settings
- **Foundation for**: Future features could extend preset system (e.g., preset scheduling)

## Related Work
- Feature #5 (Export/Import Settings) - Overlaps with preset export/import, can share infrastructure
- Feature #2 (Tempo Trainer) - Trainer configurations saveable in presets
- Feature #1 (Subdivisions) - Subdivision modes saveable in presets
- Feature #4 (Practice Timer) - Timer config optionally saveable

## Implementation Approach
See `design.md` for detailed architecture and `tasks.md` for implementation plan.

Key technical approach:
- Create `PresetManager` class to handle preset CRUD operations
- Store presets as JSON array in user config directory (`~/.config/tempo/presets.json`)
- Create `PresetManagerDialog` for full preset management UI
- Add quick-load dropdown to main window for instant access
- Implement preset versioning for future schema evolution
- Add import/export functionality for backup and sharing

## Spec Changes
This proposal introduces one new capability:
- `tempo-presets` - Save and recall complete metronome configurations with custom names
