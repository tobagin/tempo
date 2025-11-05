# Add Practice Timer

## Overview
Add comprehensive practice time management to Tempo with a session timer that supports count-up, countdown, and auto-stop functionality. This feature helps musicians track practice duration, enforce practice goals, and maintain focus during practice sessions.

## Motivation
Musicians benefit greatly from tracking their practice time to:
- Build consistent practice habits through time accountability
- Set and achieve specific duration goals
- Maintain focus during structured practice sessions
- Use techniques like Pomodoro for interval training
- Track progress over time

According to TODO.md, this feature has **High Priority** (⭐⭐⭐⭐) with **Low Complexity** and **High User Impact**, making it an ideal candidate for early implementation.

## Goals
1. **Session Tracking**: Display elapsed practice time while metronome is running
2. **Countdown Mode**: Support target duration with countdown to zero
3. **Auto-Stop**: Optionally stop metronome after configurable beat/bar/time limits
4. **Flexible Display**: Show timer in MM:SS or HH:MM:SS format
5. **Persistence**: Remember timer settings across sessions
6. **User Control**: Pause, resume, and reset timer independently of metronome

## Non-Goals
- Session history/statistics (deferred to future feature #11)
- Practice streak tracking or gamification
- Multi-session aggregation
- Export of practice data
- Integration with external calendar systems

## Success Criteria
- Musicians can see elapsed practice time while practicing
- Countdown timer can be set for specific durations (1-180 minutes)
- Auto-stop works correctly for beats, bars, and time-based limits
- Timer persists settings and state appropriately
- UI remains clean and uncluttered with timer additions
- Performance remains unchanged (sub-millisecond timing accuracy)

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Timer display clutters minimal UI | Make timer toggleable, use compact formatting |
| Auto-stop interrupts practice flow | Clear visual indication when active, optional notification |
| Timer adds complexity to MetronomeEngine | Keep timer logic separate in dedicated class |
| Settings proliferation | Group timer settings in dedicated preferences section |

## Open Questions
- [x] Should timer pause when metronome stops? → Yes, with setting to control behavior
- [x] Should we support multiple auto-stop conditions simultaneously? → No, single condition to keep UX simple
- [x] What's the maximum countdown duration? → 180 minutes (3 hours) seems reasonable
- [x] Where should timer display appear in UI? → Below beat indicator, toggleable visibility

## Dependencies
- No dependencies on other features
- Builds on existing MetronomeEngine beat tracking
- Requires new GSettings keys for timer configuration
- Minor additions to main window UI (Blueprint)

## Related Work
- Feature #18 (Practice Mode with Auto-Stop) - Merged into this proposal as auto-stop functionality
- Feature #11 (Session History/Statistics) - Future enhancement that will build on this timer
- Current beat tracking in MetronomeEngine.vala - Foundation for beat/bar counting

## Implementation Approach
See `design.md` for architectural decisions and `tasks.md` for detailed implementation plan.

## Spec Changes
This proposal introduces one new capability:
- `practice-timer` - Session timing and auto-stop functionality
