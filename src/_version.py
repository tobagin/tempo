"""
Version information for the Tempo metronome application.
"""

__version__ = "1.0.0"
__version_info__ = (1, 0, 0)

# Build information (can be updated by build system)
__build_date__ = "2025-01-01"
__git_hash__ = "unknown"

# Version components
VERSION_MAJOR = 1
VERSION_MINOR = 0
VERSION_PATCH = 0

# Version string
VERSION_STRING = f"{VERSION_MAJOR}.{VERSION_MINOR}.{VERSION_PATCH}"

def get_version():
    """Get version string."""
    return VERSION_STRING

def get_version_info():
    """Get version tuple."""
    return __version_info__

def get_build_info():
    """Get build information."""
    return {
        "version": VERSION_STRING,
        "build_date": __build_date__,
        "git_hash": __git_hash__
    }