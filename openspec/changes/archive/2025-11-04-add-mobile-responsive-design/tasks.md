# Tasks: Add Mobile-Responsive Design

## Overview
Implementation tasks for making Tempo mobile-friendly across desktop, tablet, and phone form factors. Tasks are ordered to deliver incremental value with testable milestones.

---

## Phase 1: Foundation (Core Responsiveness)

### Task 1.1: Add Window Size Constraints
**Description**: Set minimum window dimensions to support smallest target devices (360px width)

**Steps**:
1. Open `data/ui/main_window.blp`
2. Add `width-request: 360` to `$TempoWindow` template (after line 6)
3. Add `height-request: 600` to `$TempoWindow` template
4. Build and test window resizing to verify minimums are enforced
5. Verify default width/height (400x500) remains unchanged

**Validation**:
- Window cannot be resized below 360x600
- Default size remains 400x500
- No visual glitches at minimum size

**Related Specs**: RL-02

---

### Task 1.2: Define Phone Breakpoint
**Description**: Create breakpoint for phone-sized screens (≤550px width)

**Steps**:
1. Open `data/ui/main_window.blp`
2. Locate the existing `Adw.BreakpointBin` at line 25
3. Inside `Adw.BreakpointBin`, before the main `Gtk.Box`, add:
   ```blueprint
   Adw.Breakpoint phone_breakpoint {
     condition: "max-width: 550px"
   }
   ```
4. Add ID `main_content_box` to the main vertical `Gtk.Box` (line 28)
5. Add ID `beat_indicator_box` to the box containing beat indicator (if needed)
6. Build and test with GTK Inspector to verify breakpoint is listed

**Validation**:
- Breakpoint appears in GTK Inspector
- Breakpoint activates when window width ≤ 550px
- No runtime errors or warnings

**Related Specs**: RL-01

---

### Task 1.3: Implement Phone Breakpoint Setters - Beat Indicator
**Description**: Reduce beat indicator size on phone screens

**Steps**:
1. Open `data/ui/main_window.blp`
2. Add to `phone_breakpoint` (created in Task 1.2):
   ```blueprint
   setters {
     beat_indicator.content-width: 200;
     beat_indicator.content-height: 200;
   }
   ```
3. Build and test by resizing window to 400px width
4. Verify beat indicator shrinks to 200x200px
5. Test Cairo rendering scales correctly (no clipping, proper centering)

**Validation**:
- Beat indicator is 200x200px when width ≤ 550px
- Beat indicator is 300x300px when width > 550px
- Visual effects (glow, numbers) scale proportionally
- No layout shifts or glitches during resize

**Related Specs**: RL-01, RL-03

---

### Task 1.4: Implement Phone Breakpoint Setters - Margins and Spacing
**Description**: Reduce margins and spacing on phone screens

**Steps**:
1. Open `data/ui/main_window.blp`
2. Add to `phone_breakpoint` setters:
   ```blueprint
   main_content_box.margin-start: 6;
   main_content_box.margin-end: 6;
   main_content_box.margin-top: 12;
   main_content_box.margin-bottom: 12;
   main_content_box.spacing: 12;
   tempo_scale.margin-start: 6;
   tempo_scale.margin-end: 6;
   ```
3. Build and test at 400px width
4. Verify margins are reduced from desktop values (24px/12px → 12px/6px)
5. Verify content fits better on narrow screens

**Validation**:
- Margins are 6px (sides) and 12px (top/bottom) at phone width
- Spacing between sections is 12px
- Content does not overflow or clip
- Transition is smooth when crossing breakpoint

**Related Specs**: RL-01, RL-06

---

### Task 1.5: Define Tablet Breakpoint
**Description**: Create breakpoint for tablet-sized screens (551-900px width)

**Steps**:
1. Open `data/ui/main_window.blp`
2. Add second breakpoint after `phone_breakpoint`:
   ```blueprint
   Adw.Breakpoint tablet_breakpoint {
     condition: "max-width: 900px"

     setters {
       beat_indicator.content-width: 250;
       beat_indicator.content-height: 250;
       main_content_box.spacing: 18;
     }
   }
   ```
