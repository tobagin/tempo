## Description

Adds a toggle in Preferences to disable scroll wheel BPM changes. When disabled, scroll events over the BPM spin box, BPM scale, and patterns tempo scale are consumed in the GTK4 capture phase before the widgets handle them, preventing accidental tempo changes.

## Type of Change

- [ ] Bug fix
- [x] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Translation

## Related Issue

N/A

## Testing

- [ ] Unit tests pass
- [x] Manual testing completed
- [x] Tested on: Ubuntu 24.04 LTS

**Note:** No unit tests were added for `setup_scroll_blocking()`. The method installs a GTK4
`EventControllerScroll` in capture phase, which requires a display to exercise directly. The
testable gap is the GSettings key round-trip (`scroll-to-change-bpm` read/write) — deferred to
the upcoming settings persistence PR, which will extend the test infrastructure to support GIO
and per-test environment variables. ***Please let me know*** if it is preferrable to make these significant changes to meson.build now in order to have a test for this feature.

**Note:** `test_bpm_clamping` in `test_tap_tempo` has a pre-existing timing flakiness (sleep of
exactly 2 s races the 2 s timeout boundary). Not introduced by this PR; tracked separately.

## Screenshots (if UI changes)

<img width="491" height="745" alt="image" src="https://github.com/user-attachments/assets/8dc98a2d-fd60-4c6e-96dd-35f470ef7262" />

## Checklist

- [x] Code follows project style guidelines
- [x] Self-review completed
- [x] Comments added for complex code
- [x] Documentation updated
- [x] No new warnings generated
- [ ] Tests added/updated (deferred — see note above)
- [ ] All tests passing (pre-existing flaky test in `test_bpm_clamping`; not introduced by this PR)
