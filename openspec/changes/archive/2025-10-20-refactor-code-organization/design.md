# Code Organization Refactor - Design

## Context

The Tempo project currently has 6 Vala source files in a flat `/src` directory using snake_case naming. As a GNOME/GTK4 application written in Vala, the codebase should follow established Vala community conventions:
- PascalCase for class files (matches class names inside)
- Organized directory structure for related components

**Current state:**
- `/src/main.vala` - Application entry point
- `/src/main_window.vala` - Main window class
- `/src/metronome_engine.vala` - Timing engine
- `/src/tap_tempo.vala` - Tap tempo calculator
- `/src/preferences_dialog.vala` - Preferences dialog
- `/src/keyboard_shortcuts_dialog.vala` - Shortcuts dialog

**Constraints:**
- Must maintain Meson build system compatibility
- Must preserve GResource template binding (`@Gtk.Template` annotations)
- Must maintain git history through proper `git mv` usage
- Blueprint files maintain snake_case (per project conventions)
- No changes to class names or behavior

## Goals / Non-Goals

**Goals:**
- Adopt Vala community standard of PascalCase file naming
- Organize source files into logical subdirectories (dialogs, utils, windows)
- Improve code discoverability and maintainability
- Align with GNOME/Vala ecosystem best practices
- Evaluate and optionally organize `/data/ui` structure

**Non-Goals:**
- Changing class names (already PascalCase)
- Modifying application behavior or functionality
- Changing Blueprint file naming (stays snake_case)
- Creating additional abstractions or refactoring logic
- Introducing new dependencies or patterns

## Decisions

### Decision 1: PascalCase for All Vala Files
**Choice:** Rename all `.vala` files to match their internal class name in PascalCase

**Rationale:**
- Standard Vala convention (seen in GNOME core apps, libadwaita examples)
- Creates 1:1 correspondence between filename and class name
- Improves code navigation and discoverability
- Aligns with object-oriented conventions (file == class)

**Alternatives considered:**
- Keep snake_case: Rejected - conflicts with Vala ecosystem norms
- Mixed approach: Rejected - inconsistency would be confusing

### Decision 2: Three-Tier Directory Structure
**Choice:** Organize `/src` into subdirectories by component type:
```
/src/
├── Main.vala (entry point, stays at root)
├── windows/
│   └── MainWindow.vala
├── dialogs/
│   ├── PreferencesDialog.vala
│   └── KeyboardShortcutsDialog.vala
└── utils/
    ├── MetronomeEngine.vala
    └── TapTempo.vala
```

**Rationale:**
- Clear separation of concerns (windows, dialogs, utilities)
- Scales well as project grows (e.g., future settings manager → utils)
- Common pattern in GTK/GNOME applications
- Small project size (6 files) makes this manageable
- Main.vala at root emphasizes it as entry point

**Alternatives considered:**
- Flat structure: Rejected - doesn't improve discoverability
- Domain-based (audio, ui, timing): Rejected - over-engineered for current size
- Single "src/app/" directory: Rejected - adds nesting without value

### Decision 3: Optional UI Reorganization
**Choice:** Evaluate organizing `/data/ui` during implementation; only reorganize if clear value

**Rationale:**
- Only 3 Blueprint files currently
- Mirror structure may improve maintainability
- Blueprint files maintain snake_case naming (established convention)
- Decision deferred to implementation phase to assess actual benefit

**Possible structure:**
```
/data/ui/
├── windows/
│   └── main_window.blp
└── dialogs/
    ├── preferences_dialog.blp
    └── keyboard_shortcuts_dialog.blp
```

### Decision 4: Git History Preservation
**Choice:** Use `git mv` for all file relocations

**Rationale:**
- Preserves git blame and history tracking
- Explicit rename tracking in git
- Standard practice for refactoring commits

**Implementation:**
```bash
git mv src/main_window.vala src/windows/MainWindow.vala
```

### Decision 5: Meson Build Updates
**Choice:** Update `vala_sources` list and `ui_files` list in meson.build

**Rationale:**
- Meson uses explicit file lists, requires manual updates
- Source directory remains `/src` (subdirectories relative to it)
- Blueprint compilation targets remain relative to `/data`

**Example:**
```meson
vala_sources = [
  'Main.vala',
  'windows/MainWindow.vala',
  'dialogs/PreferencesDialog.vala',
  'dialogs/KeyboardShortcutsDialog.vala',
  'utils/MetronomeEngine.vala',
  'utils/TapTempo.vala',
  config_vala,
]
```

