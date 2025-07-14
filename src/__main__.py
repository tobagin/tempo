"""
Entry point for running Tempo as a Python module.

This module allows running the application with:
    python -m src
"""

import sys
import os

# Add the project root to the Python path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

def main():
    """Main entry point for module execution."""
    try:
        # Set up environment
        os.environ.setdefault('PYTHONPATH', project_root)
        
        # Import and run the application
        from src.main_window import TempoWindow
        from src.preferences_dialog import PreferencesDialog
        
        import gi
        gi.require_version('Gtk', '4.0')
        gi.require_version('Adw', '1') 
        gi.require_version('Gst', '1.0')
        
        from gi.repository import Gtk, Adw, Gio, GLib, Gst
        
        # Initialize GStreamer
        Gst.init(None)
        
        # Create application
        app = Adw.Application(
            application_id="io.github.tobagin.tempo",
            flags=Gio.ApplicationFlags.FLAGS_NONE
        )
        
        def on_activate(application):
            """Application activation callback."""
            window = TempoWindow(application=application)
            window.present()
            
        app.connect('activate', on_activate)
        
        # Run the application
        exit_code = app.run(sys.argv)
        sys.exit(exit_code)
        
    except ImportError as e:
        print(f"Failed to import required modules: {e}")
        print("Make sure all dependencies are installed:")
        print("- PyGObject (python3-gi)")
        print("- GTK4 (libgtk-4-1)")
        print("- Libadwaita (libadwaita-1-0)")
        print("- GStreamer (gstreamer1.0-plugins-base)")
        sys.exit(1)
        
    except Exception as e:
        print(f"Failed to start application: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()