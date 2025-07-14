#!/usr/bin/env python3
"""
Test audio system specifically in the Flatpak environment.
This will help debug why audio doesn't work when the metronome starts.
"""

import sys
import os
import time
sys.path.insert(0, 'src')

import gi
gi.require_version('Gst', '1.0')
gi.require_version('GLib', '2.0')
from gi.repository import Gst, GLib

def test_gstreamer_directly():
    """Test GStreamer directly without the metronome classes."""
    print("=== TESTING GSTREAMER DIRECTLY ===")
    
    # Initialize GStreamer
    Gst.init(None)
    
    # Create a simple test pipeline
    pipeline_str = """
    filesrc location=/app/share/tempo/sounds/high.wav ! 
    decodebin ! 
    audioconvert ! 
    audioresample ! 
    volume volume=0.8 ! 
    autoaudiosink
    """
    
    try:
        pipeline = Gst.parse_launch(pipeline_str.replace('\n', '').strip())
        print("Pipeline created successfully")
        
        # Set up message handling
        bus = pipeline.get_bus()
        bus.add_signal_watch()
        
        def on_message(bus, message):
            if message.type == Gst.MessageType.ERROR:
                err, debug = message.parse_error()
                print(f"ERROR: {err} - {debug}")
            elif message.type == Gst.MessageType.WARNING:
                warn, debug = message.parse_warning()
                print(f"WARNING: {warn} - {debug}")
            elif message.type == Gst.MessageType.EOS:
                print("End of stream reached")
                pipeline.set_state(Gst.State.NULL)
            return True
        
        bus.connect("message", on_message)
        
        # Start playback
        print("Starting playback...")
        ret = pipeline.set_state(Gst.State.PLAYING)
        print(f"Set state to PLAYING: {ret}")
        
        if ret == Gst.StateChangeReturn.FAILURE:
            print("FAILED to start pipeline")
            return False
        
        # Wait for playback to complete
        time.sleep(2)
        
        # Stop pipeline
        pipeline.set_state(Gst.State.NULL)
        bus.remove_signal_watch()
        
        print("Direct GStreamer test completed")
        return True
        
    except Exception as e:
        print(f"Direct GStreamer test failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_audio_file_existence():
    """Test if audio files exist in expected locations."""
    print("=== TESTING AUDIO FILE EXISTENCE ===")
    
    test_paths = [
        "/app/share/tempo/sounds/high.wav",
        "/app/share/tempo/sounds/low.wav",
        "data/sounds/high.wav",
        "data/sounds/low.wav"
    ]
    
    for path in test_paths:
        exists = os.path.exists(path)
        print(f"  {path}: {'EXISTS' if exists else 'NOT FOUND'}")
        if exists:
            size = os.path.getsize(path)
            print(f"    Size: {size} bytes")

def test_audio_sinks():
    """Test different audio sink types."""
    print("=== TESTING AUDIO SINK AVAILABILITY ===")
    
    # Initialize GStreamer
    Gst.init(None)
    
    sink_types = ["autoaudiosink", "pulsesink", "pipewireaudiosink", "alsasink"]
    
    for sink_type in sink_types:
        sink = Gst.ElementFactory.make(sink_type)
        if sink:
            print(f"  {sink_type}: AVAILABLE")
        else:
            print(f"  {sink_type}: NOT AVAILABLE")

def test_environment():
    """Check relevant environment variables."""
    print("=== TESTING ENVIRONMENT ===")
    
    env_vars = [
        "PULSE_RUNTIME_PATH",
        "PIPEWIRE_RUNTIME_DIR", 
        "XDG_RUNTIME_DIR",
        "PULSE_SOCKET",
        "GST_DEBUG"
    ]
    
    for var in env_vars:
        value = os.environ.get(var, "NOT SET")
        print(f"  {var}: {value}")

if __name__ == "__main__":
    print("Testing audio system in Flatpak environment...")
    print()
    
    test_environment()
    print()
    
    test_audio_file_existence()
    print()
    
    test_audio_sinks()
    print()
    
    test_gstreamer_directly()
    print()
    
    print("Audio testing complete")