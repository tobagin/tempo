/**
 * Precision timing engine for the metronome application.
 *
 * This module provides the core timing functionality with sub-millisecond accuracy
 * using absolute time references to prevent drift and jitter.
 */

using GLib;
using Gst;

/**
 * Error domain for metronome-related errors.
 */
public errordomain MetronomeError {
    INVALID_BPM,
    INVALID_TIME_SIGNATURE
}

/**
 * High-precision metronome timing engine.
 * 
 * Uses absolute time references with GLib.get_monotonic_time() to prevent
 * timing drift and jitter. Integrates with the GTK main loop using GLib.Timeout.
 */
public class MetronomeEngine : GLib.Object {
    
    // Properties matching Python implementation
    public int bpm { get; set; default = 120; }
    public int beats_per_bar { get; set; default = 4; }
    public int beat_value { get; set; default = 4; }
    public bool is_running { get; private set; default = false; }
    public int current_beat { get; set; default = 0; }
    
    // Signal for beat events (replaces Python callback)
    public signal void beat_occurred(int beat_number, bool is_downbeat);
    
    // Private timing state
    private uint timeout_id = 0;
    private int64 next_beat_time = 0;
    private double beat_duration = 0.5; // 120 BPM = 0.5 seconds per beat
    
    // Audio playback elements
    private Gst.Element? high_sound_player = null;
    private Gst.Element? low_sound_player = null;
    private GLib.Settings? settings = null;
    private bool audio_initialized = false;
    
    /**
     * Creates a new MetronomeEngine with default settings.
     */
    public MetronomeEngine() {
        // Connect property change notifications
        this.notify["bpm"].connect(() => {
            this.beat_duration = 60.0 / (double)bpm;
        });
        
        // Initialize beat duration
        this.beat_duration = 60.0 / (double)bpm;
        
        // Initialize audio
        initialize_audio();
    }
    
    /**
     * Start the metronome.
     */
    public void start() {
        if (is_running) {
            return; // Already running
        }
        
        is_running = true;
        current_beat = 0;
        
        // Initialize timing
        beat_duration = 60.0 / (double)bpm;
        next_beat_time = GLib.get_monotonic_time() + (int64)(beat_duration * 1000000);
        
        // Start the timing loop
        schedule_next_beat();
    }
    
    /**
     * Stop the metronome.
     */
    public void stop() {
        if (!is_running) {
            return; // Already stopped
        }
        
        is_running = false;
        
        // Remove timeout source
        if (timeout_id != 0) {
            Source.remove(timeout_id);
            timeout_id = 0;
        }
    }
    
    /**
     * Set the tempo in beats per minute.
     * 
     * @param new_bpm Beats per minute (40-240)
     * @throws MetronomeError.INVALID_BPM if BPM is out of range
     */
    public void set_tempo(int new_bpm) throws MetronomeError {
        if (new_bpm < 40 || new_bpm > 240) {
            throw new MetronomeError.INVALID_BPM(
                "BPM must be between 40 and 240, got %d".printf(new_bpm)
            );
        }
        
        bpm = new_bpm;
        beat_duration = 60.0 / (double)bpm;
    }
    
    /**
     * Set the time signature.
     * 
     * @param numerator Beats per bar (1-16)
     * @param denominator Note value (2, 4, 8, 16)
     * @throws MetronomeError.INVALID_TIME_SIGNATURE if values are invalid
     */
    public void set_time_signature(int numerator, int denominator) throws MetronomeError {
        if (numerator < 1 || numerator > 16) {
            throw new MetronomeError.INVALID_TIME_SIGNATURE(
                "Time signature numerator must be 1-16, got %d".printf(numerator)
            );
        }
        
        if (!(denominator == 2 || denominator == 4 || denominator == 8 || denominator == 16)) {
            throw new MetronomeError.INVALID_TIME_SIGNATURE(
                "Time signature denominator must be 2, 4, 8, or 16, got %d".printf(denominator)
            );
        }
        
        beats_per_bar = numerator;
        beat_value = denominator;
    }
    
    /**
     * Reset the beat counter to 0.
     */
    public void reset_beat_counter() {
        current_beat = 0;
    }
    
    /**
     * Get current beat information.
     * 
     * @return HashTable with beat information matching Python dict
     */
    public HashTable<string, Variant> get_beat_info() {
        var info = new HashTable<string, Variant>(str_hash, str_equal);
        
        info["current_beat"] = new Variant.int32(current_beat);
        info["beats_per_bar"] = new Variant.int32(beats_per_bar);
        
        // Calculate beat in bar: 1-based, cycles from 1 to beats_per_bar
        int beat_in_bar;
        if (current_beat == 0) {
            beat_in_bar = 1; // Before first beat, show 1
        } else {
            beat_in_bar = ((current_beat - 1) % beats_per_bar) + 1;
        }
        
        info["beat_in_bar"] = new Variant.int32(beat_in_bar);
        info["is_downbeat"] = new Variant.boolean(beat_in_bar == 1);
        info["is_running"] = new Variant.boolean(is_running);
        info["bpm"] = new Variant.int32(bpm);
        info["time_signature"] = new Variant.string("%d/%d".printf(beats_per_bar, beat_value));
        
        return info;
    }
    
