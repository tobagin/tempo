# TODO - Feature Roadmap for Tempo Metronome

This document tracks potential new features and enhancements for the Tempo metronome application.

## 🔥 HIGH PRIORITY FEATURES

### 1. Subdivisions Support
**Status**: Not started
**Priority**: ⭐⭐⭐⭐⭐
**Complexity**: Medium
**User Impact**: Very High

**Description**: Add the ability to hear and see subdivisions within each beat (eighth notes, sixteenth notes, triplets).

**Use Case**: Musicians practicing complex rhythms need to hear subdivisions to develop precise timing.

**Implementation Details**:
- Add subdivision toggle to main UI
- Options: None, 8ths (2 per beat), 16ths (4 per beat), Triplets (3 per beat)
- Requires additional audio playback in `MetronomeEngine.vala`
- Lighter click sound for subdivisions vs main beats
- Visual indicator could show subdivision dots/pulses
- Settings persistence in GSettings

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Add subdivision timing logic
- `data/ui/main_window.blp` - Add subdivision controls
- `src/windows/MainWindow.vala` - Handle subdivision UI
- `data/io.github.tobagin.tempo.gschema.xml.in` - Add subdivision settings

**Benefits**: Essential for advanced practice, transforms app from basic to professional-grade.

---

### 2. Tempo Trainer / Gradual Tempo Change
**Status**: Not started
**Priority**: ⭐⭐⭐⭐⭐
**Complexity**: Medium
**User Impact**: Very High

**Description**: Automatically increase or decrease tempo over time to help build speed gradually.

**Use Case**: Musicians learning difficult passages can start slow and incrementally increase speed without manual adjustment.

**Implementation Details**:
- New "Tempo Trainer" mode toggle in main window
- Settings panel with:
  - Start BPM (current tempo)
  - End BPM (target tempo)
  - Increment amount (e.g., +1 BPM)
  - Interval type: Every N bars OR Every N seconds
  - Optional: Auto-stop at target
- Timer/counter display showing progress
- Pause/resume trainer without losing progress
- Visual indication when in trainer mode

**Files to Create**:
- `src/utils/TempoTrainer.vala` - New class for tempo progression logic

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Hook for tempo changes from trainer
- `data/ui/main_window.blp` - Add trainer controls (collapsible section)
- `src/windows/MainWindow.vala` - Trainer UI handling
- `data/io.github.tobagin.tempo.gschema.xml.in` - Trainer settings

**Benefits**: Unique value proposition for structured practice, very popular feature.

---

### 3. Tempo Presets / Favorites
**Status**: Not started
**Priority**: ⭐⭐⭐⭐
**Complexity**: Medium
**User Impact**: High

**Description**: Save and quickly recall favorite tempo/time signature combinations with custom names.

**Use Case**: Musicians working on multiple pieces can save "Beethoven Symphony", "Jazz Etude", etc. and switch instantly.

