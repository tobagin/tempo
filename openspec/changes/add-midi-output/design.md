# MIDI Output Design

## Architecture Overview

MIDI output extends Tempo's metronome functionality with MIDI clock and note messages for synchronization with external devices and DAWs. The design integrates ALSA MIDI communication with the existing MetronomeEngine timing loop, maintaining sub-millisecond precision for clock messages.

## Core Concepts

### MIDI Clock (Timing Clock)
- **24 PPQN**: 24 MIDI clock messages per quarter note (beat)
- **Continuous**: Clock messages sent continuously at calculated intervals
- **Synchronization**: Must align with audio playback timing
- At 120 BPM:
  - 1 beat = 0.5 seconds
  - 24 clocks per beat = 20.83ms between clock messages

### MIDI Transport Messages
- **Start (0xFA)**: Sent when metronome starts from beginning
- **Stop (0xFC)**: Sent when metronome stops
- **Continue (0xFB)**: Sent when metronome resumes (optional, may use Start)

### MIDI Note Messages
- **Note On (0x90 + channel)**: Sent on beats and downbeats
- **Note Off (0x80 + channel)**: Sent shortly after Note On
- **Configurable notes**: User selects MIDI note numbers for downbeat and regular beat
- **Velocity**: Downbeat higher velocity (127), regular beat medium (100)

## Core Components

### 1. MIDIOutput Class

```vala
using Alsa;

public class MIDIOutput : GLib.Object {
    // ALSA sequencer handle
    private Alsa.Sequencer? sequencer = null;
    private int port_id = -1;
    private bool is_connected = false;

    // MIDI configuration
    public bool enabled { get; set; default = false; }
    public int channel { get; set; default = 0; }        // 0-15
    public int downbeat_note { get; set; default = 76; }  // E5
    public int regular_note { get; set; default = 77; }   // F5
    public bool send_clock { get; set; default = true; }
    public bool send_notes { get; set; default = false; }

    // Timing state
    private int64 next_clock_time = 0;
    private int clock_position = 0;  // 0-23 within current beat
    private uint clock_timeout_id = 0;

    // Signals
    public signal void midi_error(string message);
    public signal void device_connected(string device_name);
    public signal void device_disconnected();

    /**
     * Initialize ALSA sequencer and create output port
     */
    public bool initialize() throws Error {
        // Open ALSA sequencer in non-blocking mode
        int result = Alsa.Sequencer.open(out sequencer, "default",
                                          Alsa.Sequencer.OPEN_OUTPUT,
                                          Alsa.Sequencer.NONBLOCK);
        if (result < 0) {
            throw new IOError.FAILED("Failed to open ALSA sequencer: %s",
                                      Alsa.strerror(result));
        }

        // Set client name
        sequencer.set_client_name("Tempo Metronome");

        // Create output port
        port_id = sequencer.create_simple_port("Tempo MIDI Out",
                                                Alsa.Sequencer.PORT_CAP_READ |
                                                Alsa.Sequencer.PORT_CAP_SUBS_READ,
                                                Alsa.Sequencer.PORT_TYPE_MIDI_GENERIC |
                                                Alsa.Sequencer.PORT_TYPE_APPLICATION);
        if (port_id < 0) {
            throw new IOError.FAILED("Failed to create MIDI port");
        }

        is_connected = true;
        return true;
    }

    /**
     * Send MIDI Start message
     */
    public void send_start() {
        if (!enabled || sequencer == null) return;

        Alsa.Event event = Alsa.Event();
        event.type = Alsa.EventType.START;
        send_event(ref event);
    }

    /**
     * Send MIDI Stop message
     */
    public void send_stop() {
        if (!enabled || sequencer == null) return;

        Alsa.Event event = Alsa.Event();
        event.type = Alsa.EventType.STOP;
        send_event(ref event);
    }

    /**
     * Send MIDI Clock message
     */
    public void send_clock() {
        if (!enabled || !send_clock || sequencer == null) return;

        Alsa.Event event = Alsa.Event();
        event.type = Alsa.EventType.CLOCK;
        send_event(ref event);
    }

    /**
     * Send MIDI Note On message
     */
    public void send_note_on(int note, int velocity) {
        if (!enabled || !send_notes || sequencer == null) return;

        Alsa.Event event = Alsa.Event();
        event.type = Alsa.EventType.NOTEON;
        event.data.note.channel = (uchar)channel;
        event.data.note.note = (uchar)note;
        event.data.note.velocity = (uchar)velocity;
        send_event(ref event);
    }

    /**
     * Send MIDI Note Off message
     */
    public void send_note_off(int note) {
        if (!enabled || !send_notes || sequencer == null) return;

        Alsa.Event event = Alsa.Event();
        event.type = Alsa.EventType.NOTEOFF;
        event.data.note.channel = (uchar)channel;
        event.data.note.note = (uchar)note;
        event.data.note.velocity = 0;
        send_event(ref event);

        // Schedule note off after 50ms
        GLib.Timeout.add(50, () => {
            send_note_off_immediate(note);
            return false;
        });
    }

    /**
     * Internal: Send ALSA event
     */
    private void send_event(ref Alsa.Event event) {
        event.source.port = (uchar)port_id;
        event.dest.client = Alsa.Sequencer.ADDRESS_SUBSCRIBERS;
        event.dest.port = Alsa.Sequencer.ADDRESS_UNKNOWN;
        event.queue = Alsa.Sequencer.QUEUE_DIRECT;

        int result = sequencer.event_output_direct(ref event);
        if (result < 0) {
            midi_error("Failed to send MIDI event: " + Alsa.strerror(result));
        }
    }

    /**
     * Get list of available MIDI devices
     */
    public static Gee.ArrayList<MIDIDevice> get_available_devices() {
        // Enumerate ALSA MIDI devices
        var devices = new Gee.ArrayList<MIDIDevice>();

        // Implementation would scan ALSA sequencer clients
        // Add to devices list

        return devices;
    }

    /**
     * Cleanup and close ALSA sequencer
     */
    public void close() {
        if (sequencer != null) {
            if (port_id >= 0) {
                sequencer.delete_simple_port(port_id);
            }
            sequencer = null;
        }
        is_connected = false;
    }
}

public class MIDIDevice : GLib.Object {
    public string name { get; set; }
    public int client_id { get; set; }
    public int port_id { get; set; }
}
```

