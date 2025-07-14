#!/usr/bin/env python3

import sys
import os
sys.path.insert(0, 'src')

from audio import MetronomeAudio, AudioConfig

def test_audio():
    print("Testing audio system...")
    
    config = AudioConfig()
    print(f"Default config: high={config.high_click_path}, low={config.low_click_path}")
    
    try:
        audio = MetronomeAudio(config)
        print(f"Audio initialized: {audio.is_initialized}")
        
        if audio.is_initialized:
            print("Testing audio playback...")
            audio.play_click(False)  # Regular beat
            print("Regular beat played")
            
            import time
            time.sleep(0.5)
            
            audio.play_click(True)  # Downbeat
            print("Downbeat played")
            
            time.sleep(1)
            
        audio.cleanup()
        print("Audio cleanup done")
        
    except Exception as e:
        print(f"Audio test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_audio()