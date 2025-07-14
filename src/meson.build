# Python source files
python_sources = [
  '__init__.py',
  '__main__.py',
  'main_window.py',
  'preferences_dialog.py',
  'metronome.py',
  'audio.py',
  '_version.py'
]

# Install Python sources
foreach source : python_sources
  python_bin.install_sources(source, subdir: 'src')
endforeach

# Generate executable from template
executable = configure_file(
  input: 'tempo.in',
  output: 'tempo',
  configuration: conf,
  install: true,
  install_dir: bindir,
  install_mode: 'r-xr-xr-x'
)