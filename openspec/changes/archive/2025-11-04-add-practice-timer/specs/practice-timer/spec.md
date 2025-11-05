# practice-timer Specification

## Purpose
Enable musicians to track practice duration, set practice goals, and automatically stop after specified limits using integrated session timer and auto-stop functionality.

## ADDED Requirements

### Requirement: Timer Display and Control
The system SHALL provide a practice timer that displays elapsed time and supports count-up and countdown modes.

#### Scenario: Count-up timer displays elapsed time
- **WHEN** timer is enabled in count-up mode and metronome is running
- **THEN** display elapsed time in MM:SS format (under 1 hour) or HH:MM:SS format (1+ hours)
- **AND** update display every second
- **AND** timer continues accumulating while metronome runs

#### Scenario: Countdown timer displays remaining time
- **WHEN** timer is enabled in countdown mode with target duration 25 minutes
- **AND** metronome is running
- **THEN** display remaining time counting down from 25:00
- **AND** update display every second
- **AND** timer decrements to 00:00

#### Scenario: Countdown timer reaches zero
- **WHEN** countdown timer reaches 00:00
- **THEN** emit countdown_completed signal
- **AND** display notification toast "Practice session completed"
- **AND** reset timer to configured countdown duration
- **AND** keep metronome running unless auto-stop enabled

#### Scenario: Timer toggles visibility
- **WHEN** user disables "Show timer in main window" setting
- **THEN** hide timer display from main window
- **AND** timer continues tracking time in background
- **WHEN** user re-enables setting
- **THEN** show timer display with current elapsed/remaining time

### Requirement: Timer Synchronization with Metronome
The system SHALL synchronize timer state with metronome playback based on user preferences.

#### Scenario: Timer starts with metronome (sync enabled)
- **WHEN** "Pause timer with metronome" setting is enabled
- **AND** user starts metronome playback
- **THEN** start timer automatically
- **AND** begin time accumulation from zero (count-up) or target duration (countdown)

#### Scenario: Timer pauses with metronome (sync enabled)
- **WHEN** "Pause timer with metronome" setting is enabled
- **AND** metronome is running with timer at 05:30 elapsed
- **AND** user stops metronome
- **THEN** pause timer at 05:30
- **AND** preserve accumulated time
- **WHEN** user resumes metronome
- **THEN** resume timer from 05:30

#### Scenario: Timer continues when metronome stops (sync disabled)
- **WHEN** "Pause timer with metronome" setting is disabled
- **AND** metronome is running with timer at 05:30
- **AND** user stops metronome
- **THEN** timer continues running
- **AND** time continues accumulating to 05:31, 05:32, etc.

#### Scenario: Timer reset clears accumulated time
- **WHEN** user resets timer (via UI control or metronome restart)
- **THEN** reset elapsed time to 00:00 (count-up) or target duration (countdown)
- **AND** preserve timer mode and settings

### Requirement: Auto-Stop by Beat Count
The system SHALL support automatic metronome stop after specified number of beats.

#### Scenario: Auto-stop after N beats
- **WHEN** auto-stop mode is "Beats" with value 100
- **AND** metronome is running
- **THEN** track total beats played
- **AND** display progress "75/100 beats" near timer
- **WHEN** beat 100 is reached
- **THEN** emit auto_stop_triggered signal
- **AND** stop metronome immediately
- **AND** display notification toast "Auto-stop: 100 beats completed"

#### Scenario: Auto-stop beats counted correctly across tempo changes
- **WHEN** auto-stop set to 50 beats
- **AND** metronome plays 25 beats at 120 BPM
- **AND** user changes tempo to 140 BPM
- **AND** metronome plays 25 more beats
- **THEN** auto-stop triggers at beat 50
- **AND** beat count not affected by tempo changes

### Requirement: Auto-Stop by Bar Count
The system SHALL support automatic metronome stop after specified number of measures (bars).

#### Scenario: Auto-stop after N bars in 4/4 time
- **WHEN** auto-stop mode is "Bars" with value 16
- **AND** time signature is 4/4
- **AND** metronome is running
- **THEN** track completed bars (every 4 beats = 1 bar)
- **AND** display progress "12/16 bars"
- **WHEN** 64th beat plays (16 bars × 4 beats)
- **THEN** stop metronome
- **AND** display notification "Auto-stop: 16 bars completed"

#### Scenario: Auto-stop bars recalculated on time signature change
- **WHEN** auto-stop set to 8 bars in 4/4 time (32 beats total)
- **AND** 4 bars completed (16 beats)
- **AND** user changes time signature to 3/4
- **THEN** recalculate remaining: 4 bars × 3 beats = 12 beats needed
- **AND** display updated progress "4/8 bars"
- **WHEN** 12 more beats play
- **THEN** trigger auto-stop (8 bars total)

#### Scenario: Auto-stop at end of bar, not mid-bar
- **WHEN** auto-stop set to 8 bars in 4/4
- **AND** metronome reaches beat 3 of bar 8
- **THEN** continue playing through beat 4 of bar 8
- **WHEN** downbeat of bar 9 would play
- **THEN** stop metronome before bar 9 starts
- **AND** final displayed beat is "4" (last beat of bar 8)

### Requirement: Auto-Stop by Time Duration
The system SHALL support automatic metronome stop after specified time duration in minutes.

#### Scenario: Auto-stop after N minutes
- **WHEN** auto-stop mode is "Time" with value 5 (minutes)
- **AND** metronome is running
- **THEN** track elapsed time
- **AND** display progress "3:45 / 5:00" or "1:15 remaining"
- **WHEN** 5 minutes elapsed
- **THEN** stop metronome
- **AND** display notification "Auto-stop: 5 minutes completed"

