# Add MIDI Output Support

## Why
Professional musicians and producers often need to synchronize the metronome with external MIDI devices, DAWs, drum machines, or hardware synthesizers. MIDI clock output enables Tempo to integrate into professional workflows for recording, production, and live performance. This feature positions Tempo as a studio tool rather than just a practice app.

## What Changes
- Add MIDI clock output (24 pulses per quarter note) for tempo synchronization
- Optional MIDI note messages for beats and downbeats (configurable note numbers)
- MIDI device selection and configuration in preferences
- MIDI Start/Stop/Continue messages for transport control
- Support ALSA MIDI on Linux
- Flatpak permissions for MIDI device access
- Real-time timing synchronization between audio and MIDI output

## Impact
- **Affected specs**: New `midi-output` spec
- **Related specs**: `audio-playback` (timing synchronization), `tempo-trainer` (tempo changes via MIDI)
- **Affected code**:
  - `src/utils/MIDIOutput.vala` - NEW: ALSA MIDI communication handler
  - `src/utils/MetronomeEngine.vala` - MIDI clock and note sending integration
  - `src/dialogs/PreferencesDialog.vala` - MIDI settings page
  - `data/ui/preferences_dialog.blp` - MIDI device selector and configuration UI
  - `data/io.github.tobagin.tempo.gschema.xml.in` - MIDI settings (enabled, device, channel, notes)
  - `meson.build` - Add ALSA MIDI library dependency (libasound2-dev)
  - Flatpak manifest - Add MIDI device permissions (--device=all or specific ALSA)

## Design Decisions
- **MIDI library**: Use ALSA MIDI (alsa-lib) for native Linux MIDI support (standard, well-documented)
- **Clock precision**: Send MIDI clock at 24 PPQN, synchronized with metronome beats
- **Optional notes**: MIDI note messages optional (some users want clock only, others want notes)
- **Device selection**: Auto-detect MIDI devices, allow user selection in preferences
- **Error handling**: Graceful degradation if MIDI device unavailable (continue audio-only)
- **Flatpak sandbox**: Requires device permission, document for users to grant access

## Dependencies
- Build dependency: alsa-lib (libasound2-dev) added to meson.build
- Runtime dependency: ALSA MIDI system
- Flatpak: Add MIDI device permissions to manifest

## Migration & Compatibility
- Default: MIDI disabled (no impact on existing users)
- Optional feature, must be explicitly enabled in preferences
- No changes to existing audio metronome behavior
- If MIDI initialization fails, log error and continue audio-only (no crash)

## Risks & Considerations
- **Flatpak permissions**: Users must grant device access (may require manual flatseal configuration)
- **Timing complexity**: Synchronizing MIDI clock with audio requires careful timing coordination
- **Device compatibility**: Some MIDI devices/drivers may have issues (test with common interfaces)
- **Latency**: MIDI messages must be sent with minimal latency to maintain sync
- **User demand**: Niche feature (low priority, medium complexity, low user impact per TODO)
