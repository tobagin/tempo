# Add Tempo Trainer

## Overview
Add intelligent tempo progression to Tempo, enabling musicians to automatically increase or decrease tempo over time for gradual speed building. The Tempo Trainer guides musicians from a comfortable starting tempo to a target tempo using configurable increments and intervals, eliminating manual tempo adjustments during practice.

## Motivation
Musicians learning difficult passages often use the "slow practice" method: start at a comfortable slow tempo, master the passage, then gradually increase speed. Currently, this requires:
- Stopping to manually adjust tempo
- Losing focus and momentum during adjustment
- Forgetting to increment consistently
- No structured progression tracking

A tempo trainer automates this workflow, allowing musicians to:
- Set a progression path (e.g., 60 BPM → 120 BPM, +5 BPM every 8 bars)
- Practice continuously without interruption
- Build speed systematically and measurably
- Track progression over time

According to TODO.md, this is a **highest priority feature** (⭐⭐⭐⭐⭐) with **Medium Complexity** and **Very High User Impact**, representing a unique value proposition for structured practice.

## Goals
1. **Progressive Tempo Change**: Automatically increase or decrease tempo from start to target
2. **Flexible Intervals**: Support bar-based (every N bars) and time-based (every N seconds) progression
3. **Configurable Increments**: Allow customizable BPM increment/decrement amounts
4. **Progress Visibility**: Display current progress toward target tempo
5. **Pause/Resume**: Maintain progression state when metronome paused
6. **Target Completion**: Optional auto-stop when target tempo reached
7. **Smooth Integration**: Work seamlessly with existing tempo controls and other features

## Non-Goals
- Multiple progression presets (save/load trainer configurations) - defer to presets feature #3
- Complex progression curves (logarithmic, exponential) - linear progression only for v1
- Automatic tempo detection from audio input
- Integration with external practice tracking systems
- Metronome learning AI that adapts increment based on user performance
- Tempo decrease on detected mistakes (requires audio analysis)

## Success Criteria
- Musicians can configure start/end tempo and increment size
- Progression works in both bar-based and time-based modes
- Tempo changes apply smoothly without timing glitches
- Progress clearly visible in UI (e.g., "105/120 BPM, next in 3 bars")
- State persists when pausing/resuming
- Target completion triggers notification
- Works correctly with subdivisions and practice timer (if enabled)
- Settings persist across app restarts

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Tempo change mid-measure disrupts timing | Apply tempo changes only at measure boundaries (downbeat) |
| User confusion about current vs target tempo | Clear UI showing "Current → Target" with progress indicator |
| Progression state lost on pause | Persist progression state separately from metronome state |
| Conflicting with manual tempo changes | Disable trainer when user manually adjusts tempo, show toast |
| Very large increments jarring | Warn if increment > 20 BPM, suggest smaller steps |
| Reaching target mid-session unclear | Clear notification + optional auto-stop |

## Open Questions
- [x] Should tempo change apply immediately or at next bar? → Next bar/downbeat for smooth transition
- [x] What happens if user manually changes tempo during training? → Disable trainer, show "Tempo Trainer paused" toast
- [x] Should we support tempo decrease (start > end)? → Yes, useful for cooling down or tempo challenges
- [x] Maximum increment size? → 50 BPM (enforced range), warn if > 20 BPM
- [x] Should progression persist across app restarts? → Settings persist, but progression state resets (fresh session)
- [x] Interaction with metronome pause? → Trainer pauses with metronome, resumes from same state

## Dependencies
- Builds on MetronomeEngine beat tracking (for bar-based intervals)
- May benefit from Practice Timer (for time-based intervals) but not required
- Works with subdivisions (if enabled, subdivisions use current tempo)
- No dependencies on other features

## Related Work
- Feature #4 (Practice Timer) - Complements trainer (time tracking + tempo progression)
- Feature #3 (Tempo Presets) - Future: save trainer configurations as presets
- Feature #11 (Session History) - Future: track tempo progression over multiple sessions
- Existing tempo controls - Trainer extends, not replaces

## Implementation Approach
See `design.md` for detailed architecture and `tasks.md` for implementation plan.

Key technical approach:
- Create new `TempoTrainer` utility class for progression logic
- Integrate with MetronomeEngine via signals (beat_occurred for bars, timeout for seconds)
- Track progression state: bars_completed or seconds_elapsed, current_tempo
- Apply tempo changes via MetronomeEngine.set_tempo() at appropriate intervals
- Add trainer controls to main window (collapsible section to avoid clutter)
- Emit trainer events (tempo_incremented, target_reached) for UI updates

## Spec Changes
This proposal introduces one new capability:
- `tempo-trainer` - Automatic tempo progression for gradual speed building
