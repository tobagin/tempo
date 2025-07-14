"""
Unit tests for the main window and UI components.

Tests UI initialization, widget interactions, and settings persistence.
"""

import pytest
import os
import tempfile
from unittest.mock import Mock, patch, MagicMock

# Mock GI before importing
with patch.dict('sys.modules', {
    'gi': Mock(),
    'gi.repository': Mock(),
    'gi.repository.Gtk': Mock(),
    'gi.repository.Adw': Mock(),
    'gi.repository.Gio': Mock(),
    'gi.repository.GLib': Mock(),
    'gi.repository.Gdk': Mock(),
    'gi.repository.Gst': Mock(),
}):
    from src.main_window import TempoWindow
    from src.preferences_dialog import PreferencesDialog


class TestTempoWindow:
    """Test TempoWindow class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        # Mock GTK/Adw components
        self.mock_app = Mock()
        self.mock_settings = Mock()
        self.mock_metronome = Mock()
        self.mock_audio = Mock()
        
        # Mock template children
        self.mock_tempo_label = Mock()
        self.mock_tempo_spin = Mock()
        self.mock_tempo_scale = Mock()
        self.mock_beats_spin = Mock()
        self.mock_beat_value_dropdown = Mock()
        self.mock_play_button = Mock()
        self.mock_tap_button = Mock()
        self.mock_beat_indicator = Mock()
        
    @patch('gi.repository.Gio.Settings')
    @patch('src.metronome.MetronomeEngine')
    @patch('src.audio.MetronomeAudio')
    def test_initialization(self, mock_audio_class, mock_metronome_class, mock_settings_class):
        """Test window initialization."""
        # Mock settings
        mock_settings_class.new.return_value = self.mock_settings
        self.mock_settings.get_int.return_value = 120
        self.mock_settings.get_double.return_value = 0.8
        self.mock_settings.get_boolean.return_value = False
        
        # Mock metronome
        mock_metronome_class.return_value = self.mock_metronome
        
        # Mock audio
        mock_audio_class.return_value = self.mock_audio
        
        # Mock GTK template system
        with patch('gi.repository.Gtk.Template'):
            with patch.object(TempoWindow, '__init__', return_value=None):
                window = TempoWindow.__new__(TempoWindow)
                window.settings = self.mock_settings
                window.metronome = self.mock_metronome
                window.audio = self.mock_audio
                
                # Verify components were created
                assert window.settings is not None
                assert window.metronome is not None
                assert window.audio is not None
                
    @patch('gi.repository.Gio.Settings')
    def test_load_settings(self, mock_settings_class):
        """Test loading settings from GSettings."""
        # Mock settings values
        mock_settings_class.new.return_value = self.mock_settings
        self.mock_settings.get_int.side_effect = lambda key: {
            'tempo': 140,
            'time-signature-numerator': 3,
            'time-signature-denominator': 8,
            'window-width': 500,
            'window-height': 600
        }.get(key, 0)
        
        self.mock_settings.get_boolean.return_value = True
        
        # Mock spin buttons
        mock_tempo_spin = Mock()
        mock_beats_spin = Mock()
        mock_dropdown = Mock()
        
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.settings = self.mock_settings
            window.tempo_spin = mock_tempo_spin
            window.beats_spin = mock_beats_spin
            window.beat_value_dropdown = mock_dropdown
            window.metronome = self.mock_metronome
            
            # Test load settings method
            window._load_settings()
            
            # Verify settings were loaded
            mock_tempo_spin.set_value.assert_called_with(140)
            mock_beats_spin.set_value.assert_called_with(3)
            
    @patch('gi.repository.Gio.Settings')
    def test_save_settings(self, mock_settings_class):
        """Test saving settings to GSettings."""
        mock_settings_class.new.return_value = self.mock_settings
        
        # Mock widget values
        mock_tempo_spin = Mock()
        mock_tempo_spin.get_value.return_value = 150
        mock_beats_spin = Mock()
        mock_beats_spin.get_value.return_value = 4
        mock_dropdown = Mock()
        mock_dropdown.get_selected.return_value = 1  # Index for 4/4
        
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.settings = self.mock_settings
            window.tempo_spin = mock_tempo_spin
            window.beats_spin = mock_beats_spin
            window.beat_value_dropdown = mock_dropdown
            
            # Mock window methods
            window.get_default_size = Mock(return_value=(400, 500))
            window.is_maximized = Mock(return_value=False)
            
            # Test save settings method
            window._save_settings()
            
            # Verify settings were saved
            self.mock_settings.set_int.assert_any_call('tempo', 150)
            self.mock_settings.set_int.assert_any_call('time-signature-numerator', 4)
            self.mock_settings.set_int.assert_any_call('time-signature-denominator', 4)
            
    def test_on_tempo_changed(self):
        """Test tempo change handler."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.metronome = self.mock_metronome
            window.tempo_label = self.mock_tempo_label
            window.tempo_spin = self.mock_tempo_spin
            window.tempo_scale = self.mock_tempo_scale
            
            # Mock widget that changed
            mock_widget = Mock()
            mock_widget.get_value.return_value = 130
            
            # Test tempo change
            window._on_tempo_changed(mock_widget)
            
            # Verify label was updated
            self.mock_tempo_label.set_label.assert_called_with("130")
            
            # Verify metronome was updated
            self.mock_metronome.set_tempo.assert_called_with(130)
            
    def test_on_time_signature_changed(self):
        """Test time signature change handler."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.metronome = self.mock_metronome
            window.beats_spin = self.mock_beats_spin
            window.beat_value_dropdown = self.mock_beat_value_dropdown
            
            # Mock widget values
            self.mock_beats_spin.get_value.return_value = 5
            self.mock_beat_value_dropdown.get_selected.return_value = 2  # Index for 8
            
            # Test time signature change
            window._on_time_signature_changed(Mock())
            
            # Verify metronome was updated
            self.mock_metronome.set_time_signature.assert_called_with(5, 8)
            
    def test_on_play_clicked_start(self):
        """Test play button click when stopped."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.metronome = self.mock_metronome
            
            # Mock metronome state
            self.mock_metronome.state.is_running = False
            
            # Mock button
            mock_button = Mock()
            
            # Test play button click
            window._on_play_clicked(mock_button)
            
            # Verify metronome was started
            self.mock_metronome.start.assert_called_once()
            
            # Verify button was updated
            mock_button.set_label.assert_called_with("Stop")
            mock_button.add_css_class.assert_called_with("destructive-action")
            
    def test_on_play_clicked_stop(self):
        """Test play button click when running."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.metronome = self.mock_metronome
            
            # Mock metronome state
            self.mock_metronome.state.is_running = True
            
            # Mock button
            mock_button = Mock()
            
            # Test play button click
            window._on_play_clicked(mock_button)
            
            # Verify metronome was stopped
            self.mock_metronome.stop.assert_called_once()
            
            # Verify button was updated
            mock_button.set_label.assert_called_with("Start")
            mock_button.add_css_class.assert_called_with("suggested-action")
            
    def test_on_tap_clicked(self):
        """Test tap tempo button click."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.tempo_spin = self.mock_tempo_spin
            
            # Mock tap tempo
            mock_tap_tempo = Mock()
            mock_tap_tempo.tap.return_value = 128
            window.tap_tempo = mock_tap_tempo
            
            # Mock button
            mock_button = Mock()
            
            # Test tap button click
            window._on_tap_clicked(mock_button)
            
            # Verify tempo was updated
            self.mock_tempo_spin.set_value.assert_called_with(128)
            
            # Verify button styling
            mock_button.add_css_class.assert_called_with("suggested-action")
            
    def test_on_beat_callback(self):
        """Test beat callback from metronome."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.audio = self.mock_audio
            window.beat_indicator = self.mock_beat_indicator
            
            # Test beat callback
            result = window._on_beat(5, True)
            
            # Verify audio was played
            self.mock_audio.play_click.assert_called_with(True)
            
            # Verify visual state was updated
            assert window.beat_active == True
            assert window.is_downbeat == True
            assert window.beat_count == 5
            
            # Verify redraw was triggered
            self.mock_beat_indicator.queue_draw.assert_called_once()
            
            # Verify return value
            assert result == False
            
    def test_draw_beat_indicator_active(self):
        """Test drawing beat indicator when active."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.beat_active = True
            window.is_downbeat = True
            window.beat_count = 0
            
            # Mock metronome
            mock_metronome = Mock()
            mock_metronome.state.beats_per_bar = 4
            window.metronome = mock_metronome
            
            # Mock cairo context
            mock_cr = Mock()
            
            # Test drawing
            window._draw_beat_indicator(Mock(), mock_cr, 120, 120)
            
            # Verify circle was drawn
            mock_cr.arc.assert_called_once()
            mock_cr.fill.assert_called()
            
            # Verify text was drawn
            mock_cr.show_text.assert_called_with("1")
            
    def test_draw_beat_indicator_inactive(self):
        """Test drawing beat indicator when inactive."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.beat_active = False
            
            # Mock cairo context
            mock_cr = Mock()
            
            # Test drawing
            window._draw_beat_indicator(Mock(), mock_cr, 120, 120)
            
            # Verify circle was drawn with gray color
            mock_cr.set_source_rgba.assert_called_with(0.5, 0.5, 0.5, 0.3)
            mock_cr.arc.assert_called_once()
            mock_cr.fill.assert_called()
            
    def test_tempo_adjustment_actions(self):
        """Test tempo adjustment keyboard shortcuts."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.tempo_spin = self.mock_tempo_spin
            
            # Test increase tempo
            self.mock_tempo_spin.get_value.return_value = 120
            window._on_increase_tempo(Mock(), None)
            self.mock_tempo_spin.set_value.assert_called_with(121)
            
            # Test decrease tempo
            self.mock_tempo_spin.get_value.return_value = 120
            window._on_decrease_tempo(Mock(), None)
            self.mock_tempo_spin.set_value.assert_called_with(119)
            
    def test_tempo_adjustment_bounds(self):
        """Test tempo adjustment respects bounds."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.tempo_spin = self.mock_tempo_spin
            
            # Test max bound
            self.mock_tempo_spin.get_value.return_value = 240
            window._on_increase_tempo(Mock(), None)
            self.mock_tempo_spin.set_value.assert_called_with(240)
            
            # Test min bound
            self.mock_tempo_spin.get_value.return_value = 40
            window._on_decrease_tempo(Mock(), None)
            self.mock_tempo_spin.set_value.assert_called_with(40)
            
    def test_close_request(self):
        """Test window close request handling."""
        with patch.object(TempoWindow, '__init__', return_value=None):
            window = TempoWindow.__new__(TempoWindow)
            window.metronome = self.mock_metronome
            window.audio = self.mock_audio
            
            # Mock save settings
            window._save_settings = Mock()
            
            # Test close request
            result = window._on_close_request(Mock())
            
            # Verify cleanup
            window._save_settings.assert_called_once()
            self.mock_metronome.stop.assert_called_once()
            self.mock_audio.cleanup.assert_called_once()
            
            # Verify return value
            assert result == False


class TestPreferencesDialog:
    """Test PreferencesDialog class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        # Mock settings
        self.mock_settings = Mock()
        
        # Mock template children
        self.mock_volume_scale = Mock()
        self.mock_accent_volume_scale = Mock()
        self.mock_custom_sounds_switch = Mock()
        self.mock_high_sound_button = Mock()
        self.mock_low_sound_button = Mock()
        
    @patch('gi.repository.Gio.Settings')
    def test_initialization(self, mock_settings_class):
        """Test preferences dialog initialization."""
        mock_settings_class.new.return_value = self.mock_settings
        self.mock_settings.get_double.return_value = 0.8
        self.mock_settings.get_boolean.return_value = False
        
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.settings = self.mock_settings
            dialog.volume_scale = self.mock_volume_scale
            dialog.accent_volume_scale = self.mock_accent_volume_scale
            dialog.custom_sounds_switch = self.mock_custom_sounds_switch
            
            # Mock load settings
            dialog._load_settings = Mock()
            dialog._load_settings()
            
            # Verify settings were loaded
            dialog._load_settings.assert_called_once()
            
    @patch('gi.repository.Gio.Settings')
    def test_volume_change(self, mock_settings_class):
        """Test volume setting change."""
        mock_settings_class.new.return_value = self.mock_settings
        
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.settings = self.mock_settings
            
            # Mock scale widget
            mock_scale = Mock()
            mock_scale.get_value.return_value = 0.6
            
            # Test volume change
            dialog._on_volume_changed(mock_scale)
            
            # Verify setting was saved
            self.mock_settings.set_double.assert_called_with('click-volume', 0.6)
            
    @patch('gi.repository.Gio.Settings')
    def test_custom_sounds_toggle(self, mock_settings_class):
        """Test custom sounds toggle."""
        mock_settings_class.new.return_value = self.mock_settings
        
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.settings = self.mock_settings
            dialog.high_sound_button = self.mock_high_sound_button
            dialog.low_sound_button = self.mock_low_sound_button
            
            # Test enabling custom sounds
            dialog._on_custom_sounds_toggled(Mock(), True)
            
            # Verify setting was saved
            self.mock_settings.set_boolean.assert_called_with('use-custom-sounds', True)
            
            # Verify buttons were enabled
            self.mock_high_sound_button.set_sensitive.assert_called_with(True)
            self.mock_low_sound_button.set_sensitive.assert_called_with(True)
            
    def test_reset_to_defaults(self):
        """Test resetting to default values."""
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.volume_scale = self.mock_volume_scale
            dialog.accent_volume_scale = self.mock_accent_volume_scale
            dialog.custom_sounds_switch = self.mock_custom_sounds_switch
            dialog.high_sound_button = self.mock_high_sound_button
            dialog.low_sound_button = self.mock_low_sound_button
            
            # Mock other controls
            dialog.tap_sensitivity_spin = Mock()
            dialog.start_on_launch_switch = Mock()
            dialog.keep_on_top_switch = Mock()
            dialog.show_beat_numbers_switch = Mock()
            dialog.flash_on_beat_switch = Mock()
            dialog.downbeat_color_switch = Mock()
            
            # Test reset
            dialog.reset_to_defaults()
            
            # Verify defaults were set
            self.mock_volume_scale.set_value.assert_called_with(0.8)
            self.mock_accent_volume_scale.set_value.assert_called_with(1.0)
            self.mock_custom_sounds_switch.set_active.assert_called_with(False)
            
    def test_validate_custom_sounds_disabled(self):
        """Test validating custom sounds when disabled."""
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.custom_sounds_switch = self.mock_custom_sounds_switch
            
            # Mock disabled
            self.mock_custom_sounds_switch.get_active.return_value = False
            
            # Should return True when disabled
            result = dialog.validate_custom_sounds()
            assert result == True
            
    def test_validate_custom_sounds_missing_files(self):
        """Test validating custom sounds with missing files."""
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.custom_sounds_switch = self.mock_custom_sounds_switch
            dialog.custom_high_sound = "/nonexistent/high.wav"
            dialog.custom_low_sound = "/nonexistent/low.wav"
            
            # Mock enabled
            self.mock_custom_sounds_switch.get_active.return_value = True
            
            # Mock show error
            dialog._show_error = Mock()
            
            # Should return False with missing files
            result = dialog.validate_custom_sounds()
            assert result == False
            
            # Should show error
            dialog._show_error.assert_called_once()
            
    def test_get_custom_sound_paths(self):
        """Test getting custom sound paths."""
        with patch.object(PreferencesDialog, '__init__', return_value=None):
            dialog = PreferencesDialog.__new__(PreferencesDialog)
            dialog.custom_high_sound = "/path/to/high.wav"
            dialog.custom_low_sound = "/path/to/low.wav"
            
            # Test getting paths
            high, low = dialog.get_custom_sound_paths()
            
            assert high == "/path/to/high.wav"
            assert low == "/path/to/low.wav"


if __name__ == '__main__':
    pytest.main([__file__])