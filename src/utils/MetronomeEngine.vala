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
 * Subdivision modes for metronome timing.
 */
public enum SubdivisionMode {
    NONE = 0,      // No subdivisions (current behavior)
    EIGHTH = 2,    // 2 per beat (eighth notes)
    SIXTEENTH = 4, // 4 per beat (sixteenth notes)
    TRIPLET = 3    // 3 per beat (triplet feel)
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

    // Subdivision properties
    public SubdivisionMode subdivision_mode { get; set; default = SubdivisionMode.NONE; }
    public double subdivision_volume { get; set; default = 0.5; }

    // Mute pattern properties
    public bool mute_enabled { get; set; default = false; }
    public Tempo.MutePattern? mute_pattern { get; set; default = null; }

    // Signal for beat events (replaces Python callback)
    public signal void beat_occurred(int beat_number, bool is_downbeat, bool is_muted);

    // Signal for subdivision events
    public signal void subdivision_occurred(int beat_number, int subdivision_index, int subdivisions_per_beat);
    
    // Private timing state
    private uint timeout_id = 0;
    private int64 next_beat_time = 0;
    private double beat_duration = 0.5; // 120 BPM = 0.5 seconds per beat

    // Subdivision timing state
    private int subdivisions_per_beat = 1;
    private int64 next_subdivision_time = 0;
    private int current_subdivision_index = 0; // 0 = main beat, 1,2,3... = subdivisions

    // Audio playback elements
    private Gst.Element? high_sound_player = null;
    private Gst.Element? low_sound_player = null;
    private Gst.Element? subdivision_sound_player = null;
    private GLib.Settings? settings = null;
    private bool audio_initialized = false;

    // Practice timer integration (optional)
    private PracticeTimer? practice_timer = null;

    // Signal for audio initialization failure
    public signal void audio_system_failed(string error_message);

    /**
     * Creates a new MetronomeEngine with default settings.
     */
    public MetronomeEngine() {
        // Connect property change notifications
        this.notify["bpm"].connect(() => {
            this.beat_duration = calculate_beat_duration();
        });

        this.notify["beat_value"].connect(() => {
            this.beat_duration = calculate_beat_duration();
        });

        this.notify["subdivision_mode"].connect(() => {
            update_subdivisions_per_beat();
            // If metronome is running, reset to main beat on next cycle
            if (is_running) {
                current_subdivision_index = 0;
            }
        });

        // Initialize beat duration and subdivisions
        this.beat_duration = calculate_beat_duration();
        update_subdivisions_per_beat();

        // Initialize audio
        initialize_audio();
    }

    /**
     * Set the practice timer instance for integration.
     */
    public void set_practice_timer(PracticeTimer? timer) {
        this.practice_timer = timer;

        if (this.practice_timer != null) {
            // Connect auto-stop signal to stop metronome
            this.practice_timer.auto_stop_triggered.connect(() => {
                this.stop();
            });
        }
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
        beat_duration = calculate_beat_duration();
        update_subdivisions_per_beat();

        // Initialize subdivision state - always start on a main beat
        current_subdivision_index = 0;
        next_subdivision_time = GLib.get_monotonic_time() + (int64)(beat_duration * 1000000);

        // Start practice timer if enabled and sync is on
        if (practice_timer != null && practice_timer.enabled) {
            if (settings != null && settings.get_boolean("timer-pause-with-metronome")) {
                practice_timer.start();
            }
        }

        // Start the timing loop
        schedule_next_click();
    }
    
