#!/usr/bin/env python3
"""
Debug the real application by adding temporary debugging to understand
why the metronome beats aren't triggering audio.
"""

import sys
import os
sys.path.insert(0, '/app/lib/python3.12/site-packages')

# Import the actual main window class to test
from src.main_window import TempoWindow
from src.audio import MetronomeAudio, AudioConfig

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, GLib

class DebugApp(Adw.Application):
    """Debug version of the Tempo application."""
    
    def __init__(self):
        super().__init__(application_id="io.github.tobagin.tempo.debug")
        
    def do_activate(self):
        """Activate the application."""
        print("=== DEBUG APP ACTIVATING ===")
        
        window = TempoWindow(application=self)
        window.present()
        
        # Add debugging after window is shown
        GLib.timeout_add(2000, self.start_debug_test, window)
        
    def start_debug_test(self, window):
        """Start a debug test after the window is fully loaded."""
        print("=== STARTING DEBUG TEST ===")
        
        # Check if audio system is initialized
        if window.audio:
            print(f"Audio system is initialized: {window.audio.is_initialized}")
            
            # Test audio directly
            print("Testing audio directly...")
            window.audio.play_click(False)
            GLib.timeout_add(500, lambda: window.audio.play_click(True))
            
        else:
            print("No audio system found!")
            
        # Check metronome system
        if window.metronome:
            print(f"Metronome available: {window.metronome.beat_callback is not None}")
            print(f"Metronome running: {window.metronome.state.is_running}")
            
            # Try to simulate clicking the play button
            GLib.timeout_add(2000, self.simulate_play_click, window)
        else:
            print("No metronome found!")
            
        return False
        
    def simulate_play_click(self, window):
        """Simulate clicking the play button."""
        print("=== SIMULATING PLAY BUTTON CLICK ===")
        
        # Call the play button handler directly
        window._on_play_clicked(window.play_button)
        
        # Check state after clicking
        GLib.timeout_add(1000, self.check_running_state, window)
        
        return False
        
    def check_running_state(self, window):
        """Check if metronome is running after play click."""
        print("=== CHECKING RUNNING STATE ===")
        
        if window.metronome:
            print(f"Metronome running: {window.metronome.state.is_running}")
            print(f"Beat callback set: {window.metronome.beat_callback is not None}")
            
            if window.metronome.state.is_running:
                print("Metronome should be playing - waiting for beats...")
                # Let it run for a few beats
                GLib.timeout_add(5000, self.stop_test, window)
            else:
                print("ERROR: Metronome not running after play click!")
        
        return False
        
    def stop_test(self, window):
        """Stop the test."""
        print("=== STOPPING TEST ===")
        
        if window.metronome and window.metronome.state.is_running:
            window._on_play_clicked(window.play_button)  # Stop metronome
            
        # Quit after a moment
        GLib.timeout_add(1000, self.quit)
        return False

def main():
    """Main function."""
    app = DebugApp()
    app.run()

if __name__ == "__main__":
    main()