3. Build and test at 700px width
4. Verify tablet breakpoint activates (use GTK Inspector)
5. Verify beat indicator is 250x250px

**Validation**:
- Tablet breakpoint activates when 550px < width ≤ 900px
- Beat indicator is 250x250px in this range
- Spacing is 18px
- Desktop layout (300px indicator) activates when width > 900px

**Related Specs**: RL-01, RL-03

---

## Phase 2: Layout Adaptations

### Task 2.1: Make Time Signature Controls Adaptive
**Description**: Stack time signature controls vertically on phone screens

**Steps**:
1. Open `data/ui/main_window.blp`
2. Locate the time signature `Gtk.Box` (line 89-126)
3. Add ID `time_signature_controls_box` to the horizontal box containing spinbutton/dropdown
4. Add to `phone_breakpoint` setters:
   ```blueprint
   time_signature_controls_box.orientation: vertical;
   time_signature_controls_box.spacing: 8;
   ```
5. Optionally: Add labels for clarity in vertical mode (may require Blueprint structure change)
6. Build and test vertical layout at phone width
7. Test horizontal layout still works at tablet/desktop widths

**Validation**:
- Time signature controls are vertical when width ≤ 550px
- Time signature controls are horizontal when width > 550px
- All controls remain functional in both modes
- Visual alignment is clean in both orientations

**Related Specs**: RL-05

---

### Task 2.2: Collapse Tempo Trainer on Phone by Default
**Description**: Hide tempo trainer section by default on phone screens to reduce clutter

**Steps**:
1. Open `data/ui/main_window.blp`
2. Locate `trainer_box` (line 209)
3. Add to `phone_breakpoint` setters:
   ```blueprint
   trainer_box.visible: false;
   ```
4. Verify menu toggle ("Show Tempo Trainer") still works
5. Test that enabling trainer via menu makes it visible even on phone
6. Consider: Add conditional logic in MainWindow.vala to handle toggle properly

**Validation**:
- Trainer is hidden by default when width ≤ 550px
- Trainer visibility can still be toggled via menu
- Trainer remains visible by default on tablet/desktop
- No errors when toggling trainer on/off at phone width

**Related Specs**: RL-07

**Notes**: May require Vala code changes to sync breakpoint visibility with menu toggle state.

---

### Task 2.3: Add Scrollable Container Support
**Description**: Ensure content is scrollable when window height is constrained

**Steps**:
1. Open `data/ui/main_window.blp`
2. Wrap the main `Gtk.Box` inside `Adw.BreakpointBin` with a `Gtk.ScrolledWindow`:
   ```blueprint
   Gtk.ScrolledWindow {
     hscrollbar-policy: never;
     vscrollbar-policy: automatic;
     vexpand: true;

     Gtk.Box main_content_box {
       // ... existing content
     }
   }
   ```
3. Build and test at minimum height (600px)
4. Verify vertical scrolling appears when needed
5. Verify horizontal scrolling never appears
6. Test scrolling is smooth and functional

**Validation**:
- Vertical scrolling appears when content exceeds window height
- Horizontal scrolling never occurs
- All controls remain accessible via scrolling
- Scrolling is smooth (60fps)
- Desktop experience is not negatively impacted

**Related Specs**: RL-08

---

## Phase 3: Touch Optimization

### Task 3.1: Enhance Touch Targets - SpinButtons
**Description**: Ensure all spinbuttons meet minimum 44px height for touch

**Steps**:
1. Open `data/style.css`
2. Add CSS rule:
   ```css
   @media (pointer: coarse) {
     spinbutton {
       min-height: 44px;
     }

     spinbutton button {
       min-width: 44px;
       min-height: 44px;
     }
   }
   ```
3. Build and test on touch device or with GTK Inspector
4. Verify spinbutton increment/decrement buttons are at least 44x44px
5. Test functionality is preserved

