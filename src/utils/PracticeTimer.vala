/**
 * Practice timer for tracking session duration and implementing auto-stop.
 *
 * This module provides session timing functionality with count-up, countdown,
 * and auto-stop capabilities based on beats, bars, or time duration.
 */

using GLib;

/**
 * Timer mode enumeration.
 */
public enum TimerMode {
    COUNT_UP,     // Count up from zero
    COUNTDOWN     // Count down from duration to zero
}

/**
 * Auto-stop mode enumeration.
 */
public enum AutoStopMode {
    NONE,   // No auto-stop
    BEATS,  // Stop after N beats
    BARS,   // Stop after N bars
    TIME    // Stop after N minutes
}

/**
 * Practice session timer with auto-stop functionality.
 *
 * Tracks elapsed practice time with microsecond precision and supports
 * automatic stopping based on configurable conditions (beats, bars, time).
 */
public class PracticeTimer : GLib.Object {

    // Public properties
    public bool enabled { get; set; default = false; }
    public TimerMode mode { get; set; default = TimerMode.COUNT_UP; }
    public int64 elapsed_microseconds { get; private set; default = 0; }
    public bool is_running { get; private set; default = false; }

    // Countdown configuration (in microseconds)
    public int64 countdown_duration { get; set; default = 1500000000; } // 25 minutes default

    // Auto-stop configuration
    public AutoStopMode auto_stop_mode { get; set; default = AutoStopMode.NONE; }
    public int auto_stop_value { get; set; default = 100; }

    // Signals
    public signal void tick(int64 elapsed, int64 remaining);
    public signal void auto_stop_triggered();
    public signal void countdown_completed();

    // Private timing state
    private int64 start_time = 0;
    private int64 paused_elapsed = 0;
    private uint timeout_id = 0;

    // Private beat/bar counting
    private int current_beat_count = 0;
    private int current_bar_count = 0;

    // Settings
    private GLib.Settings? settings = null;

    /**
     * Creates a new PracticeTimer and loads settings.
     */
    public PracticeTimer(GLib.Settings? settings = null) {
        this.settings = settings;

        if (this.settings != null) {
            load_settings();
            bind_settings();
        }
    }

    /**
     * Load settings from GSettings.
     */
    private void load_settings() {
        if (settings == null) {
            return;
        }

        // Load timer configuration
        enabled = settings.get_boolean("timer-enabled");
        mode = (TimerMode)settings.get_int("timer-mode");

        // Convert minutes to microseconds for countdown duration
        int countdown_minutes = settings.get_int("timer-countdown-duration");
        countdown_duration = (int64)countdown_minutes * 60 * 1000000;

        // Load auto-stop configuration
        auto_stop_mode = (AutoStopMode)settings.get_int("timer-auto-stop-mode");
        auto_stop_value = settings.get_int("timer-auto-stop-value");
    }

    /**
     * Bind properties to GSettings for automatic persistence.
     */
    private void bind_settings() {
        if (settings == null) {
            return;
        }

        // Bind enabled property
        settings.bind("timer-enabled", this, "enabled", SettingsBindFlags.DEFAULT);

        // Listen for settings changes to update internal state
        settings.changed["timer-mode"].connect(() => {
            mode = (TimerMode)settings.get_int("timer-mode");
            reset(); // Reset timer when mode changes
        });

        settings.changed["timer-countdown-duration"].connect(() => {
            int countdown_minutes = settings.get_int("timer-countdown-duration");
            countdown_duration = (int64)countdown_minutes * 60 * 1000000;
        });

        settings.changed["timer-auto-stop-mode"].connect(() => {
            auto_stop_mode = (AutoStopMode)settings.get_int("timer-auto-stop-mode");
        });

        settings.changed["timer-auto-stop-value"].connect(() => {
            auto_stop_value = settings.get_int("timer-auto-stop-value");
        });

        // Save mode changes back to settings
        this.notify["mode"].connect(() => {
            if (settings != null) {
                settings.set_int("timer-mode", (int)mode);
            }
        });
    }

    /**
     * Validate and apply settings value with fallback.
     */
    private int get_validated_int(string key, int min_value, int max_value, int default_value) {
        if (settings == null) {
            return default_value;
        }

        int value = settings.get_int(key);
        if (value < min_value || value > max_value) {
            warning("Invalid settings value for %s: %d (expected %d-%d), using default: %d",
                    key, value, min_value, max_value, default_value);
            settings.set_int(key, default_value);
            return default_value;
        }
        return value;
    }

