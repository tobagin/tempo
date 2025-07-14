"""
Unit tests for the audio system.

Tests audio initialization, playback, and configuration.
"""

import pytest
import os
import tempfile
import wave
import struct
from unittest.mock import Mock, patch, MagicMock

from src.audio import MetronomeAudio, AudioConfig, AudioError


class TestAudioConfig:
    """Test AudioConfig dataclass."""
    
    def test_default_values(self):
        """Test default configuration values."""
        config = AudioConfig()
        assert config.high_click_path == "/app/share/tempo/sounds/high.wav"
        assert config.low_click_path == "/app/share/tempo/sounds/low.wav"
        assert config.volume == 0.8
        assert config.accent_volume == 1.0
        assert config.latency_compensation_ms == 10
        
    def test_custom_values(self):
        """Test custom configuration values."""
        config = AudioConfig(
            high_click_path="/custom/high.wav",
            low_click_path="/custom/low.wav",
            volume=0.5,
            accent_volume=0.9,
            latency_compensation_ms=20
        )
        assert config.high_click_path == "/custom/high.wav"
        assert config.low_click_path == "/custom/low.wav"
        assert config.volume == 0.5
        assert config.accent_volume == 0.9
        assert config.latency_compensation_ms == 20


class TestMetronomeAudio:
    """Test MetronomeAudio class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        # Create temporary sound files
        self.temp_dir = tempfile.mkdtemp()
        self.high_sound = os.path.join(self.temp_dir, "high.wav")
        self.low_sound = os.path.join(self.temp_dir, "low.wav")
        
        # Create dummy WAV files
        self._create_dummy_wav(self.high_sound)
        self._create_dummy_wav(self.low_sound)
        
        # Create test config
        self.config = AudioConfig(
            high_click_path=self.high_sound,
            low_click_path=self.low_sound,
            volume=0.8,
            accent_volume=1.0
        )
        
    def teardown_method(self):
        """Clean up after tests."""
        # Clean up temp files
        if os.path.exists(self.high_sound):
            os.remove(self.high_sound)
        if os.path.exists(self.low_sound):
            os.remove(self.low_sound)
        os.rmdir(self.temp_dir)
        
    def _create_dummy_wav(self, filename):
        """Create a dummy WAV file for testing."""
        # Create a short silence WAV file
        sample_rate = 44100
        duration = 0.1  # 100ms
        num_samples = int(sample_rate * duration)
        
        with wave.open(filename, 'wb') as wav_file:
            wav_file.setnchannels(1)  # Mono
            wav_file.setsampwidth(2)  # 16-bit
            wav_file.setframerate(sample_rate)
            
            # Write silence
            silence = struct.pack('<' + 'h' * num_samples, *([0] * num_samples))
            wav_file.writeframes(silence)
            
    @patch('gi.repository.Gst')
    def test_initialization_success(self, mock_gst):
        """Test successful audio initialization."""
        # Mock GStreamer components
        mock_gst.is_initialized.return_value = False
        mock_gst.init.return_value = None
        
        # Mock pipeline creation
        mock_pipeline = Mock()
        mock_gst.Pipeline.new.return_value = mock_pipeline
        
        # Mock element creation
        mock_element = Mock()
        mock_gst.ElementFactory.make.return_value = mock_element
        
        # Mock bin creation
        mock_bin = Mock()
        mock_gst.Bin.new.return_value = mock_bin
        
        # Mock bus
        mock_bus = Mock()
        mock_pipeline.get_bus.return_value = mock_bus
        
        # Mock state change
        mock_pipeline.set_state.return_value = mock_gst.StateChangeReturn.SUCCESS
        
        # Create audio system
        audio = MetronomeAudio(self.config)
        
        # Verify initialization
        mock_gst.init.assert_called_once_with(None)
        assert audio.is_initialized == True
        
    @patch('gi.repository.Gst')
    def test_initialization_failure(self, mock_gst):
        """Test audio initialization failure."""
        # Mock GStreamer failure
        mock_gst.is_initialized.return_value = False
        mock_gst.init.side_effect = Exception("GStreamer init failed")
        
        # Should raise AudioError
        with pytest.raises(AudioError):
            MetronomeAudio(self.config)
            
    @patch('gi.repository.Gst')
    def test_missing_sound_files(self, mock_gst):
        """Test handling of missing sound files."""
        # Mock GStreamer
        mock_gst.is_initialized.return_value = False
        mock_gst.init.return_value = None
        
        # Create config with non-existent files
        config = AudioConfig(
            high_click_path="/nonexistent/high.wav",
            low_click_path="/nonexistent/low.wav"
        )
        
        # Should raise AudioError
        with pytest.raises(AudioError):
            MetronomeAudio(config)
            
    @patch('gi.repository.Gst')
    @patch('gi.repository.GLib')
    def test_play_click_regular(self, mock_glib, mock_gst):
        """Test playing regular click sound."""
        # Mock successful initialization
        self._mock_gst_success(mock_gst)
        
        audio = MetronomeAudio(self.config)
        
        # Mock player elements
        mock_player = Mock()
        audio.low_player = mock_player
        mock_volume = Mock()
        setattr(mock_player, 'volume_element', mock_volume)
        
        # Test regular click
        audio.play_click(is_downbeat=False)
        
        # Verify volume was set
        mock_volume.set_property.assert_called_with('volume', 0.8)
        
    @patch('gi.repository.Gst')
    @patch('gi.repository.GLib')
    def test_play_click_downbeat(self, mock_glib, mock_gst):
        """Test playing downbeat click sound."""
        # Mock successful initialization
        self._mock_gst_success(mock_gst)
        
        audio = MetronomeAudio(self.config)
        
        # Mock player elements
        mock_player = Mock()
        audio.high_player = mock_player
        mock_volume = Mock()
        setattr(mock_player, 'volume_element', mock_volume)
        
        # Test downbeat click
        audio.play_click(is_downbeat=True)
        
        # Verify volume was set
        mock_volume.set_property.assert_called_with('volume', 1.0)
        
    @patch('gi.repository.Gst')
    def test_set_volume(self, mock_gst):
        """Test setting volume."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Test valid volume
        audio.set_volume(0.5)
        assert audio.volume == 0.5
        
        # Test volume clamping
        audio.set_volume(1.5)
        assert audio.volume == 1.0
        
        audio.set_volume(-0.5)
        assert audio.volume == 0.0
        
    @patch('gi.repository.Gst')
    def test_set_accent_volume(self, mock_gst):
        """Test setting accent volume."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Test valid volume
        audio.set_accent_volume(0.7)
        assert audio.accent_volume == 0.7
        
        # Test volume clamping
        audio.set_accent_volume(1.5)
        assert audio.accent_volume == 1.0
        
        audio.set_accent_volume(-0.5)
        assert audio.accent_volume == 0.0
        
    @patch('gi.repository.Gst')
    def test_set_custom_sounds_success(self, mock_gst):
        """Test setting custom sound files."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Create new sound files
        new_high = os.path.join(self.temp_dir, "new_high.wav")
        new_low = os.path.join(self.temp_dir, "new_low.wav")
        self._create_dummy_wav(new_high)
        self._create_dummy_wav(new_low)
        
        # Should not raise exception
        audio.set_custom_sounds(new_high, new_low)
        
        # Verify config was updated
        assert audio.config.high_click_path == new_high
        assert audio.config.low_click_path == new_low
        
        # Clean up
        os.remove(new_high)
        os.remove(new_low)
        
    @patch('gi.repository.Gst')
    def test_set_custom_sounds_missing_files(self, mock_gst):
        """Test setting custom sounds with missing files."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Test missing high file
        with pytest.raises(AudioError):
            audio.set_custom_sounds("/nonexistent/high.wav", self.low_sound)
            
        # Test missing low file
        with pytest.raises(AudioError):
            audio.set_custom_sounds(self.high_sound, "/nonexistent/low.wav")
            
    @patch('gi.repository.Gst')
    def test_test_audio(self, mock_gst):
        """Test audio testing functionality."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Mock play_click method
        audio.play_click = Mock()
        
        # Test audio
        result = audio.test_audio()
        
        # Should return True and call play_click
        assert result == True
        assert audio.play_click.call_count >= 1
        
    @patch('gi.repository.Gst')
    def test_test_audio_not_initialized(self, mock_gst):
        """Test audio testing when not initialized."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        audio.is_initialized = False
        
        # Should return False
        result = audio.test_audio()
        assert result == False
        
    @patch('gi.repository.Gst')
    def test_get_latency_info(self, mock_gst):
        """Test getting latency information."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Mock query
        mock_query = Mock()
        mock_gst.Query.new_latency.return_value = mock_query
        
        # Mock successful query
        audio.pipeline.query.return_value = True
        mock_query.parse_latency.return_value = (True, 10000000, 20000000)  # 10ms, 20ms
        
        info = audio.get_latency_info()
        
        assert info['live'] == True
        assert info['min_latency_ms'] == 10.0
        assert info['max_latency_ms'] == 20.0
        assert info['configured_latency_ms'] == 10
        
    @patch('gi.repository.Gst')
    def test_get_latency_info_failure(self, mock_gst):
        """Test latency info when query fails."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Mock failed query
        audio.pipeline.query.return_value = False
        
        info = audio.get_latency_info()
        
        assert 'error' in info
        assert info['error'] == "Failed to query latency"
        
    @patch('gi.repository.Gst')
    def test_cleanup(self, mock_gst):
        """Test audio cleanup."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Mock bus
        mock_bus = Mock()
        audio.pipeline.get_bus.return_value = mock_bus
        
        # Cleanup
        audio.cleanup()
        
        # Verify cleanup calls
        audio.pipeline.set_state.assert_called_with(mock_gst.State.NULL)
        mock_bus.remove_signal_watch.assert_called_once()
        
        # Verify state
        assert audio.pipeline is None
        assert audio.is_initialized == False
        
    @patch('gi.repository.Gst')
    def test_message_handling(self, mock_gst):
        """Test GStreamer message handling."""
        self._mock_gst_success(mock_gst)
        audio = MetronomeAudio(self.config)
        
        # Mock message components
        mock_bus = Mock()
        mock_message = Mock()
        
        # Test error message
        mock_message.type = mock_gst.MessageType.ERROR
        mock_message.parse_error.return_value = ("Test error", "Debug info")
        
        result = audio._on_message(mock_bus, mock_message)
        assert result == True
        
        # Test warning message
        mock_message.type = mock_gst.MessageType.WARNING
        mock_message.parse_warning.return_value = ("Test warning", "Debug info")
        
        result = audio._on_message(mock_bus, mock_message)
        assert result == True
        
        # Test EOS message
        mock_message.type = mock_gst.MessageType.EOS
        mock_element = Mock()
        mock_message.src = mock_element
        
        result = audio._on_message(mock_bus, mock_message)
        assert result == True
        
    def _mock_gst_success(self, mock_gst):
        """Helper to mock successful GStreamer initialization."""
        mock_gst.is_initialized.return_value = False
        mock_gst.init.return_value = None
        
        # Mock pipeline
        mock_pipeline = Mock()
        mock_gst.Pipeline.new.return_value = mock_pipeline
        
        # Mock elements
        mock_element = Mock()
        mock_gst.ElementFactory.make.return_value = mock_element
        
        # Mock bin
        mock_bin = Mock()
        mock_gst.Bin.new.return_value = mock_bin
        
        # Mock element linking
        mock_element.link.return_value = True
        
        # Mock static pads
        mock_pad = Mock()
        mock_pad.is_linked.return_value = False
        mock_element.get_static_pad.return_value = mock_pad
        
        # Mock pad linking
        mock_gst.PadLinkReturn.OK = 0
        mock_pad.link.return_value = 0
        
        # Mock bus
        mock_bus = Mock()
        mock_pipeline.get_bus.return_value = mock_bus
        
        # Mock successful state change
        mock_gst.StateChangeReturn.SUCCESS = 1
        mock_gst.StateChangeReturn.FAILURE = 0
        mock_pipeline.set_state.return_value = mock_gst.StateChangeReturn.SUCCESS
        
        # Mock other GStreamer constants
        mock_gst.State.READY = 2
        mock_gst.State.PLAYING = 4
        mock_gst.State.NULL = 1
        mock_gst.Format.TIME = 3
        mock_gst.SeekFlags.FLUSH = 1
        mock_gst.SeekFlags.KEY_UNIT = 2
        mock_gst.MessageType.ERROR = 1
        mock_gst.MessageType.WARNING = 2
        mock_gst.MessageType.EOS = 3


if __name__ == '__main__':
    pytest.main([__file__])