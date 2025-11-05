# Spec: Adaptive UI Components

## Overview
Defines adaptive UI component behavior for touch interactions, dialogs, and control accessibility across different device types. Ensures all interactive elements meet touch target requirements and adapt appropriately for mobile use.

## ADDED Requirements

### Requirement: AUI-01 - Touch Target Minimum Sizes
All interactive elements MUST meet minimum touch target sizes as defined by GNOME Human Interface Guidelines.

#### Scenario: Button touch targets
**Given** the application is running on a touch device
**When** any button is rendered
**Then** the button MUST have a minimum height of 44px
**And** the button MUST have a minimum width of 44px
**And** buttons MAY exceed these minimums for better ergonomics

#### Scenario: Existing compliant buttons
**Given** the Play/Stop button is rendered
**When** measured in any breakpoint
**Then** the button MUST maintain its current size of at least 140x52px
**And** no regression in size MUST occur

#### Scenario: Spinbutton touch accessibility
**Given** a spinbutton control is rendered on a touch device
**When** the phone or tablet breakpoint is active
**Then** the spinbutton MUST have a minimum height of 44px
**And** the spinbutton increment/decrement buttons MUST each be at least 44x44px
**And** the numeric entry area MUST be touch-friendly

---

### Requirement: AUI-02 - Tempo Slider Touch Enhancement
The tempo slider MUST provide enhanced touch interaction capabilities on touch devices.

#### Scenario: Slider thumb size on touch devices
**Given** the application is running on a touch device
**When** the tempo slider is rendered
**Then** the slider thumb MUST have a minimum size of 24x24px
**And** the thumb MUST have adequate padding (at least 6px margin)
**And** the slider trough MUST be at least 12px tall for easy thumb placement

#### Scenario: Slider thumb size on pointer devices
**Given** the application is running on a desktop with mouse/trackpad
**When** the tempo slider is rendered
**Then** the slider thumb size MAY use the default GTK sizing
**And** behavior MUST match current implementation

#### Scenario: Touch feedback on slider interaction
**Given** a user interacts with the tempo slider on a touch device
**When** the slider thumb is dragged
**Then** visual feedback MUST be immediate (no lag)
**And** the tempo value MUST update in real-time during drag
**And** the BPM label MUST reflect the current slider position

---

### Requirement: AUI-03 - Preferences Dialog Adaptation
The preferences dialog MUST automatically adapt to mobile form factors using Libadwaita's built-in adaptive behavior.

#### Scenario: Preferences on desktop
**Given** the window width is greater than 600px
**When** the preferences dialog is opened
**Then** the dialog MUST display in windowed mode
**And** the sidebar navigation MUST be visible on the left
**And** preferences pages MUST be shown on the right
**And** behavior MUST match current implementation

#### Scenario: Preferences on mobile
**Given** the window width is 600px or less
**When** the preferences dialog is opened
**Then** the dialog MUST display in full-screen mode
**And** the sidebar MUST be collapsible/hidden
**And** navigation MUST use a bottom bar or headerbar back button
**And** this behavior MUST be automatic (handled by Adw.PreferencesDialog)

#### Scenario: Preferences search on mobile
**Given** the preferences dialog is open in mobile mode
**When** the search feature is used
**Then** search MUST remain functional
**And** results MUST be displayed in a mobile-friendly manner
**And** search entry MUST have adequate touch target size

---

### Requirement: AUI-04 - Alert Dialog Adaptation
Alert dialogs MUST be readable and actionable on small screens.

#### Scenario: Alert dialog on desktop
**Given** an alert dialog is triggered (e.g., audio system failure)
**When** the window width is greater than 600px
**Then** the dialog MUST display centered over the main window
**And** dialog width MUST be appropriate for desktop (400-600px)
**And** behavior MUST match current Adw.AlertDialog implementation

#### Scenario: Alert dialog on mobile
**Given** an alert dialog is triggered
**When** the window width is 600px or less
**Then** the dialog MUST adapt to full width or bottom sheet style
**And** all text MUST be readable without horizontal scrolling
**And** action buttons MUST meet 44px minimum height
**And** this MUST be automatic (handled by Adw.AlertDialog)

---

### Requirement: AUI-05 - Keyboard Shortcuts Dialog Adaptation
The keyboard shortcuts dialog MUST remain accessible on mobile while prioritizing desktop users.