### 2. MIDI Clock Timing

```vala
public class MIDIClock : GLib.Object {
    private MIDIOutput midi_output;
    private int bpm;
    private double beat_duration;  // seconds per beat
    private double clock_interval; // seconds per clock (1/24th beat)

    private uint timeout_id = 0;
    private int64 next_clock_time = 0;

    public MIDIClock(MIDIOutput output, int bpm) {
        this.midi_output = output;
        this.bpm = bpm;
        calculate_intervals();
    }

    private void calculate_intervals() {
        beat_duration = 60.0 / (double)bpm;
        clock_interval = beat_duration / 24.0;
    }

    public void start() {
        if (timeout_id != 0) return;

        // Send MIDI Start message
        midi_output.send_start();

        // Initialize timing
        next_clock_time = GLib.get_monotonic_time();

        // Start clock loop
        schedule_next_clock();
    }

    public void stop() {
        if (timeout_id != 0) {
            GLib.Source.remove(timeout_id);
            timeout_id = 0;
        }

        // Send MIDI Stop message
        midi_output.send_stop();
    }

    private void schedule_next_clock() {
        int64 current_time = GLib.get_monotonic_time();
        int64 time_until_next = next_clock_time - current_time;

        if (time_until_next < 0) {
            time_until_next = 0;
        }

        timeout_id = GLib.Timeout.add((uint)(time_until_next / 1000), on_clock_tick);
    }

    private bool on_clock_tick() {
        // Send MIDI Clock message
        midi_output.send_clock();

        // Calculate next clock time (absolute time to prevent drift)
        next_clock_time += (int64)(clock_interval * 1000000);

        // Schedule next clock
        schedule_next_clock();

        return false; // Single-shot timeout
    }

    public void update_bpm(int new_bpm) {
        this.bpm = new_bpm;
        calculate_intervals();
    }
}
```

### 3. MetronomeEngine Integration

```vala
public class MetronomeEngine : GLib.Object {
    // Existing properties...

    // NEW: MIDI properties
    private MIDIOutput? midi_output = null;
    private MIDIClock? midi_clock = null;

    public void initialize_midi(GLib.Settings settings) {
        bool midi_enabled = settings.get_boolean("midi-enabled");
        if (!midi_enabled) return;

        midi_output = new MIDIOutput();
        midi_output.enabled = true;
        midi_output.channel = settings.get_int("midi-channel");
        midi_output.downbeat_note = settings.get_int("midi-downbeat-note");
        midi_output.regular_note = settings.get_int("midi-regular-note");
        midi_output.send_clock = settings.get_boolean("midi-send-clock");
        midi_output.send_notes = settings.get_boolean("midi-send-notes");

        try {
            midi_output.initialize();
            midi_clock = new MIDIClock(midi_output, bpm);
        } catch (Error e) {
            warning("MIDI initialization failed: %s", e.message);
            midi_output = null;
        }
    }

    public override void start() {
        // Existing audio start code...

        // Start MIDI clock if enabled
        if (midi_clock != null) {
            midi_clock.start();
        }
    }

    public override void stop() {
        // Stop MIDI clock if active
        if (midi_clock != null) {
            midi_clock.stop();
        }

        // Existing audio stop code...
    }

    private bool on_beat_timeout() {
        // Existing beat logic...

        // Send MIDI note if enabled
        if (midi_output != null && midi_output.send_notes) {
            int note = is_downbeat ? midi_output.downbeat_note : midi_output.regular_note;
            int velocity = is_downbeat ? 127 : 100;
            midi_output.send_note_on(note, velocity);

            // Note off after 50ms
            GLib.Timeout.add(50, () => {
                midi_output.send_note_off(note);
                return false;
            });
        }

        // Existing code continues...
    }

    public void set_bpm(int new_bpm) {
        // Existing BPM change code...

        // Update MIDI clock tempo
        if (midi_clock != null) {
            midi_clock.update_bpm(new_bpm);
        }
    }
}
```

