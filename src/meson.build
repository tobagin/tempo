# Vala source files for the main application
vala_sources = [
  'Main.vala',
  'windows/MainWindow.vala',
  'controllers/MetronomeViewController.vala',
  'controllers/PatternViewController.vala',
  'controllers/TrainerViewController.vala',
  'dialogs/PreferencesDialog.vala',
  'dialogs/KeyboardShortcutsDialog.vala',
  'dialogs/PresetManagerDialog.vala',
  'utils/MetronomeEngine.vala',
  'utils/TapTempo.vala',
  'utils/PracticeTimer.vala',
  'utils/TempoTrainer.vala',
  'utils/Preset.vala',
  'utils/PresetManager.vala',
  'utils/MutePattern.vala',
  'utils/MutePatternFactory.vala',
  'utils/VisualMode.vala',
  'utils/RhythmPattern.vala',
  'utils/PatternLibrary.vala',
  'utils/PatternEngine.vala',
  config_vala,  # Generated config.vala file
]

# Create main Tempo executable
executable('tempo',
  vala_sources,
  gresource_h,  # Use the generated resource header
  dependencies: [
    gtk4_dep,
    adw_dep,
    glib_dep,
    gobject_dep,
    json_glib_dep,
    gee_dep,
    gstreamer_dep,
    gstreamer_audio_dep,
  ],
  vala_args: [
    '--pkg=gtk4',
    '--pkg=libadwaita-1',
    '--pkg=glib-2.0',
    '--pkg=gobject-2.0',
    '--pkg=json-glib-1.0',
    '--pkg=gee-0.8',
    '--pkg=gstreamer-1.0',
    '--pkg=gstreamer-audio-1.0',
    '--target-glib=2.76',
  ] + (development ? ['--define=DEVELOPMENT'] : []),
  c_args: [
    '-DGETTEXT_PACKAGE="tempo"',
    '-DLOCALEDIR="@0@"'.format(localedir),
    '-DPKGDATA_DIR="@0@"'.format(pkgdatadir),
    '-DAPPLICATION_ID="@0@"'.format(application_id),
    '-DVERSION="@0@"'.format(meson.project_version()),
  ],
  link_args: ['-lm'], # Link with math library
  install: true,
  install_dir: bindir
)