    /**
     * Schedule the next beat using GLib.Timeout.
     */
    private void schedule_next_beat() {
        if (!is_running) {
            return;
        }
        
        int64 current_time = GLib.get_monotonic_time();
        int64 wait_time_us = next_beat_time - current_time;
        
        // Check if we're too far behind (e.g., after system sleep)
        if (wait_time_us < -((int64)(beat_duration * 1000000))) {
            // Reset timing to current time
            next_beat_time = current_time + (int64)(beat_duration * 1000000);
            wait_time_us = (int64)(beat_duration * 1000000);
        }
        
        // Convert microseconds to milliseconds for GLib.Timeout
        uint wait_time_ms = (uint)int64.max(1, wait_time_us / 1000);
        
        timeout_id = Timeout.add(wait_time_ms, () => {
            return on_beat_timeout();
        });
    }
    
    /**
     * Handle beat timeout - emit signal and schedule next beat.
     * 
     * @return false to remove the timeout source
     */
    private bool on_beat_timeout() {
        if (!is_running) {
            timeout_id = 0;
            return false; // Remove timeout
        }
        
        // Update beat counter first
        current_beat++;
        
        // Determine if this is a downbeat (after incrementing)
        bool is_downbeat = (current_beat % beats_per_bar) == 1;
        
        // Play click sound
        play_click_sound(is_downbeat);
        
        // Emit beat signal
        beat_occurred(current_beat, is_downbeat);
        
        // Calculate next beat time (absolute time to prevent drift)
        next_beat_time += (int64)(beat_duration * 1000000);
        
        // Update beat duration if tempo changed
        double new_duration = 60.0 / (double)bpm;
        if (Math.fabs(new_duration - beat_duration) > 0.001) { // 1ms tolerance
            beat_duration = new_duration;
        }
        
        // Schedule next beat
        schedule_next_beat();
        
        // Remove this timeout (we created a new one)
        timeout_id = 0;
        return false;
    }
    
    /**
     * Initialize audio system.
     */
    private void initialize_audio() {
        try {
            settings = new GLib.Settings("io.github.tobagin.tempo");
            
            // Initialize GStreamer elements
            create_audio_players();
            audio_initialized = true;
        } catch (Error e) {
            warning("Failed to initialize audio: %s", e.message);
        }
    }
    
    /**
     * Create GStreamer playback elements.
     */
    private void create_audio_players() {
        try {
            // Create players for high and low sounds
            high_sound_player = Gst.ElementFactory.make("playbin", "high_sound_player");
            low_sound_player = Gst.ElementFactory.make("playbin", "low_sound_player");
            
            if (high_sound_player == null || low_sound_player == null) {
                warning("Failed to create GStreamer playbin elements");
                return;
            }
            
            // Set default sound URIs
            string app_data_dir = "/app/share/tempo/sounds";
            high_sound_player.set("uri", "file://" + app_data_dir + "/high.wav");
            low_sound_player.set("uri", "file://" + app_data_dir + "/low.wav");
            
        } catch (Error e) {
            warning("Error creating audio players: %s", e.message);
        }
    }
    
    /**
     * Play a click sound.
     * 
     * @param is_downbeat Whether this is a downbeat (accent) or regular beat
     */
    private void play_click_sound(bool is_downbeat) {
        if (!audio_initialized || settings == null) {
            return;
        }
        
        try {
            Gst.Element? player = is_downbeat ? high_sound_player : low_sound_player;
            
            if (player == null) {
                return;
            }
            
            // Check if using custom sounds
            if (settings.get_boolean("use-custom-sounds")) {
                string? custom_path = is_downbeat ? 
                    settings.get_string("high-sound-path") : 
                    settings.get_string("low-sound-path");
                    
                if (custom_path != null && custom_path != "") {
                    player.set("uri", "file://" + custom_path);
                }
            }
            
            // Set volume
            double volume = is_downbeat ? 
                settings.get_double("accent-volume") : 
                settings.get_double("click-volume");
            player.set("volume", volume);
            
            // Reset to beginning and play
            player.set_state(Gst.State.NULL);
            player.set_state(Gst.State.PLAYING);
            
            // Stop after short duration to prevent overlap
            Timeout.add(200, () => {
                if (player != null) {
                    player.set_state(Gst.State.NULL);
                }
                return false;
            });
            
        } catch (Error e) {
            warning("Error playing click sound: %s", e.message);
        }
    }
}