**Implementation Details**:
- Preset manager accessible from menu or main window
- New dialog: `PresetManagerDialog.vala`
- List view showing all presets with name, tempo, time signature
- Actions: Add, Delete, Rename, Load
- Each preset stores:
  - Name (user-defined string)
  - BPM value
  - Time signature (numerator/denominator)
  - Optional: Subdivision setting (if feature #1 implemented)
- Storage: GSettings array of structs or JSON file in config directory
- Quick-load dropdown in main window (optional)

**Files to Create**:
- `src/dialogs/PresetManagerDialog.vala` - Preset management UI
- `data/ui/preset_manager_dialog.blp` - Dialog template

**Files to Modify**:
- `src/Main.vala` - Add preset manager action
- `src/windows/MainWindow.vala` - Quick load integration
- `data/io.github.tobagin.tempo.gschema.xml.in` - Preset storage

**Benefits**: Huge workflow improvement, saves time when switching between pieces.

---

### 4. Practice Session Timer
**Status**: Not started
**Priority**: ⭐⭐⭐⭐
**Complexity**: Low
**User Impact**: High

**Description**: Count-up timer showing how long the metronome has been running in current session.

**Use Case**: Track practice time, enforce practice duration goals, maintain focus.

**Implementation Details**:
- Timer display in main window (toggleable)
- Formats: MM:SS or HH:MM:SS for long sessions
- Modes:
  - **Count-up**: Shows elapsed time (default)
  - **Countdown**: Set target duration, counts down to zero
  - Auto-stop option when countdown reaches zero
- Pause when metronome stops (optional setting)
- Reset button to clear timer
- Session statistics (optional):
  - Total practice time today/this week
  - Stored in GSettings or simple log file

**Files to Modify**:
- `src/windows/MainWindow.vala` - Timer display and logic
- `data/ui/main_window.blp` - Timer label widget
- `src/utils/MetronomeEngine.vala` - Time tracking integration
- `data/io.github.tobagin.tempo.gschema.xml.in` - Timer settings

**Benefits**: Practice accountability, time management, motivational tool.

---

### 5. Export / Import Settings
**Status**: Not started
**Priority**: ⭐⭐⭐
**Complexity**: Low-Medium
**User Impact**: Medium

**Description**: Export complete settings configuration to file and import from file.

**Use Case**: Backup settings, share configurations, multiple users on same system, reinstallation.

**Implementation Details**:
- Menu actions: "Export Settings...", "Import Settings..."
- File format: JSON or XML (JSON recommended for simplicity)
- Export includes:
  - All GSettings keys (32 current settings)
  - Presets (if feature #3 implemented)
  - Optional: Custom sound files (copy files or just paths)
- Import validation:
  - Check file format
  - Validate all values against schema
  - Confirmation dialog before applying
  - Option to merge or replace all settings
- Default filename: `tempo-settings-YYYY-MM-DD.json`

**Files to Create**:
- `src/utils/SettingsExporter.vala` - Export/import logic

**Files to Modify**:
- `src/Main.vala` - Add export/import actions
- `src/dialogs/PreferencesDialog.vala` - Add export/import buttons

**Benefits**: Portability, backup, multi-user convenience.

---

## 🎼 MEDIUM PRIORITY FEATURES

### 6. Rhythm Patterns / Cycles
**Status**: Not started
**Priority**: ⭐⭐⭐
**Complexity**: High
**User Impact**: Medium

**Description**: Pre-programmed or custom rhythm patterns beyond simple beats (e.g., clave, samba patterns).

**Use Case**: Practice specific rhythmic patterns common in various musical genres.

**Implementation Details**:
- Pattern library with common rhythms:
  - Son Clave (3-2, 2-3)
  - Rumba Clave
  - Bossa Nova
  - Samba
  - Custom patterns
- Pattern editor:
  - Grid-based sequencer UI
  - Beat subdivision into 16ths or triplets
  - Accent placement
  - Different sounds per step
- Pattern storage in GSettings or separate file
- Pattern selector dropdown/dialog

**Files to Create**:
- `src/utils/RhythmPattern.vala` - Pattern data structure
- `src/utils/PatternEngine.vala` - Pattern playback engine
- `src/dialogs/PatternEditorDialog.vala` - Pattern creation UI
- `data/patterns/` - Directory for built-in patterns (JSON)

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Integration with pattern engine
- `src/windows/MainWindow.vala` - Pattern selector UI

**Benefits**: Genre-specific practice, advanced rhythmic training.

---

### 7. Silent / Muted Beats
**Status**: Not started
**Priority**: ⭐⭐⭐
**Complexity**: Medium
**User Impact**: Medium

**Description**: Randomly or programmatically mute beats to test internalization of timing.

**Use Case**: Train internal timing by removing some clicks, ensuring musicians aren't dependent on the metronome.

**Implementation Details**:
- Mute mode toggle in preferences or main window
- Mute patterns:
  - **Every Nth beat**: Mute every 2nd, 3rd, 4th beat, etc.
  - **Random percentage**: Mute 25%, 50%, 75% of beats randomly
  - **Specific beats**: Mute beats 2 and 4 only, etc.
  - **Progressive**: Gradually increase mute frequency
- Visual indicator still shows muted beats (dimmed/different color)
- Option to mute downbeats or regular beats only

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Mute logic before audio playback
- `data/ui/main_window.blp` - Mute mode controls
- `src/windows/MainWindow.vala` - Mute pattern UI
- `data/io.github.tobagin.tempo.gschema.xml.in` - Mute settings

**Benefits**: Advanced practice technique, develops internal timing.

---

### 8. MIDI Output Support
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: High
**User Impact**: Low (niche users)

**Description**: Send MIDI clock or note messages to external devices/DAWs.

**Use Case**: Sync with DAWs, drum machines, or other MIDI devices for recording/production.

**Implementation Details**:
- MIDI library integration (ALSA MIDI on Linux)
- Send MIDI Clock messages (24 per quarter note)
- Optional: Send MIDI notes on beats/downbeats
- MIDI device selector in preferences
- MIDI channel configuration
- Start/stop/continue messages
- Tempo sync with MIDI clock

**Dependencies**:
- Add ALSA MIDI or PortMIDI library to build
- May require additional Flatpak permissions

**Files to Create**:
- `src/utils/MIDIOutput.vala` - MIDI communication handler

**Files to Modify**:
- `meson.build` - Add MIDI library dependency
- `src/dialogs/PreferencesDialog.vala` - MIDI settings page
- `src/utils/MetronomeEngine.vala` - MIDI output integration

**Benefits**: Professional workflow integration for producers/composers.

---

### 9. Visual Metronome Modes
**Status**: Not started
**Priority**: ⭐⭐⭐
**Complexity**: Medium
**User Impact**: Medium

**Description**: Alternative visual indicators beyond the current circle (pendulum animation, bar graphs, etc.).

**Use Case**: Silent practice, visual learners, variety, accessibility.

**Implementation Details**:
- Visual mode selector in preferences
- Modes:
  - **Circle** (current default)
  - **Pendulum**: Swinging animation like mechanical metronome
  - **Bar Graph**: Vertical bars for each beat position
  - **Progress Ring**: Circular progress showing beat completion
  - **Minimalist**: Simple color flash
- Each mode maintains beat number display option
- Smooth animations using Cairo graphics
- Settings persistence

**Files to Modify**:
- `src/windows/MainWindow.vala` - Multiple drawing functions for each mode
- `data/ui/preferences_dialog.blp` - Visual mode selector
- `data/io.github.tobagin.tempo.gschema.xml.in` - Visual mode setting

**Benefits**: Accessibility, personal preference, visual variety.

---

### 10. Polyrhythm / Polymetric Support
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: High
**User Impact**: Low (advanced users only)

**Description**: Play two simultaneous independent rhythms (e.g., 3 against 4, 5 against 7).

**Use Case**: Advanced rhythmic training for jazz, classical, and progressive music.

**Implementation Details**:
- Dual metronome mode toggle
- Two independent time signatures running simultaneously
- Different sounds for each rhythm (Left/Right channel panning)
- Visual indicator shows both rhythms (dual beat indicators or overlay)
- Tempo relationship: Same BPM or independent tempos
- Significant architecture change - may need two `MetronomeEngine` instances

**Files to Create**:
- `src/utils/PolyrhythmEngine.vala` - Manages dual engines

**Files to Modify**:
- `src/windows/MainWindow.vala` - Dual rhythm UI
- `data/ui/main_window.blp` - Second time signature controls
- Audio system needs stereo panning

**Benefits**: Advanced practice tool for complex rhythm training.

---

## 🔧 LOW PRIORITY / POLISH FEATURES

### 11. Session History / Statistics
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: Medium
**User Impact**: Low

**Description**: Track practice sessions over time with date, duration, tempo ranges.

**Use Case**: Long-term practice tracking, motivation, progress visualization.

**Implementation Details**:
- SQLite database or JSON log file
- Log entries:
  - Date/time
  - Session duration
  - Tempo used
  - Time signature
  - Total beats played
- Statistics view dialog:
  - Total practice time (week/month/year)
  - Most used tempos
  - Practice calendar/heatmap
  - Graphs/charts (optional)
- Export statistics to CSV

**Files to Create**:
- `src/utils/SessionLogger.vala` - Logging logic
- `src/dialogs/StatisticsDialog.vala` - Statistics display
- `data/ui/statistics_dialog.blp` - Statistics UI

**Files to Modify**:
- `src/Main.vala` - Add statistics action
- `src/utils/MetronomeEngine.vala` - Session tracking integration

**Benefits**: Motivational, analytical, gamification potential.

---

### 12. Custom Visual Themes
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: Medium
**User Impact**: Low

**Description**: User-created color schemes for beat indicator beyond light/dark.

**Use Case**: Personal preference, accessibility (colorblindness), visual customization.

**Implementation Details**:
- Color picker for:
  - Regular beat color
  - Downbeat color
  - Background color
  - Glow/pulse color
- Theme presets:
  - Default (current)
  - High Contrast
  - Colorblind-friendly
  - Monochrome
  - Custom
- Custom CSS generation
- Settings persistence

**Files to Modify**:
- `src/dialogs/PreferencesDialog.vala` - Color picker controls
- `src/windows/MainWindow.vala` - Apply custom colors to drawing
- `data/io.github.tobagin.tempo.gschema.xml.in` - Color settings

**Benefits**: Personalization, accessibility improvements.

---

### 13. Pitch Reference / Tuner
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: Medium
**User Impact**: Low

**Description**: Play reference pitches (A440, etc.) alongside metronome.

**Use Case**: Tune instrument while using metronome (one-app convenience).

**Implementation Details**:
- Pitch toggle in main window
- Frequency selector (A440, A432, other notes C-B)
- Octave selector
- Volume control separate from metronome
- Continuous tone or beat-synced beep
- GStreamer tone generator (audiotestsrc element)

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Add tone generator
- `data/ui/main_window.blp` - Pitch reference controls
- `src/windows/MainWindow.vala` - Pitch UI handling

**Benefits**: Convenience (all-in-one practice tool).

---

### 14. Command-Line Interface
**Status**: Not started
**Priority**: ⭐⭐
**Complexity**: Low-Medium
**User Impact**: Low (power users)

**Description**: Start metronome from terminal with parameters.

**Use Case**: Power users, scripting, quick launch with specific settings.

**Implementation Details**:
- Argument parsing in `Main.vala`
- Arguments:
  - `--bpm=120` - Set tempo
  - `--time-signature=3/4` - Set time signature
  - `--autostart` - Start playing immediately
  - `--headless` - No GUI (terminal only)
  - `--duration=5m` - Auto-stop after duration
- Example: `tempo --bpm=140 --time-signature=4/4 --autostart`
- Output to stdout in headless mode (beat count, time elapsed)

**Files to Modify**:
- `src/Main.vala` - Add argument parsing
- `src/utils/MetronomeEngine.vala` - Headless mode support

**Benefits**: Power user workflow, automation, scripting.

---

### 15. DBus / MPRIS Integration
**Status**: Not started
**Priority**: ⭐
**Complexity**: Medium
**User Impact**: Low

**Description**: Control metronome via media keys or external scripts.

**Use Case**: Desktop environment integration, automation, media key control.

**Implementation Details**:
- DBus service registration
- MPRIS interface implementation:
  - Play/Pause - Start/Stop metronome
  - Next/Previous - Increase/Decrease tempo
  - Metadata - Current BPM, time signature
- Media key integration (Play/Pause keys)
- D-Feet compatible for debugging

**Files to Create**:
- `src/utils/DBusService.vala` - DBus interface

**Files to Modify**:
- `src/Main.vala` - Register DBus service

**Benefits**: System integration, automation possibilities.

---

### 16. Sound Waveform Preview
**Status**: Not started
**Priority**: ⭐
**Complexity**: High
**User Impact**: Low

**Description**: Visual preview of custom sound files before selection.

**Use Case**: Verify sound choice before applying.

**Implementation Details**:
- Waveform renderer in file picker dialog
- Audio file analysis (extract amplitude data)
- Cairo-based waveform drawing
- Zoom/scroll for long files
- Play button for preview (already exists)

**Files to Modify**:
- `src/dialogs/PreferencesDialog.vala` - Add waveform widget

**Benefits**: Better sound selection experience.

---

### 17. Multi-Language Audio Announcements
**Status**: Not started
**Priority**: ⭐
**Complexity**: Medium-High
**User Impact**: Low (accessibility)

**Description**: Spoken count-in or tempo announcements.

**Use Case**: Accessibility, eyes-free operation, visually impaired users.

**Implementation Details**:
- Text-to-speech integration (espeak, festival, or system TTS)
- Announcements:
  - Count-in ("1, 2, 3, 4")
  - Tempo changes ("Now 140 BPM")
  - Time signature ("4 4 time")
- Language selection based on system locale
- Volume control separate from clicks

**Files to Create**:
- `src/utils/TTSEngine.vala` - Text-to-speech wrapper

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - TTS integration
- `meson.build` - TTS library dependency

**Benefits**: Accessibility for visually impaired musicians.

---

### 18. Practice Mode with Auto-Stop
**Status**: Not started
**Priority**: ⭐⭐⭐
**Complexity**: Low
**User Impact**: Medium

**Description**: Auto-stop metronome after X beats/bars/minutes.

**Use Case**: Structured practice intervals, Pomodoro technique, timed exercises.

**Implementation Details**:
- Auto-stop toggle in main window
- Stop after:
  - X beats (e.g., 100 beats)
  - X bars (e.g., 32 bars)
  - X minutes (e.g., 5 minutes)
- Counter display showing progress to auto-stop
- Optional notification/sound when auto-stop triggers
- "Repeat" option to auto-restart after stop

**Files to Modify**:
- `src/utils/MetronomeEngine.vala` - Auto-stop logic
- `data/ui/main_window.blp` - Auto-stop controls
- `src/windows/MainWindow.vala` - Auto-stop UI handling

**Benefits**: Practice structure, time management, interval training.

---

## 📋 KNOWN ISSUES TO FIX

### Fix: Window Keep-Above Functionality
**Location**: `src/windows/MainWindow.vala:499`
**Status**: Known limitation
**Priority**: Low
**Complexity**: Medium-High

**Issue**: "Keep on top" setting exists but is non-functional in GTK4.

**Root Cause**: GTK4 doesn't expose window keep-above functionality in public API.

**Possible Solutions**:
1. Use platform-specific code (X11/Wayland protocols)
2. Wait for GTK4 API addition
3. Use compositor-specific DBus interfaces
4. Remove the setting and document limitation

**Decision Needed**: Keep as placeholder or remove entirely?

---

### Fix: Dialog Transient Window Setting
**Location**: `src/dialogs/PreferencesDialog.vala:84`
**Status**: Minor issue
**Priority**: Low
**Complexity**: Low

**Issue**: TODO comment about fixing transient_for method call.

**Investigation Needed**: Determine if this affects dialog behavior or is cosmetic.

---

## 🎯 RECOMMENDED IMPLEMENTATION ORDER

Based on user impact, complexity, and dependencies:

1. **Subdivisions Support** (Feature #1) - High impact, medium complexity
2. **Tempo Trainer** (Feature #2) - High impact, medium complexity
3. **Practice Session Timer** (Feature #4) - High impact, low complexity
4. **Practice Mode with Auto-Stop** (Feature #18) - Complements #4, low complexity
5. **Tempo Presets** (Feature #3) - High impact, medium complexity
6. **Visual Metronome Modes** (Feature #9) - Medium impact, medium complexity
7. **Export/Import Settings** (Feature #5) - Works well with #3 (presets)
8. **Silent Beats** (Feature #7) - Medium impact, medium complexity
9. **Rhythm Patterns** (Feature #6) - High complexity, advanced feature
10. **Polyrhythms** (Feature #10) - Very advanced, high complexity

---

## 📝 NOTES

- Features marked with ⭐⭐⭐⭐⭐ are most commonly found in professional metronomes
- Features marked as "Low Priority" are nice-to-have but not essential
- Complexity estimates assume familiarity with existing codebase
- All features should include comprehensive unit tests (as per project guidelines)
- Each feature should update CHANGELOG.md upon completion
- Consider creating OpenSpec proposals for major features (#1, #2, #6, #10)

---

**Last Updated**: 2025-10-20
**Document Version**: 1.0
