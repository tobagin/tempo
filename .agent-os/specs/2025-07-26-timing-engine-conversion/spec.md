# Spec Requirements Document

> Spec: Timing Engine Conversion
> Created: 2025-07-26
> Status: Planning

## Overview

Convert the Python metronome timing engine to Vala while maintaining sub-millisecond precision and all existing functionality. This conversion will replace the Python threading-based implementation with Vala's async/await patterns and GLib timing functions.

## User Stories

### Core Timing Functionality

As a musician, I want the metronome to provide precise timing, so that I can practice with accurate tempo reference.

The timing engine must maintain sub-millisecond accuracy using absolute time references to prevent drift. The current Python implementation uses `time.perf_counter()` with threading - the Vala version will use `GLib.get_monotonic_time()` with async/await patterns for equivalent precision.

### Tap Tempo Feature  

As a user, I want to tap a button to set the tempo, so that I can match the metronome to music I'm playing along with.

The tap tempo functionality calculates BPM from a sliding window of tap intervals. This mathematical logic needs to be preserved exactly in the Vala conversion.

### State Management

As a developer, I want a clean API for metronome state, so that the UI can easily control and monitor the timing engine.

The current Python dataclass-based state management needs to be converted to Vala structs or classes with equivalent property access patterns.

## Spec Scope

1. **MetronomeEngine Class** - Convert core timing logic from Python to Vala
2. **MetronomeState Management** - Port state container and property access
3. **TapTempo Functionality** - Convert tap-based BPM calculation logic
4. **Thread Safety** - Replace Python threading with Vala async patterns
5. **Callback System** - Convert Python callbacks to Vala signals

## Out of Scope

- UI changes (Blueprint files remain unchanged)
- Audio system conversion (separate spec)
- Build system modifications (handled separately)
- Settings/GSettings integration (handled separately)

## Expected Deliverable

1. Fully functional Vala timing engine with identical API to Python version
2. All timing precision maintained (sub-millisecond accuracy)
3. Tap tempo feature working identically to current implementation

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-26-timing-engine-conversion/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-26-timing-engine-conversion/sub-specs/technical-spec.md
- Tests Specification: @.agent-os/specs/2025-07-26-timing-engine-conversion/sub-specs/tests.md