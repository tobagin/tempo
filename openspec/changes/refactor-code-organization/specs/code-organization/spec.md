# Code Organization Specification

## ADDED Requirements

### Requirement: Vala File Naming Convention
The project SHALL use PascalCase naming for all Vala source files to align with Vala community conventions and improve code discoverability.

#### Scenario: Class file naming matches class name
- **WHEN** a Vala file contains a class (e.g., `MainWindow` class)
- **THEN** the file SHALL be named to match the class name in PascalCase (e.g., `MainWindow.vala`)

#### Scenario: Entry point file naming
- **WHEN** a Vala file serves as the application entry point
- **THEN** the file SHALL be named `Main.vala` in PascalCase

#### Scenario: Utility class file naming
- **WHEN** a Vala file contains a utility class (e.g., `TapTempo` class)
- **THEN** the file SHALL be named to match the class name in PascalCase (e.g., `TapTempo.vala`)

### Requirement: Source Directory Organization
The project SHALL organize Vala source files into logical subdirectories based on component type to improve code maintainability and discoverability.

#### Scenario: Window classes in windows subdirectory
- **WHEN** a Vala class represents a top-level window (e.g., `MainWindow`)
- **THEN** the file SHALL be located in `/src/windows/` subdirectory

#### Scenario: Dialog classes in dialogs subdirectory
- **WHEN** a Vala class represents a dialog (e.g., `PreferencesDialog`, `KeyboardShortcutsDialog`)
- **THEN** the file SHALL be located in `/src/dialogs/` subdirectory

#### Scenario: Utility classes in utils subdirectory
- **WHEN** a Vala class provides utility functionality (e.g., `MetronomeEngine`, `TapTempo`)
- **THEN** the file SHALL be located in `/src/utils/` subdirectory

#### Scenario: Application entry point at source root
- **WHEN** a Vala file serves as the application entry point (`Main.vala`)
- **THEN** the file SHALL remain in the `/src/` root directory to emphasize its role as the entry point

### Requirement: Blueprint File Naming Convention
The project SHALL maintain snake_case naming for all Blueprint UI definition files, consistent with established project conventions and Blueprint ecosystem practices.

#### Scenario: UI file naming remains snake_case
- **WHEN** a Blueprint file defines a UI component (e.g., main window, preferences dialog)
- **THEN** the file SHALL be named using snake_case (e.g., `main_window.blp`, `preferences_dialog.blp`)

#### Scenario: Compiled UI file naming
- **WHEN** a Blueprint file is compiled to GTK UI XML
- **THEN** the output SHALL maintain snake_case naming (e.g., `main_window.ui`, `preferences_dialog.ui`)

### Requirement: UI Directory Organization Decision
The project SHALL evaluate whether to organize Blueprint UI files into logical subdirectories based on maintainability benefits and file count.

#### Scenario: UI files organized when beneficial
- **WHEN** the number of UI files grows beyond a flat structure's maintainability threshold (more than 5 files) OR when subdirectory organization clearly improves navigation
- **THEN** Blueprint files SHALL be organized into subdirectories matching source organization (e.g., `/data/ui/windows/`, `/data/ui/dialogs/`)

#### Scenario: UI files remain flat for simplicity
- **WHEN** the number of UI files is small (5 or fewer files) AND flat structure does not impede navigation
- **THEN** UI files SHALL remain in a flat `/data/ui/` structure to avoid unnecessary complexity

### Requirement: Build System Path Configuration
The build system SHALL correctly reference all source and UI files in their organized locations.

#### Scenario: Meson vala_sources list references organized paths
- **WHEN** Vala source files are located in subdirectories
- **THEN** the `vala_sources` list in `/src/meson.build` SHALL include relative paths from `/src/` (e.g., `'windows/MainWindow.vala'`, `'dialogs/PreferencesDialog.vala'`)

#### Scenario: Meson ui_files list references UI paths
- **WHEN** UI files are organized in subdirectories
- **THEN** the `ui_files` list in `/data/meson.build` SHALL include relative paths from `/data/` (e.g., `'ui/windows/main_window.blp'`)

#### Scenario: GResource paths remain stable
- **WHEN** source or UI files are reorganized on the filesystem
- **THEN** GResource bundle paths SHALL remain unchanged to maintain template binding compatibility (e.g., `/io/github/tobagin/tempo/main_window.ui`)

### Requirement: Git History Preservation
File reorganization SHALL preserve git history through proper use of git move operations.

#### Scenario: File moves tracked as renames
- **WHEN** a file is relocated or renamed during reorganization
- **THEN** the operation SHALL use `git mv` to ensure git tracks the operation as a rename, preserving file history and blame information

#### Scenario: Atomic refactor commit
- **WHEN** completing the code reorganization refactor
- **THEN** all file moves and renames SHALL be committed in a single atomic commit with a clear "refactor:" prefix message

#### Scenario: Commit message documentation
- **WHEN** creating the reorganization commit
- **THEN** the commit message SHALL document all changes (file renames, directory reorganization, build system updates) and explicitly state "No functional changes"

### Requirement: Build and Runtime Validation
The code reorganization SHALL maintain full build compatibility and runtime functionality.

#### Scenario: Clean build after reorganization
- **WHEN** the code reorganization is complete
- **THEN** the project SHALL build successfully without errors using `./scripts/build.sh --dev`

#### Scenario: Application launches successfully
- **WHEN** the reorganized application is built
- **THEN** the application SHALL launch without errors and display the main window correctly

#### Scenario: UI templates load correctly
- **WHEN** the application runs after reorganization
- **THEN** all GtkTemplate-bound UI elements SHALL load and render correctly, including dialogs and windows

#### Scenario: No functional behavior changes
- **WHEN** comparing pre- and post-reorganization application behavior
- **THEN** all application functionality SHALL remain identical, including metronome timing, UI interactions, and user preferences

### Requirement: Documentation Updates
Project documentation SHALL be updated to reflect the new code organization structure.

#### Scenario: README reflects new structure
- **WHEN** README.md references file locations or project structure
- **THEN** documentation SHALL be updated to reflect new file paths and directory organization

#### Scenario: Development documentation updated
- **WHEN** contributor or development documentation references source file locations
- **THEN** documentation SHALL be updated with new directory structure and naming conventions

#### Scenario: Project conventions documented
- **WHEN** the code organization change is complete
- **THEN** `openspec/project.md` SHALL document the PascalCase file naming and subdirectory organization conventions for future development
