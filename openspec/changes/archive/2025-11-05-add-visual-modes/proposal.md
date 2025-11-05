# Add Visual Metronome Modes

## Why
Currently, Tempo displays beats using a single visual style (circle indicator). Different users have different visual preferences, learning styles, and use cases (silent practice, accessibility needs, personal preference). Offering multiple visual modes enhances usability, supports accessibility (visual learners, low vision users), and provides variety to prevent visual fatigue during long practice sessions.

## What Changes
- Add multiple visual indicator modes: Circle (current), Pendulum, Bar Graph, Progress Ring, Minimalist Flash
- Visual mode selector in preferences
- Each mode maintains beat number display and timing accuracy
- Smooth animations using Cairo graphics where appropriate
- Mode setting persists across sessions
- All modes support beat/downbeat distinction with appropriate visual emphasis

## Impact
- **Affected specs**: New `visual-modes` spec
- **Related specs**: `responsive-layout` (visual modes adapt to window size)
- **Affected code**:
  - `src/windows/MainWindow.vala` - Multiple draw functions for each visual mode
  - `src/utils/VisualMode.vala` - NEW: Abstract interface and concrete mode implementations
  - `data/ui/preferences_dialog.blp` - Visual mode selector dropdown
  - `src/dialogs/PreferencesDialog.vala` - Mode selection handling
  - `data/io.github.tobagin.tempo.gschema.xml.in` - visual-mode setting
  - `data/style.css` - Styles for each visual mode

## Design Decisions
- **Mode architecture**: Strategy pattern - interface with concrete implementations for each mode
- **Animation**: Use Cairo for smooth animations, maintain 60fps target
- **Accessibility**: Ensure each mode meets WCAG contrast requirements
- **Performance**: Lightweight drawing code, no mode should impact timing accuracy
- **Default**: Keep current circle mode as default to preserve existing UX

## Dependencies
- No hard dependencies
- Integrates with existing beat indicator infrastructure
- Optional: Could enhance `subdivisions` feature by visualizing subdivision beats

## Migration & Compatibility
- Default: Circle mode (current behavior)
- Settings: Add `visual-mode` key (string: 'circle', 'pendulum', 'bar', 'ring', 'flash')
- Existing users see no change unless they select a different mode
