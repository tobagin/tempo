# Deprecated Libadwaita Classes to Avoid

This document lists deprecated Libadwaita classes that should NOT be used in new development, based on the official documentation.

## Deprecated in Version 1.6
- **AboutWindow** → Use `AboutDialog` instead
- **MessageDialog** → Use `AlertDialog` instead  
- **PreferencesWindow** → Use `PreferencesDialog` instead
- Related functions:
  - `adw_show_about_window()` → Use `AboutDialog.present()`
  - `adw_show_about_window_from_appdata()` → Use `AboutDialog` with AppStream data

## Deprecated in Version 1.4
- **Clamp** → Use breakpoints and adaptive layouts instead
- **Flap** → Use `OverlaySplitView` or `NavigationSplitView` instead
- **Leaflet** → Use `NavigationView` or `OverlaySplitView` instead
- **LeafletPage** → No longer needed with new navigation widgets
- **Squeezer** → Use breakpoints and adaptive layouts instead
- **SqueezerPage** → No longer needed
- **ViewSwitcherTitle** → Use `ViewSwitcher` with `HeaderBar` instead

## Deprecated Enumerations (Version 1.4)
- **FlapFoldPolicy** → Use breakpoint-based folding
- **FlapTransitionType** → Use new transition system
- **FoldThresholdPolicy** → Use breakpoints
- **LeafletTransitionType** → Use new navigation transitions
- **SqueezerTransitionType** → Use adaptive layouts

## Migration Guidelines

### PreferencesWindow → PreferencesDialog
```vala
// OLD (deprecated)
public class MyPrefs : Adw.PreferencesWindow { }

// NEW (current)
public class MyPrefs : Adw.PreferencesDialog { }
```

### AboutWindow → AboutDialog
```vala
// OLD (deprecated)
var about = new Adw.AboutWindow();
about.present();

// NEW (current)
var about = new Adw.AboutDialog();
about.present(parent_window);
```

### Adaptive Layouts
Instead of deprecated `Leaflet`, `Flap`, `Squeezer`, use:
- `NavigationView` for hierarchical navigation
- `OverlaySplitView` for side panels
- `NavigationSplitView` for three-pane layouts
- `BreakpointBin` with `Breakpoint` for responsive design

## Current Best Practices
- Use `PreferencesDialog` for settings windows
- Use `AboutDialog` for application about dialogs
- Use `AlertDialog` for message dialogs
- Use breakpoint-based responsive design instead of deprecated adaptive containers
- Use modern navigation widgets (`NavigationView`, `NavigationSplitView`)

## References
- [Libadwaita Documentation](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/)
- [Migration Guide to Adaptive Dialogs](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/migrating-to-adaptive-dialogs.html)
- [Migration Guide to Breakpoints](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/migrating-to-breakpoints.html)
