"""
Unit tests for the metronome timing engine.

Tests timing accuracy, tempo changes, and tap tempo functionality.
"""

import pytest
import time
import threading
from unittest.mock import Mock, patch

from src.metronome import MetronomeEngine, MetronomeState, TapTempo


class TestMetronomeState:
    """Test MetronomeState dataclass."""
    
    def test_default_values(self):
        """Test default state values."""
        state = MetronomeState()
        assert state.bpm == 120
        assert state.beats_per_bar == 4
        assert state.beat_value == 4
        assert state.is_running == False
        assert state.current_beat == 0
        assert state.is_playing == False
        
    def test_custom_values(self):
        """Test custom state values."""
        state = MetronomeState(
            bpm=140,
            beats_per_bar=3,
            beat_value=8,
            is_running=True,
            current_beat=5,
            is_playing=True
        )
        assert state.bpm == 140
        assert state.beats_per_bar == 3
        assert state.beat_value == 8
        assert state.is_running == True
        assert state.current_beat == 5
        assert state.is_playing == True


class TestMetronomeEngine:
    """Test MetronomeEngine class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.engine = MetronomeEngine()
        
    def teardown_method(self):
        """Clean up after tests."""
        if self.engine.state.is_running:
            self.engine.stop()
            
    def test_initialization(self):
        """Test engine initialization."""
        assert self.engine.state.bpm == 120
        assert self.engine.state.beats_per_bar == 4
        assert self.engine.state.beat_value == 4
        assert self.engine.state.is_running == False
        assert self.engine.beat_callback is None
        
    def test_set_tempo_valid(self):
        """Test setting valid tempo."""
        self.engine.set_tempo(140)
        assert self.engine.state.bpm == 140
        
        self.engine.set_tempo(60)
        assert self.engine.state.bpm == 60
        
        self.engine.set_tempo(240)
        assert self.engine.state.bpm == 240
        
    def test_set_tempo_invalid(self):
        """Test setting invalid tempo."""
        with pytest.raises(ValueError):
            self.engine.set_tempo(39)
            
        with pytest.raises(ValueError):
            self.engine.set_tempo(241)
            
        with pytest.raises(ValueError):
            self.engine.set_tempo(0)
            
    def test_set_time_signature_valid(self):
        """Test setting valid time signature."""
        self.engine.set_time_signature(3, 4)
        assert self.engine.state.beats_per_bar == 3
        assert self.engine.state.beat_value == 4
        
        self.engine.set_time_signature(7, 8)
        assert self.engine.state.beats_per_bar == 7
        assert self.engine.state.beat_value == 8
        
    def test_set_time_signature_invalid(self):
        """Test setting invalid time signature."""
        with pytest.raises(ValueError):
            self.engine.set_time_signature(0, 4)
            
        with pytest.raises(ValueError):
            self.engine.set_time_signature(17, 4)
            
        with pytest.raises(ValueError):
            self.engine.set_time_signature(4, 3)
            
        with pytest.raises(ValueError):
            self.engine.set_time_signature(4, 32)
            
    def test_start_stop(self):
        """Test starting and stopping the engine."""
        assert not self.engine.state.is_running
        
        self.engine.start()
        assert self.engine.state.is_running
        assert self.engine.state.is_playing
        
        self.engine.stop()
        assert not self.engine.state.is_running
        assert not self.engine.state.is_playing
        
    def test_beat_callback(self):
        """Test beat callback functionality."""
        callback_mock = Mock()
        self.engine.beat_callback = callback_mock
        
        # Start for a short time
        self.engine.set_tempo(240)  # Fast tempo for quick test
        self.engine.start()
        time.sleep(0.3)  # Should get at least one beat
        self.engine.stop()
        
        # Verify callback was called
        assert callback_mock.call_count >= 1
        
        # Check callback arguments
        args, kwargs = callback_mock.call_args_list[0]
        assert len(args) == 2
        assert isinstance(args[0], int)  # beat_count
        assert isinstance(args[1], bool)  # is_downbeat
        
    def test_timing_accuracy(self):
        """Test timing accuracy of the metronome."""
        beat_times = []
        
        def beat_callback(beat_count, is_downbeat):
            beat_times.append(time.perf_counter())
            
        self.engine.beat_callback = beat_callback
        self.engine.set_tempo(120)  # 0.5 seconds per beat
        
        # Run for about 3 seconds to get ~6 beats
        self.engine.start()
        time.sleep(3.1)
        self.engine.stop()
        
        # Check we got enough beats
        assert len(beat_times) >= 5
        
        # Check timing accuracy (within 5ms tolerance)
        expected_interval = 0.5  # 120 BPM = 0.5 sec per beat
        
        for i in range(1, len(beat_times)):
            interval = beat_times[i] - beat_times[i-1]
            assert abs(interval - expected_interval) < 0.005  # 5ms tolerance
            
    def test_tempo_change_while_running(self):
        """Test changing tempo while running."""
        callback_mock = Mock()
        self.engine.beat_callback = callback_mock
        
        # Start at 120 BPM
        self.engine.set_tempo(120)
        self.engine.start()
        time.sleep(0.1)
        
        # Change to 180 BPM
        self.engine.set_tempo(180)
        time.sleep(0.1)
        
        self.engine.stop()
        
        # Should not crash and should continue running
        assert callback_mock.call_count >= 1
        
    def test_reset_beat_counter(self):
        """Test resetting the beat counter."""
        # Start and let it run for a bit
        self.engine.start()
        time.sleep(0.1)
        
        # Reset counter
        self.engine.reset_beat_counter()
        assert self.engine.state.current_beat == 0
        
        self.engine.stop()
        
    def test_get_beat_info(self):
        """Test getting beat information."""
        self.engine.set_tempo(140)
        self.engine.set_time_signature(3, 8)
        
        info = self.engine.get_beat_info()
        
        assert info['bpm'] == 140
        assert info['beats_per_bar'] == 3
        assert info['is_running'] == False
        assert info['time_signature'] == "3/8"
        assert 'current_beat' in info
        assert 'beat_in_bar' in info
        assert 'is_downbeat' in info
        
    def test_get_timing_stats(self):
        """Test getting timing statistics."""
        stats = self.engine.get_timing_stats()
        
        assert 'beat_duration' in stats
        assert 'current_time' in stats
        assert 'thread_alive' in stats
        assert isinstance(stats['beat_duration'], float)
        assert isinstance(stats['current_time'], float)
        assert isinstance(stats['thread_alive'], bool)
        
    def test_downbeat_detection(self):
        """Test downbeat detection in different time signatures."""
        downbeats = []
        
        def beat_callback(beat_count, is_downbeat):
            if is_downbeat:
                downbeats.append(beat_count)
                
        self.engine.beat_callback = beat_callback
        self.engine.set_tempo(240)  # Fast for quick test
        self.engine.set_time_signature(3, 4)  # 3/4 time
        
        self.engine.start()
        time.sleep(0.8)  # Should get multiple measures
        self.engine.stop()
        
        # Check downbeats occur every 3 beats
        if len(downbeats) >= 2:
            assert downbeats[1] - downbeats[0] == 3
            
    def test_thread_safety(self):
        """Test thread safety of tempo changes."""
        errors = []
        
        def change_tempo():
            try:
                for tempo in range(60, 200, 10):
                    self.engine.set_tempo(tempo)
                    time.sleep(0.01)
            except Exception as e:
                errors.append(e)
                
        self.engine.start()
        
        # Start multiple threads changing tempo
        threads = []
        for _ in range(3):
            t = threading.Thread(target=change_tempo)
            threads.append(t)
            t.start()
            
        # Wait for threads to complete
        for t in threads:
            t.join()
            
        self.engine.stop()
        
        # Should not have any errors
        assert len(errors) == 0


class TestTapTempo:
    """Test TapTempo class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.tap_tempo = TapTempo()
        
    def test_initialization(self):
        """Test tap tempo initialization."""
        assert self.tap_tempo.max_taps == 8
        assert self.tap_tempo.timeout == 2.0
        assert len(self.tap_tempo.tap_times) == 0
        
    def test_single_tap(self):
        """Test single tap returns None."""
        result = self.tap_tempo.tap()
        assert result is None
        
    def test_two_taps(self):
        """Test two taps returns BPM."""
        self.tap_tempo.tap()
        time.sleep(0.5)  # 500ms interval = 120 BPM
        result = self.tap_tempo.tap()
        
        assert result is not None
        assert isinstance(result, int)
        assert 100 <= result <= 140  # Should be around 120 BPM
        
    def test_multiple_taps(self):
        """Test multiple taps for better accuracy."""
        # Tap at 100 BPM (0.6 second intervals)
        for _ in range(5):
            self.tap_tempo.tap()
            time.sleep(0.6)
            
        result = self.tap_tempo.tap()
        assert result is not None
        assert 90 <= result <= 110  # Should be around 100 BPM
        
    def test_tap_timeout(self):
        """Test tap timeout functionality."""
        self.tap_tempo.tap()
        time.sleep(2.1)  # Wait longer than timeout
        
        # Should reset after timeout
        result = self.tap_tempo.tap()
        assert result is None
        
    def test_max_taps_limit(self):
        """Test maximum taps limit."""
        # Add more taps than max
        for _ in range(10):
            self.tap_tempo.tap()
            time.sleep(0.1)
            
        # Should only keep max_taps
        assert len(self.tap_tempo.tap_times) <= self.tap_tempo.max_taps
        
    def test_reset(self):
        """Test tap tempo reset."""
        self.tap_tempo.tap()
        self.tap_tempo.tap()
        
        assert len(self.tap_tempo.tap_times) == 2
        
        self.tap_tempo.reset()
        assert len(self.tap_tempo.tap_times) == 0
        
    def test_get_tap_count(self):
        """Test getting tap count."""
        assert self.tap_tempo.get_tap_count() == 0
        
        self.tap_tempo.tap()
        assert self.tap_tempo.get_tap_count() == 1
        
        self.tap_tempo.tap()
        assert self.tap_tempo.get_tap_count() == 2
        
    def test_bpm_range_clamping(self):
        """Test BPM range clamping."""
        # Very fast taps (should clamp to max)
        self.tap_tempo.tap()
        time.sleep(0.1)  # Very fast
        result = self.tap_tempo.tap()
        
        assert result is not None
        assert result <= 240
        
        # Very slow taps (should clamp to min)
        self.tap_tempo.reset()
        self.tap_tempo.tap()
        time.sleep(1.6)  # Very slow
        result = self.tap_tempo.tap()
        
        assert result is not None
        assert result >= 40


if __name__ == '__main__':
    pytest.main([__file__])