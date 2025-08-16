/**
 * Tap tempo calculator for determining BPM from user taps.
 *
 * Uses a sliding window of tap intervals to calculate average BPM.
 * This is a direct port of the Python TapTempo class.
 */

using GLib;

/**
 * Tap tempo calculator for determining BPM from user taps.
 * 
 * Uses a sliding window of tap intervals to calculate average BPM,
 * exactly matching the Python implementation behavior.
 */
public class TapTempo : Object {
    
    /**
     * Maximum number of taps to consider in the sliding window.
     */
    public int max_taps { get; construct; default = 8; }
    
    /**
     * Timeout in seconds - taps older than this are removed.
     */
    public double timeout_seconds { get; construct; default = 2.0; }
    
    /**
     * Array storing tap times in microseconds (GLib.get_monotonic_time format).
     */
    private Array<int64> tap_times;
    
    /**
     * Creates a new TapTempo calculator.
     * 
     * @param max_taps Maximum number of taps to consider (default: 8)
     * @param timeout_seconds Reset if no tap within this time (default: 2.0)
     */
    public TapTempo(int max_taps = 8, double timeout_seconds = 2.0) {
        Object(max_taps: max_taps, timeout_seconds: timeout_seconds);
        this.tap_times = new Array<int64>();
    }
    
    /**
     * Register a tap and calculate BPM.
     * 
     * This method exactly replicates the Python TapTempo.tap() logic:
     * 1. Get current time
     * 2. Remove old taps beyond timeout
     * 3. Add current tap
     * 4. Keep only recent taps (up to max_taps)
     * 5. Calculate intervals and average
     * 6. Convert to BPM and clamp to valid range
     * 
     * @return Calculated BPM or null if insufficient taps
     */
    public int? tap() {
        int64 current_time = GLib.get_monotonic_time();
        
        // Remove old taps beyond timeout (convert timeout to microseconds)
        int64 cutoff_time = current_time - (int64)(timeout_seconds * 1000000);
        
        // Filter out expired taps (equivalent to Python list comprehension)
        var new_tap_times = new Array<int64>();
        for (int i = 0; i < tap_times.length; i++) {
            if (tap_times.index(i) > cutoff_time) {
                new_tap_times.append_val(tap_times.index(i));
            }
        }
        tap_times = new_tap_times;
        
        // Add current tap
        tap_times.append_val(current_time);
        
        // Keep only recent taps (equivalent to Python slice [-max_taps:])
        if (tap_times.length > max_taps) {
            var trimmed_times = new Array<int64>();
            uint start_index = tap_times.length - max_taps;
            for (uint i = start_index; i < tap_times.length; i++) {
                trimmed_times.append_val(tap_times.index(i));
            }
            tap_times = trimmed_times;
        }
        
        // Need at least 2 taps to calculate BPM
        if (tap_times.length < 2) {
            return null;
        }
        
        // Calculate intervals between taps (in seconds)
        var intervals = new Array<double>();
        for (int i = 1; i < tap_times.length; i++) {
            // Convert microsecond interval to seconds
            double interval = (tap_times.index(i) - tap_times.index(i-1)) / 1000000.0;
            intervals.append_val(interval);
        }
        
        // Calculate average interval
        double sum = 0.0;
        for (int i = 0; i < intervals.length; i++) {
            sum += intervals.index(i);
        }
        double avg_interval = sum / intervals.length;
        
        // Convert to BPM
        double bpm_double = 60.0 / avg_interval;
        
        // Clamp to valid range and round (matches Python logic exactly)
        int bpm = (int)Math.round(bpm_double);
        bpm = int.max(40, int.min(240, bpm));
        
        return bpm;
    }
    
    /**
     * Reset tap tempo calculator.
     * 
     * Clears all stored tap times, equivalent to Python's tap_times.clear().
     */
    public void reset() {
        tap_times = new Array<int64>();
    }
    
    /**
     * Get number of active taps.
     * 
     * @return Number of taps currently stored
     */
    public int get_tap_count() {
        return (int)tap_times.length;
    }
}