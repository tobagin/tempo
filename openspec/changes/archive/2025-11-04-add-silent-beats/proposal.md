# Add Silent/Muted Beats

## Why
Musicians can become overly dependent on metronomes, struggling with timing when the click is removed. Silent/muted beats train internal timing by intentionally removing some clicks, forcing musicians to maintain tempo independently. This pedagogical technique is commonly used in music education and professional practice to develop stronger rhythmic internalization.

## What Changes
- Add mute mode toggle in preferences or main window
- Multiple mute patterns:
  - **Every Nth beat**: Mute every 2nd, 3rd, 4th, etc. beat
  - **Random percentage**: Mute 25%, 50%, or 75% of beats randomly
  - **Specific beats**: Mute only beats 2 and 4, or only downbeats, etc.
  - **Progressive**: Gradually increase mute frequency over time
- Visual indicator still shows muted beats with different styling (dimmed, outline-only, or different color)
- Mute logic applied before audio playback in MetronomeEngine
- Settings persistence for mute mode and pattern preferences

## Impact
- **Affected specs**: New `silent-beats` spec
- **Related specs**: `audio-playback` (mute logic integration), `subdivisions` (mute can apply to subdivisions)
- **Affected code**:
  - `src/utils/MetronomeEngine.vala` - Mute decision logic before sound playback
  - `src/utils/MutePattern.vala` - NEW: Mute pattern implementations (every Nth, random, progressive)
  - `src/windows/MainWindow.vala` - Visual indicator for muted beats
  - `data/ui/main_window.blp` - Mute mode toggle and pattern selector
  - `data/ui/preferences_dialog.blp` - Mute settings page
  - `src/dialogs/PreferencesDialog.vala` - Mute configuration UI
  - `data/io.github.tobagin.tempo.gschema.xml.in` - Mute settings (enabled, pattern, parameters)

## Design Decisions
- **Mute applies to audio only**: Visual indicator always shows all beats (including muted) to provide reference
- **Mute happens before playback**: Check mute condition before calling play_sound() to avoid audio glitches
- **Random seed**: Use predictable pseudo-random for same pattern each session (optional: truly random setting)
- **Progressive mode**: Separate feature flag, increases mute frequency based on elapsed time or bar count
- **Subdivisions**: Mute can apply to subdivisions if enabled, separate from main beat muting

## Dependencies
- No hard dependencies
- Recommended after `subdivisions` feature for muting subdivision clicks
- Enhances `practice-timer` feature (progressive muting over session duration)

## Migration & Compatibility
- Default: Mute disabled (all beats audible)
- Settings: Add `mute-enabled` (bool), `mute-pattern` (string), `mute-parameter` (int/double)
- Visual feedback ensures users aren't confused when beats are muted