#### Scenario: Shortcuts dialog on desktop
**Given** the keyboard shortcuts dialog is opened via F1 or menu
**When** the window width is greater than 600px
**Then** the dialog MUST display in standard window format
**And** shortcuts MUST be organized in sections
**And** behavior MUST match current Adw.ShortcutsWindow implementation

#### Scenario: Shortcuts dialog on mobile
**Given** the keyboard shortcuts dialog is opened
**When** the window width is 600px or less
**Then** the dialog MUST adapt to full-screen or scrollable format
**And** all shortcut information MUST be readable
**And** note about keyboard-centric shortcuts MAY be displayed on pure touch devices

---

### Requirement: AUI-06 - Preset Manager Dialog Adaptation
The preset manager dialog MUST adapt its layout for mobile screens while maintaining functionality.

#### Scenario: Preset manager on desktop
**Given** the preset manager is opened
**When** the window width is greater than 600px
**Then** the dialog width MUST be at least 600px (current implementation)
**And** the preset list and details MUST be visible side-by-side
**And** search bar MUST be at the top
**And** behavior MUST match current implementation

#### Scenario: Preset manager on mobile
**Given** the preset manager is opened
**When** the window width is 600px or less
**Then** the dialog MUST adapt to full-screen mode
**And** the preset list MUST be scrollable
**And** preset details MUST be shown via navigation (not side-by-side)
**And** search entry MUST have minimum 44px height
**And** all action buttons (load, delete, etc.) MUST meet touch target minimums

#### Scenario: Preset list item touch targets
**Given** the preset manager displays a list of presets
**When** rendering on a touch device
**Then** each preset list item MUST have a minimum height of 44px
**And** tap targets for actions (load, edit, delete) MUST be at least 44x44px
**And** adequate spacing MUST prevent accidental taps (at least 8px between items)

---

### Requirement: AUI-07 - Menu Button and Popover Adaptation
The main menu button and its popover MUST be accessible on mobile devices.

#### Scenario: Menu button touch target
**Given** the header bar contains the menu button
**When** rendered on any screen size
**Then** the menu button MUST be at least 44x44px
**And** the button MUST be positioned in the header bar end section (current position)

#### Scenario: Menu popover on mobile
**Given** the menu button is tapped on a touch device
**When** the menu popover opens
**Then** all menu items MUST have a minimum height of 44px
**And** menu items MUST be easily tappable without accidental selections
**And** the popover MUST fit within screen bounds
**And** this behavior MUST be automatic (handled by Gtk.MenuButton and Gtk.Popover)

---

### Requirement: AUI-08 - Control Input Adaptation
Numeric input controls MUST be optimized for touch input on mobile devices.

#### Scenario: SpinButton on touch devices
**Given** any spinbutton (tempo, beats, etc.) is focused on a touch device
**When** the user taps the entry field
**Then** an on-screen numeric keyboard SHOULD be displayed (OS-dependent)
**And** the entry field MUST be large enough for touch input (min 44px height)
**And** increment/decrement buttons MUST be at least 44x44px each

#### Scenario: Dropdown on touch devices
**Given** any dropdown (time signature, subdivisions, etc.) is tapped
**When** the dropdown opens
**Then** all dropdown items MUST have a minimum height of 44px
**And** the dropdown MUST be scrollable if content exceeds screen height
**And** selected item MUST be clearly indicated

---

### Requirement: AUI-09 - Header Bar Adaptation
The header bar MUST adapt to constrain screen widths while maintaining functionality.

#### Scenario: Header bar on desktop
**Given** the window width is greater than 600px
**When** the header bar is rendered
**Then** the window title "Tempo" MUST be visible
**And** the subtitle "Metronome" MUST be visible
**And** the menu button MUST be in the end position
**And** layout MUST match current implementation

#### Scenario: Header bar on narrow screens
**Given** the window width is 550px or less
**When** the header bar is rendered
**Then** the window title "Tempo" MUST remain visible
**And** the subtitle MAY be hidden to save space
**And** the menu button MUST remain accessible
**And** all header bar buttons MUST meet touch target minimums

---

### Requirement: AUI-10 - Focus Indication for Touch and Keyboard
Focus indicators MUST be clear for both keyboard navigation (desktop) and touch interaction (mobile).

#### Scenario: Keyboard focus on desktop
**Given** the user navigates with keyboard (Tab key)
**When** a control receives focus
**Then** a clear focus ring MUST be visible
**And** focus behavior MUST match current GTK4 implementation
**And** focus order MUST be logical (top to bottom, primary to secondary controls)

