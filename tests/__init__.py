"""
Test package for Tempo metronome application.

This package contains unit tests for all components of the metronome application.
"""

import sys
import os

# Add src to path for testing
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src_path = os.path.join(project_root, 'src')
sys.path.insert(0, src_path)

# Test configuration
TEST_DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')
TEST_SOUNDS_DIR = os.path.join(TEST_DATA_DIR, 'sounds')

# Create test data directories if they don't exist
os.makedirs(TEST_SOUNDS_DIR, exist_ok=True)