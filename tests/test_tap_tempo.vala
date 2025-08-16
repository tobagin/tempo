/**
 * Test suite for TapTempo Vala implementation.
 * 
 * This file tests the tap tempo calculation functionality
 * to ensure it matches the behavior of the Python version.
 */

using GLib;

// Global test instance
private static TapTempo? test_tap_tempo;

private static void setup_test() {
    test_tap_tempo = new TapTempo();
}

private static void teardown_test() {
    test_tap_tempo = null;
}

/**
 * Test TapTempo creation with default values.
 */
private static void test_tap_tempo_creation() {
    setup_test();
    assert(test_tap_tempo != null);
    assert(test_tap_tempo.max_taps == 8);
    assert(test_tap_tempo.timeout_seconds == 2.0);
    assert(test_tap_tempo.get_tap_count() == 0);
    teardown_test();
}

/**
 * Test TapTempo creation with custom values.
 */
private static void test_tap_tempo_custom_creation() {
    test_tap_tempo = new TapTempo(4, 1.5);
    assert(test_tap_tempo.max_taps == 4);
    assert(test_tap_tempo.timeout_seconds == 1.5);
    assert(test_tap_tempo.get_tap_count() == 0);
    test_tap_tempo = null;
}

/**
 * Test single tap (should return null - insufficient data).
 */
private static void test_single_tap() {
    setup_test();
    
    var bpm = test_tap_tempo.tap();
    assert(bpm == null);
    assert(test_tap_tempo.get_tap_count() == 1);
    
    teardown_test();
}

/**
 * Test two taps to calculate BPM.
 */
private static void test_two_taps_bpm_calculation() {
    setup_test();
    
    // Simulate two taps 0.5 seconds apart (120 BPM)
    var bpm1 = test_tap_tempo.tap();
    assert(bpm1 == null); // First tap returns null
    
    // Wait and add second tap (simulate 0.5 second interval)
    Thread.usleep(500000); // 500ms = 0.5 seconds
    var bpm2 = test_tap_tempo.tap();
    
    assert(bpm2 != null);
    // Should be close to 120 BPM (60 / 0.5 = 120)
    // Allow some tolerance for timing variations
    assert(bpm2 >= 110 && bpm2 <= 130);
    assert(test_tap_tempo.get_tap_count() == 2);
    
    teardown_test();
}

/**
 * Test multiple taps for averaging.
 */
private static void test_multiple_taps_averaging() {
    setup_test();
    
    // Simulate consistent 150 BPM tapping (0.4 second intervals)
    var interval_us = 400000; // 400ms in microseconds
    
    test_tap_tempo.tap(); // First tap
    Thread.usleep(interval_us);
    
    test_tap_tempo.tap(); // Second tap
    Thread.usleep(interval_us);
    
    test_tap_tempo.tap(); // Third tap
    Thread.usleep(interval_us);
    
    var bpm = test_tap_tempo.tap(); // Fourth tap
    
    assert(bpm != null);
    // Should be close to 150 BPM (60 / 0.4 = 150)
    assert(bpm >= 140 && bpm <= 160);
    assert(test_tap_tempo.get_tap_count() == 4);
    
    teardown_test();
}

/**
 * Test BPM clamping to valid range (40-240).
 */
private static void test_bpm_clamping() {
    setup_test();
    
    // Test very slow tapping (should clamp to minimum 40 BPM)
    test_tap_tempo.tap();
    Thread.usleep(2000000); // 2 seconds (30 BPM)
    var slow_bpm = test_tap_tempo.tap();
    
    assert(slow_bpm != null);
    assert(slow_bpm == 40); // Should clamp to minimum
    
    teardown_test();
    setup_test();
    
    // Test very fast tapping (should clamp to maximum 240 BPM)
    test_tap_tempo.tap();
    Thread.usleep(100000); // 0.1 seconds (600 BPM)
    var fast_bpm = test_tap_tempo.tap();
    
    assert(fast_bpm != null);
    assert(fast_bpm == 240); // Should clamp to maximum
    
    teardown_test();
}

/**
 * Test tap timeout functionality.
 */
private static void test_tap_timeout() {
    // Create with short timeout for testing
    test_tap_tempo = new TapTempo(8, 0.5); // 0.5 second timeout
    
    test_tap_tempo.tap(); // First tap
    assert(test_tap_tempo.get_tap_count() == 1);
    
    // Wait longer than timeout
    Thread.usleep(600000); // 0.6 seconds
    
    test_tap_tempo.tap(); // Second tap (should clear old taps)
    
    // The old tap should be removed due to timeout
    assert(test_tap_tempo.get_tap_count() == 1);
    
    test_tap_tempo = null;
}

/**
 * Test maximum tap limit.
 */
private static void test_max_tap_limit() {
    test_tap_tempo = new TapTempo(3, 10.0); // Max 3 taps, long timeout
    
    // Add 5 taps quickly
    for (int i = 0; i < 5; i++) {
        test_tap_tempo.tap();
        Thread.usleep(100000); // 0.1 second intervals
    }
    
    // Should only keep the last 3 taps
    assert(test_tap_tempo.get_tap_count() == 3);
    
    test_tap_tempo = null;
}

/**
 * Test reset functionality.
 */
private static void test_reset() {
    setup_test();
    
    // Add some taps
    test_tap_tempo.tap();
    test_tap_tempo.tap();
    assert(test_tap_tempo.get_tap_count() == 2);
    
    // Reset should clear all taps
    test_tap_tempo.reset();
    assert(test_tap_tempo.get_tap_count() == 0);
    
    teardown_test();
}

/**
 * Test known BPM calculation accuracy.
 */
private static void test_known_bpm_accuracy() {
    setup_test();
    
    // Test 60 BPM (1 second intervals)
    test_tap_tempo.tap();
    Thread.usleep(1000000); // 1 second
    var bpm_60 = test_tap_tempo.tap();
    
    assert(bpm_60 != null);
    assert(bpm_60 >= 55 && bpm_60 <= 65); // Allow 5 BPM tolerance
    
    teardown_test();
    setup_test();
    
    // Test 180 BPM (1/3 second intervals)
    test_tap_tempo.tap();
    Thread.usleep(333333); // ~1/3 second
    var bpm_180 = test_tap_tempo.tap();
    
    assert(bpm_180 != null);
    assert(bpm_180 >= 170 && bpm_180 <= 190); // Allow 10 BPM tolerance
    
    teardown_test();
}

/**
 * Main test runner
 */
public static int main(string[] args) {
    Test.init(ref args);
    
    Test.add_func("/tap_tempo/creation", test_tap_tempo_creation);
    Test.add_func("/tap_tempo/custom_creation", test_tap_tempo_custom_creation);
    Test.add_func("/tap_tempo/single_tap", test_single_tap);
    Test.add_func("/tap_tempo/two_taps", test_two_taps_bpm_calculation);
    Test.add_func("/tap_tempo/multiple_taps", test_multiple_taps_averaging);
    Test.add_func("/tap_tempo/bpm_clamping", test_bpm_clamping);
    Test.add_func("/tap_tempo/timeout", test_tap_timeout);
    Test.add_func("/tap_tempo/max_limit", test_max_tap_limit);
    Test.add_func("/tap_tempo/reset", test_reset);
    Test.add_func("/tap_tempo/accuracy", test_known_bpm_accuracy);
    
    return Test.run();
}