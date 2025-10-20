# Contributing to Tempo

Thank you for your interest in contributing to Tempo! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing Requirements](#testing-requirements)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Feature Requests](#feature-requests)
- [Bug Reports](#bug-reports)
- [Translation Contributions](#translation-contributions)

---

## Code of Conduct

This project follows the standard open-source code of conduct. Please be respectful, inclusive, and constructive in all interactions.

### Our Standards

- **Be respectful**: Treat everyone with respect and kindness
- **Be inclusive**: Welcome contributors of all backgrounds and skill levels
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Remember that everyone is learning

---

## Getting Started

Before contributing, please:

1. **Read the documentation**: Familiarize yourself with the project by reading [README.md](README.md)
2. **Check existing issues**: Look through [existing issues](https://github.com/tobagin/tempo/issues) to avoid duplicates
3. **Review the roadmap**: Check [TODO.md](TODO.md) for planned features and priorities
4. **Set up your environment**: Follow the [Development Setup](#development-setup) instructions

---

## Development Setup

### Prerequisites

Ensure you have the following installed:

- **Python 3.8+** (for build scripts)
- **Vala Compiler** (`valac`)
- **GTK4 development libraries** (`libgtk-4-dev`)
- **Libadwaita development libraries** (`libadwaita-1-dev`)
- **GStreamer development libraries** (`libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev`)
- **Meson build system** (`meson`)
- **Blueprint compiler** (`blueprint-compiler`)
- **Git**

#### Ubuntu/Debian
```bash
sudo apt install git valac libgtk-4-dev libadwaita-1-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    meson blueprint-compiler python3-dev
```

#### Fedora
```bash
sudo dnf install git vala gtk4-devel libadwaita-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel \
    meson blueprint-compiler python3-devel
```

### Clone the Repository

```bash
git clone https://github.com/tobagin/tempo.git
cd tempo
```

### Build for Development

Use the convenience build script:

```bash
# Development build with local installation
./scripts/build.sh --dev --install

# Run the application
flatpak run io.github.tobagin.tempo.Devel
```

**Note**: Development builds use the app ID `io.github.tobagin.tempo.Devel` to avoid conflicts with production installations.

### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage report
pytest tests/ -v --cov=src --cov-report=html

# Run specific test file
pytest tests/test_metronome.py -v
```

### Code Quality Checks

```bash
# Linting (if using Ruff for Vala - currently Python only)
ruff check src/ tests/

# Type checking (if using MyPy - currently Python only)
mypy src/ --strict

# Auto-fix issues
ruff check src/ tests/ --fix
```

---

## How to Contribute

There are many ways to contribute to Tempo:

### 1. Code Contributions
- Implement new features from [TODO.md](TODO.md)
- Fix bugs listed in [GitHub Issues](https://github.com/tobagin/tempo/issues)
- Improve performance or code quality
- Add unit tests for existing code

### 2. Documentation
- Improve README.md or other documentation
- Add code comments and docstrings
- Create tutorials or guides
- Update screenshots

### 3. Testing
- Report bugs with detailed reproduction steps
- Test on different Linux distributions
- Verify fixes and new features

### 4. Design
- Create new icons or graphics
- Improve UI/UX design
- Suggest accessibility improvements

### 5. Translations
- Add translations for new languages
- Improve existing translations
- See [Translation Contributions](#translation-contributions)

---

## Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/tempo.git
cd tempo
git remote add upstream https://github.com/tobagin/tempo.git
```

### 2. Create a Feature Branch

```bash
# Create a branch for your feature or bugfix
git checkout -b feature/your-feature-name

# Or for bug fixes:
git checkout -b fix/bug-description
```

**Branch naming conventions**:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions or improvements
- `i18n/` - Translation updates

### 3. Make Your Changes

- Write clean, well-documented code
- Follow the [Code Style Guidelines](#code-style-guidelines)
- Add tests for new functionality
- Update documentation as needed
- Keep commits focused and atomic

### 4. Test Your Changes

```bash
# Build and test locally
./scripts/build.sh --dev --install
flatpak run io.github.tobagin.tempo.Devel

# Run unit tests
pytest tests/ -v

# Test on different GTK themes (Light/Dark)
# Test keyboard shortcuts
# Test all UI interactions
```

### 5. Commit Your Changes

```bash
git add .
git commit -m "type: brief description"
```

See [Commit Message Guidelines](#commit-message-guidelines) for details.

### 6. Keep Your Branch Updated

```bash
# Fetch latest changes from upstream
git fetch upstream
git rebase upstream/main
```

### 7. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

---

## Code Style Guidelines

### Vala Code Style

Follow these conventions for consistency:

#### Naming Conventions

```vala
// Classes: PascalCase
public class MetronomeEngine : Object {

    // Private fields: lowercase with underscores
    private uint timeout_id;
    private double current_bpm;

    // Public properties: lowercase with underscores
    public bool is_running { get; private set; }

    // Methods: lowercase with underscores
    public void start_metronome() {
        // Implementation
    }

    // Constants: UPPERCASE with underscores
    private const int MAX_BPM = 240;
    private const int MIN_BPM = 40;
}

// Signals: lowercase with underscores
public signal void beat_occurred(int beat_number, bool is_downbeat);
```

#### Indentation and Formatting

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 100 characters (prefer 80)
- **Braces**: Opening brace on same line
- **Spacing**: Space after keywords, around operators

```vala
// Good
if (condition) {
    do_something();
} else {
    do_something_else();
}

// Bad
if(condition)
{
    do_something();
}
```

#### Comments and Documentation

```vala
/**
 * Brief description of the class.
 *
 * Detailed description if needed.
 */
public class ExampleClass {

    /**
     * Brief description of the method.
     *
     * @param param1 Description of parameter
     * @return Description of return value
     */
    public int example_method(string param1) {
        // Inline comment explaining complex logic
        return 42;
    }
}
```

#### File Organization

```vala
// 1. License header (if applicable)
// 2. Using directives
using Gtk;
using Adw;

// 3. Namespace (if used)
namespace Tempo {

    // 4. Class definition
    public class ClassName {
        // 5. Constants
        // 6. Signals
        // 7. Properties
        // 8. Constructor
        // 9. Public methods
        // 10. Private methods
    }
}
```

### Blueprint (.blp) Style

- Use 2-space indentation
- Keep hierarchy clear with proper indentation
- Group related properties together
- Comment complex UI structures

```blueprint
using Gtk 4.0;
using Adw 1;

template $TempoWindow : Adw.ApplicationWindow {
  title: _("Tempo");
  default-width: 400;
  default-height: 500;

  content: Adw.ToolbarView {
    [top]
    Adw.HeaderBar {
      [end]
      MenuButton menu_button {
        icon-name: "open-menu-symbolic";
        menu-model: primary_menu;
      }
    }

    content: Box {
      orientation: vertical;
      spacing: 12;

      // Widgets here
    };
  };
}
```

### GSettings Schema Style

```xml
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
  <schema id="io.github.tobagin.tempo" path="/io/github/tobagin/tempo/">
    <key name="tempo" type="i">
      <default>120</default>
      <range min="40" max="240"/>
      <summary>Metronome tempo</summary>
      <description>The current tempo in beats per minute (BPM)</description>
    </key>
  </schema>
</schemalist>
```

---

## Testing Requirements

### Unit Test Guidelines

All new features and bug fixes **must** include unit tests.

#### Test Structure

```python
# tests/test_feature.py
import pytest
from tempo.module import ClassName

class TestClassName:
    """Test suite for ClassName."""

    def test_expected_behavior(self):
        """Test that feature works as expected."""
        obj = ClassName()
        result = obj.method()
        assert result == expected_value

    def test_edge_case(self):
        """Test edge case handling."""
        obj = ClassName()
        result = obj.method(edge_case_input)
        assert result is not None

    def test_error_handling(self):
        """Test error handling."""
        obj = ClassName()
        with pytest.raises(ValueError):
            obj.method(invalid_input)
```

#### Test Coverage Requirements

- **Minimum coverage**: 70% for new code
- **Target coverage**: 85% or higher
- Include tests for:
  - Expected behavior (happy path)
  - Edge cases
  - Error conditions
  - Boundary values

#### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=src --cov-report=html

# Open coverage report
firefox htmlcov/index.html
```

---

## Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
type(scope): brief description

Detailed explanation (optional)

Fixes #issue_number (if applicable)
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build scripts)
- `perf`: Performance improvements
- `i18n`: Translation updates

### Scopes (optional)

- `ui`: User interface changes
- `audio`: Audio system changes
- `engine`: Metronome engine changes
- `settings`: Settings/preferences changes
- `build`: Build system changes

### Examples

```bash
# Feature
feat(ui): add subdivisions toggle to main window

# Bug fix
fix(audio): prevent audio overlap on rapid tempo changes

Fixes #42

# Documentation
docs: update README with new keyboard shortcuts

# Refactoring
refactor(engine): simplify beat calculation logic

# Translation
i18n: add French translation
```

### Commit Message Best Practices

- Use imperative mood ("add" not "added")
- Keep first line under 72 characters
- Reference issues and pull requests
- Explain **why** not **what** in the body
- One logical change per commit

---

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new features
- [ ] Documentation updated (README, comments, etc.)
- [ ] Commits are well-formatted and atomic
- [ ] Branch is up-to-date with `main`

### Pull Request Template

When creating a pull request, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement
- [ ] Translation

## Related Issue
Fixes #(issue number)

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Tested on: [distribution/version]

## Screenshots (if UI changes)
[Add screenshots here]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests passing
```

### Review Process

1. **Automated checks**: CI/CD pipeline runs tests and linting
2. **Code review**: Maintainer(s) review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, maintainer will merge

### After Merge

- Your contribution will be included in the next release
- You'll be credited in CHANGELOG.md
- Thank you for contributing!

---

## Feature Requests

### Proposing New Features

1. **Check TODO.md**: Feature might already be planned
2. **Open an issue**: Use the "Feature Request" template
3. **Describe the feature**:
   - What problem does it solve?
   - Who benefits from this feature?
   - How should it work?
   - Are there examples in other apps?
4. **Discuss**: Engage with maintainers and community

### Major Features

For significant features (architecture changes, new subsystems), consider:

1. **Creating an OpenSpec proposal**: See `@/openspec/AGENTS.md`
2. **Writing a design document**: Explain architecture and implementation plan
3. **Getting consensus**: Discuss with maintainers before implementing

---

## Bug Reports

### How to Report Bugs

1. **Check existing issues**: Bug might already be reported
2. **Use the bug template**: Provide all requested information
3. **Include details**:
   - Tempo version (from About dialog)
   - Linux distribution and version
   - Desktop environment (GNOME, KDE, etc.)
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots or video (if applicable)
   - Error messages or logs

### Example Bug Report

```markdown
**Tempo Version**: 1.3.0
**Distribution**: Fedora 40
**Desktop**: GNOME 46

**Description**
Audio clicks when using custom sound files.

**Steps to Reproduce**
1. Go to Preferences > Audio
2. Enable "Use custom sounds"
3. Select a custom WAV file
4. Start metronome

**Expected Behavior**
Smooth audio playback without clicks.

**Actual Behavior**
Audio clicks/pops between beats.

**Screenshots**
[Attach screenshot]

**Additional Context**
Only happens with custom sounds, not default sounds.
```

---

## Translation Contributions

### Adding a New Language

1. **Check existing translations**: See `po/` directory
2. **Create translation file**:
   ```bash
   cd po
   msginit --locale=LANG_CODE --input=tempo.pot
   ```
3. **Translate strings**: Edit the `.po` file
4. **Test translation**:
   ```bash
   ./scripts/build.sh --dev --install
   LANG=LANG_CODE flatpak run io.github.tobagin.tempo.Devel
   ```
5. **Submit pull request**: Include the new `.po` file

### Updating Existing Translations

1. **Update POT template**:
   ```bash
   ninja -C builddir tempo-update-po
   ```
2. **Edit `.po` file**: Update outdated strings
3. **Test and submit**

### Translation Guidelines

- Use appropriate musical terminology
- Keep translations concise (UI space is limited)
- Test on actual GTK4 interface
- Include translator credits in about dialog

---

## Questions?

If you have questions about contributing:

- **Documentation**: Check [README.md](README.md) and [TODO.md](TODO.md)
- **Issues**: [Open a question issue](https://github.com/tobagin/tempo/issues/new)
- **Discussions**: Use [GitHub Discussions](https://github.com/tobagin/tempo/discussions)

---

## License

By contributing to Tempo, you agree that your contributions will be licensed under the GNU General Public License v3.0 or later (GPLv3+).

---

## Acknowledgments

Thank you for contributing to Tempo! Every contribution, no matter how small, helps make this project better for musicians everywhere.

**Happy coding!** 🎵