**Validation**:
- Spinbuttons are at least 44px tall on touch devices
- Increment/decrement buttons are at least 44x44px
- Spinbuttons work correctly on desktop (no regression)
- Touch target detection via `@media (pointer: coarse)` works

**Related Specs**: AUI-01, AUI-08

---

### Task 3.2: Enhance Touch Targets - Tempo Slider
**Description**: Make tempo slider thumb larger and more touch-friendly

**Steps**:
1. Open `data/style.css`
2. Add CSS rule:
   ```css
   @media (pointer: coarse) {
     scale slider {
       min-width: 24px;
       min-height: 24px;
       margin: 6px;
     }

     scale trough {
       min-height: 12px;
     }
   }
   ```
3. Build and test slider on touch device
4. Verify thumb is easier to grab and drag
5. Test desktop slider is not negatively affected

**Validation**:
- Slider thumb is at least 24x24px on touch devices
- Slider trough is at least 12px tall
- Slider thumb has 6px margin for easier touch
- Desktop slider appearance is unchanged
- Slider drag is smooth and responsive on touch

**Related Specs**: AUI-02

---

### Task 3.3: Enhance Touch Targets - Buttons
**Description**: Ensure all buttons meet minimum touch target sizes

**Steps**:
1. Open `data/ui/main_window.blp`
2. Audit all buttons for height:
   - Play/Stop button (line 192): Already 52px+ ✅
   - Tap Tempo button (line 200): Add `styles ["large"]` or set min-height
   - Menu button in header bar: Verify 44x44px
3. Add to buttons that need adjustment:
   ```blueprint
   css-classes: ["large-touch-target"]
   ```
4. In `data/style.css`, add:
   ```css
   .large-touch-target {
     min-height: 44px;
     min-width: 44px;
   }
   ```
5. Build and test all buttons
6. Measure touch targets with GTK Inspector

**Validation**:
- All buttons are at least 44x44px
- Play/Stop button maintains current size (140x52px)
- Tap Tempo button is at least 44px tall
- Menu button is at least 44x44px
- No visual regressions on desktop

**Related Specs**: AUI-01

---

### Task 3.4: Add Touch-Friendly Spacing
**Description**: Increase spacing between interactive elements on touch devices

**Steps**:
1. Open `data/ui/main_window.blp`
2. Add to `phone_breakpoint` setters (if not already present):
   ```blueprint
   time_signature_controls_box.spacing: 12;
   ```
3. For tempo trainer controls (if visible on phone), ensure spacing is at least 12px
4. Build and test at phone width
5. Verify tap targets don't overlap or cause accidental taps

**Validation**:
- At least 8px spacing between adjacent interactive elements
- No accidental taps occur during testing
- Layout remains compact but usable
- Desktop spacing is preserved (no regression)

**Related Specs**: AUI-13

---

## Phase 4: Dialog Adaptations

### Task 4.1: Verify Preferences Dialog Mobile Adaptation
**Description**: Confirm Adw.PreferencesDialog automatically adapts to mobile (no code changes needed)

**Steps**:
1. Build application
2. Resize window to 550px width
3. Open Preferences dialog
4. Verify dialog goes full-screen automatically
5. Verify all preferences pages are accessible
6. Test search functionality
7. Test on tablet width (700px) - should show sidebar

**Validation**:
- Preferences dialog is full-screen when window width ≤ 600px
- Preferences dialog shows sidebar when window width > 600px
- All preferences are accessible in both modes
- Search works in both modes
- No code changes required (Libadwaita handles this)

**Related Specs**: AUI-03

---

### Task 4.2: Verify Alert Dialog Mobile Adaptation
**Description**: Confirm Adw.AlertDialog automatically adapts to mobile

**Steps**:
1. Build application
2. Resize window to 400px width
3. Trigger an alert dialog (e.g., audio system failure simulation)
4. Verify dialog adapts to narrow width
5. Verify text is readable without horizontal scrolling
6. Verify action buttons are accessible and meet touch targets

