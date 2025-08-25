project('tempo', ['c', 'vala'],
  version: '1.2.1',
  license: 'GPL3+',
  meson_version: '>= 0.59.0',
  default_options: [
    'warning_level=2',
    'werror=false',
  ]
)

# Project metadata
base_application_id = 'io.github.tobagin.tempo'
base_project_name = 'Tempo'
project_description = 'A modern metronome application for musicians'

# Check if this is a development build
development = get_option('development')
application_id = development ? base_application_id + '.Devel' : base_application_id
project_name = development ? base_project_name + ' (Devel)' : base_project_name

# Import gnome module
gnome = import('gnome')
i18n = import('i18n')
fs = import('fs')

# Dependencies
gtk4_dep = dependency('gtk4', version: '>= 4.10.0')
adw_dep = dependency('libadwaita-1', version: '>= 1.5')
glib_dep = dependency('glib-2.0', version: '>= 2.76')
gobject_dep = dependency('gobject-2.0', version: '>= 2.76')
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
conf.set('PKGDATA_DIR', join_paths(get_option('prefix'), get_option('datadir'), 'tempo'))
conf.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

# Configuration for config.vala
config_conf = configuration_data()
config_conf.set('VERSION', meson.project_version())
config_conf.set('GETTEXT_PACKAGE', 'tempo')
config_conf.set('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
config_conf.set('DATADIR', join_paths(get_option('prefix'), get_option('datadir')))
config_conf.set('APP_ID', application_id)
config_conf.set('RESOURCE_PATH', '/' + application_id.replace('.', '/'))
config_conf.set('PROJECT_NAME', project_name)
config_conf.set('DEVELOPMENT', development.to_string())

# Generate config.vala from config.vala.in
config_vala = configure_file(
  input: 'src/config.vala.in',
  output: 'config.vala',
  configuration: config_conf
)

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