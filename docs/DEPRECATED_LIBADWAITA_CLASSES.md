# Deprecated GTK4 and Libadwaita Classes to Avoid

This document lists deprecated GTK4 and Libadwaita classes that should NOT be used in new development, based on official documentation.

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

# GTK4 Deprecated Classes

## Deprecated in GTK 4.10

### Dialog and Chooser Widgets
- **Dialog** → Use `AlertDialog`, `MessageDialog`, or custom dialogs
- **MessageDialog** → Use `AlertDialog`
- **FileChooserDialog** → Use `FileDialog`
- **FileChooserNative** → Use `FileDialog`
- **FileChooserWidget** → Use `FileDialog`
- **ColorChooserDialog** → Use `ColorDialog`
- **ColorChooserWidget** → Use `ColorDialog`
- **ColorButton** → Use `ColorDialogButton`
- **FontChooserDialog** → Use `FontDialog`
- **FontChooserWidget** → Use `FontDialog`
- **FontButton** → Use `FontDialogButton`

### Application Chooser Widgets
- **AppChooserButton** → Use system file associations
- **AppChooserDialog** → Use system file associations
- **AppChooserWidget** → Use system file associations

### Combo Boxes
- **ComboBox** → Use `DropDown`
- **ComboBoxText** → Use `DropDown` with `StringList`

### Tree/List Widgets (TreeView family)
- **TreeView** → Use `ListView`, `ColumnView`, or `GridView`
- **TreeViewColumn** → Use `ColumnView` columns
- **TreeStore** → Use `ListStore` with `TreeListModel`
- **ListStore** → Use `GListModel` implementations
- **TreeModel** → Use `GListModel`
- **TreeModelFilter** → Use `FilterListModel`
- **TreeModelSort** → Use `SortListModel`
- **TreeSelection** → Use selection models (`SingleSelection`, `MultiSelection`)
- **IconView** → Use `GridView`

### Cell Renderers (entire family)
- **CellArea**, **CellAreaBox**, **CellAreaContext** → Use list item factories
- **CellRenderer**, **CellRendererText**, **CellRendererPixbuf** → Use `ListItemFactory`
- **CellRendererToggle**, **CellRendererCombo**, **CellRendererSpin** → Use `ListItemFactory`
- **CellRendererAccel**, **CellRendererProgress**, **CellRendererSpinner** → Use `ListItemFactory`
- **CellView** → Use `GridView` or `ListView`

### Other Widgets
- **Assistant** → Use custom navigation with `NavigationView`
- **AssistantPage** → Not needed
- **InfoBar** → Use `AlertDialog` or custom banners
- **StatusBar** → Use `ActionBar` or custom status areas
- **LockButton** → Handle authorization manually
- **VolumeButton** → Use custom volume controls
- **StyleContext** → Use CSS classes and direct styling
- **EntryCompletion** → Use `Popover` with search results

### Interfaces
- **AppChooser** → Use system integration
- **ColorChooser** → Use `ColorDialog`
- **FileChooser** → Use `FileDialog`
- **FontChooser** → Use `FontDialog`
- **CellEditable**, **CellLayout** → Use list item factories
- **TreeDragSource**, **TreeDragDest** → Use modern drag-and-drop
- **TreeModel**, **TreeSortable** → Use `GListModel`

## Deprecated in GTK 4.18
- **ShortcutsWindow** → Use `HelpDialog` or custom help
- **ShortcutsSection**, **ShortcutsGroup** → Custom help sections
- **ShortcutsShortcut**, **ShortcutLabel** → Custom shortcut displays

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

### GTK4 Dialog Migration
```vala
// OLD (deprecated)
var dialog = new Gtk.FileChooserDialog(
    "Choose File", parent_window, FileChooserAction.OPEN,
    "Cancel", ResponseType.CANCEL,
    "Open", ResponseType.ACCEPT
);

// NEW (current)
var dialog = new Gtk.FileDialog();
dialog.open.begin(parent_window, null, (obj, res) => {
    try {
        var file = dialog.open.end(res);
        // Handle selected file
    } catch (Error e) {
        // Handle cancellation/error
    }
});
```

### ComboBox Migration
```vala
// OLD (deprecated)
var combo = new Gtk.ComboBoxText();
combo.append_text("Option 1");
combo.append_text("Option 2");

// NEW (current)
var string_list = new Gtk.StringList(null);
string_list.append("Option 1");
string_list.append("Option 2");
var dropdown = new Gtk.DropDown(string_list, null);
```

### TreeView Migration
```vala
// OLD (deprecated)
var store = new Gtk.ListStore(2, typeof(string), typeof(int));
var tree_view = new Gtk.TreeView.with_model(store);

// NEW (current)
var model = new GLib.ListStore(typeof(MyObject));
var selection = new Gtk.SingleSelection(model);
var list_view = new Gtk.ListView(selection, factory);
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
- [GTK4 Documentation](https://docs.gtk.org/gtk4/)
- [Libadwaita Documentation](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/)
- [GTK Migration Guide](https://docs.gtk.org/gtk4/migrating-3to4.html)
- [Migration Guide to Adaptive Dialogs](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/migrating-to-adaptive-dialogs.html)
- [Migration Guide to Breakpoints](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/migrating-to-breakpoints.html)
