# Proposal: Add Mobile-Responsive Design

## Overview
Make the Tempo metronome application fully responsive and adaptive to work seamlessly across desktop computers, tablets, and phones. The application currently has a fixed 400x500px default window size optimized for desktop use. This proposal adds responsive breakpoints, adaptive layouts, and touch-friendly controls to ensure an optimal user experience on all device form factors.

## Motivation
- **Market expansion**: Enable use on mobile Linux devices (PinePhone, Librem 5, etc.) and tablets running GNOME
- **Usability**: Musicians often use tablets/phones during practice sessions for portability
- **GNOME HIG compliance**: Follow GNOME Human Interface Guidelines for adaptive applications
- **Future-proofing**: Prepare for convergent desktop/mobile Linux ecosystems

## Current State
The application uses:
- Fixed default window size: 400x500px (main_window.blp:5-6)
- `Adw.BreakpointBin` container (main_window.blp:25) but no breakpoints defined
- Fixed content dimensions: beat indicator is 300x300px (main_window.blp:164-165)
- Desktop-optimized spacing and margins
- Mouse/keyboard-centric interaction model
- No adaptive layouts based on screen size

## Proposed Solution
Implement a comprehensive responsive design system using:

1. **Libadwaita Breakpoints**: Define breakpoints for phone (0-550px), tablet (551-900px), and desktop (900+px) form factors
2. **Adaptive Layouts**: Switch between horizontal and vertical layouts based on available space
3. **Flexible Sizing**: Replace fixed dimensions with responsive constraints
4. **Touch Optimization**: Increase touch target sizes, add swipe gestures, improve spacing
5. **Content Prioritization**: Hide/collapse secondary UI on small screens
6. **Orientation Support**: Handle portrait and landscape orientations gracefully

## Impact Assessment
### Benefits
- Broader device compatibility and user base
- Improved usability on existing desktop installations (window resizing)
- Better accessibility for touch-based interactions
- Alignment with GNOME design principles

### Risks
- Increased UI complexity and testing surface area
- Potential layout bugs on edge cases
- Need to maintain desktop UX quality while optimizing for mobile

### Mitigation
- Use Libadwaita's built-in adaptive widgets (proven patterns)
- Thorough testing on various screen sizes using GTK Inspector
- Progressive enhancement: desktop remains primary target
- Leverage existing `Adw.BreakpointBin` infrastructure (already in UI)

## Dependencies
- Libadwaita >= 1.5 (already required, provides breakpoint support)
- GTK4 >= 4.10.0 (already required)
- No new external dependencies needed

## Out of Scope
- Native Android/iOS ports
- Platform-specific mobile features (haptics, sensors)
- Complete redesign of UI metaphors (retain existing visual identity)
- Performance optimization for low-end mobile hardware (future work)

## Success Criteria
1. Application functions correctly on screens from 360px to 4K
2. All controls accessible via touch on small screens
3. No horizontal scrolling required in portrait phone mode
4. Beat indicator remains visible and functional on all screen sizes
5. Keyboard shortcuts continue to work on desktop
6. Pass GNOME Builder/GTK Inspector responsive checks

## Related Specifications
This proposal creates/modifies the following specs:
- `openspec/specs/responsive-layout/spec.md` (NEW) - Breakpoint definitions, layout adaptation rules
- `openspec/specs/adaptive-ui/spec.md` (NEW) - Touch targets, gestures, UI element behavior
