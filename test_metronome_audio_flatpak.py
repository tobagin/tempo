#!/usr/bin/env python3
"""
Test the actual MetronomeAudio class in Flatpak environment.
"""

import sys
import time
sys.path.insert(0, '/app/lib/python3.12/site-packages')

from src.audio import MetronomeAudio, AudioConfig

def test_metronome_audio():
    """Test the MetronomeAudio class directly."""
    print("=== TESTING METRONOME AUDIO CLASS ===")
    
    try:
        config = AudioConfig()
        print(f"Config: high={config.high_click_path}, low={config.low_click_path}")
        
        audio = MetronomeAudio(config)
        print(f"Audio initialized: {audio.is_initialized}")
        
        if audio.is_initialized:
            print("Testing audio playback...")
            
            # Test regular beat
            print("Playing regular beat...")
            audio.play_click(False)
            time.sleep(0.5)
            
            # Test downbeat
            print("Playing downbeat...")
            audio.play_click(True)
            time.sleep(0.5)
            
            print("Audio test completed successfully")
        else:
            print("Audio not initialized")
            
        audio.cleanup()
        
    except Exception as e:
        print(f"MetronomeAudio test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_metronome_audio()