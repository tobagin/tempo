# Add Sound Type Selection

## Why
Currently, Tempo provides only one built-in sound type (the default high/low WAV files). Users who want variety must provide their own custom audio files, which requires external file management. Offering multiple built-in sound types (woodblocks, metal, etc.) improves the out-of-box experience and caters to different musical preferences and practice contexts without requiring custom file management.

## What Changes
- Add multiple built-in sound type presets (e.g., Default, Woodblock, Metal, Cowbell, Digital)
- Each sound type includes a high (accent/downbeat) and low (regular beat) sound pair
- Add UI control in preferences to select sound type
- Bundle additional audio files in the application resources
- Maintain existing custom sound functionality alongside built-in types
- Allow per-beat sound customization: users can select different sound types for high and low sounds independently

## Impact
- **Affected specs**: `audio-playback` (new spec or extension of existing audio functionality)
- **Affected code**:
  - `src/utils/MetronomeEngine.vala` - sound URI resolution and playback logic
  - `src/dialogs/PreferencesDialog.vala` - UI for sound type selection
  - `data/ui/preferences_dialog.blp` - preferences UI markup
  - `data/sounds/` - new audio files for each sound type
  - `data/io.github.tobagin.tempo.gschema.xml` - new settings keys for sound type
  - `data/io.github.tobagin.tempo.gresource.xml` - register new audio resources
  - `meson.build` - ensure new sounds are installed