    /**
     * Stop the metronome.
     */
    public void stop() {
        if (!is_running) {
            return; // Already stopped
        }

        is_running = false;

        // Reset subdivision state
        current_subdivision_index = 0;

        // Pause practice timer if enabled and sync is on
        if (practice_timer != null && practice_timer.enabled) {
            if (settings != null && settings.get_boolean("timer-pause-with-metronome")) {
                practice_timer.pause();
            }
        }

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
                _("BPM must be between 40 and 240, got %d").printf(new_bpm)
            );
        }
        
        bpm = new_bpm;
        beat_duration = calculate_beat_duration();
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
                _("Time signature numerator must be 1-16, got %d").printf(numerator)
            );
        }
        
        if (!(denominator == 2 || denominator == 4 || denominator == 8 || denominator == 16)) {
            throw new MetronomeError.INVALID_TIME_SIGNATURE(
                _("Time signature denominator must be 2, 4, 8, or 16, got %d").printf(denominator)
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
        current_subdivision_index = 0;
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
     * Schedule the next click (beat or subdivision) using GLib.Timeout.
     */
    private void schedule_next_click() {
        if (!is_running) {
            return;
        }

        int64 current_time = GLib.get_monotonic_time();
        int64 wait_time_us = next_subdivision_time - current_time;

        // Check if we're too far behind (e.g., after system sleep)
        if (wait_time_us < -((int64)(beat_duration * 1000000))) {
            // Reset timing to current time
            next_subdivision_time = current_time + (int64)(beat_duration * 1000000);
            wait_time_us = (int64)(beat_duration * 1000000);
            current_subdivision_index = 0; // Reset to main beat
        }

        // Convert microseconds to milliseconds for GLib.Timeout
        uint wait_time_ms = (uint)int64.max(1, wait_time_us / 1000);

        timeout_id = Timeout.add(wait_time_ms, () => {
            return on_click_timeout();
        });
    }
    
    /**
     * Handle click timeout - emit signal and schedule next click (beat or subdivision).
     *
     * @return false to remove the timeout source
     */
    private bool on_click_timeout() {
        if (!is_running) {
            timeout_id = 0;
            return false; // Remove timeout
        }

        // Determine if this is a main beat or subdivision
        bool is_main_beat = (current_subdivision_index == 0);

        if (is_main_beat) {
            // This is a main beat
            current_beat++;

            // Determine if this is a downbeat
            bool is_downbeat = (current_beat % beats_per_bar) == 1;

            // Calculate beat in bar (1-based)
            int beat_in_bar = ((current_beat - 1) % beats_per_bar) + 1;

            // Notify practice timer about beat occurrence
            if (practice_timer != null && practice_timer.enabled) {
                practice_timer.on_beat_occurred(beat_in_bar, beats_per_bar);
            }

            // Determine if this beat should be muted
            bool is_muted = should_mute_current_beat();

            // Play main beat sound only if not muted
            if (!is_muted) {
                play_click_sound(is_downbeat);
            }

            // Emit beat signal (always emit, even if muted)
            beat_occurred(current_beat, is_downbeat, is_muted);
        } else {
            // This is a subdivision
            play_subdivision_click();

            // Emit subdivision signal
            subdivision_occurred(current_beat, current_subdivision_index, subdivisions_per_beat);
        }

        // Advance to next subdivision
        current_subdivision_index++;
        if (current_subdivision_index >= subdivisions_per_beat) {
            current_subdivision_index = 0; // Next click will be a main beat
        }

        // Calculate next click time (absolute time to prevent drift)
        double click_duration = calculate_subdivision_duration();
        next_subdivision_time += (int64)(click_duration * 1000000);

        // Update beat duration if tempo or time signature changed
        double new_duration = calculate_beat_duration();
        if (Math.fabs(new_duration - beat_duration) > 0.001) { // 1ms tolerance
            beat_duration = new_duration;
        }

        // Schedule next click
        schedule_next_click();

        // Remove this timeout (we created a new one)
        timeout_id = 0;
        return false;
    }

    /**
     * Determine if the current beat should be muted.
     *
     * @return true if beat should be muted (silent), false otherwise
     */
    private bool should_mute_current_beat() {
        if (!mute_enabled || mute_pattern == null) {
            return false;
        }

        return mute_pattern.should_mute_beat(current_beat, beats_per_bar);
    }
    
    /**
     * Calculate the duration for a single subdivision based on current mode.
     *
     * @return Subdivision duration in seconds
     */
    private double calculate_subdivision_duration() {
        if (subdivision_mode == SubdivisionMode.NONE) {
            return beat_duration;
        }

        // Calculate duration per subdivision based on mode
        if (subdivision_mode == SubdivisionMode.TRIPLET) {
            // Triplets: divide beat into 3 equal parts
            return beat_duration / 3.0;
        } else {
            // Eighths (2) or Sixteenths (4): divide evenly
            return beat_duration / (double)subdivisions_per_beat;
        }
    }

    /**
     * Update the subdivisions_per_beat value based on current subdivision_mode.
     */
    private void update_subdivisions_per_beat() {
        switch (subdivision_mode) {
            case SubdivisionMode.NONE:
                subdivisions_per_beat = 1;
                break;
            case SubdivisionMode.EIGHTH:
                subdivisions_per_beat = 2;
                break;
            case SubdivisionMode.TRIPLET:
                subdivisions_per_beat = 3;
                break;
            case SubdivisionMode.SIXTEENTH:
                subdivisions_per_beat = 4;
                break;
            default:
                subdivisions_per_beat = 1;
                break;
        }
    }

    /**
     * Initialize audio system.
     */
    private void initialize_audio() {
        try {
            settings = new GLib.Settings(Config.APP_ID);

            // Bind subdivision settings
            bind_subdivision_settings();

            // Initialize GStreamer elements
            bool success = create_audio_players();
            if (success) {
                audio_initialized = true;
            } else {
                audio_system_failed("Failed to create audio players. GStreamer elements could not be initialized.");
            }
        } catch (Error e) {
            warning("Failed to initialize audio: %s", e.message);
            audio_system_failed("Audio system initialization failed: %s".printf(e.message));
        }
    }

    /**
     * Bind subdivision settings from GSettings to MetronomeEngine properties.
     */
    private void bind_subdivision_settings() {
        if (settings == null) {
            return;
        }

        // Bind subdivision mode (with validation)
        int mode_value = settings.get_int("subdivision-mode");
        if (mode_value < 0 || mode_value > 4) {
            warning("Invalid subdivision mode %d in settings, resetting to NONE", mode_value);
            mode_value = 0;
            settings.set_int("subdivision-mode", 0);
        }

        // Convert int to SubdivisionMode enum
        switch (mode_value) {
            case 2:
                subdivision_mode = SubdivisionMode.EIGHTH;
                break;
            case 3:
                subdivision_mode = SubdivisionMode.TRIPLET;
                break;
            case 4:
                subdivision_mode = SubdivisionMode.SIXTEENTH;
                break;
            default:
                subdivision_mode = SubdivisionMode.NONE;
                break;
        }

        // Bind subdivision volume (with validation)
        double volume = settings.get_double("subdivision-volume");
        subdivision_volume = double.max(0.0, double.min(1.0, volume)); // Clamp to 0.0-1.0

        // Connect to settings changes
        settings.changed["subdivision-mode"].connect(() => {
            int new_mode = settings.get_int("subdivision-mode");
            switch (new_mode) {
                case 2:
                    subdivision_mode = SubdivisionMode.EIGHTH;
                    break;
                case 3:
                    subdivision_mode = SubdivisionMode.TRIPLET;
                    break;
                case 4:
                    subdivision_mode = SubdivisionMode.SIXTEENTH;
                    break;
                default:
                    subdivision_mode = SubdivisionMode.NONE;
                    break;
            }
        });

        settings.changed["subdivision-volume"].connect(() => {
            double new_volume = settings.get_double("subdivision-volume");
            subdivision_volume = double.max(0.0, double.min(1.0, new_volume));
        });

        // Sync property changes back to settings
        this.notify["subdivision-mode"].connect(() => {
            int mode_int = (int)subdivision_mode;
            if (settings.get_int("subdivision-mode") != mode_int) {
                settings.set_int("subdivision-mode", mode_int);
            }
        });

        this.notify["subdivision-volume"].connect(() => {
            if (Math.fabs(settings.get_double("subdivision-volume") - subdivision_volume) > 0.01) {
                settings.set_double("subdivision-volume", subdivision_volume);
            }
        });
    }

    /**
     * Check if audio system is available.
     *
     * @return true if audio is initialized and working, false for visual-only mode
     */
    public bool is_audio_available() {
        return audio_initialized;
    }
    
    /**
     * Create GStreamer playback elements.
     *
     * @return true if successful, false otherwise
     */
    private bool create_audio_players() {
        try {
            // Create players for high, low, and subdivision sounds
            high_sound_player = Gst.ElementFactory.make("playbin", "high_sound_player");
            low_sound_player = Gst.ElementFactory.make("playbin", "low_sound_player");
            subdivision_sound_player = Gst.ElementFactory.make("playbin", "subdivision_sound_player");

            if (high_sound_player == null || low_sound_player == null || subdivision_sound_player == null) {
                warning("Failed to create GStreamer playbin elements");
                return false;
            }

            // Set default sound URIs using safe File.get_uri() method
            string app_data_dir = "/app/share/tempo/sounds";
            var high_file = GLib.File.new_for_path(app_data_dir + "/high.wav");
            var low_file = GLib.File.new_for_path(app_data_dir + "/low.wav");

            high_sound_player.set("uri", high_file.get_uri());
            low_sound_player.set("uri", low_file.get_uri());
            subdivision_sound_player.set("uri", low_file.get_uri()); // Start with low sound

            return true;

        } catch (Error e) {
            warning("Error creating audio players: %s", e.message);
            return false;
        }
    }
    
    /**
     * Play a subdivision click sound.
     */
    private void play_subdivision_click() {
        if (!audio_initialized || settings == null || subdivision_sound_player == null) {
            return;
        }

        try {
            // Determine which sound URI to use for subdivisions
            string sound_uri = get_subdivision_sound_uri();
            subdivision_sound_player.set("uri", sound_uri);

            // Apply subdivision volume
            subdivision_sound_player.set("volume", subdivision_volume);

            // Reset to beginning and play
            subdivision_sound_player.set_state(Gst.State.NULL);
            subdivision_sound_player.set_state(Gst.State.PLAYING);

            // Calculate safe duration based on tempo to prevent overlap
            double subdivision_duration = calculate_subdivision_duration();
            int stop_duration_ms = (int)(subdivision_duration * 1000 * 0.8); // 80% of subdivision duration
            stop_duration_ms = int.min(stop_duration_ms, 200); // Cap at 200ms

            // Stop after duration to prevent overlap
            Timeout.add(stop_duration_ms, () => {
                if (subdivision_sound_player != null) {
                    subdivision_sound_player.set_state(Gst.State.NULL);
                }
                return false;
            });

        } catch (Error e) {
            warning("Error playing subdivision click sound: %s", e.message);
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

            // Determine which sound URI to use
            string sound_uri = get_sound_uri(is_downbeat);
            player.set("uri", sound_uri);

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

    /**
     * Get the appropriate sound URI based on settings and validation.
     * Priority: custom path (if enabled) > sound type > default
     *
     * @param is_downbeat Whether this is for high (accent) or low sound
     * @return The URI string to use for playback
     */
    private string get_sound_uri(bool is_downbeat) {
        string app_data_dir = "/app/share/tempo/sounds";
        string default_sound = is_downbeat ? "high.wav" : "low.wav";
        var default_file = GLib.File.new_for_path(app_data_dir + "/" + default_sound);
        string default_uri = default_file.get_uri();

        // If custom sounds are enabled and path is set, use custom path
        if (settings.get_boolean("use-custom-sounds")) {
            string? custom_path = is_downbeat ?
                settings.get_string("high-sound-path") :
                settings.get_string("low-sound-path");

            // If custom path is set, validate and use it
            if (custom_path != null && custom_path != "") {
                if (validate_audio_path(custom_path)) {
                    var custom_file = GLib.File.new_for_path(custom_path);
                    return custom_file.get_uri();
                } else {
                    warning("Invalid custom sound path, falling back to sound type: %s", custom_path);
                    // Clear invalid path from settings
                    if (is_downbeat) {
                        settings.set_string("high-sound-path", "");
                    } else {
                        settings.set_string("low-sound-path", "");
                    }
                    // Fall through to sound type check
                }
            }
        }

        // Use sound type setting (custom sounds disabled or no custom path set)
        string sound_type = is_downbeat ?
            settings.get_string("high-sound-type") :
            settings.get_string("low-sound-type");

        return get_sound_type_uri(sound_type, is_downbeat, default_uri);
    }

    /**
     * Get the appropriate sound URI for subdivisions based on settings.
     *
     * @return The URI string to use for subdivision playback
     */
    private string get_subdivision_sound_uri() {
        string app_data_dir = "/app/share/tempo/sounds";
        var default_file = GLib.File.new_for_path(app_data_dir + "/low.wav");
        string default_uri = default_file.get_uri();

        // Check if subdivision-sound-type setting exists
        if (settings == null) {
            return default_uri;
        }

        // Get subdivision sound type setting (will add to schema later)
        // For now, use low sound type as default
        string sound_type = "default";
        try {
            sound_type = settings.get_string("subdivision-sound-type");
        } catch (Error e) {
            // Setting doesn't exist yet, use default
            return default_uri;
        }

        // Use same logic as get_sound_type_uri but for low sound
        return get_sound_type_uri(sound_type, false, default_uri);
    }

    /**
     * Get the URI for a specific sound type.
     *
     * @param sound_type The sound type ("default", "woodblock", "metal", "digital")
     * @param is_downbeat Whether this is for high (accent) or low sound
     * @param fallback_uri The URI to use if sound type file is not found
     * @return The URI string to use for playback
     */
    private string get_sound_type_uri(string sound_type, bool is_downbeat, string fallback_uri) {
        string app_data_dir = "/app/share/tempo/sounds";
        string beat_suffix = is_downbeat ? "high" : "low";

        // Validate and sanitize sound type
        string safe_type = sound_type.strip();
        if (safe_type == "" || safe_type == "default") {
            // Use default high.wav/low.wav
            return fallback_uri;
        }

        // Map sound type to filename
        string filename;
        switch (safe_type) {
            case "woodblock":
            case "metal":
            case "digital":
                filename = "%s-%s.wav".printf(safe_type, beat_suffix);
                break;
            default:
                warning("Unknown sound type '%s', falling back to default", safe_type);
                return fallback_uri;
        }

        // Check if file exists
        var sound_file = GLib.File.new_for_path(app_data_dir + "/" + filename);
        if (!sound_file.query_exists()) {
            warning("Sound type file not found: %s, falling back to default", filename);
            return fallback_uri;
        }

        return sound_file.get_uri();
    }

    /**
     * Validate an audio file path from settings.
     *
     * @param path The file path to validate
     * @return true if valid, false otherwise
     */
    private bool validate_audio_path(string path) {
        try {
            var file = GLib.File.new_for_path(path);

            // Check if file exists and is a regular file
            if (!file.query_exists()) {
                return false;
            }

            var file_type = file.query_file_type(FileQueryInfoFlags.NONE);
            if (file_type != FileType.REGULAR) {
                return false;
            }

            // Check file size (10MB limit)
            FileInfo info = file.query_info("standard::size", FileQueryInfoFlags.NONE);
            int64 size = info.get_size();
            const int64 MAX_FILE_SIZE = 10 * 1024 * 1024;
            if (size > MAX_FILE_SIZE) {
                return false;
            }

            return true;

        } catch (Error e) {
            return false;
        }
    }
    
    /**
     * Calculate beat duration based on BPM and time signature denominator.
     * 
     * @return Beat duration in seconds
     */
    private double calculate_beat_duration() {
        // Base duration for quarter note at given BPM
        double quarter_note_duration = 60.0 / (double)bpm;
        
        // Adjust based on time signature denominator
        // denominator = 4 means quarter note gets the beat (base case)
        // denominator = 8 means eighth note gets the beat (half duration)
        // denominator = 2 means half note gets the beat (double duration)
        // denominator = 16 means sixteenth note gets the beat (quarter duration)
        double multiplier = 4.0 / (double)beat_value;
        
        return quarter_note_duration * multiplier;
    }
}
