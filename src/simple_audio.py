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
        print(f"=== PLAYING AUDIO FILE: {file_path} ===")
        
        # Stop any currently playing audio first
        if self.current_player:
            print("Stopping previous player before starting new one...")
            self._stop_current_player()
        
        # Check if file exists
        if not os.path.exists(file_path):
            print(f"ERROR: File not found: {file_path}")
            return False
            
        file_size = os.path.getsize(file_path)
        print(f"File exists, size: {file_size} bytes")
        
        try:
            # Create playbin element (recommended for Flatpak)
            player = Gst.ElementFactory.make("playbin", "audio-player")
            if not player:
                print("ERROR: Could not create playbin element")
                return False
                
            print("Playbin created successfully")
            
            # Set the file URI
            uri = f"file://{os.path.abspath(file_path)}"
            print(f"Setting URI: {uri}")
            player.set_property("uri", uri)
            
            # Set up message handling
            bus = player.get_bus()
            bus.add_signal_watch()
            bus.connect("message", self._on_message)
            
            # Start playback
            print("Starting playback...")
            ret = player.set_state(Gst.State.PLAYING)
            print(f"Set state result: {ret}")
            
            if ret == Gst.StateChangeReturn.FAILURE:
                print("ERROR: Failed to start playback")
                return False
                
            # Wait for state change
            print("Waiting for state change...")
            state_ret, state, pending = player.get_state(2 * Gst.SECOND)
            print(f"Final state: {state}, return: {state_ret}")
            
            # Store current player
            self.current_player = player
            
            # Auto-stop after 1 second for short sounds
            GLib.timeout_add(1000, self._stop_current_player)
            
            return True
            
        except Exception as e:
            print(f"ERROR in play_file: {e}")
            import traceback
            traceback.print_exc()
            return False
            
    def _on_message(self, bus, message):
        """Handle GStreamer messages."""
        msg_type = message.type
        
        if msg_type == Gst.MessageType.ERROR:
            err, debug = message.parse_error()
            print(f"GSTREAMER ERROR: {err}")
            print(f"DEBUG INFO: {debug}")
            
        elif msg_type == Gst.MessageType.WARNING:
            warn, debug = message.parse_warning()
            print(f"GSTREAMER WARNING: {warn}")
            
        elif msg_type == Gst.MessageType.EOS:
            print("GSTREAMER: End of stream reached")
            
        elif msg_type == Gst.MessageType.STATE_CHANGED:
            if message.src == self.current_player:
                old, new, pending = message.parse_state_changed()
                print(f"STATE CHANGE: {old} -> {new}")
                
        return True
        
    def _stop_current_player(self):
        """Stop the current player properly."""
        if self.current_player:
            print("Stopping current player...")
            
            # First set to NULL state to properly clean up
            self.current_player.set_state(Gst.State.NULL)
            
            # Wait for state change to complete
            ret, state, pending = self.current_player.get_state(1 * Gst.SECOND)
            if ret == Gst.StateChangeReturn.SUCCESS:
                print(f"Player stopped successfully, final state: {state}")
            else:
                print(f"Warning: Player state change returned: {ret}")
            
            # Clean up bus
            bus = self.current_player.get_bus()
            if bus:
                bus.remove_signal_watch()
            
            # Clear reference
            self.current_player = None
            print("Player stopped and cleaned up")
            
        return False  # Remove from timeout
    
    def cleanup(self):
        """Clean up any remaining players on shutdown."""
        if self.current_player:
            print("Cleaning up audio player on shutdown...")
            self._stop_current_player()

# Test function
def test_audio():
    """Test function to verify audio works."""
    print("=== TESTING SIMPLE AUDIO PLAYER ===")
    
    player = SimpleAudioPlayer()
    
    # Test high sound
    success = player.play_file("/app/share/tempo/sounds/high.wav")
    print(f"High sound test result: {success}")
    
    return success

if __name__ == "__main__":
    test_audio()