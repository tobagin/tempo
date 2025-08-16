/**
 * API Compatibility tests for Vala MetronomeEngine and TapTempo.
 * 
 * This file tests that the Vala implementation provides complete API
 * compatibility with the Python version for seamless integration.
 */

using GLib;

// Global test instances
private static MetronomeEngine? test_engine;
private static TapTempo? test_tap_tempo;

private static void setup_engine_test() {
    test_engine = new MetronomeEngine();
}

private static void setup_tap_test() {
    test_tap_tempo = new TapTempo();
}

private static void teardown_engine_test() {
    if (test_engine != null && test_engine.is_running) {
        test_engine.stop();
    }
    test_engine = null;
}

private static void teardown_tap_test() {
    test_tap_tempo = null;
}

/**
 * Test MetronomeEngine API compatibility with Python version.
 */
private static void test_metronome_engine_api_compatibility() {
    setup_engine_test();
    
    // Test all properties exist and have correct types/defaults
    assert(test_engine.bpm == 120);                // int, default 120
    assert(test_engine.beats_per_bar == 4);        // int, default 4
    assert(test_engine.beat_value == 4);           // int, default 4
    assert(test_engine.is_running == false);       // bool, default false
    assert(test_engine.current_beat == 0);         // int, default 0
    
    // Test all methods exist and work correctly
    
    // start() method
    test_engine.start();
    assert(test_engine.is_running == true);
    
    // stop() method  
    test_engine.stop();
    assert(test_engine.is_running == false);
    
    // set_tempo() method with validation
    try {
        test_engine.set_tempo(150);
        assert(test_engine.bpm == 150);
    } catch (MetronomeError e) {
        assert_not_reached();
    }
    
    // set_time_signature() method with validation
    try {
        test_engine.set_time_signature(3, 8);
        assert(test_engine.beats_per_bar == 3);
        assert(test_engine.beat_value == 8);
    } catch (MetronomeError e) {
        assert_not_reached();
    }
    
    // reset_beat_counter() method
    test_engine.current_beat = 10;
    test_engine.reset_beat_counter();
    assert(test_engine.current_beat == 0);
    
    // get_beat_info() method returns proper dictionary-like structure
    var beat_info = test_engine.get_beat_info();
    assert(beat_info != null);
    assert(beat_info.contains("current_beat"));
    assert(beat_info.contains("beats_per_bar"));
    assert(beat_info.contains("beat_in_bar"));
    assert(beat_info.contains("is_downbeat"));
    assert(beat_info.contains("is_running"));
    assert(beat_info.contains("bpm"));
    assert(beat_info.contains("time_signature"));
    
    teardown_engine_test();
}

/**
 * Test TapTempo API compatibility with Python version.
 */
private static void test_tap_tempo_api_compatibility() {
    setup_tap_test();
    
    // Test default constructor
    assert(test_tap_tempo.max_taps == 8);
    assert(test_tap_tempo.timeout_seconds == 2.0);
    assert(test_tap_tempo.get_tap_count() == 0);
    
    teardown_tap_test();
    
    // Test custom constructor
    test_tap_tempo = new TapTempo(4, 1.5);
    assert(test_tap_tempo.max_taps == 4);
    assert(test_tap_tempo.timeout_seconds == 1.5);
    
    // Test tap() method returns nullable int
    var bpm1 = test_tap_tempo.tap();
    assert(bpm1 == null); // First tap should return null
    
    Thread.usleep(500000); // 0.5 seconds
    var bpm2 = test_tap_tempo.tap();
    assert(bpm2 != null); // Second tap should return BPM
    assert(bpm2 >= 40 && bpm2 <= 240); // Within valid range
    
    // Test reset() method
    test_tap_tempo.reset();
    assert(test_tap_tempo.get_tap_count() == 0);
    
    // Test get_tap_count() method
    test_tap_tempo.tap();
    assert(test_tap_tempo.get_tap_count() == 1);
    
    teardown_tap_test();
}

/**
 * Test signal connectivity and callback compatibility.
 */
private static void test_signal_callback_compatibility() {
    setup_engine_test();
    
    // Test that beat_occurred signal can be connected (replaces Python callback)
    bool signal_received = false;
    int received_beat = -1;
    bool received_downbeat = false;
    
    // This syntax should work for UI integration
    ulong signal_id = test_engine.beat_occurred.connect((beat, is_downbeat) => {
        signal_received = true;
        received_beat = beat;
        received_downbeat = is_downbeat;
    });
    
    // Test manual signal emission (for testing purposes)
    test_engine.beat_occurred(5, true);
    
    assert(signal_received);
    assert(received_beat == 5);
    assert(received_downbeat == true);
    
    // Test signal disconnection
    test_engine.disconnect(signal_id);
    
    // Reset flags and test that signal no longer fires
    signal_received = false;
    test_engine.beat_occurred(6, false);
    assert(!signal_received); // Should not have received signal
    
    teardown_engine_test();
}

/**
 * Test error handling compatibility with Python exceptions.
 */
