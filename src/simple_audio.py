#!/usr/bin/env python3
"""
Simple GStreamer audio player for Flatpak applications.
Based on the recommended approach for playing WAV files in Flatpak.
"""

import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GLib
import os

class SimpleAudioPlayer:
    """Simple audio player using GStreamer playbin."""
    
    def __init__(self):
        """Initialize GStreamer."""
        Gst.init(None)
        self.current_player = None
        
    def play_file(self, file_path: str) -> bool:
        """
        Play a WAV file using the recommended Flatpak approach.
        
        Args:
            file_path: Path to the WAV file
            
        Returns:
            True if playback started successfully
        """
        # Stop any currently playing audio first
        if self.current_player:
            self._stop_current_player()
        
        # Check if file exists
        if not os.path.exists(file_path):
            return False
        
        try:
            # Create playbin element (recommended for Flatpak)
            player = Gst.ElementFactory.make("playbin", "audio-player")
            if not player:
                return False
            
            # Set the file URI
            uri = f"file://{os.path.abspath(file_path)}"
            player.set_property("uri", uri)
            
            # Set up message handling
            bus = player.get_bus()
            bus.add_signal_watch()
            bus.connect("message", self._on_message)
            
            # Start playback
            ret = player.set_state(Gst.State.PLAYING)
            
            if ret == Gst.StateChangeReturn.FAILURE:
                return False
                
            # Wait for state change
            state_ret, state, pending = player.get_state(2 * Gst.SECOND)
            
            # Store current player
            self.current_player = player
            
            # Auto-stop after 1 second for short sounds
            GLib.timeout_add(1000, self._stop_current_player)
            
            return True
            
        except Exception:
            return False
            
    def _on_message(self, bus, message):
        """Handle GStreamer messages."""
        # Silently handle messages without debug output
        return True
        
    def _stop_current_player(self):
        """Stop the current player properly."""
        if self.current_player:
            # First set to NULL state to properly clean up
            self.current_player.set_state(Gst.State.NULL)
            
            # Wait for state change to complete
            self.current_player.get_state(1 * Gst.SECOND)
            
            # Clean up bus
            bus = self.current_player.get_bus()
            if bus:
                bus.remove_signal_watch()
            
            # Clear reference
            self.current_player = None
            
        return False  # Remove from timeout
    
    def cleanup(self):
        """Clean up any remaining players on shutdown."""
        if self.current_player:
            self._stop_current_player()