## Risks / Trade-offs

### Risk: Breaking Template Bindings
**Impact:** GtkTemplate annotations may fail to locate UI files
**Mitigation:**
- Template binding uses GResource paths (not file system paths)
- GResource paths remain stable (`/io/github/tobagin/tempo/main_window.ui`)
- Test build immediately after refactor

### Risk: Git Blame Loss
**Impact:** Historical authorship tracking may break
**Mitigation:**
- Use `git mv` exclusively (tracked renames)
- Create single atomic commit for all renames
- Document in commit message with "Refactor:" prefix

### Risk: Merge Conflicts
**Impact:** Active branches may experience conflicts
**Mitigation:**
- Check for active branches before refactor
- Coordinate with any parallel development
- Provide clear migration guide in commit message

### Trade-off: Initial Learning Curve
**Impact:** Contributors need to learn new structure
**Benefit:** Long-term discoverability and maintainability
**Justification:** Small one-time cost for ongoing benefits

### Trade-off: More Directories
**Impact:** Adds 2-3 subdirectories to `/src`
**Benefit:** Clear organization and future scalability
**Justification:** Common pattern in mature GNOME projects

## Migration Plan

### Phase 1: Preparation
1. Ensure clean working tree (`git status`)
2. Create feature branch: `refactor/code-organization`
3. Run full build to establish baseline: `./scripts/build.sh`
4. Document current structure in commit message

### Phase 2: Source File Reorganization
1. Create subdirectories:
   ```bash
   mkdir -p src/windows src/dialogs src/utils
   ```

2. Move and rename files with `git mv`:
   ```bash
   git mv src/main_window.vala src/windows/MainWindow.vala
   git mv src/preferences_dialog.vala src/dialogs/PreferencesDialog.vala
   git mv src/keyboard_shortcuts_dialog.vala src/dialogs/KeyboardShortcutsDialog.vala
   git mv src/metronome_engine.vala src/utils/MetronomeEngine.vala
   git mv src/tap_tempo.vala src/utils/TapTempo.vala
   git mv src/main.vala src/Main.vala
   ```

3. Update `/src/meson.build` vala_sources list

### Phase 3: UI Reorganization (If Beneficial)
1. Evaluate whether UI organization provides value
2. If yes, create subdirectories in `/data/ui`
3. Move Blueprint files with `git mv` (no renaming - keep snake_case)
4. Update `/data/meson.build` ui_files list

### Phase 4: Validation
1. Build project: `./scripts/build.sh --dev`
2. Verify no compilation errors
3. Test application launch: `flatpak run io.github.tobagin.tempo.Devel`
4. Verify all UI elements load correctly
5. Run validation script: `./scripts/validate-automation.sh`

### Phase 5: Finalization
1. Review all changes: `git status`, `git diff --staged`
2. Create atomic commit with clear message:
   ```
   refactor: adopt PascalCase naming and organize source structure

   - Rename all Vala files to PascalCase (Vala convention)
   - Organize src/ into windows/, dialogs/, utils/ subdirectories
   - [Optional] Organize data/ui/ into matching subdirectories
   - Update meson.build files for new paths

   No functional changes - pure structural refactor
   ```
3. Test final build on clean checkout
4. Request review and merge

### Rollback Plan
If issues arise during implementation:
1. Discard changes: `git reset --hard HEAD`
2. Return to main branch: `git checkout main`
3. Clean build directory: `rm -rf _build`

If issues arise after merge:
1. Revert commit: `git revert <commit-hash>`
2. Investigate root cause before retry

## Open Questions

1. **Should UI files be organized into subdirectories?**
   - Decision: Evaluate during implementation based on actual benefit
   - Consider: Only 3 files currently - may not justify complexity
   - Action: Implement source reorganization first, assess UI need afterward

2. **Should config.vala.in be renamed to Config.vala.in?**
   - Decision: Leave as-is initially (generated file, different pattern)
   - Rationale: Template files may have different conventions
   - Future: Can be addressed in follow-up if needed

3. **Should subdirectories be added preemptively for future files?**
   - Decision: No - add directories as needed
   - Rationale: YAGNI principle - avoid premature structure
   - Examples: `/src/models/`, `/src/services/` only when needed