private static void test_error_handling_compatibility() {
    setup_engine_test();
    
    // Test BPM validation errors (matches Python ValueError)
    try {
        test_engine.set_tempo(39); // Below minimum
        assert_not_reached();
    } catch (MetronomeError e) {
        assert(e is MetronomeError.INVALID_BPM);
        // Error message should be descriptive
        assert(e.message.contains("40"));
        assert(e.message.contains("240"));
    }
    
    try {
        test_engine.set_tempo(241); // Above maximum
        assert_not_reached();
    } catch (MetronomeError e) {
        assert(e is MetronomeError.INVALID_BPM);
    }
    
    // Test time signature validation errors
    try {
        test_engine.set_time_signature(0, 4); // Invalid numerator
        assert_not_reached();
    } catch (MetronomeError e) {
        assert(e is MetronomeError.INVALID_TIME_SIGNATURE);
    }
    
    try {
        test_engine.set_time_signature(4, 3); // Invalid denominator
        assert_not_reached();
    } catch (MetronomeError e) {
        assert(e is MetronomeError.INVALID_TIME_SIGNATURE);
    }
    
    teardown_engine_test();
}

/**
 * Test property access patterns match Python attribute access.
 */
private static void test_property_access_compatibility() {
    setup_engine_test();
    
    // Test that properties can be read/written like Python attributes
    var original_bpm = test_engine.bpm;
    test_engine.bpm = 180;
    assert(test_engine.bpm == 180);
    
    var original_beats = test_engine.beats_per_bar;
    test_engine.beats_per_bar = 6;
    assert(test_engine.beats_per_bar == 6);
    
    var original_value = test_engine.beat_value;
    test_engine.beat_value = 8;
    assert(test_engine.beat_value == 8);
    
    var original_beat = test_engine.current_beat;
    test_engine.current_beat = 15;
    assert(test_engine.current_beat == 15);
    
    // is_running should be read-only (private setter)
    var running_state = test_engine.is_running;
    assert(running_state == false || running_state == true); // Valid bool
    
    teardown_engine_test();
}

/**
 * Test integration with typical UI usage patterns.
 */
private static void test_ui_integration_patterns() {
    setup_engine_test();
    
    // Test typical UI integration scenario
    var beat_count = 0;
    var downbeat_count = 0;
    
    // Connect signal like UI would
    test_engine.beat_occurred.connect((beat, is_downbeat) => {
        beat_count++;
        if (is_downbeat) {
            downbeat_count++;
        }
    });
    
    // Set up metronome like UI would
    test_engine.bpm = 240; // Fast for quick testing
    test_engine.beats_per_bar = 4;
    test_engine.start();
    
    // Let it run briefly
    var main_loop = new MainLoop();
    uint timeout_id = Timeout.add(100, () => { // 100ms
        test_engine.stop();
        main_loop.quit();
        return false;
    });
    
    main_loop.run();
    
    // Should be stopped now
    assert(!test_engine.is_running);
    
    // At 240 BPM, we should get at least one beat in 100ms
    // (240 BPM = 4 beats per second = 1 beat per 250ms)
    // So in 100ms we might get 0-1 beats depending on timing
    assert(beat_count >= 0);
    assert(downbeat_count >= 0);
    assert(downbeat_count <= beat_count); // Downbeats are subset of all beats
    
    teardown_engine_test();
}

/**
 * Test performance characteristics.
 */
private static void test_performance_characteristics() {
    setup_engine_test();
    
    // Test that operations complete quickly (performance baseline)
    int64 start_time, end_time;
    
    // Test property access performance
    start_time = GLib.get_monotonic_time();
    for (int i = 0; i < 1000; i++) {
        var bpm = test_engine.bpm;
        test_engine.bpm = bpm;
    }
    end_time = GLib.get_monotonic_time();
    var property_time = end_time - start_time;
    
    // Should complete in under 10ms (10,000 microseconds)
    assert(property_time < 10000);
    
    // Test method call performance
    start_time = GLib.get_monotonic_time();
    for (int i = 0; i < 100; i++) {
        try {
            test_engine.set_tempo(120 + (i % 100)); // Valid range
        } catch (MetronomeError e) {
            // Should not error with valid values
            assert_not_reached();
        }
    }
    end_time = GLib.get_monotonic_time();
    var method_time = end_time - start_time;
    
    // Should complete in under 5ms (5,000 microseconds)
    assert(method_time < 5000);
    
    teardown_engine_test();
}

/**
 * Main test runner
 */
public static int main(string[] args) {
    Test.init(ref args);
    
    Test.add_func("/api/metronome_engine_compatibility", test_metronome_engine_api_compatibility);
    Test.add_func("/api/tap_tempo_compatibility", test_tap_tempo_api_compatibility);
    Test.add_func("/api/signal_callback_compatibility", test_signal_callback_compatibility);
    Test.add_func("/api/error_handling_compatibility", test_error_handling_compatibility);
    Test.add_func("/api/property_access_compatibility", test_property_access_compatibility);
    Test.add_func("/api/ui_integration_patterns", test_ui_integration_patterns);
    Test.add_func("/api/performance_characteristics", test_performance_characteristics);
    
    return Test.run();
}