#!/usr/bin/env python3
"""
Test the complete callback chain: metronome -> audio in Flatpak environment.
"""

import sys
import time
sys.path.insert(0, '/app/lib/python3.12/site-packages')

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('GLib', '2.0')
from gi.repository import Gtk, GLib, Gio

from src.audio import MetronomeAudio, AudioConfig
from src.metronome import MetronomeEngine

class AudioTestCallback:
    """Test callback that mimics the main window callback."""
    
    def __init__(self, loop):
        self.loop = loop
        self.audio = MetronomeAudio(AudioConfig())
        self.metronome = MetronomeEngine()
        self.metronome.beat_callback = self.on_beat
        self.beat_count = 0
        
    def on_beat(self, beat_count: int, is_downbeat: bool) -> bool:
        """Handle beat callback from metronome engine."""
        print(f"=== BEAT CALLBACK: count={beat_count}, downbeat={is_downbeat} ===")
        
        if self.audio:
            try:
                self.audio.play_click(is_downbeat)
                print("Audio played successfully")
            except Exception as e:
                print(f"Audio failed: {e}")
        else:
            print("No audio system")
            
        self.beat_count += 1
        
        # Stop after 5 beats
        if self.beat_count >= 5:
            print("Stopping metronome after 5 beats")
            GLib.timeout_add(100, self.stop_metronome)
            
        return False
        
    def stop_metronome(self):
        """Stop the metronome."""
        self.metronome.stop()
        print("Metronome stopped")
        # Exit the main loop
        GLib.timeout_add(100, lambda: self.loop.quit())
        return False
        
    def start_test(self):
        """Start the test."""
        print("Starting metronome test...")
        self.metronome.set_tempo(120)  # 120 BPM = 0.5 seconds per beat
        self.metronome.start()
        print("Metronome started")

def main():
    """Main test function."""
    print("=== TESTING COMPLETE CALLBACK CHAIN ===")
    
    # Create main loop
    loop = GLib.MainLoop()
    
    # Create test instance
    test = AudioTestCallback(loop)
    
    # Start test after a delay
    GLib.timeout_add(1000, test.start_test)
    
    print("Starting GLib main loop...")
    
    # Run main loop with timeout
    GLib.timeout_add(10000, lambda: loop.quit())  # 10 second timeout
    
    try:
        loop.run()
    except KeyboardInterrupt:
        print("Test interrupted")
        loop.quit()
    
    print("Test completed")

if __name__ == "__main__":
    main()