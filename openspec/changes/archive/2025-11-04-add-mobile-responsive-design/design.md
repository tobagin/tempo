# Design: Mobile-Responsive Architecture

## Overview
This design document outlines the technical approach for making Tempo responsive across desktop, tablet, and phone form factors using Libadwaita's adaptive patterns.

## Design Principles

1. **Progressive Adaptation**: Desktop experience remains unchanged; mobile adaptations are additive
2. **Content-First**: Beat indicator and tempo controls remain prioritized on all screens
3. **Touch-Friendly**: Minimum 44x44px touch targets (GNOME HIG recommendation)
4. **Graceful Degradation**: Advanced features (tempo trainer) collapse/hide on constrained screens
5. **Performance**: No layout thrashing; breakpoint changes are smooth and efficient

## Breakpoint Strategy

### Breakpoint Definitions
Following GNOME HIG and common device sizes:

| Breakpoint | Width Range | Target Devices | Layout Mode |
|------------|-------------|----------------|-------------|
| Phone (narrow) | 0-550px | PinePhone (720px), Librem 5 (720px), portrait phones | Compact vertical |
| Tablet (medium) | 551-900px | Tablets, landscape phones, narrow desktop windows | Adaptive hybrid |
| Desktop (wide) | 900px+ | Desktop monitors, wide windows | Current layout (unchanged) |

### Why These Breakpoints?
- **550px**: Standard phone landscape width minus margins (~600px typical landscape)
- **900px**: Threshold where horizontal space allows side-by-side controls
- Aligns with Libadwaita's `Adw.Breakpoint` recommendations

## Layout Adaptations

### Phone Layout (0-550px)
**Key Changes:**
- Beat indicator: Reduced to 200x200px (from 300x300px)
- Tempo slider: Full width, larger thumb for touch
- Time signature controls: Stacked vertically instead of horizontal
- Trainer section: Collapsed by default, expandable via Adw.ExpanderRow
- All margins reduced: 12px → 6px for sides, 24px → 12px for top/bottom
- Preset manager: Opens in bottom sheet style instead of dialog
- Preferences: Uses full-screen adaptive dialog mode

**Justification:**
- Maximize vertical space for primary controls (BPM, play/stop)
- Reduce clutter by hiding advanced features (trainer) behind progressive disclosure
- Touch targets meet 44x44px minimum (buttons, sliders)

### Tablet Layout (551-900px)
**Key Changes:**
- Beat indicator: 250x250px (intermediate size)
- Time signature: Remains horizontal
- Trainer: Visible but more compact spacing
- Margins: Moderate reduction (12px sides, 18px top/bottom)
- Preset manager: Standard dialog size (600px width)

**Justification:**
- Balanced approach: more space than phone, less than desktop
- All features remain accessible without scrolling

### Desktop Layout (900px+)
**No Changes**: Current implementation preserved exactly as-is.

## Component-Level Design

### 1. Main Window (`main_window.blp`)

#### Breakpoint Implementation
```blueprint
Adw.BreakpointBin {
  vexpand: true;

  // Phone breakpoint
  Adw.Breakpoint {
    condition: "max-width: 550px"

    setters {
      beat_indicator.content-width: 200;
      beat_indicator.content-height: 200;
      tempo_scale.margin-start: 6;
      tempo_scale.margin-end: 6;
      main_content_box.margin-start: 6;
      main_content_box.margin-end: 6;
      main_content_box.margin-top: 12;
      main_content_box.margin-bottom: 12;
      main_content_box.spacing: 12;
      trainer_box.visible: false; // Hidden by default on phones
    }
  }

  // Tablet breakpoint
  Adw.Breakpoint {
    condition: "max-width: 900px"

    setters {
      beat_indicator.content-width: 250;
      beat_indicator.content-height: 250;
      main_content_box.spacing: 18;
    }
  }

  // Content goes here
  Gtk.Box main_content_box {
    // ... existing content
  }
}
```

#### Window Size Constraints
```blueprint
template $TempoWindow : Adw.ApplicationWindow {
  default-width: 400;
  default-height: 500;
  width-request: 360;  // NEW: Minimum width (smallest phone in portrait)
  height-request: 600; // NEW: Minimum height (ensure scrollability)
}
```

### 2. Beat Indicator Adaptation

**Strategy**: Use Cairo drawing context to scale dynamically based on allocated size
- Desktop: 300x300px (unchanged)
- Tablet: 250x250px (breakpoint-controlled)
- Phone: 200x200px (breakpoint-controlled)

**Implementation**: Existing `draw_beat_indicator()` in MainWindow.vala:610 already uses relative sizing (`width`, `height` parameters). Breakpoints only need to adjust `content-width/content-height` properties.

### 3. Time Signature Controls

**Desktop/Tablet**: Horizontal layout (existing)
```
[Beats Spin] [/] [Beat Value Dropdown]  (horizontal box)
```

**Phone**: Vertical stacking
```
Beats per Bar: [Spin]
Note Value:    [Dropdown]
```

**Implementation**: Use `Adw.Breakpoint` setter to change `Gtk.Box.orientation` from `horizontal` to `vertical`.

### 4. Tempo Trainer Collapsing

**Desktop**: Visible in `Gtk.Box` (current)
**Tablet**: Visible but compact
**Phone**: Collapsed into `Adw.ExpanderRow` or hidden behind menu