## Settings Schema

```xml
<key name="midi-enabled" type="b">
  <default>false</default>
  <summary>Enable MIDI output</summary>
</key>

<key name="midi-device" type="s">
  <default>''</default>
  <summary>MIDI device name</summary>
</key>

<key name="midi-channel" type="i">
  <default>0</default>
  <range min="0" max="15"/>
  <summary>MIDI channel (0-15)</summary>
</key>

<key name="midi-send-clock" type="b">
  <default>true</default>
  <summary>Send MIDI clock messages</summary>
</key>

<key name="midi-send-notes" type="b">
  <default>false</default>
  <summary>Send MIDI note messages</summary>
</key>

<key name="midi-downbeat-note" type="i">
  <default>76</default>
  <range min="0" max="127"/>
  <summary>MIDI note number for downbeat (E5 = 76)</summary>
</key>

<key name="midi-regular-note" type="i">
  <default>77</default>
  <range min="0" max="127"/>
  <summary>MIDI note number for regular beat (F5 = 77)</summary>
</key>
```

## Preferences UI

### MIDI Settings Page
- **Enable MIDI**: Toggle switch
- **Device Selection**: Dropdown with available MIDI devices (or "Virtual Port")
- **MIDI Channel**: Spin button (1-16, display 1-indexed, store 0-indexed)
- **Send Clock**: Checkbox (enabled by default)
- **Send Notes**: Checkbox (disabled by default)
- **Note Numbers**:
  - Downbeat note: Spin button (0-127) with note name display (e.g., "76 - E5")
  - Regular beat note: Spin button (0-127) with note name display
- **Test**: Button to send test notes
- **Status**: Label showing connection status ("Connected", "Disconnected", "Error")

## Flatpak Permissions

Add to manifest (io.github.tobagin.tempo.json):
```json
{
  "finish-args": [
    "--device=all",
    // OR more restrictive:
    "--device=dri",
    "--filesystem=xdg-run/pipewire-0",
    "--socket=pulseaudio"
  ]
}
```

Note: `--device=all` grants access to ALSA MIDI devices. More restrictive approach may require users to manually grant permission via Flatseal.

## Error Handling

### MIDI Device Unavailable
- Attempt initialization on startup
- If fails, log warning and continue audio-only
- Display error toast: "MIDI device unavailable, using audio only"
- Allow retry via preferences (reconnect button)

### MIDI Device Disconnected Mid-Session
- Detect disconnect (ALSA error codes)
- Stop MIDI output gracefully
- Continue audio playback
- Show notification: "MIDI device disconnected"
- Attempt reconnection on next start

### Buffer Overflow/Underrun
- ALSA may report buffer issues
- Log warning
- Continue operation (MIDI messages may be dropped)

## Testing Strategy

### Unit Tests
- MIDI clock interval calculation (120 BPM = 20.83ms per clock)
- MIDI message construction (correct bytes)
- Note on/off timing (50ms duration)
- BPM change updates clock interval

### Integration Tests
- MIDI clock synchronization with audio beats
- Start/Stop messages sent correctly
- Note messages align with beat events
- Device enumeration works

### Manual Testing
- Connect to DAW (Ardour, Reaper, etc.) via MIDI
- Verify clock messages received (24 per beat)
- Verify tempo sync with DAW clock
- Test note messages trigger DAW instruments
- Test various BPMs (60, 120, 180, 240)
- Test MIDI channel selection
- Test device disconnect/reconnect

## Performance Considerations

### Timing Precision
- MIDI clock must maintain < 1ms jitter
- Use absolute time references (GLib.get_monotonic_time())
- Separate timeout for each clock message (not batched)

### CPU Usage
- MIDI clock adds 24 timeout callbacks per beat
- At 240 BPM: 96 callbacks per second (minimal overhead)
- ALSA is efficient, < 0.1ms per message

### Memory
- MIDIOutput object: ~2KB
- MIDIClock object: ~1KB
- Total overhead: < 5KB

## Alternatives Considered

### PortMIDI Library
- Cross-platform MIDI library
- Pros: Platform-independent
- Cons: Additional dependency, less native to Linux
- Decision: Use ALSA for native Linux integration

### JACK MIDI
- Professional audio/MIDI routing
- Pros: Low latency, studio standard
- Cons: Requires JACK server, complex setup
- Decision: ALSA sufficient for most users, JACK optional future enhancement

### PipeWire MIDI
- Modern audio/MIDI framework
- Pros: Future of Linux audio
- Cons: Newer, less documentation
- Decision: ALSA currently, migrate to PipeWire when mature
