/**
 * Keyboard shortcuts dialog for the Tempo metronome application.
 * 
 * This class displays all available keyboard shortcuts in an organized manner
 * using Libadwaita components for a professional interface.
 */

using Gtk;
using Adw;

#if DEVELOPMENT
    [GtkTemplate (ui = "/io/github/tobagin/tempo/Devel/ui/keyboard_shortcuts_dialog.ui")]
#else
    [GtkTemplate (ui = "/io/github/tobagin/tempo/ui/keyboard_shortcuts_dialog.ui")]
#endif
public class KeyboardShortcutsDialog : Adw.Dialog {
    
    /**
     * Create a new keyboard shortcuts dialog.
     */
    public KeyboardShortcutsDialog() {
        GLib.Object();
        
        // Set dialog properties
        this.title = _("Keyboard Shortcuts");
        
        // Setup dialog
        setup_dialog();
    }
    
    private void setup_dialog() {
        // The UI is defined in the Blueprint template
        // This method can be used for additional setup if needed
    }
    
    /**
     * Show the keyboard shortcuts dialog.
     */
    public void show_dialog(Gtk.Widget parent) {
        this.present(parent);
    }
}