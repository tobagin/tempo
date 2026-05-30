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
and per-test environment variables.

## Screenshots (if UI changes)

[Add screenshot of new toggle in Preferences → Behavior]

## Checklist

- [x] Code follows project style guidelines
- [x] Self-review completed
- [x] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests passing