**Validation**:
- Alert dialogs adapt to narrow widths automatically
- Text is readable without horizontal scrolling
- Action buttons are at least 44px tall
- No code changes required (Libadwaita handles this)

**Related Specs**: AUI-04

---

### Task 4.3: Adapt Preset Manager Dialog for Mobile
**Description**: Make preset manager dialog responsive for phone screens

**Steps**:
1. Open `data/ui/preset_manager_dialog.blp`
2. Wrap dialog content in responsive container or add breakpoints
3. Consider using `Adw.NavigationView` for mobile navigation (preset list → details)
4. Ensure all touch targets (list items, buttons) meet 44px minimum
5. Test search bar is usable on narrow screens
6. Build and test at phone/tablet/desktop widths

**Validation**:
- Preset manager is usable at 360px width
- All buttons meet touch target minimums
- List items are at least 44px tall
- Search bar is accessible
- Desktop layout is preserved (no regression)

**Related Specs**: AUI-06

**Notes**: This task may require significant Blueprint restructuring. Consider using `Adw.NavigationSplitView` for automatic adaptive behavior.

---

## Phase 5: Testing and Polish

### Task 5.1: Manual Responsiveness Testing
**Description**: Comprehensive manual testing across all breakpoints

**Steps**:
1. Build application
2. Test window resize from 360px to 1920px width in 50px increments
3. Document any layout issues at each width
4. Test all features at phone (400px), tablet (700px), and desktop (1200px) widths:
   - Start/stop metronome
   - Adjust tempo via slider and spinbutton
   - Change time signature
   - Enable subdivisions
   - Toggle tempo trainer
   - Open preferences, presets, shortcuts dialogs
   - Tap tempo functionality
5. Take screenshots at key breakpoints (360px, 550px, 900px, 1200px)
6. File bug reports for any issues discovered

**Validation**:
- No layout breaks at any tested width
- All features work at all breakpoints
- Screenshots show proper adaptation
- Any issues are documented

**Related Specs**: RL-10, All AUI requirements

---

### Task 5.2: GTK Inspector Verification
**Description**: Use GTK Inspector to verify breakpoints and touch targets

**Steps**:
1. Build application with `GTK_DEBUG=interactive`
2. Run application and open GTK Inspector
3. Navigate to BreakpointBin widget
4. Verify all defined breakpoints are listed
5. Resize window and verify correct breakpoint activates
6. Use Inspector's measurement tool to verify touch targets:
   - All buttons ≥ 44x44px
   - Spinbuttons ≥ 44px height
   - Slider thumb ≥ 24x24px on touch devices
7. Check CSS is correctly applied via `@media (pointer: coarse)`

**Validation**:
- All breakpoints visible in Inspector
- Correct breakpoint activates at each width range
- All touch targets meet minimums
- CSS media queries work correctly

**Related Specs**: RL-10, AUI-01

---

### Task 5.3: Touch Device Testing
**Description**: Test on actual touch devices or emulators

**Steps**:
1. Deploy to PinePhone emulator or physical device
2. Test all core functionality:
   - Start/stop metronome via touch
   - Adjust tempo with slider drag
   - Use spinbuttons with touch
   - Navigate dialogs
   - Use tap tempo
3. Test orientation changes (portrait ↔ landscape)
4. Measure touch interaction latency (should be < 100ms)
5. Document any usability issues

**Validation**:
- All features work on touch devices
- Touch targets are easily tappable
- No accidental taps occur
- Orientation changes are smooth
- Touch latency is acceptable (< 100ms)

**Related Specs**: AUI-12, AUI-14, All touch-related requirements

---

### Task 5.4: Performance Testing
**Description**: Verify responsiveness and performance during breakpoint transitions

**Steps**:
1. Build release version of application
2. Resize window rapidly across breakpoints (drag resize back and forth)
3. Monitor CPU usage during resizes (should remain low, < 20%)
4. Use GTK profiler to check for layout thrashing
5. Verify no frame drops during transitions (maintain 60fps)
6. Test metronome continues playing smoothly during resize

