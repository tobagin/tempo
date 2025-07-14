project('tempo', 'c',
  version: '1.0.1',
  license: 'GPL3+',
  meson_version: '>= 0.59.0',
  default_options: [
    'warning_level=2',
    'werror=false',
  ]
)

# Project metadata
application_id = 'io.github.tobagin.tempo'
project_name = 'Tempo'
project_description = 'A modern metronome application for musicians'

# Import gnome module
gnome = import('gnome')
i18n = import('i18n')
python = import('python')
fs = import('fs')

# Python installation
python_bin = python.find_installation('python3')
if not python_bin.found()
  error('Python 3 is required')
endif

# Dependencies
dependency('gtk4', version: '>= 4.10.0')
dependency('libadwaita-1', version: '>= 1.5')
gstreamer_dep = dependency('gstreamer-1.0', version: '>= 1.18', required: false)
gstreamer_audio_dep = dependency('gstreamer-audio-1.0', version: '>= 1.18', required: false)

if not gstreamer_dep.found() or not gstreamer_audio_dep.found()
  warning('GStreamer not found - audio functionality will be limited')
endif

# Find blueprint-compiler
blueprint_compiler = find_program('blueprint-compiler', required: true)

# Configuration
conf = configuration_data()
conf.set('APPLICATION_ID', application_id)
conf.set('PROJECT_NAME', project_name)
conf.set('VERSION', meson.project_version())
conf.set('PYTHON_DIR', python_bin.get_install_dir())
conf.set('PYTHON_EXEC', python_bin.full_path())
conf.set('PKGDATA_DIR', join_paths(get_option('prefix'), get_option('datadir'), 'tempo'))
conf.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

# Directories
prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
pkgdatadir = join_paths(datadir, 'tempo')
localedir = join_paths(prefix, get_option('localedir'))
schemadir = join_paths(datadir, 'glib-2.0', 'schemas')
desktopdir = join_paths(datadir, 'applications')
metainfodir = join_paths(datadir, 'metainfo')
icondir = join_paths(datadir, 'icons')

# Global configuration
subdir('po')
subdir('data')
subdir('src')
subdir('tests')

# Use gnome.post_install() for proper schema compilation
gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)