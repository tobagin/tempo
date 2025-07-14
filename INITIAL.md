## FEATURE:

-   A simple, reliable, and aesthetically pleasing metronome application, **Tempo**, for musicians.
-   A modern graphical interface built with **GTK4** and **Libadwaita**, providing a distraction-free user experience.
-   **Customizable Tempo**: Set beats per minute (BPM) using a slider, stepper, or tap tempo.
-   **Time Signature Control**: Easily select common time signatures (e.g., 4/4, 3/4, 6/8), with an accented sound for the first beat of each measure.
-   **Clear Feedback**: Provides precise auditory clicks and a clear visual indicator that syncs with the beat.
-   Packaged as a **Flatpak** application for easy installation on Linux desktops.

---

## EXAMPLES:

The following files will form the core structure of the application, designed for a modern GTK project.

-   `tempo/main.py` - The main application entry point to initialize and run the GTK app.
-   `tempo/window.py` - Defines the main `Adw.ApplicationWindow`. This will contain all UI controls, including the BPM slider, time signature selector, start/stop button, and visual beat indicator.
-   `tempo/metronome.py` - The core timing engine. This module will run in a high-priority background thread to ensure accurate, low-latency beat generation and audio playback using a library like **GStreamer**.
-   `data/com.example.Tempo.blp` - The UI layout defined declaratively using **Blueprint** syntax.
-   `data/sounds/` - A directory containing audio assets for the metronome clicks (e.g., `high.wav`, `low.wav`).
-   `com.github.your_username.Tempo.json` - The **Flatpak** manifest for building the application, packaging sound assets, and defining necessary permissions.

---

## DOCUMENTATION:

Development will be guided by the official documentation for the following libraries and platforms.

### Core Logic & Audio
-   **GStreamer**: `https://gstreamer.freedesktop.org/documentation/`
-   **Python GObject Introspection**: `https://pygobject.readthedocs.io/`

### Frontend & Packaging
-   **GTK4**: `https://docs.gtk.org/gtk4/`
-   **Libadwaita**: `https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/`
-   **Blueprint**: `https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/`
-   **Flatpak**: `https://docs.flatpak.org/`
-   **Flathub**: `https://docs.flathub.org/`

---

## OTHER CONSIDERATIONS:

-   **Timing Precision**: The metronome's core challenge is timing accuracy. The engine must be carefully designed to prevent drift and jitter, likely using a high-precision clock rather than standard `time.sleep()`.
-   **Audio Latency**: The application should use a low-latency audio path (like GStreamer's) to ensure the sound is produced as close to the beat event as possible.
-   **Resource Packaging**: The sound files must be included as data in the Flatpak manifest to be accessible by the application at runtime.
-   **Flatpak Permissions**: The application will require access to the system's audio device (`--socket=pulseaudio`), which is a standard permission.
-   **README Structure**: The main `README.md` will describe the project and provide clear instructions for building with Flatpak and running the app in a development environment.