#### Scenario: Touch feedback on mobile
**Given** the user taps a control on a touch device
**When** the control is activated
**Then** visual feedback MUST be immediate (pressed state)
**And** the control MUST respond within 100ms
**And** haptic feedback MAY be provided (platform-dependent)

#### Scenario: Focus for screen readers
**Given** a screen reader is active
**When** the user navigates through controls
**Then** all interactive elements MUST be focusable
**And** all labels and tooltips MUST be accessible to the screen reader
**And** focus order MUST be logical and consistent

---

### Requirement: AUI-11 - Visual Feedback for Touch Interactions
Touch interactions MUST provide clear visual feedback to confirm user actions.

#### Scenario: Button press feedback
**Given** a user taps any button on a touch device
**When** the tap occurs
**Then** the button MUST show a pressed state immediately
**And** the pressed state MUST be visually distinct from default state
**And** the state MUST revert after tap release

#### Scenario: Slider drag feedback
**Given** a user drags the tempo slider on a touch device
**When** the drag is in progress
**Then** the slider thumb MUST follow the finger position smoothly
**And** the BPM value MUST update in real-time
**And** visual feedback MUST not lag behind touch input

---

### Requirement: AUI-12 - Orientation Robustness
The application MUST handle device orientation changes gracefully on mobile devices.

#### Scenario: Portrait to landscape transition
**Given** the application is running in portrait mode on a mobile device
**When** the device is rotated to landscape
**Then** the layout MUST adapt to the new width using appropriate breakpoint
**And** no content MUST be clipped or hidden incorrectly
**And** the beat indicator MUST remain centered and properly sized
**And** user state (playing/stopped, tempo value) MUST be preserved

#### Scenario: Landscape to portrait transition
**Given** the application is running in landscape mode
**When** the device is rotated to portrait
**Then** the layout MUST adapt to portrait mode (phone breakpoint if width ≤ 550px)
**And** content MUST reflow to vertical orientation where configured
**And** no visual glitches MUST occur during transition
**And** metronome playback MUST continue uninterrupted

---

### Requirement: AUI-13 - Touch-Friendly Spacing
Spacing between interactive elements MUST prevent accidental taps on touch devices.

#### Scenario: Minimum spacing between tappable elements
**Given** two interactive elements are adjacent
**When** rendered on a touch device
**Then** there MUST be at least 8px spacing between their tap targets
**And** this spacing MUST prevent accidental activation of adjacent controls

#### Scenario: Spacing in tempo trainer controls
**Given** the tempo trainer is visible on a mobile device
**When** the trainer controls are rendered
**Then** spinbuttons MUST have adequate spacing (at least 12px between rows)
**And** all controls MUST remain usable without accidental taps
**And** the Enable/Disable button MUST be clearly separated from spinbuttons

---

### Requirement: AUI-14 - Performance on Touch Interactions
Touch interactions MUST be responsive with minimal latency.

#### Scenario: Tap tempo responsiveness
**Given** the user taps the "Tap Tempo" button repeatedly on a touch device
**When** taps occur in rapid succession
**Then** each tap MUST be registered without dropped inputs
**And** the calculated BPM MUST update accurately
**And** visual feedback MUST occur for each tap within 50ms

#### Scenario: Slider drag performance
**Given** the user drags the tempo slider on a touch device
**When** the drag occurs
**Then** the slider MUST track finger position with < 16ms latency (60fps)
**And** the UI MUST remain responsive during drag
**And** the metronome MUST update tempo smoothly if playing

---

### Requirement: AUI-15 - Adaptive Content Prioritization
Content MUST be prioritized on small screens to show the most important controls first.

#### Scenario: Primary controls visibility on phone
**Given** the phone breakpoint is active (width ≤ 550px)
**When** the application is displayed at minimum height (600px)
**Then** the following MUST be visible without scrolling:
  - BPM display and tempo controls (slider, spinbutton)
  - Time signature controls
  - Play/Stop button
  - Beat indicator
**And** the following MAY require scrolling:
  - Tempo trainer (when enabled)
  - Practice timer display
  - Subdivision controls

#### Scenario: Full feature access via scrolling
**Given** any content is below the fold on a small screen
**When** the user scrolls down
**Then** all features MUST remain accessible and functional
**And** scrolling MUST be smooth (60fps)
**And** no content MUST be permanently hidden or inaccessible