**Rationale**: Trainer is advanced feature; beginners on mobile need simple BPM control first.

### 5. Preferences Dialog

**Desktop**: `Adw.PreferencesDialog` with sidebar (current)
**Mobile**: Automatically adapts to full-screen mode (Libadwaita built-in behavior)

**No code changes needed**: `Adw.PreferencesDialog` handles this automatically below ~600px.

## Touch Interaction Design

### Touch Targets
Audit all interactive elements to meet 44x44px minimum:

| Element | Current Size | Mobile Size | Status |
|---------|--------------|-------------|--------|
| Play/Stop button | 140x52px | Unchanged | ✅ Compliant |
| Tap Tempo button | Auto | min-height: 44px | ⚠️ Needs fix |
| SpinButton | ~90x36px | min-height: 44px | ⚠️ Needs fix |
| Tempo slider thumb | Default (~20px) | Larger via CSS | ⚠️ Needs enhancement |
| Menu button | 40x40px | 44x44px | ⚠️ Minor adjustment |

### Gesture Support
**Future Enhancement** (out of scope for this proposal):
- Swipe left/right on tempo slider to adjust BPM
- Double-tap beat indicator to start/stop
- Pinch-to-zoom on beat indicator

## CSS Adaptations

### Touch-Friendly Slider
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

**Note**: GTK/CSS `@media (pointer: coarse)` detects touch devices.

### Spacing Adjustments
Use CSS classes to reduce spacing on mobile:
```css
.mobile-compact {
  margin-top: 12px;
  margin-bottom: 12px;
  spacing: 12px;
}
```

Applied via breakpoint setter:
```blueprint
Adw.Breakpoint {
  condition: "max-width: 550px"
  setters {
    main_content_box.css-classes: "mobile-compact";
  }
}
```

## Technical Constraints

### GTK4 Limitations
1. **No CSS @media queries for width**: Must use `Adw.Breakpoint` in Blueprint
2. **No dynamic orientation changes**: Breakpoints are based on width only
3. **Touch detection**: Limited to `@media (pointer: coarse)` in CSS

### Libadwaita Capabilities
1. **Adw.BreakpointBin**: Container that manages breakpoint conditions ✅
2. **Adw.Breakpoint**: Defines conditions and property setters ✅
3. **Automatic dialog adaptation**: PreferencesDialog, AlertDialog adapt automatically ✅
4. **Adw.ExpanderRow**: For collapsible sections ✅

## Testing Strategy

### Manual Testing Checklist
1. Resize window from 360px to 1920px width
2. Test on actual devices: PinePhone emulator, Librem 5 emulator
3. Use GTK Inspector to verify breakpoint activation
4. Test touch interactions on touch-enabled laptop/tablet
5. Verify keyboard shortcuts still work on desktop

### Test Scenarios
| Scenario | Width | Expected Behavior |
|----------|-------|-------------------|
| Portrait phone | 360px | Beat indicator 200px, trainer hidden, vertical time sig |
| Landscape phone | 720px | Beat indicator 250px, trainer visible, horizontal time sig |
| Tablet portrait | 800px | Beat indicator 250px, all features visible, compact spacing |
| Desktop small | 1024px | Beat indicator 300px, full desktop layout |
| Desktop large | 1920px | Beat indicator 300px, full desktop layout (unchanged) |

### Automated Testing
- GTK test suite for widget sizing
- Visual regression tests (screenshots at key breakpoints)
- Accessibility checks (touch target sizes via GTK a11y inspector)

## Performance Considerations

1. **Breakpoint Changes**: Adw.Breakpoint uses property setters, not layout recalculation → minimal cost
2. **Cairo Rendering**: Beat indicator already scales dynamically → no additional overhead
3. **Memory**: No additional widgets created for mobile (just property changes) → same footprint

## Migration Path

### Phase 1: Foundation (This Proposal)
- Add breakpoints to main window
- Implement responsive sizing for beat indicator
- Adapt time signature controls
- Ensure minimum touch target sizes

### Phase 2: Polish (Future)
- Add touch gestures (swipe, double-tap)
- Optimize trainer UI for mobile
- Add orientation-specific optimizations
- Custom keyboard for numeric inputs on mobile

### Phase 3: Native Mobile Features (Future)
- Haptic feedback on beats
- Screen wake lock during playback
- Integration with mobile audio routing

## Alternative Approaches Considered

### Alternative 1: Separate Mobile UI
**Rejected**: Maintenance burden, code duplication, violates GNOME convergence principles.

### Alternative 2: Single-Column Phone Layout
**Rejected**: Wastes horizontal space in landscape mode, poor UX on wide phones.

### Alternative 3: No Breakpoints, Pure CSS
**Rejected**: GTK4 CSS doesn't support width-based media queries for layout changes.

## References
- [GNOME Human Interface Guidelines - Adaptive Design](https://developer.gnome.org/hig/patterns/containers/adaptive.html)
- [Libadwaita Breakpoint Documentation](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/class.Breakpoint.html)
- [GTK4 Touch Support](https://docs.gtk.org/gtk4/input-handling.html#touch-support)
- Existing codebase: `data/ui/main_window.blp:25` (already has `Adw.BreakpointBin`)
