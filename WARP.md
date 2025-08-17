# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**Tempo** is a modern metronome application for musicians built with Vala, GTK4, and Libadwaita. It provides precise timing, customizable settings, and a distraction-free user experience. This repository (`tempo-vala`) is a fork/continuation of the original Tempo project, maintaining the same Vala codebase but as an independent development branch.

### Key Features
- Precise sub-millisecond timing with drift-free engine
- Customizable tempo (40-240 BPM) with tap tempo support
- Time signature control and visual beat indicators
- Low-latency GStreamer audio pipeline
- Modern GTK4/Libadwaita interface
- Flatpak packaging for distribution

## Development Environment Setup

### Prerequisites
- Vala compiler (`valac`)
- GTK4 development libraries (>= 4.10.0)
- Libadwaita development libraries (>= 1.5)
- GStreamer development libraries (>= 1.18)
- Blueprint compiler (for UI compilation)
- Meson build system (>= 0.59.0)
- Flatpak and flatpak-builder (for packaging)

### Installation on Fedora Linux
```bash
sudo dnf install vala vala-tools gtk4-devel libadwaita-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel \
    meson blueprint-compiler flatpak flatpak-builder
```

### GNOME Runtime Setup
```bash
# Install GNOME runtime for Flatpak builds
flatpak install flathub org.gnome.Platform//48 org.gnome.Sdk//48
```

## Common Development Commands

### Building the Project

#### Meson Build (Direct)
```bash
# Initialize build directory
meson setup builddir

# Compile the project
meson compile -C builddir

# Install locally
meson install -C builddir

# Run tests
meson test -C builddir
```

#### Flatpak Build (Recommended)
```bash
# Development build from local sources
./build.sh --dev --install

# Production build
./build.sh --force-clean

# Run the installed Flatpak
flatpak run io.github.tobagin.tempo
```

### Development Workflow
```bash
# Quick Vala compilation check
valac --pkg gtk4 --pkg libadwaita-1 --pkg gstreamer-1.0 \
      --check src/*.vala

# Build and install for testing
./build.sh --dev --install --verbose

# Run from Flatpak
flatpak run io.github.tobagin.tempo

# Clean build artifacts
rm -rf builddir .flatpak-builder repo
```

### Code Quality
```bash
# Syntax check all Vala files
valac --pkg gtk4 --pkg libadwaita-1 --pkg gstreamer-1.0 \
      --check src/*.vala

# Run tests
meson test -C builddir -v
```

## Project Architecture

### Core Components
- **`TempoApplication`** (`main.vala`) - Main application class inheriting from `Adw.Application`
- **`MetronomeEngine`** (`metronome_engine.vala`) - Timing engine with precision beat generation
- **`TapTempo`** (`tap_tempo.vala`) - Tap tempo calculation and BPM detection

### File Structure
```
tempo-vala/
├── src/                    # Vala source files
│   ├── main.vala          # Application entry point
│   ├── metronome_engine.vala  # Core timing engine
│   └── tap_tempo.vala     # Tap tempo functionality
├── data/                   # Application data
│   ├── ui/                # Blueprint UI files
│   ├── icons/             # Application icons
│   └── resources/         # GResource configuration
├── tests/                  # Unit tests
├── packaging/              # Flatpak manifests
│   ├── io.github.tobagin.tempo.yml        # Production manifest
│   └── io.github.tobagin.tempo-local.yml  # Development manifest
├── po/                     # Translations
├── build.sh               # Convenience build script
└── meson.build            # Build configuration
```

### Architecture Patterns
- **MVC-like Structure**: Model (MetronomeEngine), View (GTK4/Libadwaita), Controller (TempoApplication)
- **GObject Signals**: Used for beat events and state changes
- **GStreamer Pipeline**: Low-latency audio with precise timing
- **Composite Templates**: Blueprint UI files linked to Vala classes
- **GSettings**: Persistent configuration management
- **GResource**: Compiled binary assets

### Key Dependencies
- `gtk4` (>= 4.10.0) - UI toolkit
- `libadwaita-1` (>= 1.5) - Modern GNOME widgets
- `gstreamer-1.0` (>= 1.18) - Audio pipeline
- `gstreamer-audio-1.0` - Audio-specific GStreamer components
- `glib-2.0`, `gobject-2.0` - Core GLib functionality

### Error Handling
The project uses custom `MetronomeError` exceptions for timing engine errors and follows Vala/GLib error handling patterns.

## Build System Details

### Flatpak Manifests
- **Production** (`packaging/io.github.tobagin.tempo.yml`): Builds from git tags for reproducible releases
- **Local** (`packaging/io.github.tobagin.tempo-local.yml`): Builds from local directory for development

### Build Script Usage
```bash
# Show help
./build.sh --help

# Development workflow
./build.sh --dev --install --verbose

# Clean production build
./build.sh --force-clean

# Install after build
./build.sh --dev --install
```

## Testing and Quality

### Running Tests
```bash
# Run all tests with Meson
meson test -C builddir -v

# Run specific test
meson test -C builddir test_metronome_engine
```

### Development Principles
- Follow GNOME coding conventions
- Use precise timing algorithms with drift compensation
- Implement proper signal handling for UI responsiveness
- Maintain low-latency audio pipeline performance
- Ensure thread safety for timing-critical components

## Git Workflow

### Repository Setup
```bash
# Add original repository as upstream (if desired)
git remote add upstream https://github.com/tobagin/Tempo.git

# Create feature branches
git checkout -b feature/new-timing-algorithm

# Commit with descriptive messages
git commit -m "metronome: improve drift compensation in timing engine"
```

### Branching Strategy
- `main` - Stable development branch
- `feature/*` - New features and enhancements
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates
