# Implementation Tasks

## Phase 1: ALSA MIDI Infrastructure

### Task 1: Add ALSA dependency to build system
- Open `meson.build`, add `alsa = dependency('alsa', version: '>= 1.0')`
- Add ALSA to dependencies list for Vala compilation
- Test build with dependency

**Validation**: Build succeeds with ALSA linked

**Dependencies**: None

---

### Task 2: Create MIDIOutput class skeleton
- Create `src/utils/MIDIOutput.vala`
- Add `using Alsa;` import
- Define class with properties: enabled, channel, notes, send_clock, send_notes
- Add signals: midi_error, device_connected, device_disconnected
- Add to `src/meson.build`

**Validation**: File compiles, class instantiates

**Dependencies**: Task 1

---

### Task 3: Implement ALSA sequencer initialization
- In `MIDIOutput`, implement `initialize()` method
- Open ALSA sequencer with `Alsa.Sequencer.open()`
- Set client name "Tempo Metronome"
- Create simple output port
- Handle errors with throws Error
- Add `close()` method for cleanup

**Validation**: Sequencer opens successfully on Linux with ALSA

**Dependencies**: Task 2

---

### Task 4: Implement MIDI message sending
- In `MIDIOutput`, implement `send_start()`, `send_stop()`, `send_clock()`
- Implement `send_note_on()`, `send_note_off()`
- Use `Alsa.Event` structure for messages
- Send via `sequencer.event_output_direct()`
- Handle send errors

**Validation**: Messages sent to ALSA successfully (verify with amidi)

**Dependencies**: Task 3

---

## Phase 2: MIDI Clock Engine

### Task 5: Create MIDIClock class
- Create `src/utils/MIDIClock.vala` (or add to MIDIOutput.vala)
- Properties: bpm, beat_duration, clock_interval (1/24th beat)
- Timing state: next_clock_time, timeout_id
- Methods: start(), stop(), update_bpm()
- Use absolute time with GLib.get_monotonic_time()

**Validation**: Clock class instantiates, intervals calculated correctly

**Dependencies**: Task 4

---

### Task 6: Implement MIDI clock timing loop
- In `MIDIClock`, implement `on_clock_tick()` callback
- Send clock message via MIDIOutput
- Calculate next_clock_time (absolute time)
- Schedule next clock with GLib.Timeout
- Maintain < 1ms jitter

**Validation**: 24 clocks sent per beat at correct intervals

**Dependencies**: Task 5

---

## Phase 3: MetronomeEngine Integration

### Task 7: Add MIDI properties to MetronomeEngine
- Open `src/utils/MetronomeEngine.vala`
- Add members: midi_output, midi_clock
- Add method: `initialize_midi(GLib.Settings)`
- Load MIDI settings and create objects if enabled

**Validation**: MetronomeEngine can initialize MIDI

**Dependencies**: Task 4, Task 5

---

### Task 8: Integrate MIDI with metronome start/stop
- In `MetronomeEngine.start()`, call `midi_clock.start()` if enabled
- Send MIDI Start message
- In `MetronomeEngine.stop()`, call `midi_clock.stop()`
- Send MIDI Stop message
- Handle null checks

**Validation**: MIDI Start/Stop sent on play/pause

**Dependencies**: Task 7

---

### Task 9: Send MIDI notes on beats
- In `MetronomeEngine.on_beat_timeout()`, send MIDI note if enabled
- Select downbeat or regular note based on is_downbeat
- Set velocity: 127 for downbeat, 100 for regular
- Schedule Note Off after 50ms

**Validation**: MIDI notes sent aligned with audio beats

**Dependencies**: Task 8

---

### Task 10: Synchronize MIDI with BPM changes
- In `MetronomeEngine.set_bpm()`, call `midi_clock.update_bpm()` if active
- Recalculate clock intervals
- Ensure smooth tempo transition

**Validation**: MIDI clock adjusts to new BPM immediately

**Dependencies**: Task 8

---

## Phase 4: Settings and Preferences

### Task 11: Add MIDI settings to schema
- Open `data/io.github.tobagin.tempo.gschema.xml.in`
- Add keys: midi-enabled, midi-device, midi-channel
- Add keys: midi-send-clock, midi-send-notes
- Add keys: midi-downbeat-note, midi-regular-note
- Validate schema

**Validation**: Settings keys accessible

**Dependencies**: None

---

