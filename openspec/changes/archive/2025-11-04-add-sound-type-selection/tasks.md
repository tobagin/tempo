# Implementation Tasks

## 1. Audio Assets
- [x] 1.1 Record or source woodblock high/low sound pair (50-500ms, WAV, 16-bit, 44.1kHz, <200KB each)
- [x] 1.2 Record or source metal high/low sound pair (meeting same specs)
- [x] 1.3 Record or source digital high/low sound pair (meeting same specs)
- [x] 1.4 Normalize all audio files to consistent peak levels
- [x] 1.5 Verify high/low pairs within each type have similar volumes
- [x] 1.6 Verify accented (high) sounds are audibly distinct from regular (low) sounds
- [x] 1.7 Name files: `woodblock-high.wav`, `woodblock-low.wav`, `metal-high.wav`, `metal-low.wav`, `digital-high.wav`, `digital-low.wav`
- [x] 1.8 Place files in `data/sounds/` directory

## 2. Build System Integration
- [x] 2.1 Register new sound files in `data/io.github.tobagin.tempo.gresource.xml`
- [x] 2.2 Verify sound files are included in Meson build install step
- [x] 2.3 Test that all sound files are accessible via GResource URIs after build
- [x] 2.4 Verify Flatpak build includes all sound files

## 3. GSettings Schema
- [x] 3.1 Add `high-sound-type` string setting with default value "default" to gschema.xml
- [x] 3.2 Add `low-sound-type` string setting with default value "default" to gschema.xml
- [x] 3.3 Add summary and description for both new settings
- [x] 3.4 Compile and test schema changes locally
- [x] 3.5 Verify backward compatibility with existing settings

## 4. MetronomeEngine Sound Loading
- [x] 4.1 Create helper method `get_sound_type_uri(sound_type: string, is_high: bool): string`
- [x] 4.2 Implement sound type to file path mapping (e.g., "woodblock" -> "/app/share/tempo/sounds/woodblock-high.wav")
- [x] 4.3 Update `get_sound_uri()` to check sound type settings when custom sounds are disabled
- [x] 4.4 Add validation for sound type file existence with fallback to default
- [x] 4.5 Update sound URI resolution priority: custom path (if enabled) > sound type > default
- [x] 4.6 Add startup validation for all bundled sound type files
- [x] 4.7 Log warnings for missing sound type files without crashing
- [x] 4.8 Test sound type changes take effect on next beat without restart

## 5. PreferencesDialog UI
- [x] 5.1 Add `high_sound_type_dropdown` and `low_sound_type_dropdown` UI elements to Blueprint file
- [x] 5.2 Create string list model with sound type options: "Default", "Woodblock", "Metal", "Digital"
- [x] 5.3 Position dropdowns above custom sound file selector rows
- [x] 5.4 Bind dropdown selections to GSettings keys
- [x] 5.5 Implement logic to disable high sound type dropdown when custom high sound is set
- [x] 5.6 Implement logic to disable low sound type dropdown when custom low sound is set
- [x] 5.7 Re-enable type dropdown when corresponding custom sound is cleared
- [x] 5.8 Load initial sound type selections from GSettings on dialog open

## 6. PreferencesDialog Logic
- [x] 6.1 Add `high_sound_type` and `low_sound_type` properties to track current selections
- [x] 6.2 Connect dropdown `notify["selected"]` signals to save sound type to GSettings
- [x] 6.3 Update `update_custom_sounds_sensitivity()` to also control sound type dropdown sensitivity
- [x] 6.4 Update `reset_custom_sound()` to re-enable corresponding sound type dropdown
- [x] 6.5 Handle external GSettings changes for sound type keys
- [x] 6.6 Update `load_settings()` to initialize sound type dropdowns

## 7. Testing
- [x] 7.1 Test all sound types play correctly for high and low sounds
- [x] 7.2 Test mixing sound types (e.g., woodblock high + metal low)
- [x] 7.3 Test sound type persistence across application restarts
- [x] 7.4 Test mixing built-in sound type with custom sounds
- [x] 7.5 Test clearing custom sound re-enables type dropdown
- [x] 7.6 Test backward compatibility: fresh install vs upgrade
- [x] 7.7 Test invalid sound type in GSettings falls back gracefully
- [x] 7.8 Test missing sound file falls back to default without crash
- [x] 7.9 Test sound type changes while metronome is running
- [x] 7.10 Test visual-only mode doesn't break with sound types

## 8. Documentation
- [x] 8.1 Update CHANGELOG.md with new sound type feature
- [x] 8.2 Update README.md if sound types are notable user-facing feature
- [x] 8.3 Add code comments explaining sound type priority and fallback logic

## 9. Validation
- [x] 9.1 Run `./scripts/build.sh --dev` and verify successful build
- [x] 9.2 Run application and test all sound types manually
- [x] 9.3 Check for memory leaks with rapid sound type switching
- [x] 9.4 Verify no regressions in custom sound functionality
- [x] 9.5 Run `./scripts/validate-automation.sh` if available
