# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-26-timing-engine-conversion/spec.md

> Created: 2025-07-26
> Version: 1.0.0

## Test Coverage

### Unit Tests

**MetronomeEngine**
- Test start/stop functionality
- Test BPM setting within valid range (40-240)
- Test time signature changes
- Test beat number incrementing correctly
- Test signal emission on beat events
- Test timing precision (verify beat intervals)

**TapTempo**
- Test single tap (no BPM calculation)
- Test multiple taps for BPM calculation
- Test tap timeout and reset behavior
- Test BPM calculation accuracy with known intervals
- Test edge cases (very fast/slow taps)

**MetronomeState**
- Test property getters/setters
- Test state validation
- Test default values

### Integration Tests

**Timing Accuracy**
- Verify sub-millisecond precision over extended periods
- Test drift prevention over long sessions (10+ minutes)
- Compare timing accuracy with Python implementation

**Signal Integration**
- Test signal connection and disconnection
- Verify beat callback timing accuracy
- Test multiple signal handlers

### Performance Tests

**Memory Usage**
- Monitor memory allocation during operation
- Test for memory leaks during start/stop cycles
- Compare memory usage with Python version

**CPU Usage**
- Measure CPU impact of timing loop
- Test performance under high BPM (240)
- Compare performance with Python threading version

### Mocking Requirements

- **Time Functions:** Mock `GLib.get_monotonic_time()` for deterministic testing
- **Timeout Sources:** Mock `GLib.Timeout.add()` for predictable test execution
- **Signal Emission:** Capture and verify signal emissions in tests

## Test Data

### BPM Test Cases
- Minimum: 40 BPM
- Maximum: 240 BPM  
- Common values: 60, 120, 180 BPM
- Edge cases: 39, 241 (invalid values)

### Time Signature Test Cases
- 4/4 (common time)
- 3/4 (waltz time)
- 6/8 (compound time)
- 7/8 (odd time)
- 1/1 (whole note)

### Tap Tempo Test Cases
- 2 taps: 120 BPM (0.5 second intervals)
- 4 taps: 60 BPM (1.0 second intervals)
- 8 taps: 180 BPM (0.333 second intervals)
- Irregular taps: mixed intervals