### Task 12: Create MIDI preferences page UI
- Open `data/ui/preferences_dialog.blp`
- Add "MIDI Output" page
- Add Gtk.Switch for MIDI enabled
- Add Adw.ComboRow for device selection
- Add Adw.SpinRow for channel (1-16)
- Add checkboxes for send-clock, send-notes
- Add spin rows for note numbers with note name labels
- Add "Test MIDI" button

**Validation**: MIDI preferences UI renders

**Dependencies**: Task 11

---

### Task 13: Implement device enumeration
- In `MIDIOutput`, add static method `get_available_devices()`
- Use ALSA sequencer client enumeration
- Return list of MIDIDevice objects (name, client_id, port_id)
- Include "Virtual Port" option

**Validation**: Lists available MIDI devices correctly

**Dependencies**: Task 3

---

### Task 14: Populate device dropdown in preferences
- Open `src/dialogs/PreferencesDialog.vala`
- Call `MIDIOutput.get_available_devices()` on page open
- Populate device ComboRow with device names
- Bind to GSettings midi-device

**Validation**: Device dropdown shows available devices

**Dependencies**: Task 12, Task 13

---

### Task 15: Implement MIDI test functionality
- In `PreferencesDialog`, add handler for "Test MIDI" button
- Create temporary MIDIOutput instance
- Send test notes: downbeat note, wait 200ms, regular note
- Display "Test sent" confirmation
- Handle errors gracefully

**Validation**: Test notes sent when button clicked

**Dependencies**: Task 4, Task 14

---

## Phase 5: Error Handling and Polish

### Task 16: Implement graceful MIDI failure handling
- In `MetronomeEngine.initialize_midi()`, wrap in try-catch
- On error, log warning and set midi_output = null
- Display toast: "MIDI unavailable, using audio only"
- Ensure metronome continues audio-only operation

**Validation**: App doesn't crash if MIDI fails, shows helpful message

**Dependencies**: Task 7

---

### Task 17: Handle MIDI disconnect during playback
- In `MIDIOutput`, detect disconnect via ALSA error codes
- Emit device_disconnected signal
- Stop MIDI output gracefully
- In `MainWindow`, listen for signal and show notification

**Validation**: Disconnect detected, app continues audio playback

**Dependencies**: Task 4, Task 16

---

### Task 18: Add note name display helper
- Create helper function: `midi_note_to_name(int note) -> string`
- Map 0-127 to note names (e.g., 60 = "C4", 76 = "E5")
- Update note number spin rows to display name alongside number
- Update in real-time as spinner changes

**Validation**: Note names displayed correctly (e.g., "60 - C4")

**Dependencies**: Task 12

---

### Task 19: Update Flatpak manifest for MIDI permissions
- Open Flatpak manifest (io.github.tobagin.tempo.json)
- Add `"--device=all"` to finish-args
- Document in README.md that MIDI requires device permissions
- Note users may need Flatseal if sandboxed

**Validation**: Flatpak build includes MIDI permissions

**Dependencies**: None

---

## Phase 6: Testing

### Task 20: Test MIDI clock accuracy
- Measure clock interval timing over 1000 beats
- Verify 24 clocks per beat
- Check jitter < 1ms
- Test at various BPMs (60, 120, 180, 240)

**Validation**: Clock timing accurate and stable

**Dependencies**: Task 6

---

### Task 21: Test MIDI synchronization with DAW
- Connect Tempo MIDI output to DAW (Ardour, Reaper, etc.)
- Start metronome and verify DAW syncs
- Check tempo changes reflected in DAW
- Verify Start/Stop messages control DAW transport

**Validation**: DAW synchronizes correctly with Tempo

**Dependencies**: All previous tasks

---

### Task 22: Test MIDI note messages
- Connect to MIDI monitor or DAW instrument
- Verify downbeat and regular beat notes sent
- Check note duration (50ms Note Off delay)
- Test various note numbers and channels

**Validation**: Notes trigger correctly in external devices

**Dependencies**: Task 9

---

### Task 23: Update CHANGELOG and documentation
- Add feature entry: "Add MIDI output support with clock and note messages"
- Document MIDI setup in README.md
- Explain Flatpak permissions requirements
- Provide example DAW connection instructions

**Validation**: Documentation complete

**Dependencies**: All feature tasks complete

---

## Notes
- Total tasks: 23
- Estimated complexity: High (requires ALSA/MIDI expertise)
- Priority: Medium (per TODO.md)
- User impact: Low (niche feature for producers/DAW users)
- Flatpak permissions required: `--device=all`
