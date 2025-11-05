# Add Polyrhythm and Polymetric Support

## Why
Advanced musicians studying jazz, progressive rock, classical, and world music need to practice polyrhythms (e.g., 3 against 4, 5 against 7) and polymetric patterns (simultaneous independent time signatures). Current metronomes play a single rhythmic stream, making polyrhythmic practice difficult. Adding dual-rhythm support enables advanced rhythmic training and positions Tempo as a professional-grade practice tool.

## What Changes
- Add polyrhythm mode toggle in main window or preferences
- Support two simultaneous independent rhythmic streams
- Each stream has independent time signature (e.g., 3/4 vs 4/4)
- Same tempo (BPM) for both streams, different bar lengths
- Different sounds for each stream (Left/Right channel panning OR different timbres)
- Dual visual indicators showing both rhythmic patterns
- Polyrhythm presets (e.g., "3 against 4", "5 against 7")
- Significant architecture change - may require dual MetronomeEngine instances or unified polyrhythm engine

## Impact
- **Affected specs**: New `polyrhythms` spec
- **Related specs**: `audio-playback` (stereo panning, dual sound sources), `subdivisions` (each stream may have subdivisions)
- **Affected code**:
  - `src/utils/PolyrhythmEngine.vala` - NEW: Manages dual rhythmic streams
  - `src/utils/MetronomeEngine.vala` - Refactor to support dual-engine mode OR extend for polyrhythm calculations
  - `src/windows/MainWindow.vala` - Dual visual indicators, polyrhythm UI controls
  - `data/ui/main_window.blp` - Second time signature controls, stream configuration
  - `src/dialogs/PreferencesDialog.vala` - Polyrhythm sound/panning settings
  - `data/io.github.tobagin.tempo.gschema.xml.in` - Polyrhythm settings (enabled, stream1/stream2 time signatures, panning)
  - Audio system: Stereo panning or separate sound types per stream

## Design Decisions
- **Architecture**: PolyrhythmEngine coordinates two rhythmic streams with least-common-multiple (LCM) beat scheduling
- **Tempo relationship**: Same BPM for both streams (simplifies synchronization)
- **Audio distinction**: Stereo panning (stream 1 = left, stream 2 = right) AND/OR different sound types
- **Visual representation**: Side-by-side or overlaid dual beat indicators
- **Complexity trade-off**: Very high complexity for niche use case (low user impact)
- **Optional feature**: Clearly marked as "Advanced" to avoid overwhelming basic users

## Dependencies
- Depends on `audio-playback` for stereo panning support
- Enhanced by `subdivisions` (each stream can have independent subdivisions)
- May benefit from `visual-modes` for distinct visual representations

## Migration & Compatibility
- Default: Polyrhythm disabled (single metronome mode)
- Settings: Add `polyrhythm-enabled` (bool), stream time signatures, panning preferences
- Optional feature, no impact on standard metronome use

## Risks & Considerations
- **Very high complexity**: Requires significant timing engine refactoring
- **Low user demand**: Advanced feature for small subset of musicians (priority ⭐⭐ per TODO)
- **Timing precision**: Maintaining accuracy with two simultaneous streams is challenging
- **UI complexity**: Dual time signature controls may confuse casual users
- **Testing difficulty**: Complex test cases for various polyrhythm combinations
- **Recommendation**: Consider deferring until other features complete, or implement as separate "Pro" mode
