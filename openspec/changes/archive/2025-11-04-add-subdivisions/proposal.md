# Add Subdivisions Support

## Overview
Add comprehensive subdivision support to Tempo, enabling musicians to hear and see rhythmic divisions within each beat. This transforms Tempo from a basic metronome into a professional-grade practice tool by supporting eighth notes, sixteenth notes, and triplets with precise timing and visual feedback.

## Motivation
Musicians practicing complex rhythms need to hear subdivisions to develop precise timing and internalize intricate rhythmic patterns. Current metronome functionality only provides whole beats, limiting its usefulness for:
- Practicing fast passages that require subdivision awareness
- Developing timing for syncopated rhythms
- Building polyrhythmic facility
- Learning jazz swing feels (triplet subdivisions)
- Mastering classical music with complex note divisions

According to TODO.md, this is the **highest priority feature** (⭐⭐⭐⭐⭐) with **Very High User Impact** and **Medium Complexity**, representing the single most impactful enhancement to transform Tempo into a professional tool.

## Goals
1. **Subdivision Modes**: Support None, Eighth Notes (2 per beat), Sixteenth Notes (4 per beat), and Triplets (3 per beat)
2. **Audio Feedback**: Play lighter/quieter click sounds for subdivisions vs. main beats
3. **Visual Feedback**: Display subdivision indicators synchronized with audio
4. **Timing Precision**: Maintain sub-millisecond accuracy for all subdivisions
5. **Customizable Sounds**: Allow different sounds for subdivisions vs. beats
6. **Settings Persistence**: Remember subdivision mode and preferences
7. **Performance**: No degradation to core timing engine performance

## Non-Goals
- Polyrhythmic subdivisions (e.g., 5 against 4) - deferred to future feature #10
- Custom subdivision ratios beyond standard musical divisions
- Visual subdivision editor/sequencer - deferred to rhythm patterns feature #6
- MIDI output for subdivisions - deferred to MIDI support feature #8
- Dotted note subdivisions (e.g., dotted eighths)

## Success Criteria
- Musicians can enable eighth, sixteenth, or triplet subdivisions
- Subdivision clicks are audibly distinct from main beats (lighter/quieter)
- Subdivision timing is precise across all tempos (40-240 BPM)
- Visual indicators show subdivision positions within beats
- No timing drift or jitter introduced by subdivision calculation
- Settings persist across app restarts
- UI remains clean with subdivision controls integrated naturally

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Timing precision degraded by multiple clicks per beat | Use same absolute time reference architecture, schedule each subdivision independently |
| Audio overlap at fast tempos with 16th notes | Implement sample duration check, adjust subdivision volume dynamically |
| Visual clutter from subdivision indicators | Use subtle dots/lines, make size/visibility configurable |
| CPU overhead from 4x click rate (16th notes) | Pre-calculate subdivision times, optimize audio playback, profile at 240 BPM |
| Triplet timing complexity (3 divisions per beat) | Use precise floating-point math, validate against metronome standards |

## Open Questions
- [x] Should subdivision sounds be distinct from beat sounds or just quieter? → Quieter volume (configurable), optionally different sound
- [x] How to display subdivisions visually? → Dots/lines around beat circle, pulse on subdivision
- [x] Should triplets work in compound time signatures (6/8, 9/8)? → Yes, but subdivisions divide the beat, not the measure
- [x] Maximum tempo with 16th notes? → Full range (40-240 BPM), validate audio doesn't overlap
- [x] Should subdivision volume be independent setting? → Yes, separate volume control

## Dependencies
- No dependencies on other features
- Builds on existing MetronomeEngine timing architecture
- Requires GStreamer audio playback (already implemented)
- May benefit from built-in sound types (recently added)

## Related Work
- Feature #6 (Rhythm Patterns) - Future feature that will extend subdivision concept
- Feature #10 (Polyrhythms) - Advanced subdivision with independent timing
- Recently implemented sound type selection - provides foundation for subdivision sounds
- Existing beat_occurred signal - will add subdivision_occurred signal

## Implementation Approach
See `design.md` for detailed timing architecture and `tasks.md` for implementation plan.

Key technical approach:
- Extend MetronomeEngine with subdivision timing logic
- Use same absolute time reference architecture to prevent drift
- Schedule subdivision clicks between main beats using calculated subdivision times
- Emit new `subdivision_occurred` signal for visual feedback
- Add subdivision sound player (lighter/quieter than main beat)
- Integrate subdivision controls into main window UI

## Spec Changes
This proposal introduces one new capability:
- `subdivisions` - Rhythmic subdivision support for eighth notes, sixteenth notes, and triplets
