"""
Preferences dialog for the Tempo metronome application.

This module implements the preferences window using Libadwaita,
allowing users to configure audio settings and application behavior.
"""

import os
from typing import Optional

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gio, GLib


@Gtk.Template(resource_path='/io/github/tobagin/tempo/ui/preferences_dialog.ui')
class PreferencesDialog(Adw.PreferencesWindow):
    """
    Preferences dialog window.
    
    Provides interface for configuring audio settings, behavior options,
    and visual preferences for the metronome application.
    """
    
    __gtype_name__ = 'PreferencesDialog'
    
    # Template children from Blueprint UI
    volume_scale: Gtk.Scale = Gtk.Template.Child()
    accent_volume_scale: Gtk.Scale = Gtk.Template.Child()
    custom_sounds_switch: Gtk.Switch = Gtk.Template.Child()
    high_sound_button: Gtk.Button = Gtk.Template.Child()
    low_sound_button: Gtk.Button = Gtk.Template.Child()
    tap_sensitivity_spin: Gtk.SpinButton = Gtk.Template.Child()
    start_on_launch_switch: Gtk.Switch = Gtk.Template.Child()
    keep_on_top_switch: Gtk.Switch = Gtk.Template.Child()
    theme_dropdown: Gtk.DropDown = Gtk.Template.Child()
    show_beat_numbers_switch: Gtk.Switch = Gtk.Template.Child()
    flash_on_beat_switch: Gtk.Switch = Gtk.Template.Child()
    downbeat_color_switch: Gtk.Switch = Gtk.Template.Child()
    
    def __init__(self, **kwargs) -> None:
        """
        Initialize the preferences dialog.
        
        Args:
            **kwargs: Additional arguments
        """
        super().__init__(**kwargs)
        
        # Initialize settings
        self.settings = Gio.Settings.new('io.github.tobagin.tempo')
        
        # Custom sound file paths
        self.custom_high_sound = ""
        self.custom_low_sound = ""
        
        # Load current settings
        self._load_settings()
        
        # Connect signals
        self._connect_signals()
        
    def _load_settings(self) -> None:
        """Load current settings from GSettings."""
        # Audio settings
        self.volume_scale.set_value(self.settings.get_double('click-volume'))
        self.accent_volume_scale.set_value(self.settings.get_double('accent-volume'))
        
        # Sound settings
        self.custom_sounds_switch.set_active(
            self.settings.get_boolean('use-custom-sounds')
        )
        
        # Behavior settings
        self.tap_sensitivity_spin.set_value(5)  # Default value
        self.start_on_launch_switch.set_active(False)  # Default value
        self.keep_on_top_switch.set_active(False)  # Default value
        
        # Visual settings - Theme
        # 0 = Auto, 1 = Light, 2 = Dark
        self.theme_dropdown.set_selected(0)  # Default to Auto
        
        # Visual settings - Beat indicator
        self.show_beat_numbers_switch.set_active(True)  # Default value
        self.flash_on_beat_switch.set_active(True)  # Default value
        self.downbeat_color_switch.set_active(True)  # Default value
        
    def _connect_signals(self) -> None:
        """Connect UI signals to handlers."""
        # Audio settings
        self.volume_scale.connect('value-changed', self._on_volume_changed)
        self.accent_volume_scale.connect('value-changed', self._on_accent_volume_changed)
        
        # Sound settings
        self.custom_sounds_switch.connect('state-set', self._on_custom_sounds_toggled)
        self.high_sound_button.connect('clicked', self._on_high_sound_clicked)
        self.low_sound_button.connect('clicked', self._on_low_sound_clicked)
        
        # Behavior settings
        self.tap_sensitivity_spin.connect('value-changed', self._on_tap_sensitivity_changed)
        self.start_on_launch_switch.connect('state-set', self._on_start_on_launch_toggled)
        self.keep_on_top_switch.connect('state-set', self._on_keep_on_top_toggled)
        
        # Visual settings
        self.theme_dropdown.connect('notify::selected', self._on_theme_changed)
        self.show_beat_numbers_switch.connect('state-set', self._on_show_beat_numbers_toggled)
        self.flash_on_beat_switch.connect('state-set', self._on_flash_on_beat_toggled)
        self.downbeat_color_switch.connect('state-set', self._on_downbeat_color_toggled)
        
    def _on_volume_changed(self, scale: Gtk.Scale) -> None:
        """Handle volume scale change."""
        value = scale.get_value()
        self.settings.set_double('click-volume', value)
        
    def _on_accent_volume_changed(self, scale: Gtk.Scale) -> None:
        """Handle accent volume scale change."""
        value = scale.get_value()
        self.settings.set_double('accent-volume', value)
        
    def _on_custom_sounds_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle custom sounds toggle."""
        self.settings.set_boolean('use-custom-sounds', state)
        
        # Update button sensitivity
        self.high_sound_button.set_sensitive(state)
        self.low_sound_button.set_sensitive(state)
        
    def _on_high_sound_clicked(self, button: Gtk.Button) -> None:
        """Handle high sound file selection."""
        self._select_sound_file("high")
        
    def _on_low_sound_clicked(self, button: Gtk.Button) -> None:
        """Handle low sound file selection."""
        self._select_sound_file("low")
        
    def _select_sound_file(self, sound_type: str) -> None:
        """
        Show file chooser for sound file selection.
        
        Args:
            sound_type: "high" or "low"
        """
        # Create file dialog (GTK4 portal-enabled)
        dialog = Gtk.FileDialog()
        dialog.set_title(f"Select {sound_type.title()} Click Sound")
        
        # Create file filters
        filter_audio = Gtk.FileFilter()
        filter_audio.set_name("Audio Files")
        filter_audio.add_mime_type("audio/wav")
        filter_audio.add_mime_type("audio/ogg")
        filter_audio.add_mime_type("audio/mp3")
        filter_audio.add_mime_type("audio/flac")
        
        filter_all = Gtk.FileFilter()
        filter_all.set_name("All Files")
        filter_all.add_pattern("*")
        
        # Create filter list store
        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(filter_audio)
        filters.append(filter_all)
        dialog.set_filters(filters)
        dialog.set_default_filter(filter_audio)
        
        # Show dialog asynchronously (portal-enabled)
        dialog.open(self, None, self._on_file_dialog_finish, sound_type)
        
    def _on_file_dialog_finish(self, dialog: Gtk.FileDialog, 
                              result: Gio.AsyncResult, sound_type: str) -> None:
        """
        Handle file dialog completion (async callback).
        
        Args:
            dialog: File dialog
            result: Async result
            sound_type: "high" or "low"
        """
        try:
            file = dialog.open_finish(result)
            if file:
                file_path = file.get_path()
                
                # Store the selected file
                if sound_type == "high":
                    self.custom_high_sound = file_path
                    self.high_sound_button.set_label(os.path.basename(file_path))
                else:
                    self.custom_low_sound = file_path
                    self.low_sound_button.set_label(os.path.basename(file_path))
                    
                # Save to settings (you might want to add these keys to the schema)
                # self.settings.set_string(f'custom-{sound_type}-sound', file_path)
                
        except Exception:
            # User cancelled or error occurred
            pass
        
    def _on_tap_sensitivity_changed(self, spin: Gtk.SpinButton) -> None:
        """Handle tap sensitivity change."""
        value = int(spin.get_value())
        # Save to settings when this key is added to schema
        # self.settings.set_int('tap-sensitivity', value)
        
    def _on_start_on_launch_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle start on launch toggle."""
        # Save to settings when this key is added to schema
        # self.settings.set_boolean('start-on-launch', state)
        pass
        
    def _on_keep_on_top_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle keep on top toggle."""
        # Save to settings when this key is added to schema
        # self.settings.set_boolean('keep-on-top', state)
        
        # Apply to parent window if possible
        parent = self.get_transient_for()
        if parent and hasattr(parent, 'set_keep_above'):
            parent.set_keep_above(state)
    
    def _on_theme_changed(self, dropdown: Gtk.DropDown, _param) -> None:
        """Handle theme selection change."""
        selected = dropdown.get_selected()
        
        # Get the application instance
        app = self.get_application()
        if not app:
            # Try to get it from the transient parent
            parent = self.get_transient_for()
            if parent:
                app = parent.get_application()
        
        if app and hasattr(app, 'get_style_manager'):
            style_manager = app.get_style_manager()
        else:
            style_manager = Adw.StyleManager.get_default()
        
        # Apply theme based on selection
        if selected == 0:  # Auto
            style_manager.set_color_scheme(Adw.ColorScheme.DEFAULT)
        elif selected == 1:  # Light
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_LIGHT)
        elif selected == 2:  # Dark
            style_manager.set_color_scheme(Adw.ColorScheme.FORCE_DARK)
            
    def _on_show_beat_numbers_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle show beat numbers toggle."""
        # Save to settings when this key is added to schema
        # self.settings.set_boolean('show-beat-numbers', state)
        pass
        
    def _on_flash_on_beat_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle flash on beat toggle."""
        # Save to settings when this key is added to schema
        # self.settings.set_boolean('flash-on-beat', state)
        pass
        
    def _on_downbeat_color_toggled(self, switch: Gtk.Switch, state: bool) -> None:
        """Handle downbeat color toggle."""
        # Save to settings when this key is added to schema
        # self.settings.set_boolean('downbeat-color', state)
        pass
        
    def reset_to_defaults(self) -> None:
        """Reset all settings to default values."""
        # Audio settings
        self.volume_scale.set_value(0.8)
        self.accent_volume_scale.set_value(1.0)
        
        # Sound settings
        self.custom_sounds_switch.set_active(False)
        
        # Behavior settings
        self.tap_sensitivity_spin.set_value(5)
        self.start_on_launch_switch.set_active(False)
        self.keep_on_top_switch.set_active(False)
        
        # Visual settings
        self.theme_dropdown.set_selected(0)  # Reset to Auto
        self.show_beat_numbers_switch.set_active(True)
        self.flash_on_beat_switch.set_active(True)
        self.downbeat_color_switch.set_active(True)
        
        # Reset custom sound paths
        self.custom_high_sound = ""
        self.custom_low_sound = ""
        self.high_sound_button.set_label("Choose File")
        self.low_sound_button.set_label("Choose File")
        
    def get_custom_sound_paths(self) -> tuple[str, str]:
        """
        Get custom sound file paths.
        
        Returns:
            Tuple of (high_sound_path, low_sound_path)
        """
        return (self.custom_high_sound, self.custom_low_sound)
        
    def validate_custom_sounds(self) -> bool:
        """
        Validate that custom sound files exist and are readable.
        
        Returns:
            True if custom sounds are valid or not enabled
        """
        if not self.custom_sounds_switch.get_active():
            return True
            
        # Check if files exist
        if self.custom_high_sound and not os.path.exists(self.custom_high_sound):
            self._show_error("High click sound file not found")
            return False
            
        if self.custom_low_sound and not os.path.exists(self.custom_low_sound):
            self._show_error("Low click sound file not found")
            return False
            
        return True
        
    def _show_error(self, message: str) -> None:
        """
        Show an error message.
        
        Args:
            message: Error message to display
        """
        dialog = Adw.MessageDialog.new(
            self,
            "Error",
            message
        )
        dialog.add_response("ok", "OK")
        dialog.present()