# Desktop file
desktop_file = configure_file(
  input: 'io.github.tobagin.tempo.desktop.in',
  output: 'io.github.tobagin.tempo.desktop',
  configuration: conf,
  install: true,
  install_dir: desktopdir
)

# AppData file
appdata_file = configure_file(
  input: 'io.github.tobagin.tempo.appdata.xml.in',
  output: 'io.github.tobagin.tempo.appdata.xml',
  configuration: conf,
  install: true,
  install_dir: metainfodir
)

# GSettings schema
install_data(
  'io.github.tobagin.tempo.gschema.xml',
  install_dir: schemadir
)

# Blueprint UI files - compile to .ui
ui_files = [
  'ui/main_window.blp',
  'ui/preferences_dialog.blp'
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

# Icons - PNG sizes
icon_sizes = ['16x16', '32x32', '48x48', '64x64', '128x128', '256x256', '512x512']
foreach size : icon_sizes
  install_data(
    join_paths('icons', 'hicolor', size, 'apps', 'io.github.tobagin.tempo.png'),
    install_dir: join_paths(icondir, 'hicolor', size, 'apps')
  )
endforeach

# Icons - SVG (scalable and symbolic)
install_data(
  'icons/io.github.tobagin.tempo.svg',
  install_dir: join_paths(icondir, 'hicolor', 'scalable', 'apps')
)

install_data(
  'icons/io.github.tobagin.tempo-symbolic.svg',
  install_dir: join_paths(icondir, 'hicolor', 'symbolic', 'apps')
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

# GResource file - generate both .h and .c versions
gresource_h = gnome.compile_resources(
  'tempo-resources-h',
  'resources/tempo.gresource.xml',
  dependencies: ui_compiled,
  source_dir: meson.current_source_dir(),
  c_name: 'tempo_resources'
)

gresource_file = gnome.compile_resources(
  'tempo-resources',
  'resources/tempo.gresource.xml',
  dependencies: ui_compiled,
  source_dir: meson.current_source_dir(),
  gresource_bundle: true,
  install: true,
  install_dir: pkgdatadir
)