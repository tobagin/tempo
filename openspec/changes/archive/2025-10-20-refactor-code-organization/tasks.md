# Implementation Tasks

## 1. Preparation
- [x] 1.1 Verify clean working tree with `git status`
- [x] 1.2 Create feature branch: `git checkout -b refactor/code-organization`
- [x] 1.3 Run baseline build: `./scripts/build.sh` to confirm everything works
- [x] 1.4 Document current file structure for reference

## 2. Create Source Directory Structure
- [x] 2.1 Create subdirectories: `mkdir -p src/windows src/dialogs src/utils`
- [x] 2.2 Verify directories created successfully with `ls -la src/`

## 3. Rename and Relocate Vala Source Files
- [x] 3.1 Move main window: `git mv src/main_window.vala src/windows/MainWindow.vala`
- [x] 3.2 Move preferences dialog: `git mv src/preferences_dialog.vala src/dialogs/PreferencesDialog.vala`
- [x] 3.3 Move shortcuts dialog: `git mv src/keyboard_shortcuts_dialog.vala src/dialogs/KeyboardShortcutsDialog.vala`
- [x] 3.4 Move metronome engine: `git mv src/metronome_engine.vala src/utils/MetronomeEngine.vala`
- [x] 3.5 Move tap tempo: `git mv src/tap_tempo.vala src/utils/TapTempo.vala`
- [x] 3.6 Rename main entry point: `git mv src/main.vala src/Main.vala`
- [x] 3.7 Verify all files moved: `git status` and `ls -R src/`

## 4. Update Source Build Configuration
- [x] 4.1 Read current `/src/meson.build` to understand vala_sources list
- [x] 4.2 Update vala_sources list with new file paths:
  - `'Main.vala'`
  - `'windows/MainWindow.vala'`
  - `'dialogs/PreferencesDialog.vala'`
  - `'dialogs/KeyboardShortcutsDialog.vala'`
  - `'utils/MetronomeEngine.vala'`
  - `'utils/TapTempo.vala'`
- [x] 4.3 Verify meson.build syntax is correct

## 5. Evaluate UI Directory Organization
- [x] 5.1 Review current `/data/ui` structure (3 Blueprint files)
- [x] 5.2 Decide if subdirectory organization provides clear value
- [x] 5.3 Document decision rationale

## 6. Reorganize UI Files (If Decision is Yes)
- [x] 6.1 Create UI subdirectories: `mkdir -p data/ui/windows data/ui/dialogs`
- [x] 6.2 Move main window UI: `git mv data/ui/main_window.blp data/ui/windows/main_window.blp`
- [x] 6.3 Move preferences dialog UI: `git mv data/ui/preferences_dialog.blp data/ui/dialogs/preferences_dialog.blp`
- [x] 6.4 Move shortcuts dialog UI: `git mv data/ui/keyboard_shortcuts_dialog.blp data/ui/dialogs/keyboard_shortcuts_dialog.blp`
- [x] 6.5 Update `/data/meson.build` ui_files list with new paths
- [x] 6.6 Verify all UI files moved: `git status` and `ls -R data/ui/`

## 7. Build System Validation
- [x] 7.1 Clean build directory: `rm -rf _build`
- [x] 7.2 Run development build: `./scripts/build.sh --dev`
- [x] 7.3 Verify build completes without errors
- [x] 7.4 Check for any compilation warnings
- [x] 7.5 Verify generated files are in correct locations

## 8. Runtime Testing
- [x] 8.1 Launch development app: `flatpak run io.github.tobagin.tempo.Devel`
- [x] 8.2 Verify main window displays correctly
- [x] 8.3 Open preferences dialog and verify it loads
- [x] 8.4 Open keyboard shortcuts dialog and verify it loads
- [x] 8.5 Test basic metronome functionality (start/stop)
- [x] 8.6 Test tap tempo feature
- [x] 8.7 Verify all UI elements render properly

## 9. Automated Validation
- [x] 9.1 Run validation script: `./scripts/validate-automation.sh` (if exists)
- [x] 9.2 Address any validation failures
- [x] 9.3 Verify all checks pass

## 10. Git Commit and Review
- [x] 10.1 Review staged changes: `git status` and `git diff --staged`
- [x] 10.2 Verify all file moves are tracked as renames (not delete+add)
- [x] 10.3 Create atomic commit with descriptive message:
  ```
  refactor: adopt PascalCase naming and organize source structure

  - Rename all Vala files to PascalCase (Vala community convention)
  - Organize src/ into windows/, dialogs/, utils/ subdirectories
  - [Include if done] Organize data/ui/ into matching subdirectories
  - Update meson.build files to reference new paths

  No functional changes - pure structural refactor to improve
  code discoverability and align with GNOME/Vala best practices.
  ```
- [x] 10.4 Verify commit shows renames: `git show --stat`

## 11. Production Build Verification
- [x] 11.1 Run production build: `./scripts/build.sh`
- [x] 11.2 Verify production build completes successfully
- [x] 11.3 Test production flatpak if possible

## 12. Documentation Updates
- [x] 12.1 Check if `README.md` references file structure - update if needed
- [x] 12.2 Check if `PLANNING.md` needs directory structure updates
- [x] 12.3 Update any development documentation referencing file paths

## 13. Final Review
- [x] 13.1 Confirm all tasks completed successfully
- [x] 13.2 Run final smoke test of application
- [x] 13.3 Push branch: `git push -u origin refactor/code-organization`
- [x] 13.4 Create pull request for review
- [x] 13.5 Address any review feedback

## Validation Criteria
✓ All Vala files renamed to PascalCase
✓ Source files organized into subdirectories
✓ Build completes without errors
✓ Application launches and runs correctly
✓ All UI dialogs and windows load properly
✓ Git history preserved through `git mv`
✓ Meson build configuration updated correctly
✓ No functional behavior changes
