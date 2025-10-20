# Security & Input Validation Design

## Context

Current codebase analysis revealed several security vulnerabilities and input validation gaps in the Tempo metronome application:

- **File handling**: User-supplied audio files lack size, format, and symlink validation
- **URI construction**: Unsafe string concatenation for GStreamer URIs (lines MetronomeEngine.vala:277, 309; PreferencesDialog.vala:371)
- **Resource exhaustion**: Unbounded tap history, unlimited drawing operations, no settings debouncing
- **Input validation**: GSettings string values have no validation or sanitization

These issues could lead to denial-of-service attacks, crashes, or unexpected behavior. This design addresses defensive security improvements without breaking existing functionality.

## Goals / Non-Goals

**Goals:**
- Prevent file-based DoS attacks (size limits, format validation)
- Secure GStreamer URI construction against path injection
- Limit resource consumption (tap history, drawing FPS, settings updates)
- Validate all external input (file paths, version strings)
- Provide clear error messages to users for invalid inputs
- Maintain graceful degradation (visual-only mode if audio fails)

**Non-Goals:**
- Cryptographic security or authentication mechanisms
- Network security (app is local-only)
- Memory safety improvements (Vala/GLib handle this)
- Performance optimization beyond resource limiting

## Decisions

### 1. File Validation Strategy

**Decision:** Multi-layer validation at selection time
- File size check (10MB max) before attempting to load
- MIME type validation against allowlist (wav, mp3, ogg, flac)
- Symlink resolution with validation of final target
- Basic audio header validation before passing to GStreamer

**Why:** Fail fast at the UI layer rather than waiting for GStreamer errors. 10MB limit chosen to support high-quality samples while preventing abuse.

**Alternatives considered:**
- Let GStreamer handle all validation → **Rejected**: Provides poor error messages and may crash on malformed files
- Use file extension only → **Rejected**: Trivially bypassed by renaming files
- No size limit → **Rejected**: Allows memory exhaustion via large files

### 2. URI Construction

**Decision:** Use `GLib.File.get_uri()` for all GStreamer URI paths

**Why:** GLib provides proper URI encoding, escaping, and validation. Eliminates string concatenation vulnerabilities.

**Implementation:**
```vala
// OLD (unsafe):
player.set("uri", "file://" + custom_path);

// NEW (safe):
var file = GLib.File.new_for_path(custom_path);
player.set("uri", file.get_uri());
```

**Alternatives considered:**
- Manual URI escaping → **Rejected**: Error-prone and reinvents the wheel
- Validate path characters → **Rejected**: Incomplete, doesn't handle all edge cases

### 3. Resource Limits

**Decision:** Conservative hard limits with no user configuration

| Resource | Limit | Rationale |
|----------|-------|-----------|
| Tap history | 100 entries | Max 8 used for calculation; 100 provides debugging headroom |
| Beat indicator FPS | 60 FPS | Matches display refresh rate; prevents runaway redraws |
| Settings debounce | 100ms | Balances responsiveness with update storms |

**Why:** Hard limits are simpler and sufficient for single-user desktop app. No compelling use case for higher values.

**Alternatives considered:**
- User-configurable limits → **Rejected**: Adds complexity without clear benefit
- Adaptive limits based on system load → **Rejected**: Over-engineered for the threat model

### 4. GSettings Validation

**Decision:** Add validation at both schema and runtime levels

**Schema level (gschema.xml):**
- Add max length for string paths (4096 characters)
- Add pattern validation for version strings (`^[0-9]+\.[0-9]+\.[0-9]+$`)

**Runtime level (Vala):**
- Validate paths exist and are regular files before use
- Sanitize version strings before comparison
- Handle missing/corrupted settings gracefully with defaults

**Why:** Defense in depth - schema prevents invalid storage, runtime handles legacy/corrupted data.

