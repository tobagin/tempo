/**
 * Test suite for MetronomeEngine Vala implementation.
 * 
 * This file tests the core functionality of the MetronomeEngine class
 * to ensure it matches the behavior of the Python version.
 */

using GLib;

// Global test engine instance
private static MetronomeEngine? test_engine;

private static void setup_test() {
    test_engine = new MetronomeEngine();
}

private static void teardown_test() {
    if (test_engine != null && test_engine.is_running) {
        test_engine.stop();
    }
    test_engine = null;
}

/**
 * Test that MetronomeEngine can be instantiated with default values.
 */
private static void test_metronome_engine_creation() {
    setup_test();
    assert(test_engine != null);
    assert(test_engine.bpm == 120);
    assert(test_engine.beats_per_bar == 4);
    assert(test_engine.beat_value == 4);
    assert(!test_engine.is_running);
    assert(test_engine.current_beat == 0);
    teardown_test();
}

/**
 * Test BPM property setting within valid range.
 */
private static void test_bpm_setting_valid_range() {
    setup_test();
    // Test minimum valid BPM
    test_engine.bpm = 40;
    assert(test_engine.bpm == 40);
    
    // Test maximum valid BPM
    test_engine.bpm = 240;
    assert(test_engine.bpm == 240);
    
    // Test common BPM values
    test_engine.bpm = 120;
    assert(test_engine.bpm == 120);
    
    test_engine.bpm = 60;
    assert(test_engine.bpm == 60);
    teardown_test();
}

/**
 * Test BPM validation rejects invalid values.
 */
private static void test_bpm_validation() {
    setup_test();
    // Test below minimum (should throw error)
    try {
        test_engine.set_tempo(39);
        assert_not_reached(); // Should not reach here
    } catch (MetronomeError e) {
        // Expected behavior
    }
    
    // Test above maximum
    try {
        test_engine.set_tempo(241);
        assert_not_reached();
    } catch (MetronomeError e) {
        // Expected behavior
    }
    teardown_test();
}

/**
 * Test time signature setting.
 */
private static void test_time_signature_setting() {
    setup_test();
    // Test 4/4 time (default)
    try {
        test_engine.set_time_signature(4, 4);
        assert(test_engine.beats_per_bar == 4);
        assert(test_engine.beat_value == 4);
        
        // Test 3/4 time (waltz)
        test_engine.set_time_signature(3, 4);
        assert(test_engine.beats_per_bar == 3);
        assert(test_engine.beat_value == 4);
        
        // Test 6/8 time
        test_engine.set_time_signature(6, 8);
        assert(test_engine.beats_per_bar == 6);
        assert(test_engine.beat_value == 8);
    } catch (MetronomeError e) {
        assert_not_reached();
    }
    teardown_test();
}

/**
 * Test time signature validation.
 */
private static void test_time_signature_validation() {
    setup_test();
    // Test invalid numerator
    try {
        test_engine.set_time_signature(0, 4);
        assert_not_reached();
    } catch (MetronomeError e) {
        // Expected
    }
    
    try {
        test_engine.set_time_signature(17, 4);
        assert_not_reached();
    } catch (MetronomeError e) {
        // Expected
    }
    
    // Test invalid denominator
    try {
        test_engine.set_time_signature(4, 3);
        assert_not_reached();
    } catch (MetronomeError e) {
        // Expected
    }
    teardown_test();
}

/**
 * Test basic start/stop functionality.
 */
private static void test_start_stop_basic() {
    setup_test();
    // Initially not running
    assert(!test_engine.is_running);
    
    // Start should change state
    test_engine.start();
    assert(test_engine.is_running);
    assert(test_engine.current_beat == 0);
    
    // Stop should change state
    test_engine.stop();
    assert(!test_engine.is_running);
    teardown_test();
}

/**
 * Test beat counter reset functionality.
 */
private static void test_beat_counter_reset() {
    setup_test();
    test_engine.current_beat = 5;
    test_engine.reset_beat_counter();
    assert(test_engine.current_beat == 0);
    teardown_test();
}

/**
 * Test signal connection and emission.
 */
private static void test_beat_signal_connection() {
    setup_test();
    bool signal_received = false;
    int received_beat = -1;
    bool received_downbeat = false;
    
    // Connect to beat signal
    test_engine.beat_occurred.connect((beat, is_downbeat) => {
        signal_received = true;
        received_beat = beat;
        received_downbeat = is_downbeat;
    });
    
    // Manual signal emission for testing
    test_engine.beat_occurred(1, true);
    
    assert(signal_received);
    assert(received_beat == 1);
    assert(received_downbeat);
    teardown_test();
}

/**
 * Test that multiple starts don't cause issues.
 */
private static void test_multiple_starts() {
    setup_test();
    test_engine.start();
    assert(test_engine.is_running);
    
    // Second start should be ignored
    test_engine.start();
    assert(test_engine.is_running);
    
    test_engine.stop();
    assert(!test_engine.is_running);
    teardown_test();
}

/**
 * Test that multiple stops don't cause issues.
 */
private static void test_multiple_stops() {
    setup_test();
    assert(!test_engine.is_running);
    
    // Stop when not running should be ignored
    test_engine.stop();
    assert(!test_engine.is_running);
    
    test_engine.start();
    test_engine.stop();
    test_engine.stop(); // Second stop
    assert(!test_engine.is_running);
    teardown_test();
}

/**
 * Main test runner
 */
public static int main(string[] args) {
    Test.init(ref args);
    
    Test.add_func("/metronome/creation", test_metronome_engine_creation);
    Test.add_func("/metronome/bpm_valid", test_bpm_setting_valid_range);
    Test.add_func("/metronome/bpm_validation", test_bpm_validation);
    Test.add_func("/metronome/time_signature", test_time_signature_setting);
    Test.add_func("/metronome/time_signature_validation", test_time_signature_validation);
    Test.add_func("/metronome/start_stop", test_start_stop_basic);
    Test.add_func("/metronome/beat_reset", test_beat_counter_reset);
    Test.add_func("/metronome/signals", test_beat_signal_connection);
    Test.add_func("/metronome/multiple_starts", test_multiple_starts);
    Test.add_func("/metronome/multiple_stops", test_multiple_stops);
    
    return Test.run();
}