**Validation**:
- CPU usage remains low during resizes
- No layout thrashing detected
- Smooth 60fps transitions
- Metronome playback is uninterrupted
- No memory leaks from repeated resizes

**Related Specs**: RL-09, AUI-14

---

### Task 5.5: Accessibility Testing
**Description**: Verify responsive design maintains accessibility

**Steps**:
1. Build application
2. Enable screen reader (Orca on GNOME)
3. Test navigation with screen reader at phone/tablet/desktop widths
4. Verify all controls are reachable and properly labeled
5. Test keyboard navigation (Tab order) at all breakpoints
6. Use GTK Accessibility Inspector
7. Verify focus indicators are visible for keyboard users

**Validation**:
- All controls are accessible via screen reader
- Tab order is logical at all breakpoints
- Focus indicators are visible
- No accessibility regressions from responsive changes
- Keyboard shortcuts work at all widths

**Related Specs**: AUI-10

---

### Task 5.6: Documentation Updates
**Description**: Update documentation to reflect mobile support

**Steps**:
1. Update `README.md`:
   - Add "Mobile Linux Support" section
   - List tested devices (PinePhone, Librem 5, etc.)
   - Note minimum screen size (360x600)
2. Update `CHANGELOG.md`:
   - Add entry for mobile/responsive support
   - List breakpoints and adaptive features
   - Note touch optimization improvements
3. Update screenshots if present (add mobile screenshots)
4. Update Flathub metadata (appdata) to mention mobile support

**Validation**:
- Documentation accurately reflects new capabilities
- Users understand mobile support
- Screenshots show responsive layouts
- Flathub listing is updated

---

### Task 5.7: Final Integration Testing
**Description**: End-to-end testing of complete responsive implementation

**Steps**:
1. Build production version
2. Test complete user workflows at each breakpoint:
   - Phone (400px): Quick practice session (simple BPM, start/stop)
   - Tablet (700px): Medium session with subdivisions
   - Desktop (1200px): Advanced session with presets and tempo trainer
3. Test edge cases:
   - Minimum size (360x600)
   - Breakpoint boundaries (549px, 550px, 551px, 899px, 900px, 901px)
   - Orientation changes
   - Dialog openings at various widths
4. Verify no regressions in existing desktop functionality
5. Run any automated tests (if present)

**Validation**:
- All workflows complete successfully at all breakpoints
- No edge case failures
- No regressions in existing features
- All tests pass
- Application is ready for release

---

## Dependencies Between Tasks

```
1.1 (Window Constraints) → 1.2 (Phone Breakpoint)
1.2 → 1.3 (Beat Indicator) + 1.4 (Margins) + 1.5 (Tablet Breakpoint)
1.3, 1.4, 1.5 → 2.1 (Time Signature) + 2.2 (Trainer) + 2.3 (Scrolling)
2.1, 2.2, 2.3 → 3.1, 3.2, 3.3, 3.4 (Touch Optimizations)
3.* → 4.1, 4.2, 4.3 (Dialog Adaptations)
4.* → 5.1, 5.2, 5.3, 5.4, 5.5 (Testing)
5.1-5.5 → 5.6 (Documentation) → 5.7 (Final Integration)
```

## Parallelizable Tasks

These tasks can be worked on in parallel:
- Phase 3 tasks (3.1, 3.2, 3.3, 3.4) can be done concurrently after Phase 2
- Phase 4 tasks (4.1, 4.2, 4.3) can be done concurrently after Phase 3
- Phase 5 tasks (5.1, 5.2, 5.3) can be done concurrently

## Estimated Effort

- **Phase 1**: 4-6 hours (foundation, breakpoints)
- **Phase 2**: 4-6 hours (layout adaptations)
- **Phase 3**: 3-4 hours (touch optimization)
- **Phase 4**: 3-4 hours (dialog adaptations)
- **Phase 5**: 6-8 hours (testing, documentation, polish)

**Total**: 20-28 hours
