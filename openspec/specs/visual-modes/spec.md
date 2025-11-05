# visual-modes Specification

## Purpose
TBD - created by archiving change add-visual-modes. Update Purpose after archive.
## Requirements
### Requirement: Multiple Visual Mode Support
The system SHALL provide 5 distinct visual indicator modes: Circle, Pendulum, Bar Graph, Progress Ring, and Minimalist Flash.

#### Scenario: Circle mode displays (default)
- **WHEN** visual mode set to "Circle"
- **THEN** display filled circle that pulses on beats
- **AND** downbeat shows red circle
- **AND** regular beats show blue circle

#### Scenario: Pendulum mode displays
- **WHEN** visual mode set to "Pendulum"
- **THEN** display swinging pendulum animation
- **AND** pendulum swings -45° to +45°
- **AND** reaches center on downbeat

#### Scenario: Bar graph mode displays
- **WHEN** visual mode set to "Bar Graph"
- **THEN** display vertical bars for each beat in measure
- **AND** current beat highlighted (filled)
- **AND** upcoming beats dimmed (outline)
- **AND** first bar taller for downbeat emphasis

#### Scenario: Progress ring mode displays
- **WHEN** visual mode set to "Progress Ring"
- **THEN** display circular ring filling clockwise
- **AND** completes full rotation per measure
- **AND** beat marks on perimeter

#### Scenario: Minimalist flash mode displays
- **WHEN** visual mode set to "Minimalist"
- **THEN** display color flash on beats
- **AND** flash fades quickly
- **AND** bright flash for downbeat, subdued for regular

### Requirement: Visual Mode Selection UI
The system SHALL provide dropdown in preferences to select visual mode.

#### Scenario: Mode selector populated
- **WHEN** user opens preferences visual section
- **THEN** dropdown shows all 5 mode options
- **AND** current selection highlighted
- **AND** mode description displayed

#### Scenario: Mode changed
- **WHEN** user selects different visual mode
- **THEN** apply new mode immediately
- **AND** update beat indicator in main window
- **AND** persist selection to GSettings

### Requirement: Mode Animation Performance
The system SHALL render visual modes at 60fps with smooth animations.

#### Scenario: Smooth animation
- **WHEN** any visual mode active during playback
- **THEN** animations render at ≥60fps
- **AND** no visual stutter or lag
- **AND** transitions between beats smooth

#### Scenario: Drawing performance
- **WHEN** visual mode draw function called
- **THEN** completes in < 5ms
- **AND** does not impact metronome timing accuracy

### Requirement: Visual Mode Accessibility
The system SHALL ensure all visual modes meet WCAG AA contrast requirements.

#### Scenario: Contrast ratio sufficient
- **WHEN** any visual mode displays beat indication
- **THEN** contrast ratio between indicator and background ≥4.5:1
- **AND** downbeat/regular beat distinction clear
- **AND** readable for users with low vision

#### Scenario: Photosensitivity consideration
- **WHEN** flash mode active
- **THEN** flash frequency < 3 Hz (below seizure threshold)
- **AND** flash intensity configurable
- **AND** warning shown if user selects flash mode

### Requirement: Mode Persistence
The system SHALL persist visual mode selection across application restarts.

#### Scenario: Mode restored on startup
- **WHEN** application starts
- **THEN** load visual-mode from GSettings
- **AND** initialize with saved mode
- **AND** apply to beat indicator

### Requirement: Beat Distinction in All Modes
The system SHALL visually distinguish downbeats from regular beats in all modes.

#### Scenario: Downbeat emphasis
- **WHEN** downbeat occurs in any mode
- **THEN** visual indicator shows clear emphasis
- **AND** emphasis style appropriate to mode (color, size, intensity)

### Requirement: Time Signature Adaptation
The system SHALL adapt visual modes to current time signature.

#### Scenario: Bar graph adapts to time signature
- **WHEN** time signature changes to 3/4
- **THEN** bar graph displays 3 bars
- **AND** progress ring divides into 3 sections

#### Scenario: Visual wraps at measure end
- **WHEN** beat exceeds beats_per_bar
- **THEN** visual indicator resets to beginning
- **AND** cycle continues smoothly

