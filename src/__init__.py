"""
Tempo - A modern metronome application for musicians.

This package provides a GTK4-based metronome application with precise timing,
customizable tempo and time signatures, and low-latency audio playback.
"""

__version__ = "1.0.7"
__author__ = "Thiago Fernandes"
__email__ = "tempo@example.com"
__license__ = "GPL-3.0-or-later"
__description__ = "A modern metronome application for musicians"

# Version information
VERSION = __version__
APPLICATION_ID = "io.github.tobagin.tempo"
APPLICATION_NAME = "Tempo"

# Resource paths
RESOURCE_PREFIX = "/io/github/tobagin/tempo"
SCHEMA_ID = APPLICATION_ID

# Export main components (UI components imported lazily to avoid template loading issues)
from .metronome import MetronomeEngine, MetronomeState, TapTempo
from .audio import MetronomeAudio, AudioConfig

# Note: main_window and preferences_dialog are NOT imported here to avoid 
# early template validation before gresource is loaded

__all__ = [
    "MetronomeEngine",
    "MetronomeState", 
    "TapTempo",
    "MetronomeAudio",
    "AudioConfig",
    "VERSION",
    "APPLICATION_ID",
    "APPLICATION_NAME",
    "RESOURCE_PREFIX",
    "SCHEMA_ID",
]