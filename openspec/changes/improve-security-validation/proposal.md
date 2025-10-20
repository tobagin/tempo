# Security & Input Validation Improvements

## Why

Code analysis revealed several security vulnerabilities and input validation gaps that could lead to denial-of-service, crashes, or unexpected behavior:

1. **File handling**: Custom sound files lack size limits, format validation, and symlink checking
2. **GStreamer security**: User-supplied paths constructed unsafely in URI strings
3. **Resource exhaustion**: No limits on tap tempo history, drawing operations, or settings updates
4. **Input validation**: GSettings string values (file paths) have no validation or sanitization

These issues range from medium severity (file size DoS) to low severity (resource exhaustion), but collectively they create a poor security posture and could lead to user frustration or data loss.

## What Changes

**File Handling Security** (HIGH PRIORITY):
- Add file size validation (10MB limit for custom sounds)
- Implement audio format validation (wav, mp3, ogg, flac only)
- Add symlink resolution and validation
- Validate audio file headers before loading into GStreamer
- Add proper error handling for invalid files

**URI Construction** (HIGH PRIORITY):
- Replace string concatenation with `File.get_uri()` for GStreamer paths
- Add timeout handling for audio file loading operations
- Wrap GStreamer operations in proper error handlers

**Resource Limits** (MEDIUM PRIORITY):
- Cap TapTempo history at 100 entries
- Implement frame rate limiting for beat indicator (60 FPS)
- Add debouncing for rapid settings changes

**Input Validation** (MEDIUM PRIORITY):
- Validate file paths read from GSettings
- Add max length constraints for string settings
- Sanitize version strings

**Error Reporting** (MEDIUM PRIORITY):
- Add user-visible error dialogs for critical failures
- Replace silent warnings with actionable error messages
- Implement graceful degradation (visual-only mode if audio fails)

## Impact

- **Affected specs**: `security` (new capability)
- **Affected code**:
  - `/src/dialogs/PreferencesDialog.vala` - File selection and validation
  - `/src/utils/MetronomeEngine.vala` - GStreamer security improvements
  - `/src/utils/TapTempo.vala` - History size limiting
  - `/src/windows/MainWindow.vala` - Drawing throttling, error dialogs
  - `/data/io.github.tobagin.tempo.gschema.xml.in` - Add validation constraints
- **Affected systems**: File I/O, GStreamer audio, settings persistence, UI error handling
- **User experience**: Better error messages, prevents crashes, protects against malformed files
- **Security improvement**: Mitigates DoS, file parsing vulnerabilities, resource exhaustion
- **Breaking changes**: None - all changes are additive or internal improvements
