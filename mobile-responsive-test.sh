#!/bin/bash
# mobile-responsive-test.sh - Quick verification of mobile responsive features

echo "🔍 Tempo Mobile Responsive Design Test Script"
echo "=============================================="
echo

# Check if app is installed
if ! flatpak list | grep -q "io.github.tobagin.tempo"; then
    echo "❌ Tempo not installed. Please build and install first."
    exit 1
fi

echo "✅ Tempo is installed"

# Check Blueprint files for breakpoints
echo
echo "📄 Checking Blueprint files for breakpoints..."
if grep -q "Adw.Breakpoint.*phone_breakpoint" data/ui/main_window.blp; then
    echo "✅ Phone breakpoint found in main_window.blp"
else
    echo "❌ Phone breakpoint NOT found"
fi

if grep -q "max-width: 550sp" data/ui/main_window.blp; then
    echo "✅ Phone breakpoint condition correct (≤550sp)"
else
    echo "❌ Phone breakpoint condition incorrect"
fi

if grep -q "Adw.Breakpoint.*tablet_breakpoint" data/ui/main_window.blp; then
    echo "✅ Tablet breakpoint found"
else
    echo "❌ Tablet breakpoint NOT found"
fi

if grep -q "max-width: 900sp" data/ui/main_window.blp; then
    echo "✅ Tablet breakpoint condition correct (≤900sp)"
else
    echo "❌ Tablet breakpoint condition incorrect"
fi

# Check CSS for touch optimizations
echo
echo "🎨 Checking CSS for touch optimizations..."
if grep -q "@media (pointer: coarse)" data/style.css; then
    echo "✅ Touch device media query found"
else
    echo "❌ Touch device media query NOT found"
fi

if grep -q "min-height: 44px" data/style.css; then
    echo "✅ Touch-friendly minimum heights defined"
else
    echo "❌ Touch-friendly heights missing"
fi

# Check for ScrolledWindow
echo
echo "📜 Checking for scrollable container..."
if grep -q "Gtk.ScrolledWindow" data/ui/main_window.blp; then
    echo "✅ ScrolledWindow found for scrollable content"
else
    echo "❌ ScrolledWindow NOT found"
fi

# Check preset manager dialog
echo
echo "📋 Checking preset manager dialog responsiveness..."
if grep -q "Adw.BreakpointBin" data/ui/preset_manager_dialog.blp; then
    echo "✅ BreakpointBin found in preset manager"
else
    echo "❌ Preset manager not responsive"
fi

# Check for mobile trainer logic in Vala
echo
echo "🔧 Checking Vala code for mobile trainer logic..."
if grep -q "trainer_user_toggled" src/windows/MainWindow.vala; then
    echo "✅ Mobile trainer toggle logic found"
else
    echo "❌ Mobile trainer logic missing"
fi

if grep -q "apply_mobile_trainer_visibility" src/windows/MainWindow.vala; then
    echo "✅ Mobile trainer visibility function found"
else
    echo "❌ Mobile trainer visibility function missing"
fi

echo
echo "=============================================="
echo "✨ Static analysis complete!"
echo
echo "Next steps:"
echo "1. Launch app: flatpak run io.github.tobagin.tempo.Devel"
echo "2. Test window resizing from 360px to 1920px"
echo "3. Use GTK Inspector: GTK_DEBUG=interactive flatpak run io.github.tobagin.tempo.Devel"
echo "4. Refer to TESTING_MOBILE_RESPONSIVE.md for full test procedures"
echo
echo "Quick manual tests:"
echo "  • Resize window to 400px width (phone) - beat indicator should be 200px"
echo "  • Resize window to 700px width (tablet) - beat indicator should be 250px"
echo "  • Resize window to 1200px width (desktop) - beat indicator should be 300px"
echo "  • Time signature should be vertical at ≤550px, horizontal at >550px"
echo "  • Tempo trainer should hide by default on phone screens"