#### Scenario: Auto-stop time unaffected by metronome pause (sync enabled)
- **WHEN** auto-stop set to 10 minutes
- **AND** "Pause timer with metronome" enabled
- **AND** metronome runs for 6 minutes then stops
- **AND** user pauses for 2 minutes (timer paused)
- **AND** user resumes metronome
- **THEN** auto-stop triggers after 4 more minutes of active playing
- **AND** total elapsed time is 10 minutes (pause time excluded)

#### Scenario: Auto-stop time includes metronome pause (sync disabled)
- **WHEN** auto-stop set to 10 minutes
- **AND** "Pause timer with metronome" disabled
- **AND** metronome runs for 6 minutes then stops
- **AND** timer continues for 4 more minutes while metronome stopped
- **THEN** auto-stop triggers even though metronome wasn't playing
- **AND** total wall-clock time is 10 minutes

### Requirement: Auto-Stop Mode Exclusivity
The system SHALL enforce only one auto-stop condition active at a time.

#### Scenario: Changing auto-stop mode clears previous condition
- **WHEN** auto-stop mode is "Beats" with value 100
- **AND** 50 beats completed
- **AND** user changes auto-stop mode to "Time" with value 5 minutes
- **THEN** reset beat counter
- **AND** start tracking time from current moment
- **AND** display only time-based progress

#### Scenario: Disabling auto-stop clears tracking
- **WHEN** auto-stop mode is "Bars" with value 16
- **AND** 8 bars completed
- **AND** user sets auto-stop mode to "None"
- **THEN** stop displaying progress
- **AND** metronome continues indefinitely
- **AND** timer continues normally (if enabled)

### Requirement: Timer Settings Persistence
The system SHALL persist timer configuration and restore on application restart.

#### Scenario: Timer settings persisted
- **WHEN** user enables timer in countdown mode with 25-minute duration
- **AND** sets auto-stop to 32 bars
- **AND** enables "Pause with metronome"
- **AND** closes application
- **WHEN** user reopens application
- **THEN** timer enabled with countdown mode
- **AND** countdown duration is 25 minutes
- **AND** auto-stop mode is "Bars" with value 32
- **AND** "Pause with metronome" setting preserved

#### Scenario: Timer state reset on app restart
- **WHEN** user has timer at 08:45 elapsed
- **AND** auto-stop progress at 15/32 bars
- **AND** closes application
- **WHEN** user reopens application
- **THEN** timer shows 00:00 (fresh session)
- **AND** auto-stop progress reset to 0/32 bars
- **AND** timer configuration preserved but state cleared

### Requirement: Timer Accuracy and Performance
The system SHALL maintain timer accuracy without impacting metronome timing precision.

#### Scenario: Timer display updates reliably
- **WHEN** timer is running
- **THEN** update display at 1-second intervals using GLib.Timeout
- **AND** calculate elapsed time from monotonic timestamps (not accumulated intervals)
- **AND** display accuracy within ±100ms over 60 minutes

#### Scenario: Timer does not impact metronome timing
- **WHEN** metronome runs at 240 BPM (fastest tempo) with timer enabled
- **AND** both count-up timer and auto-stop (bars) active
- **THEN** metronome timing accuracy remains sub-millisecond
- **AND** no audible jitter or drift
- **AND** timer CPU overhead < 0.1%
- **AND** timer memory overhead < 1KB

### Requirement: Timer UI Integration
The system SHALL integrate timer display cleanly into existing main window without cluttering interface.

#### Scenario: Timer display positioned below beat indicator
- **WHEN** timer is enabled and visible
- **THEN** display timer below circular beat indicator
- **AND** use compact HH:MM:SS or MM:SS format
- **AND** timer label uses system font at standard size
- **AND** timer aligned center horizontally

#### Scenario: Auto-stop progress shown when active
- **WHEN** auto-stop mode is not "None"
- **AND** metronome is running
- **THEN** display progress below timer in parentheses
- **AND** format as "(15/32 bars)" or "(3:45 remaining)"
- **AND** update progress every second or every beat (whichever appropriate)

#### Scenario: Preferences organized in dedicated section
- **WHEN** user opens Preferences dialog
- **THEN** show "Practice Timer" section with:
  - Enable/disable timer toggle
  - Timer mode selection (Count-up / Countdown)
  - Countdown duration spinner (1-180 minutes)
  - "Pause with metronome" checkbox
  - Auto-stop mode selection (None / Beats / Bars / Time)
  - Auto-stop value spinner (range depends on mode)
  - "Show in main window" checkbox

### Requirement: Timer Input Validation
The system SHALL validate all timer-related user inputs and settings.

#### Scenario: Countdown duration within valid range
- **WHEN** user enters countdown duration
- **THEN** enforce minimum 1 minute
- **AND** enforce maximum 180 minutes (3 hours)
- **AND** reject invalid values with error message
- **AND** revert to previous valid value on invalid input

#### Scenario: Auto-stop values within valid ranges
- **WHEN** auto-stop mode is "Beats"
- **THEN** enforce range 1-10000 beats
- **WHEN** auto-stop mode is "Bars"
- **THEN** enforce range 1-1000 bars
- **WHEN** auto-stop mode is "Time"
- **THEN** enforce range 1-180 minutes

#### Scenario: Settings fallback on corruption
- **WHEN** GSettings contains corrupted timer values (e.g., negative duration)
- **THEN** log warning with g_warning()
- **AND** fallback to default values (count-up, 25-minute countdown, no auto-stop)
- **AND** timer remains disabled if critical values corrupted
- **AND** continue application startup gracefully
