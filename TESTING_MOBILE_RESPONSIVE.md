# Mobile Responsive Design Testing Guide

This document provides comprehensive testing procedures for the mobile-responsive design implementation in Tempo v1.4.0.

## Table of Contents
1. [Manual Responsiveness Testing](#manual-responsiveness-testing)
2. [GTK Inspector Verification](#gtk-inspector-verification)
3. [Touch Device Testing](#touch-device-testing)
4. [Performance Testing](#performance-testing)
5. [Accessibility Testing](#accessibility-testing)
6. [Test Results Summary](#test-results-summary)

---

## Manual Responsiveness Testing

### Prerequisites
```bash
# Launch the application
flatpak run io.github.tobagin.tempo.Devel
```

### Test 1: Window Resizing Across Breakpoints

**Objective**: Verify smooth layout transitions at breakpoint boundaries.

**Procedure**:
1. Launch Tempo
2. Resize window width from 360px to 1920px in 50px increments
3. Observe layout changes at key breakpoints:
   - **550px boundary**: Phone → Tablet transition
   - **900px boundary**: Tablet → Desktop transition

**Expected Results**:
- ✅ Window cannot be resized below 360x600 pixels
- ✅ At ≤550px width:
  - Beat indicator: 200x200px
  - Time signature controls: Vertical layout
  - Margins: 6px (sides), 12px (top/bottom)
  - Spacing: 12px between elements
  - Tempo trainer: Hidden by default (unless user toggled)
- ✅ At 551-900px width:
  - Beat indicator: 250x250px
  - Time signature controls: Horizontal layout
  - Spacing: 18px between elements
- ✅ At >900px width:
  - Beat indicator: 300x300px (original desktop size)
  - Original desktop layout preserved
- ✅ No layout breaks, glitches, or visual artifacts during transitions
- ✅ No horizontal scrolling at any width

### Test 2: Beat Indicator Responsiveness

**Objective**: Verify beat indicator scales correctly at all breakpoints.

**Procedure**:
1. Start metronome playback
2. Resize window across all three breakpoints while playing
3. Observe beat indicator behavior

**Expected Results**:
- ✅ Beat indicator remains centered and visible at all widths
- ✅ Visual effects (glow, numbers, colors) scale proportionally
- ✅ No clipping or overflow at any size
- ✅ Smooth transitions between sizes (200px → 250px → 300px)
- ✅ Playback continues uninterrupted during resize

### Test 3: Time Signature Layout Adaptation

**Objective**: Verify time signature controls adapt between horizontal and vertical layouts.

**Procedure**:
1. Resize window to <550px (phone mode)
2. Observe time signature controls layout
3. Resize window to >550px (tablet/desktop mode)
4. Test interaction with spinbuttons and dropdown in both layouts

**Expected Results**:
- ✅ Phone mode (≤550px): Vertical layout with controls stacked
- ✅ Tablet/Desktop mode (>550px): Horizontal layout with controls inline
- ✅ All controls remain functional in both layouts
- ✅ Labels remain readable and properly aligned
- ✅ Spacing is appropriate for touch interaction (8px in vertical, 12px in horizontal)

### Test 4: Scrolling Behavior

**Objective**: Verify vertical scrolling works on constrained screens.

**Procedure**:
1. Resize window to minimum height (600px) or smaller display
2. Enable all features (tempo trainer, practice timer)
3. Scroll through content

**Expected Results**:
- ✅ Vertical scrollbar appears when content exceeds window height
- ✅ Horizontal scrollbar never appears
- ✅ All controls remain accessible via scrolling
- ✅ Scrolling is smooth (60fps)
- ✅ Content doesn't get cut off or hidden

### Test 5: Tempo Trainer Mobile Behavior

**Objective**: Verify tempo trainer hides on phone screens by default.

**Procedure**:
1. Launch application at desktop width (>900px)
2. Open "Show Tempo Trainer" menu item (should toggle visibility)
3. Resize window to phone width (≤550px)
4. Observe trainer visibility
5. Toggle trainer visibility via menu at phone width
6. Resize back to desktop width

**Expected Results**:
- ✅ Trainer hidden by default on phone width on first launch
- ✅ User can still toggle trainer visibility via menu on phone
- ✅ Once user toggles, preference is remembered during that session
- ✅ Trainer remains visible at desktop/tablet widths when enabled

### Test 6: Dialog Responsiveness

**Objective**: Verify all dialogs adapt to mobile screens.

**Procedure**:
1. At phone width (≤550px), open each dialog:
   - Preferences dialog (Ctrl+,)
   - Preset Manager (Ctrl+P)
   - Keyboard Shortcuts (Ctrl+?)
   - About dialog
2. Test functionality in each dialog
3. Repeat at tablet (700px) and desktop (1200px) widths

**Expected Results**:

**Preferences Dialog**:
- ✅ Full-screen mode on phone (≤600px)
- ✅ Sidebar navigation mode on tablet/desktop
- ✅ All pages accessible in both modes
- ✅ Search functionality works in both modes

**Preset Manager**:
- ✅ Vertical pane layout on phone (preset list above, details below)
- ✅ Horizontal pane layout on tablet/desktop (list left, details right)
- ✅ All buttons and controls accessible
- ✅ Search entry usable on all screen sizes

**Alert Dialogs**:
- ✅ Adapt to narrow widths automatically
- ✅ Text readable without horizontal scrolling
- ✅ Buttons meet touch target requirements

---

## GTK Inspector Verification

### Launch with Inspector

```bash
GTK_DEBUG=interactive flatpak run io.github.tobagin.tempo.Devel
```

Or press `Ctrl+Shift+D` while app is running.

### Test 1: Breakpoint Verification

**Procedure**:
1. Open GTK Inspector
2. Navigate to the main window widget tree
3. Find `Adw.BreakpointBin` widget
4. Examine defined breakpoints

**Expected Results**:
- ✅ Two breakpoints visible:
  - `phone_breakpoint`: condition "max-width: 550sp"
  - `tablet_breakpoint`: condition "max-width: 900sp"
- ✅ Resize window and observe active breakpoint changes
- ✅ At ≤550px: `phone_breakpoint` is active
- ✅ At 551-900px: `tablet_breakpoint` is active
- ✅ At >900px: No breakpoints active (desktop default)

### Test 2: Touch Target Measurements

**Objective**: Verify all interactive elements meet 44px minimum on touch devices.

**Procedure**:
1. Open GTK Inspector
2. Use the "Select" tool (pointer icon) to measure widgets
3. Check dimensions of:
   - All buttons (play, tap tempo, trainer buttons, etc.)
   - Spinbutton controls (increment/decrement buttons)
   - Slider thumb
4. Enable touch simulation if available

**Expected Results**:
- ✅ All buttons: ≥44x44px (on touch devices via CSS @media pointer: coarse)
- ✅ Spinbutton height: ≥44px
- ✅ Spinbutton increment/decrement buttons: ≥44x44px each
- ✅ Slider thumb: ≥24x24px with 6px margin
- ✅ Slider trough: ≥12px height

### Test 3: CSS Media Query Verification

**Procedure**:
1. Open GTK Inspector → CSS tab
2. Select interactive elements (buttons, spinbuttons, scales)
3. Check applied CSS rules

**Expected Results**:
- ✅ `@media (pointer: coarse)` rules apply on touch devices
- ✅ Touch-specific sizing is active:
  ```css
  spinbutton { min-height: 44px; }
  spinbutton button { min-width: 44px; min-height: 44px; }
  scale slider { min-width: 24px; min-height: 24px; }
  button { min-height: 44px; min-width: 44px; }
  ```

### Test 4: Property Verification

**Procedure**:
1. Open Inspector → Object Properties
2. Select `beat_indicator` widget
3. Check `content-width` and `content-height` properties
4. Resize window across breakpoints and re-check

**Expected Results**:
- ✅ At ≤550px: content-width=200, content-height=200
- ✅ At 551-900px: content-width=250, content-height=250
- ✅ At >900px: content-width=300, content-height=300

---

## Touch Device Testing

### Target Devices
- **PinePhone** (720x1440, Linux)
- **Librem 5** (720x1440, Linux)
- Touch-enabled laptops/tablets
- Mobile Linux emulators

### Test 1: Touch Target Interaction

**Procedure**:
1. Deploy to touch device or enable touch simulation
2. Test tapping all interactive elements:
   - Play/Stop button
   - Tap Tempo button
   - Spinbutton increment/decrement arrows
   - Tempo slider thumb
   - Time signature controls
   - Menu button
   - All dialog buttons
3. Attempt "fat finger" taps (inaccurate touch points)

**Expected Results**:
- ✅ All buttons respond to touch reliably
- ✅ No accidental taps on adjacent controls
- ✅ Spinbutton arrows are easily tappable
- ✅ Slider thumb is grabbable and draggable smoothly
- ✅ Touch feedback is immediate (<100ms response)

### Test 2: Slider Drag Interaction

**Procedure**:
1. On touch device, drag tempo slider thumb
2. Test rapid drags, slow drags, and edge cases
3. Test with varying touch pressure

**Expected Results**:
- ✅ Thumb follows finger accurately
- ✅ Drag is smooth without jitter
- ✅ Thumb doesn't get "stuck"
- ✅ Value updates in real-time during drag
- ✅ No accidental jumps in value

### Test 3: Orientation Changes

**Procedure**:
1. On mobile device, test in portrait orientation (360px width typical)
2. Rotate to landscape orientation (~720px width)
3. Observe layout changes

**Expected Results**:
- ✅ Portrait (≤550px): Phone breakpoint active
- ✅ Landscape (~720px): Tablet breakpoint active
- ✅ Layout transitions smoothly during rotation
- ✅ No loss of functionality or state
- ✅ Content remains accessible without horizontal scrolling

### Test 4: Touch Latency Measurement

**Procedure**:
1. On touch device, tap Play/Stop button rapidly
2. Drag slider quickly
3. Tap spinbutton arrows in succession

**Expected Results**:
- ✅ Touch latency <100ms (imperceptible)
- ✅ No missed taps or double-registrations
- ✅ UI feels responsive to touch input

---

## Performance Testing

### Test 1: Breakpoint Transition Performance

**Objective**: Verify smooth transitions with no frame drops.

**Procedure**:
1. Launch with performance monitoring:
   ```bash
   # Enable frame timing
   GSK_DEBUG=geometry flatpak run io.github.tobagin.tempo.Devel
   ```
2. Rapidly resize window across breakpoints (drag resize back and forth)
3. Monitor CPU usage during resizes
4. Observe for visual stuttering or lag

**Expected Results**:
- ✅ Smooth 60fps transitions (no dropped frames)
- ✅ CPU usage remains low during resize (<20% on modern hardware)
- ✅ No layout thrashing detected
- ✅ No visual glitches or tearing
- ✅ Memory usage remains stable (no leaks from repeated resizes)

### Test 2: Metronome Performance During Resize

**Procedure**:
1. Start metronome at 120 BPM
2. Rapidly resize window across all breakpoints
3. Listen for audio glitches or timing drift
4. Monitor beat indicator refresh rate

**Expected Results**:
- ✅ Metronome timing remains accurate (no drift)
- ✅ No audio glitches, pops, or dropouts
- ✅ Beat indicator continues animating smoothly
- ✅ Beat indicator frame rate maintains 60fps cap
- ✅ No increase in CPU/memory usage

### Test 3: Resource Usage at Minimum Size

**Procedure**:
1. Resize window to minimum (360x600)
2. Enable all features (trainer, timer, subdivisions)
3. Run metronome for 5 minutes
4. Monitor resource usage:
   ```bash
   # Monitor with htop or similar
   htop -p $(pgrep tempo)
   ```

**Expected Results**:
- ✅ Memory usage stable (~50-100MB typical)
- ✅ CPU usage reasonable (<5% idle, <15% during playback)
- ✅ No memory leaks over extended use
- ✅ Application remains responsive

### Test 4: Dialog Opening Performance

**Procedure**:
1. At phone width, rapidly open and close each dialog 10 times
2. Monitor CPU usage and responsiveness

**Expected Results**:
- ✅ Dialog opens in <200ms
- ✅ No lag or stuttering during opening animation
- ✅ No memory leaks from repeated open/close
- ✅ UI remains responsive throughout

---

## Accessibility Testing

### Test 1: Screen Reader Navigation

**Objective**: Verify all controls are accessible via screen reader.

**Procedure**:
1. Enable screen reader (Orca on GNOME):
   ```bash
   orca &
   flatpak run io.github.tobagin.tempo.Devel
   ```
2. Navigate through UI using Tab key
3. Test at phone (400px), tablet (700px), and desktop (1200px) widths
4. Verify all controls are announced correctly

**Expected Results**:
- ✅ All controls are reachable via keyboard
- ✅ Tab order is logical at all breakpoints
- ✅ All buttons announce their labels
- ✅ Spinbuttons announce current values
- ✅ Slider announces current tempo value
- ✅ No controls become unreachable in mobile mode

### Test 2: Keyboard Navigation

**Procedure**:
1. Disable mouse/touchpad
2. Navigate entire UI using only keyboard
3. Test all keyboard shortcuts at each breakpoint
4. Test at phone, tablet, and desktop widths

**Expected Results**:
- ✅ Tab order flows naturally
- ✅ All controls are keyboard-accessible
- ✅ Keyboard shortcuts work at all widths:
  - Spacebar: Start/stop
  - T: Tap tempo
  - ↑/↓: Adjust tempo
  - Ctrl+,: Preferences
  - Ctrl+P: Presets
  - Ctrl+Q: Quit
- ✅ Focus indicators are visible
- ✅ No keyboard traps

### Test 3: Focus Visibility

**Procedure**:
1. Navigate through controls using Tab key
2. Observe focus indicator visibility
3. Test on light and dark themes
4. Test at all breakpoints

**Expected Results**:
- ✅ Focus indicators clearly visible on all controls
- ✅ Focus ring is at least 2px thick
- ✅ Sufficient contrast ratio (≥3:1)
- ✅ Focus visible on both light and dark themes
- ✅ Focus order remains logical on mobile layouts

### Test 4: Color Contrast

**Procedure**:
1. Use accessibility inspector or contrast checker
2. Check key UI elements:
   - Text labels vs background
   - Button text vs button color
   - Active beat indicator vs inactive
   - Downbeat (red) vs regular beat (blue)

**Expected Results**:
- ✅ All text meets WCAG AA standard (≥4.5:1 for normal text)
- ✅ Large text meets WCAG AA (≥3:1)
- ✅ Interactive elements are distinguishable
- ✅ Color is not the only means of conveying information

---

## Test Results Summary

### Checklist for Sign-Off

Complete this checklist after testing:

#### Phase 1: Foundation
- [ ] Window minimum size enforced (360x600)
- [ ] Phone breakpoint activates at ≤550px
- [ ] Tablet breakpoint activates at 551-900px
- [ ] Desktop layout preserved at >900px
- [ ] Beat indicator sizes correctly (200/250/300px)
- [ ] Margins and spacing adapt correctly

#### Phase 2: Layout Adaptations
- [ ] Time signature controls vertical on phone
- [ ] Time signature controls horizontal on tablet/desktop
- [ ] Tempo trainer hides by default on phone
- [ ] Tempo trainer toggle works at all sizes
- [ ] Vertical scrolling works when needed
- [ ] No horizontal scrolling occurs

#### Phase 3: Touch Optimization
- [ ] All spinbuttons ≥44px height on touch devices
- [ ] Spinbutton buttons ≥44x44px on touch
- [ ] Slider thumb ≥24x24px on touch
- [ ] Slider trough ≥12px height on touch
- [ ] All buttons ≥44x44px on touch devices
- [ ] Touch interactions feel responsive

#### Phase 4: Dialogs
- [ ] Preferences dialog adapts to mobile
- [ ] Preset manager panes stack vertically on phone
- [ ] Alert dialogs adapt to narrow widths
- [ ] All dialog controls are touch-accessible

#### Phase 5: Testing & Performance
- [ ] Smooth 60fps transitions at breakpoints
- [ ] No frame drops during resize
- [ ] Metronome timing unaffected by resize
- [ ] Memory usage stable over time
- [ ] CPU usage reasonable
- [ ] All controls keyboard-accessible
- [ ] Screen reader compatibility verified
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA

### Known Issues
Document any issues found during testing here:

```
None identified during implementation.
```

### Test Environment
- **Date**: [Fill in test date]
- **Tester**: [Fill in tester name]
- **OS**: [e.g., Fedora 40, Debian 12, etc.]
- **GTK Version**: [Run: gtk4-query-version or check About dialog]
- **Libadwaita Version**: [Check dependencies]
- **Device**: [Desktop, Laptop, PinePhone, etc.]
- **Screen Resolution**: [e.g., 1920x1080]

---

## Automated Testing Script

For quick verification, use this bash script:

```bash
#!/bin/bash
# mobile-responsive-test.sh - Quick verification of mobile responsive features

echo "🔍 Tempo Mobile Responsive Design Test Script"
echo "=============================================="
echo

# Check if app is installed
if ! flatpak list | grep -q "io.github.tobagin.tempo"; then
    echo "❌ Tempo not installed. Please build and install first."
    exit 1
fi

echo "✅ Tempo is installed"

# Check Blueprint files for breakpoints
echo
echo "📄 Checking Blueprint files for breakpoints..."
if grep -q "Adw.Breakpoint.*phone_breakpoint" data/ui/main_window.blp; then
    echo "✅ Phone breakpoint found in main_window.blp"
else
    echo "❌ Phone breakpoint NOT found"
fi

if grep -q "max-width: 550sp" data/ui/main_window.blp; then
    echo "✅ Phone breakpoint condition correct (≤550sp)"
else
    echo "❌ Phone breakpoint condition incorrect"
fi

if grep -q "Adw.Breakpoint.*tablet_breakpoint" data/ui/main_window.blp; then
    echo "✅ Tablet breakpoint found"
else
    echo "❌ Tablet breakpoint NOT found"
fi

if grep -q "max-width: 900sp" data/ui/main_window.blp; then
    echo "✅ Tablet breakpoint condition correct (≤900sp)"
else
    echo "❌ Tablet breakpoint condition incorrect"
fi

# Check CSS for touch optimizations
echo
echo "🎨 Checking CSS for touch optimizations..."
if grep -q "@media (pointer: coarse)" data/style.css; then
    echo "✅ Touch device media query found"
else
    echo "❌ Touch device media query NOT found"
fi

if grep -q "min-height: 44px" data/style.css; then
    echo "✅ Touch-friendly minimum heights defined"
else
    echo "❌ Touch-friendly heights missing"
fi

# Check for ScrolledWindow
echo
echo "📜 Checking for scrollable container..."
if grep -q "Gtk.ScrolledWindow" data/ui/main_window.blp; then
    echo "✅ ScrolledWindow found for scrollable content"
else
    echo "❌ ScrolledWindow NOT found"
fi

# Check preset manager dialog
echo
echo "📋 Checking preset manager dialog responsiveness..."
if grep -q "Adw.BreakpointBin" data/ui/preset_manager_dialog.blp; then
    echo "✅ BreakpointBin found in preset manager"
else
    echo "❌ Preset manager not responsive"
fi

echo
echo "=============================================="
echo "✨ Static analysis complete!"
echo
echo "Next steps:"
echo "1. Launch app: flatpak run io.github.tobagin.tempo.Devel"
echo "2. Test window resizing from 360px to 1920px"
echo "3. Use GTK Inspector: GTK_DEBUG=interactive flatpak run io.github.tobagin.tempo.Devel"
echo "4. Refer to TESTING_MOBILE_RESPONSIVE.md for full test procedures"
```

Save as `mobile-responsive-test.sh`, make executable with `chmod +x`, and run.

---

## Conclusion

This comprehensive testing guide ensures the mobile-responsive design implementation meets all requirements for phone, tablet, and desktop form factors. Follow all test procedures to verify proper functionality before release.

For issues or questions, file a bug report at: https://github.com/tobagin/tempo/issues
