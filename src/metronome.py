"""
Precision timing engine for the metronome application.

This module provides the core timing functionality with sub-millisecond accuracy
using absolute time references to prevent drift and jitter.
"""

import time
from dataclasses import dataclass
from threading import Thread, Event
from typing import Callable, Optional

from gi.repository import GLib


@dataclass
class MetronomeState:
    """State container for metronome parameters."""
    bpm: int = 120  # Beats per minute (40-240 range)
    beats_per_bar: int = 4  # Time signature numerator
    beat_value: int = 4  # Time signature denominator
    is_running: bool = False
    current_beat: int = 0
    is_playing: bool = False


class MetronomeEngine:
    """
    High-precision metronome timing engine.
    
    Uses absolute time references with time.perf_counter() to prevent
    timing drift and jitter. Runs in a separate thread to avoid blocking
    the GTK main loop.
    """

    def __init__(self) -> None:
        """Initialize the metronome engine."""
        self.state = MetronomeState()
        self._stop_event = Event()
        self._thread: Optional[Thread] = None
        self.beat_callback: Optional[Callable[[int, bool], None]] = None
        
        # Timing parameters
        self._next_beat_time: float = 0.0
        self._beat_duration: float = 0.5  # 120 BPM = 0.5 seconds per beat
        
        # Thread synchronization
        self._lock = Event()
        self._lock.set()  # Start unlocked
        
    def start(self) -> None:
        """Start the metronome."""
        if self.state.is_running:
            return
            
        self.state.is_running = True
        self.state.is_playing = True
        self.state.current_beat = 0
        
        # Clear stop event and start thread
        self._stop_event.clear()
        self._thread = Thread(target=self._run_loop, daemon=True)
        self._thread.start()
        
    def stop(self) -> None:
        """Stop the metronome."""
        if not self.state.is_running:
            return
            
        self.state.is_running = False
        self.state.is_playing = False
        
        # Signal thread to stop
        self._stop_event.set()
        
        # Wait for thread to finish
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=1.0)
            
        self._thread = None
        
    def set_tempo(self, bpm: int) -> None:
        """
        Set the tempo in beats per minute.
        
        Args:
            bpm: Beats per minute (40-240)
        """
        if not 40 <= bpm <= 240:
            raise ValueError(f"BPM must be between 40 and 240, got {bpm}")
            
        self.state.bpm = bpm
        self._beat_duration = 60.0 / bpm
        
    def set_time_signature(self, numerator: int, denominator: int) -> None:
        """
        Set the time signature.
        
        Args:
            numerator: Beats per bar (1-16)
            denominator: Note value (2, 4, 8, 16)
        """
        if not 1 <= numerator <= 16:
            raise ValueError(f"Time signature numerator must be 1-16, got {numerator}")
            
        if denominator not in (2, 4, 8, 16):
            raise ValueError(f"Time signature denominator must be 2, 4, 8, or 16, got {denominator}")
            
        self.state.beats_per_bar = numerator
        self.state.beat_value = denominator
        
    def reset_beat_counter(self) -> None:
        """Reset the beat counter to 0."""
        self.state.current_beat = 0
        
    def _run_loop(self) -> None:
        """
        Main timing loop running in separate thread.
        
        Uses absolute time references to prevent drift and jitter.
        """
        # Initialize timing
        self._beat_duration = 60.0 / self.state.bpm
        self._next_beat_time = time.perf_counter() + self._beat_duration
        
        while not self._stop_event.is_set():
            current_time = time.perf_counter()
            
            # Calculate wait time until next beat
            wait_time = self._next_beat_time - current_time
            
            if wait_time > 0:
                # Wait for next beat or stop signal
                if self._stop_event.wait(wait_time):
                    break  # Stop signal received
                    
            # Check if we should stop
            if self._stop_event.is_set():
                break
                
            # Check if we're too far behind (e.g., after system sleep)
            current_time = time.perf_counter()
            if current_time > self._next_beat_time + self._beat_duration:
                # Reset timing to current time
                self._next_beat_time = current_time
                
            # Determine if this is a downbeat
            is_downbeat = (self.state.current_beat % self.state.beats_per_bar) == 0
            
            # Emit beat signal via callback
            if self.beat_callback:
                # Use GLib.idle_add for thread-safe GUI updates
                GLib.idle_add(self.beat_callback, self.state.current_beat, is_downbeat)
                
            # Update beat counter
            self.state.current_beat += 1
            
            # Calculate next beat time (absolute time to prevent drift)
            self._next_beat_time += self._beat_duration
            
            # Update beat duration if tempo changed
            new_duration = 60.0 / self.state.bpm
            if abs(new_duration - self._beat_duration) > 0.001:  # 1ms tolerance
                self._beat_duration = new_duration
                
        print(f"Metronome run loop exiting")
                
    def get_beat_info(self) -> dict:
        """
        Get current beat information.
        
        Returns:
            Dictionary with beat information
        """
        return {
            'current_beat': self.state.current_beat,
            'beats_per_bar': self.state.beats_per_bar,
            'beat_in_bar': (self.state.current_beat % self.state.beats_per_bar) + 1,
            'is_downbeat': (self.state.current_beat % self.state.beats_per_bar) == 0,
            'is_running': self.state.is_running,
            'bpm': self.state.bpm,
            'time_signature': f"{self.state.beats_per_bar}/{self.state.beat_value}"
        }
        
    def get_timing_stats(self) -> dict:
        """
        Get timing statistics for debugging.
        
        Returns:
            Dictionary with timing statistics
        """
        return {
            'beat_duration': self._beat_duration,
            'next_beat_time': self._next_beat_time,
            'current_time': time.perf_counter(),
            'time_to_next_beat': self._next_beat_time - time.perf_counter(),
            'thread_alive': self._thread.is_alive() if self._thread else False
        }


class TapTempo:
    """
    Tap tempo calculator for determining BPM from user taps.
    
    Uses a sliding window of tap intervals to calculate average BPM.
    """
    
    def __init__(self, max_taps: int = 8, timeout: float = 2.0) -> None:
        """
        Initialize tap tempo calculator.
        
        Args:
            max_taps: Maximum number of taps to consider
            timeout: Reset if no tap within this time (seconds)
        """
        self.max_taps = max_taps
        self.timeout = timeout
        self.tap_times: list[float] = []
        
    def tap(self) -> Optional[int]:
        """
        Register a tap and calculate BPM.
        
        Returns:
            Calculated BPM or None if insufficient taps
        """
        current_time = time.perf_counter()
        
        # Remove old taps beyond timeout
        cutoff_time = current_time - self.timeout
        self.tap_times = [t for t in self.tap_times if t > cutoff_time]
        
        # Add current tap
        self.tap_times.append(current_time)
        
        # Keep only recent taps
        if len(self.tap_times) > self.max_taps:
            self.tap_times = self.tap_times[-self.max_taps:]
            
        # Need at least 2 taps to calculate BPM
        if len(self.tap_times) < 2:
            return None
            
        # Calculate intervals between taps
        intervals = []
        for i in range(1, len(self.tap_times)):
            interval = self.tap_times[i] - self.tap_times[i-1]
            intervals.append(interval)
            
        # Calculate average interval
        avg_interval = sum(intervals) / len(intervals)
        
        # Convert to BPM
        bpm = 60.0 / avg_interval
        
        # Clamp to valid range
        bpm = max(40, min(240, int(round(bpm))))
        
        return bpm
        
    def reset(self) -> None:
        """Reset tap tempo calculator."""
        self.tap_times.clear()
        
    def get_tap_count(self) -> int:
        """Get number of active taps."""
        return len(self.tap_times)