    /**
     * Start the timer from zero or resume from paused state.
     */
    public void start() {
        if (is_running) {
            return; // Already running
        }

        is_running = true;
        start_time = GLib.get_monotonic_time();

        // Reset counters on fresh start
        if (paused_elapsed == 0) {
            current_beat_count = 0;
            current_bar_count = 0;
        }

        // Schedule timeout for display updates (every second)
        timeout_id = GLib.Timeout.add(1000, on_timeout);
    }

    /**
     * Pause the timer, preserving elapsed time.
     */
    public void pause() {
        if (!is_running) {
            return; // Already paused
        }

        is_running = false;

        // Save elapsed time before stopping
        update_elapsed();
        paused_elapsed = elapsed_microseconds;

        // Cancel timeout
        if (timeout_id > 0) {
            Source.remove(timeout_id);
            timeout_id = 0;
        }
    }

    /**
     * Resume the timer from paused state.
     */
    public void resume() {
        if (is_running) {
            return; // Already running
        }

        // Adjust start time to account for paused duration
        start_time = GLib.get_monotonic_time() - paused_elapsed;
        is_running = true;

        // Reschedule timeout
        timeout_id = GLib.Timeout.add(1000, on_timeout);
    }

    /**
     * Reset the timer to zero.
     */
    public void reset() {
        bool was_running = is_running;

        // Stop if running
        if (is_running) {
            pause();
        }

        // Clear all state
        elapsed_microseconds = 0;
        paused_elapsed = 0;
        current_beat_count = 0;
        current_bar_count = 0;

        // Restart if was running
        if (was_running) {
            start();
        }
    }

    /**
     * Called by MetronomeEngine when a beat occurs.
     * Used for beat/bar counting and auto-stop tracking.
     */
    public void on_beat_occurred(int beat_num, int beats_per_bar) {
        if (!is_running) {
            return;
        }

        // Increment beat counter
        current_beat_count++;

        // Increment bar counter on downbeat
        if (beat_num == beats_per_bar) {
            current_bar_count++;
        }

        // Check auto-stop conditions
        check_auto_stop();
    }

    /**
     * Update elapsed time from monotonic clock.
     */
    private void update_elapsed() {
        if (!is_running) {
            return;
        }

        int64 current_time = GLib.get_monotonic_time();
        elapsed_microseconds = current_time - start_time;
    }

    /**
     * Timeout callback for display updates.
     */
    private bool on_timeout() {
        if (!is_running) {
            return false; // Stop timeout
        }

        // Update elapsed time
        update_elapsed();

        // Calculate remaining time for countdown mode
        int64 remaining = 0;
        if (mode == TimerMode.COUNTDOWN) {
            remaining = countdown_duration - elapsed_microseconds;

            // Check if countdown completed
            if (remaining <= 0) {
                remaining = 0;
                on_countdown_completed();
                return false; // Stop timeout
            }
        }

        // Check time-based auto-stop
        if (auto_stop_mode == AutoStopMode.TIME) {
            check_auto_stop();
        }

        // Emit tick signal for UI updates
        tick(elapsed_microseconds, remaining);

        return true; // Continue timeout
    }

    /**
     * Check if auto-stop condition is met.
     */
    private void check_auto_stop() {
        bool should_stop = false;

        switch (auto_stop_mode) {
            case AutoStopMode.BEATS:
                should_stop = current_beat_count >= auto_stop_value;
                break;
            case AutoStopMode.BARS:
                should_stop = current_bar_count >= auto_stop_value;
                break;
            case AutoStopMode.TIME:
                // Convert auto_stop_value from minutes to microseconds
                int64 time_limit = (int64)auto_stop_value * 60 * 1000000;
                should_stop = elapsed_microseconds >= time_limit;
                break;
            case AutoStopMode.NONE:
            default:
                should_stop = false;
                break;
        }

        if (should_stop) {
            auto_stop_triggered();
        }
    }

    /**
     * Handle countdown completion.
     */
    private void on_countdown_completed() {
        pause();
        countdown_completed();

        // Reset to countdown duration for next session
        elapsed_microseconds = 0;
        paused_elapsed = 0;
    }
}