**Alternatives considered:**
- Schema validation only → **Rejected**: Doesn't protect against external gsettings manipulation
- Runtime validation only → **Rejected**: Allows invalid data to persist in settings

### 5. Error Reporting

**Decision:** Three-tier error strategy

1. **Critical errors (audio system failure):** Modal dialog with explanation and option to continue in visual-only mode
2. **User errors (invalid file):** Toast notification with specific reason (e.g., "File too large: 15MB exceeds 10MB limit")
3. **Recoverable errors (temporary GStreamer issue):** Warning log only, silent fallback

**Why:** Different error severities require different UX approaches. Users should only be interrupted for decisions they need to make.

**Alternatives considered:**
- All errors as dialogs → **Rejected**: Annoying for transient issues
- All errors silent → **Rejected**: Users left confused about why features don't work

### 6. Graceful Degradation

**Decision:** Implement visual-only mode when audio system fails

**Implementation:**
- Detect audio initialization failure at startup
- Show one-time notification: "Audio system unavailable. Running in visual-only mode."
- Beat indicator continues to work
- Audio controls disabled/grayed out
- App remains fully functional for visual tempo tracking

**Why:** Audio problems (missing GStreamer plugins, PulseAudio issues) are common on Linux. App should remain useful.

**Alternatives considered:**
- Refuse to start without audio → **Rejected**: Makes app unusable for valid use cases (visual tempo reference)
- Retry audio indefinitely → **Rejected**: Wastes resources and likely won't succeed

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| **False positives rejecting valid files** | User frustration | Allowlist common formats; clear error messages; manual override possible via file manager |
| **10MB limit too restrictive** | Can't use long samples | Chosen based on typical click sound size (~100KB); 10MB supports even 1-minute 44.1kHz wav files |
| **Performance impact of validation** | Slower file selection | Validation only runs on user action (file selection), not in hot path |
| **Legacy settings corruption** | App fails to start | Graceful fallback to defaults if validation fails; settings can be reset via gsettings |

## Migration Plan

**Deployment:**
1. Deploy changes as minor version update (no API/data format changes)
2. Existing settings remain valid (new constraints only apply to new inputs)
3. No user action required

**Rollback:**
- Changes are additive/defensive only
- Rollback involves removing validation checks
- No data migration needed

**Backward compatibility:**
- Existing custom sound paths continue to work (validated at load time)
- Invalid paths from older versions fail gracefully with fallback to default sounds
- Settings schema version unchanged (no migration needed)

## Implementation Notes

### File Size Check
```vala
FileInfo info = file.query_info("standard::size", FileQueryInfoFlags.NONE);
int64 size = info.get_size();
if (size > 10 * 1024 * 1024) {
    show_error_toast("File too large: %s exceeds 10MB limit".printf(format_size(size)));
    return false;
}
```

### Audio Format Validation
```vala
FileInfo info = file.query_info("standard::content-type", FileQueryInfoFlags.NONE);
string mime_type = info.get_content_type();
string[] allowed_types = {"audio/wav", "audio/x-wav", "audio/mpeg", "audio/mp3",
                          "audio/ogg", "audio/flac", "audio/x-flac"};
if (!(mime_type in allowed_types)) {
    show_error_toast("Unsupported audio format: %s".printf(mime_type));
    return false;
}
```

### Symlink Resolution
```vala
// GLib.File automatically resolves symlinks via get_path()
// Just validate the final target is a regular file
if (file.query_file_type(FileQueryInfoFlags.NONE) != FileType.REGULAR) {
    show_error_toast("Path is not a regular file");
    return false;
}
```

### Debouncing Pattern
```vala
private uint debounce_timer = 0;

private void on_setting_changed(string value) {
    if (debounce_timer != 0) {
        Source.remove(debounce_timer);
    }

    debounce_timer = Timeout.add(100, () => {
        apply_setting(value);
        debounce_timer = 0;
        return false;
    });
}
```

## Open Questions

None - design is complete and ready for implementation.
