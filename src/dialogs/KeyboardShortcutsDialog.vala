/**
 * Keyboard shortcuts dialog for the Tempo metronome application.
 * 
 * This class displays all available keyboard shortcuts in an organized manner
 * using the modern Libadwaita ShortcutsDialog via Gtk.Builder.
 */

using Gtk;
using Adw;

public class KeyboardShortcutsDialog {
    
    /**
     * Present the keyboard shortcuts dialog.
     */
    public static void present(Gtk.Window parent) {
#if DEVELOPMENT
        var builder = new Gtk.Builder.from_resource("/io/github/tobagin/tempo/Devel/ui/keyboard_shortcuts_dialog.ui");
#else
        var builder = new Gtk.Builder.from_resource("/io/github/tobagin/tempo/ui/keyboard_shortcuts_dialog.ui");
#endif
        var dialog = builder.get_object("shortcuts_dialog") as Adw.ShortcutsDialog;
        dialog.present(parent);
    }
}