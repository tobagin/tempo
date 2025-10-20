# Code Organization Refactor

## Why

The current codebase uses snake_case naming for Vala source files (`main_window.vala`, `preferences_dialog.vala`), which conflicts with Vala community conventions that prefer PascalCase for class files. Additionally, all source files are currently flat in `/src`, making it difficult to locate and organize related functionality as the project grows. Adopting standard Vala naming conventions (PascalCase for files) and organizing code into logical subdirectories (dialogs, utils, etc.) will improve code discoverability, maintainability, and align with GNOME/Vala ecosystem best practices.

## What Changes

- **File naming**: Rename all Vala source files from `snake_case.vala` to `PascalCase.vala`:
  - `main_window.vala` → `MainWindow.vala`
  - `preferences_dialog.vala` → `PreferencesDialog.vala`
  - `keyboard_shortcuts_dialog.vala` → `KeyboardShortcutsDialog.vala`
  - `metronome_engine.vala` → `MetronomeEngine.vala`
  - `tap_tempo.vala` → `TapTempo.vala`
  - `main.vala` → `Main.vala`

- **Source organization**: Organize `/src` with subdirectories:
  - `/src/dialogs/` - Dialog classes (PreferencesDialog, KeyboardShortcutsDialog)
  - `/src/utils/` - Utility classes (TapTempo, MetronomeEngine)
  - `/src/windows/` - Window classes (MainWindow)
  - `/src/Main.vala` - Application entry point (stays at root)

- **UI organization**: Evaluate organizing `/data/ui` with subdirectories if beneficial:
  - Blueprint files maintain `snake_case.blp` naming (per project conventions)
  - Consider subdirectories like `/data/ui/dialogs/`, `/data/ui/windows/` if it improves clarity
  - Only implement if it provides clear organizational value

- **Build system updates**: Update all `meson.build` files to reference new file paths and structure

- **No class name changes**: Internal class names remain unchanged (already use PascalCase)

## Impact

- **Affected specs**: `code-organization` (new capability being added)
- **Affected code**:
  - `/src/*.vala` - All Vala source files (renamed and relocated)
  - `/src/meson.build` - Source file list updated
  - `/data/ui/*.blp` - Potentially reorganized (evaluation needed)
  - `/data/meson.build` - UI file paths updated if reorganized
  - Git history - File renames tracked with `git mv`
- **Affected systems**: Build system (Meson), GResource compilation, template binding
- **Migration effort**: Low - pure refactoring with no behavior changes
- **Breaking changes**: None - this is internal reorganization only
