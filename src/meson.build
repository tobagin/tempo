# Vala source files for the main application
vala_sources = [
  'main.vala',
  'metronome_engine.vala',
  'tap_tempo.vala',
]

# Create main Tempo executable
executable('tempo',
  vala_sources,
  dependencies: [
    gtk4_dep,
    adw_dep,
    glib_dep,
    gobject_dep,
  ],
  vala_args: [
    '--pkg=gtk4',
    '--pkg=libadwaita-1',
    '--pkg=glib-2.0',
    '--pkg=gobject-2.0',
    '--target-glib=2.76',
  ],
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