/**
 * Precision timing engine for the metronome application.
 *
 * This module provides the core timing functionality with sub-millisecond accuracy
 * using absolute time references to prevent drift and jitter.
 */

using GLib;

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
public class MetronomeEngine : Object {
    
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
        info["beat_in_bar"] = new Variant.int32((current_beat % beats_per_bar) + 1);
        info["is_downbeat"] = new Variant.boolean((current_beat % beats_per_bar) == 0);
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
        
        // Determine if this is a downbeat
        bool is_downbeat = (current_beat % beats_per_bar) == 0;
        
        // Emit beat signal
        beat_occurred(current_beat, is_downbeat);
        
        // Update beat counter
        current_beat++;
        
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
}