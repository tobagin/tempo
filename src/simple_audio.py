#!/usr/bin/env python3
"""
Simple GStreamer audio player for Flatpak applications.
Optimized for rapid-fire metronome beats with minimal latency.
"""

import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GLib
import os

class SimpleAudioPlayer:
    """Simple audio player using GStreamer optimized for rapid metronome beats."""
    
    def __init__(self):
        """Initialize GStreamer with optimized settings for low latency."""
        Gst.init(None)
        self.current_player = None
        self.last_file_path = None
        self.player_ready = False
        
    def play_file(self, file_path: str) -> bool:
        """
        Play a WAV file with minimal latency for rapid beats.
        
        Args:
            file_path: Path to the WAV file
            
        Returns:
            True if playback started successfully
        """
        # Check if file exists
        if not os.path.exists(file_path):
            return False
        
        try:
            # If we're playing a different file or no player exists, create new one
            if not self.current_player or self.last_file_path != file_path:
                self._create_player(file_path)
                self.last_file_path = file_path
            
            # For rapid beats, just seek to beginning and play
            if self.current_player and self.player_ready:
                # Seek to beginning instantly
                self.current_player.seek_simple(
                    Gst.Format.TIME,
                    Gst.SeekFlags.FLUSH | Gst.SeekFlags.ACCURATE,
                    0
                )
                
                # Ensure we're playing
                ret = self.current_player.set_state(Gst.State.PLAYING)
                return ret != Gst.StateChangeReturn.FAILURE
            
            return False
            
        except Exception:
            return False
    
    def _create_player(self, file_path: str):
        """Create and configure a new player for the given file."""
        try:
            # Clean up previous player
            if self.current_player:
                self.current_player.set_state(Gst.State.NULL)
                bus = self.current_player.get_bus()
                if bus:
                    bus.remove_signal_watch()
            
            # Create new playbin element
            player = Gst.ElementFactory.make("playbin", "metronome-player")
            if not player:
                return False
            
            # Set the file URI
            uri = f"file://{os.path.abspath(file_path)}"
            player.set_property("uri", uri)
            
            # Configure for low latency
            # Set audio sink properties for minimal buffering
            try:
                # Get the audio sink and configure it
                audio_sink = Gst.ElementFactory.make("pulsesink", "audio-sink")
                if audio_sink:
                    # Minimize buffering for low latency
                    audio_sink.set_property("buffer-time", 10000)  # 10ms
                    audio_sink.set_property("latency-time", 1000)   # 1ms
                    player.set_property("audio-sink", audio_sink)
            except Exception:
                pass  # Fall back to default sink
            
            # Set up message handling
            bus = player.get_bus()
            bus.add_signal_watch()
            bus.connect("message", self._on_message)
            
            # Preload the file by setting to PAUSED state
            ret = player.set_state(Gst.State.PAUSED)
            if ret == Gst.StateChangeReturn.FAILURE:
                return False
            
            # Wait for preload to complete
            ret, state, pending = player.get_state(500 * Gst.MSECOND)  # 500ms timeout
            
            self.current_player = player
            self.player_ready = (ret == Gst.StateChangeReturn.SUCCESS)
            
            return self.player_ready
            
        except Exception:
            self.player_ready = False
            return False
    
    def _on_message(self, bus, message):
        """Handle GStreamer messages."""
        if message.type == Gst.MessageType.EOS:
            # End of stream - reset to beginning for rapid replay
            if self.current_player:
                self.current_player.seek_simple(
                    Gst.Format.TIME,
                    Gst.SeekFlags.FLUSH,
                    0
                )
                # Keep in PAUSED state, ready for next play
                self.current_player.set_state(Gst.State.PAUSED)
        return True
    
    def _stop_current_player(self):
        """Stop the current player and pause it for reuse."""
        if self.current_player:
            # Don't destroy, just pause for rapid reuse
            self.current_player.set_state(Gst.State.PAUSED)
            # Seek to beginning
            self.current_player.seek_simple(
                Gst.Format.TIME,
                Gst.SeekFlags.FLUSH,
                0
            )
        return False  # Remove from timeout
    
    def cleanup(self):
        """Clean up all players on shutdown."""
        if self.current_player:
            self.current_player.set_state(Gst.State.NULL)
            bus = self.current_player.get_bus()
            if bus:
                bus.remove_signal_watch()
            self.current_player = None
        self.player_ready = False
        self.last_file_path = None