# Configure template files
desktop_input = configure_file(
  input: 'io.github.tobagin.tempo.desktop.in',
  output: application_id + '.desktop.in',
  configuration: {
    'APPLICATION_ID': application_id,
    'PROJECT_NAME': project_name,
    'VERSION': meson.project_version()
  }
)

metainfo_input = configure_file(
  input: 'io.github.tobagin.tempo.metainfo.xml.in',
  output: application_id + '.metainfo.xml.in',
  configuration: {
    'APPLICATION_ID': application_id,
    'PROJECT_NAME': project_name,
    'VERSION': meson.project_version()
  }
)

# Desktop file
desktop_file = i18n.merge_file(
  input: desktop_input,
  output: application_id + '.desktop',
  type: 'desktop',
  po_dir: join_paths(meson.current_source_dir(), '..', 'po'),
  install: true,
  install_dir: desktopdir
)

# MetaInfo file
metainfo_file = i18n.merge_file(
  input: metainfo_input,
  output: application_id + '.metainfo.xml',
  type: 'xml',
  po_dir: join_paths(meson.current_source_dir(), '..', 'po'),
  install: true,
  install_dir: metainfodir
)

# Configure and install GSchema
gschema_file = configure_file(
  input: 'io.github.tobagin.tempo.gschema.xml.in',
  output: application_id + '.gschema.xml',
  configuration: {
    'APP_ID': application_id,
    'APP_ID_PATH': application_id.replace('.', '/')
  }
)

install_data(gschema_file,
  install_dir: schemadir
)

# Compile GSettings schemas for build time
gnome.compile_schemas(build_by_default: true)

# Blueprint UI files - compile to .ui
ui_files = [
  'ui/main_window.blp',
  'ui/preferences_dialog.blp',
  'ui/keyboard_shortcuts_dialog.blp'
]

ui_compiled = []
foreach ui_file : ui_files
  ui_name = fs.stem(ui_file)
  ui_compiled += custom_target(
    ui_name + '_ui',
    input: ui_file,
    output: ui_name + '.ui',
    command: [blueprint_compiler, 'compile', '--output', '@OUTPUT@', '@INPUT@'],
    install: false
  )
endforeach

# Install scalable app icon
configure_file(
  input: 'icons/hicolor/scalable/io.github.tobagin.tempo.svg',
  output: application_id + '.svg',
  copy: true,
  install: true,
  install_dir: join_paths(icondir, 'hicolor', 'scalable', 'apps')
)

# Sound files
install_data(
  'sounds/high.wav',
  'sounds/low.wav',
  install_dir: join_paths(pkgdatadir, 'sounds')
)

# CSS styles
install_data(
  'style.css',
  install_dir: pkgdatadir
)

# Configure the gresource.xml file with the correct resource path
gresource_xml = configure_file(
  input: 'resources/tempo.gresource.xml.in',
  output: 'tempo.gresource.xml',
  configuration: {
    'RESOURCE_PATH': '/' + application_id.replace('.', '/')
  }
)

# GResource file - generate both .h and .c versions
gresource_h = gnome.compile_resources(
  'tempo-resources-h',
  gresource_xml,
  dependencies: ui_compiled,
  source_dir: [meson.current_source_dir(), meson.current_build_dir()],
  c_name: 'tempo_resources'
)

gresource_file = gnome.compile_resources(
  'tempo-resources',
  gresource_xml,
  dependencies: ui_compiled,
  source_dir: [meson.current_source_dir(), meson.current_build_dir()],
  gresource_bundle: true,
  install: true,
  install_dir: pkgdatadir
)