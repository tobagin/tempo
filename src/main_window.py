"""
Main window controller for the Tempo metronome application.

This module implements the main application window using GTK4 and Libadwaita,
connecting the UI with the metronome engine and audio system.
"""

import math
import time
from typing import Optional

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib, Gdk

from .metronome import MetronomeEngine, TapTempo
from .audio import MetronomeAudio, AudioConfig


@Gtk.Template(resource_path='/io/github/tobagin/tempo/ui/main_window.ui')
class TempoWindow(Adw.ApplicationWindow):
    """
    Main application window.
    
    Provides the user interface for the metronome with controls for tempo,
    time signature, and visual beat indication.
    """
    
    __gtype_name__ = 'TempoWindow'
    
    # Template children from Blueprint UI
    tempo_label: Gtk.Label = Gtk.Template.Child()
    tempo_spin: Gtk.SpinButton = Gtk.Template.Child()
    tempo_scale: Gtk.Scale = Gtk.Template.Child()
    beats_spin: Gtk.SpinButton = Gtk.Template.Child()
    beat_value_dropdown: Gtk.DropDown = Gtk.Template.Child()
    play_button: Gtk.Button = Gtk.Template.Child()
    tap_button: Gtk.Button = Gtk.Template.Child()
    beat_indicator: Gtk.DrawingArea = Gtk.Template.Child()
    
    def __init__(self, application: Adw.Application, **kwargs) -> None:
        """
        Initialize the main window.
        
        Args:
            application: The Adw.Application instance
            **kwargs: Additional arguments
        """
        super().__init__(application=application, **kwargs)
        
        # Initialize settings
        self.settings = Gio.Settings.new('io.github.tobagin.tempo')
        
        # Initialize subsystems
        self.metronome: Optional[MetronomeEngine] = None
        self.audio: Optional[MetronomeAudio] = None
        self.tap_tempo = TapTempo()
        
        # Beat indicator state
        self.beat_active = False
        self.is_downbeat = False
        self.beat_count = 0
        
        # Initialize components
        self._setup_metronome()
        self._setup_audio()
        self._setup_ui()
        self._load_settings()
        
        # Connect signals
        self._connect_signals()
        
    def _setup_metronome(self) -> None:
        """Initialize the metronome engine."""
        self.metronome = MetronomeEngine()
        self.metronome.beat_callback = self._on_beat
        
    def _setup_audio(self) -> None:
        """Initialize the audio system."""
        try:
            config = AudioConfig()
            # Load volume settings
            config.volume = self.settings.get_double('click-volume')
            config.accent_volume = self.settings.get_double('accent-volume')
            
            print(f"Audio config: volume={config.volume}, accent_volume={config.accent_volume}")
            print(f"Audio files: high={config.high_click_path}, low={config.low_click_path}")
            
            self.audio = MetronomeAudio(config)
            
            print(f"Audio initialized: {self.audio.is_initialized}")
            
        except Exception as e:
            print(f"Failed to initialize audio: {e}")
            # Show error dialog
            self._show_error_dialog("Audio Error", 
                                   f"Failed to initialize audio system: {e}")
            
    def _setup_ui(self) -> None:
        """Set up the user interface."""
        # Set up beat indicator drawing
        self.beat_indicator.set_draw_func(self._draw_beat_indicator)
        
        # Set up CSS styling
        self._setup_css()
        
        # Set up keyboard shortcuts
        self._setup_shortcuts()
        
    def _setup_css(self) -> None:
        """Load and apply CSS styling."""
        css_provider = Gtk.CssProvider()
        try:
            # Load CSS from resources
            css_provider.load_from_resource('/io/github/tobagin/tempo/style.css')
            
            # Apply to display
            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            )
        except Exception as e:
            print(f"Failed to load CSS: {e}")
            
    def _setup_shortcuts(self) -> None:
        """Set up keyboard shortcuts."""
        # Spacebar for play/pause
        shortcut = Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string("space"),
            Gtk.ShortcutAction.parse_string("action(win.toggle-play)")
        )
        self.add_shortcut(shortcut)
        
        # T key for tap tempo
        shortcut = Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string("t"),
            Gtk.ShortcutAction.parse_string("action(win.tap-tempo)")
        )
        self.add_shortcut(shortcut)
        
        # Arrow keys for tempo adjustment
        shortcut = Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string("Up"),
            Gtk.ShortcutAction.parse_string("action(win.increase-tempo)")
        )
        self.add_shortcut(shortcut)
        
        shortcut = Gtk.Shortcut.new(
            Gtk.ShortcutTrigger.parse_string("Down"),
            Gtk.ShortcutAction.parse_string("action(win.decrease-tempo)")
        )
        self.add_shortcut(shortcut)
        
    def _connect_signals(self) -> None:
        """Connect UI signals to handlers."""
        # Tempo controls
        self.tempo_spin.connect('value-changed', self._on_tempo_changed)
        self.tempo_scale.connect('value-changed', self._on_tempo_changed)
        
        # Time signature controls
        self.beats_spin.connect('value-changed', self._on_time_signature_changed)
        self.beat_value_dropdown.connect('notify::selected', self._on_time_signature_changed)
        
        # Buttons
        self.play_button.connect('clicked', self._on_play_clicked)
        self.tap_button.connect('clicked', self._on_tap_clicked)
        
        # Window signals
        self.connect('close-request', self._on_close_request)
        
        # Add actions
        self._add_actions()
        
    def _add_actions(self) -> None:
        """Add window actions."""
        # Toggle play action
        action = Gio.SimpleAction.new('toggle-play', None)
        action.connect('activate', lambda a, p: self._on_play_clicked(self.play_button))
        self.add_action(action)
        
        # Tap tempo action
        action = Gio.SimpleAction.new('tap-tempo', None)
        action.connect('activate', lambda a, p: self._on_tap_clicked(self.tap_button))
        self.add_action(action)
        
        # Tempo adjustment actions
        action = Gio.SimpleAction.new('increase-tempo', None)
        action.connect('activate', self._on_increase_tempo)
        self.add_action(action)
        
        action = Gio.SimpleAction.new('decrease-tempo', None)
        action.connect('activate', self._on_decrease_tempo)
        self.add_action(action)
        
    def _load_settings(self) -> None:
        """Load settings from GSettings."""
        # Load tempo
        tempo = self.settings.get_int('tempo')
        self.tempo_spin.set_value(tempo)
        
        # Load time signature
        numerator = self.settings.get_int('time-signature-numerator')
        denominator = self.settings.get_int('time-signature-denominator')
        
        self.beats_spin.set_value(numerator)
        
        # Set denominator in dropdown
        denominator_values = [2, 4, 8, 16]
        if denominator in denominator_values:
            self.beat_value_dropdown.set_selected(denominator_values.index(denominator))
            
        # Load window state
        width = self.settings.get_int('window-width')
        height = self.settings.get_int('window-height')
        self.set_default_size(width, height)
        
        if self.settings.get_boolean('window-maximized'):
            self.maximize()
            
        # Apply settings to metronome
        if self.metronome:
            self.metronome.set_tempo(tempo)
            self.metronome.set_time_signature(numerator, denominator)
            
    def _save_settings(self) -> None:
        """Save settings to GSettings."""
        # Save tempo
        self.settings.set_int('tempo', int(self.tempo_spin.get_value()))
        
        # Save time signature
        numerator = int(self.beats_spin.get_value())
        denominator_values = [2, 4, 8, 16]
        denominator = denominator_values[self.beat_value_dropdown.get_selected()]
        
        self.settings.set_int('time-signature-numerator', numerator)
        self.settings.set_int('time-signature-denominator', denominator)
        
        # Save window state
        width, height = self.get_default_size()
        self.settings.set_int('window-width', width)
        self.settings.set_int('window-height', height)
        
        self.settings.set_boolean('window-maximized', self.is_maximized())
        
    def _on_tempo_changed(self, widget: Gtk.Widget) -> None:
        """Handle tempo change."""
        tempo = int(widget.get_value())
        
        # Update label
        self.tempo_label.set_label(str(tempo))
        
        # Update metronome
        if self.metronome:
            self.metronome.set_tempo(tempo)
            
        # Sync spin button and scale
        if widget == self.tempo_spin:
            self.tempo_scale.set_value(tempo)
        elif widget == self.tempo_scale:
            self.tempo_spin.set_value(tempo)
            
    def _on_time_signature_changed(self, widget: Gtk.Widget, *args) -> None:
        """Handle time signature change."""
        numerator = int(self.beats_spin.get_value())
        denominator_values = [2, 4, 8, 16]
        denominator = denominator_values[self.beat_value_dropdown.get_selected()]
        
        # Update metronome
        if self.metronome:
            self.metronome.set_time_signature(numerator, denominator)
            
    def _on_play_clicked(self, button: Gtk.Button) -> None:
        """Handle play/stop button click."""
        if not self.metronome:
            return
            
        if self.metronome.state.is_running:
            # Stop metronome
            self.metronome.stop()
            button.set_label("Start")
            button.remove_css_class("destructive-action")
            button.add_css_class("suggested-action")
            
        else:
            # Start metronome
            self.metronome.start()
            button.set_label("Stop")
            button.remove_css_class("suggested-action")
            button.add_css_class("destructive-action")
            
    def _on_tap_clicked(self, button: Gtk.Button) -> None:
        """Handle tap tempo button click."""
        bpm = self.tap_tempo.tap()
        
        if bpm is not None:
            # Update tempo
            self.tempo_spin.set_value(bpm)
            
            # Visual feedback
            button.add_css_class("suggested-action")
            GLib.timeout_add(100, self._reset_tap_button_style, button)
            
    def _reset_tap_button_style(self, button: Gtk.Button) -> bool:
        """Reset tap button styling."""
        button.remove_css_class("suggested-action")
        return False
        
    def _on_beat(self, beat_count: int, is_downbeat: bool) -> bool:
        """
        Handle beat callback from metronome engine.
        
        Args:
            beat_count: Current beat number
            is_downbeat: True if this is the first beat of the measure
            
        Returns:
            False to remove from idle queue
        """
        # Play audio
        if self.audio:
            print(f"Playing beat: count={beat_count}, downbeat={is_downbeat}")
            self.audio.play_click(is_downbeat)
        else:
            print("No audio system available")
            
        # Update visual indicator
        self.beat_active = True
        self.is_downbeat = is_downbeat
        self.beat_count = beat_count
        
        # Trigger redraw
        self.beat_indicator.queue_draw()
        
        # Schedule indicator reset
        GLib.timeout_add(100, self._reset_beat_indicator)
        
        return False
        
    def _reset_beat_indicator(self) -> bool:
        """Reset beat indicator visual state."""
        self.beat_active = False
        self.beat_indicator.queue_draw()
        return False
        
    def _draw_beat_indicator(self, area: Gtk.DrawingArea, cr, width: int, height: int) -> None:
        """
        Draw the beat indicator.
        
        Args:
            area: DrawingArea widget
            cr: Cairo context
            width: Widget width
            height: Widget height
        """
        # Calculate center and radius
        center_x = width / 2
        center_y = height / 2
        radius = min(width, height) / 2 - 10
        
        # Set colors based on state
        if self.beat_active:
            if self.is_downbeat:
                # Red for downbeat
                cr.set_source_rgba(0.9, 0.2, 0.2, 1.0)
            else:
                # Blue for regular beat
                cr.set_source_rgba(0.2, 0.4, 0.9, 1.0)
        else:
            # Gray when inactive
            cr.set_source_rgba(0.5, 0.5, 0.5, 0.3)
            
        # Draw circle
        cr.arc(center_x, center_y, radius, 0, 2 * math.pi)
        cr.fill()
        
        # Draw beat number if active
        if self.beat_active and self.metronome:
            beat_in_bar = (self.beat_count % self.metronome.state.beats_per_bar) + 1
            
            # Set text color
            cr.set_source_rgba(1.0, 1.0, 1.0, 1.0)
            
            # Draw text
            cr.select_font_face("Sans", 0, 0)
            cr.set_font_size(radius * 0.8)
            
            text = str(beat_in_bar)
            text_extents = cr.text_extents(text)
            
            text_x = center_x - text_extents.width / 2
            text_y = center_y + text_extents.height / 2
            
            cr.move_to(text_x, text_y)
            cr.show_text(text)
            
    def _on_increase_tempo(self, action: Gio.SimpleAction, param) -> None:
        """Increase tempo by 1 BPM."""
        current = self.tempo_spin.get_value()
        self.tempo_spin.set_value(min(240, current + 1))
        
    def _on_decrease_tempo(self, action: Gio.SimpleAction, param) -> None:
        """Decrease tempo by 1 BPM."""
        current = self.tempo_spin.get_value()
        self.tempo_spin.set_value(max(40, current - 1))
        
    def _on_close_request(self, window) -> bool:
        """Handle window close request."""
        # Save settings
        self._save_settings()
        
        # Stop metronome
        if self.metronome:
            self.metronome.stop()
            
        # Cleanup audio
        if self.audio:
            self.audio.cleanup()
            
        return False
        
    def _show_error_dialog(self, title: str, message: str) -> None:
        """
        Show an error dialog.
        
        Args:
            title: Dialog title
            message: Error message
        """
        dialog = Adw.MessageDialog.new(
            self,
            title,
            message
        )
        dialog.add_response("ok", "OK")
        dialog.present()