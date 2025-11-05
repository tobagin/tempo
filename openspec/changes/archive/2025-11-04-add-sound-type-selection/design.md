# Sound Type Selection Design

## Context
Tempo currently provides a single default sound (high.wav/low.wav) with custom sound file support. Users want more variety without managing external files. This change adds built-in sound type presets while maintaining custom sound functionality.

**Constraints:**
- Must bundle sound files in GResource (Flatpak sandbox requires compiled resources)
- Must maintain backward compatibility with existing custom sound settings
- Must follow existing sound validation and security patterns
- No external dependencies allowed (sounds must be bundled)

**Stakeholders:**
- Musicians wanting different sound aesthetics (practice vs performance)
- Users who find custom file management cumbersome
- Existing users with custom sounds configured

## Goals / Non-Goals

**Goals:**
- Provide 3-4 built-in sound type presets (Woodblock, Metal, Digital, etc.)
- Allow independent high/low sound type selection
- Maintain full custom sound functionality
- Zero breaking changes to existing settings or API
- All sounds bundled in application binary

**Non-Goals:**
- User-created sound type presets or favorites
- Sound type marketplace or downloading
- Real-time sound synthesis or effects
- Per-beat-number customization (only high/low distinction)
- Visual sound wave previews

## Decisions

### Decision 1: Independent High/Low Sound Type Selection
**Choice:** Allow users to select different sound types for high (accent) and low (regular) sounds independently.

**Rationale:**
- Provides maximum flexibility for musical expression
- Mirrors existing high-sound-path/low-sound-path custom sound structure
- Minimal additional complexity (two dropdowns instead of one)

**Alternatives considered:**
- Single sound type dropdown (rejected: less flexible, limits creative combinations)
- Unified preset system with pre-defined pairs (rejected: too rigid, limits user control)

### Decision 2: Custom Sounds Take Precedence
**Choice:** When custom sounds are enabled and a path is set, use custom file regardless of sound type setting. Disable sound type dropdown when custom path exists.

**Rationale:**
- Clear, predictable behavior: custom always wins
- Prevents confusion about which setting is active
- Maintains existing custom sound behavior perfectly
- UI clearly indicates which control is active via enabled/disabled state

**Alternatives considered:**
- Three-way toggle (default/type/custom) (rejected: more complex UI, harder to understand)
- Allow mixing in complex ways (rejected: confusing precedence rules)

### Decision 3: File Naming Convention
**Choice:** Use pattern `{type}-high.wav` and `{type}-low.wav`, with legacy `high.wav`/`low.wav` as "default" type.

**Rationale:**
- Clear, consistent naming structure
- Backward compatible (existing files remain)
- Easy to add new types in future
- Simple file path construction in code

**Alternatives considered:**
- Nested directories `sounds/{type}/high.wav` (rejected: unnecessary complexity for 3-4 types)
- Include type in GResource path (rejected: harder to reference, less flexible)

### Decision 4: GSettings String Keys
**Choice:** Store sound types as strings ("default", "woodblock", "metal", "digital") rather than enum integers.

**Rationale:**
- More readable in gsettings command line and dconf-editor
- Easier to add new types without schema version migration
- Self-documenting setting values
- Simpler validation (string comparison vs enum range checking)

**Alternatives considered:**
- Integer enum (0=default, 1=woodblock, etc.) (rejected: less maintainable, requires mapping)
- JSON structure (rejected: overkill for simple string value)

### Decision 5: UI Placement
**Choice:** Place sound type dropdowns above custom sound file pickers in Audio preferences section.

**Rationale:**
- Natural flow: choose preset OR choose custom file
- Dropdowns above file pickers indicates precedence hierarchy
- Keeps all sound configuration in one visual group
- Disabled dropdowns when custom is active makes relationship clear

### Decision 6: Sound Type at Startup Validation
**Choice:** Validate all bundled sound type files exist at MetronomeEngine initialization. Log warnings for missing files but continue with fallback.

**Rationale:**
- Fail gracefully rather than crash on missing resource
- Early detection of build/packaging issues
- Follows existing validation pattern from custom sounds
- Logging helps debugging without blocking user

## Risks / Trade-offs

### Risk: Increased Binary Size
**Impact:** Each sound type adds ~400KB (200KB × 2 files). 3 new types = ~1.2MB.
**Mitigation:** Use efficient WAV compression (16-bit, not 24-bit), keep durations short (100-200ms typical). Total app size increase acceptable for Linux desktop app.

### Risk: Sound Quality Expectations
**Impact:** Users may expect studio-quality sound samples.
**Mitigation:** Ensure all sounds are professionally normalized and tested. Document sound specifications clearly. Can improve sounds in future updates based on feedback.

### Trade-off: Type vs Custom Complexity
**Impact:** Two ways to customize sounds (type selection + custom files) adds UI/logic complexity.
**Mitigation:** Clear precedence rule (custom wins), visual feedback (disabled dropdowns), preserve both workflows for different user needs.

### Risk: Backward Compatibility Edge Cases
**Impact:** Existing users with unusual GSettings state (corrupted values, manual edits) might see unexpected behavior.
**Mitigation:** Robust fallback logic, invalid type → default type, extensive logging, settings validation on load.

## Migration Plan

**Deployment:**
1. Build includes new sound files in gresource bundle
2. GSettings schema updated with new keys (default values prevent breaking existing installs)
3. Existing users: see "default" type selected, custom sounds unaffected
4. Fresh installs: see "default" type, can explore other types

**Rollback:**
- If critical bug found, can revert commits
- Old version will ignore `high-sound-type`/`low-sound-type` keys (graceful degradation)
- No data loss: custom sound paths preserved

**Testing before release:**
- Test fresh install
- Test upgrade from current version with no custom sounds
- Test upgrade with custom sounds configured
- Test invalid GSettings values (manual corruption)

## Open Questions

1. **Which specific sound types to include?**
   - Proposal: Default (current), Woodblock, Metal, Digital
   - Need to decide on exact sounds based on user research or musician input
   - Can add more types in future updates

2. **Should we include a "beep" or pure tone option?**
   - Some users prefer electronic beeps over acoustic samples
   - Can be added as "Beep" or "Tone" type if requested

3. **Preview sound button in preferences?**
   - Would help users hear sound before selecting
   - Adds UI complexity
   - Can be future enhancement

4. **Sound type in main window status/indicator?**
   - Should main window show current sound type?
   - Probably not needed (most users set once and forget)
   - Preferences are sufficient for now
